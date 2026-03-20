// lib/features/prediction/services/relapse_prediction_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/relapse_prediction_model.dart';

export '../models/relapse_prediction_model.dart';

/// ⚠️ Relapse Prediction Service
///
/// Evidence-based multi-factor model (GORSKI/CENAPS-inspired):
///   A — Streak fragility       (25%)
///   B — Urge acceleration      (20%)
///   C — Intensity spike        (20%)
///   D — Emotional instability  (15%)
///   E — Temporal vulnerability (12%)
///   F — Relapse history mult.  (×)
class RelapsePredictionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth           = FirebaseAuth.instance;

  static const _negativeEmotions = {
    'Stressed', 'Anxious', 'Lonely', 'Bored', 'Sad',
    'Angry', 'Frustrated', 'Depressed', 'Hopeless', 'Empty',
  };

  Future<RelapsePredictionModel> analyzeRelapseRisk() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return const RelapsePredictionModel(probability: 0, level: 'Low');

      final now     = DateTime.now();
      final results = await Future.wait([
        _firestore
            .collection('users').doc(user.uid).collection('urge_logs')
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(
                now.subtract(const Duration(days: 14))))
            .orderBy('timestamp', descending: false)
            .get(),
        _firestore
            .collection('users').doc(user.uid)
            .collection('stats').doc('streak').get(),
      ]);

      final urgeSnap   = results[0] as QuerySnapshot<Map<String, dynamic>>;
      final streakSnap = results[1] as DocumentSnapshot<Map<String, dynamic>>;
      final streakData    = streakSnap.data() ?? {};
      final currentStreak = (streakData['currentStreak'] as num?)?.toInt() ?? 0;
      final totalRelapses = (streakData['totalRelapses'] as num?)?.toInt() ?? 0;

      final docs       = urgeSnap.docs;
      final confidence = (docs.length / 30.0).clamp(0.1, 1.0);

      if (docs.isEmpty) {
        return RelapsePredictionModel(
          probability:        _streakFragility(currentStreak, totalRelapses) * 20,
          level:              'Low',
          primaryWarningSign: 'Insufficient urge log data',
          confidenceScore:    0.1,
        );
      }

      // ── A: streak fragility ────────────────────────────────────────
      final fragility = _streakFragility(currentStreak, totalRelapses);

      // ── B: urge acceleration ───────────────────────────────────────
      final mid   = now.subtract(const Duration(days: 7));
      final week1 = docs.where((d) => (d.data()['timestamp'] as Timestamp).toDate().isBefore(mid)).length;
      final week2 = docs.length - week1;
      final accel = week1 == 0 ? 1.0 : ((week2 - week1) / week1.toDouble()).clamp(-1.0, 2.0);
      final accelScore = ((accel + 1) / 3.0).clamp(0.0, 1.0);

      // ── C/D/E aggregation ──────────────────────────────────────────
      double maxIntensity = 0, totalIntensity = 0;
      int spikeCount = 0;
      final emotions = <String>[];
      final hourSet  = <int>{};

      for (final doc in docs) {
        final d         = doc.data();
        final intensity = ((d['intensity'] ?? 5) as num).toDouble();
        totalIntensity += intensity;
        if (intensity > maxIntensity) maxIntensity = intensity;
        if (intensity >= 8) spikeCount++;
        final e = d['emotion'] as String?;
        if (e != null) emotions.add(e);
        int? hour = d['hour'] as int?;
        final ts = d['timestamp'];
        if (hour == null && ts is Timestamp) hour = ts.toDate().hour;
        if (hour != null) hourSet.add(hour);
      }

      final avgIntensity   = totalIntensity / docs.length;
      final intensityScore = ((avgIntensity - 1) / 9.0).clamp(0.0, 1.0);
      final spikeScore     = (spikeCount / docs.length).clamp(0.0, 1.0);

      final negCount     = emotions.where((e) => _negativeEmotions.contains(e)).length;
      final emotionScore = emotions.isEmpty ? 0.3 : (negCount / emotions.length).clamp(0.0, 1.0);

      final lateNight    = hourSet.where((h) => h >= 22 || h <= 3).length;
      final temporalScore= (lateNight / 5.0).clamp(0.0, 1.0);

      final historyMult  = 1.0 + (totalRelapses * 0.05).clamp(0.0, 0.5);

      // ── Composite ──────────────────────────────────────────────────
      final base = (fragility      * 0.25) +
                   (accelScore     * 0.20) +
                   (intensityScore * 0.20) +
                   (emotionScore   * 0.15) +
                   (spikeScore     * 0.12) +
                   (temporalScore  * 0.08);
      final probability = (base * historyMult * 100).clamp(0.0, 100.0);

      // ── Signals ────────────────────────────────────────────────────
      final signals = <String>[];
      if (fragility    > 0.6) signals.add('Short streak after prior relapse');
      if (accelScore   > 0.6) signals.add('Urges increasing this week');
      if (spikeScore   > 0.4) signals.add('Multiple high-intensity urge spikes');
      if (emotionScore > 0.6) signals.add('Dominant negative emotional state');
      if (temporalScore> 0.4) signals.add('Frequent late-night vulnerability');
      if (totalRelapses>= 3)  signals.add('History of repeated relapses');

      final primaryWarning = signals.isNotEmpty ? signals.first
          : <String, double>{
              'Short streak fragility':  fragility,
              'Rising urge acceleration':accelScore,
              'High urge intensity':     intensityScore,
              'Emotional instability':   emotionScore,
              'Intensity spike pattern': spikeScore,
              'Late-night vulnerability':temporalScore,
            }.entries.reduce((a, b) => a.value > b.value ? a : b).key;

      final level = probability >= 80 ? 'Critical'
          : probability >= 60          ? 'High'
          : probability >= 40          ? 'Moderate'
          :                              'Low';

      return RelapsePredictionModel(
        probability:        probability,
        level:              level,
        primaryWarningSign: primaryWarning,
        warningSignals:     signals,
        confidenceScore:    confidence,
      );
    } catch (_) {
      return const RelapsePredictionModel(probability: 0, level: 'Low');
    }
  }

  double _streakFragility(int streak, int relapses) {
    final streakFactor  = 1.0 - (streak / 90.0).clamp(0.0, 1.0);
    final relapseFactor = (relapses / 10.0).clamp(0.0, 1.0);
    return ((streakFactor * 0.6) + (relapseFactor * 0.4)).clamp(0.0, 1.0);
  }
}