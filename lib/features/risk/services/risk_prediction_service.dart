// lib/features/risk/services/risk_prediction_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/risk_model.dart';

export '../models/risk_model.dart';

/// 🚦 Risk Prediction Service
///
/// Multi-signal weighted scoring:
///   • Urge frequency (7d)          — 30%
///   • Average intensity             — 25%
///   • Velocity (acceleration)       — 20%
///   • Emotional negativity ratio    — 15%
///   • High-intensity cluster density— 10%
///
/// Returns [RiskModel] (canonical model in risk/models/risk_model.dart).
class RiskPredictionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth           = FirebaseAuth.instance;

  static const _negativeEmotions = {
    'Stressed', 'Anxious', 'Lonely', 'Bored', 'Sad',
    'Angry', 'Frustrated', 'Depressed', 'Hopeless', 'Empty',
  };

  Future<RiskModel?> analyzeRisk() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final now  = DateTime.now();
      final snap = await _firestore
          .collection('users').doc(user.uid).collection('urge_logs')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(
              now.subtract(const Duration(days: 14))))
          .orderBy('timestamp', descending: false)
          .get();

      if (snap.docs.isEmpty) {
        return RiskModel(
          level: 'Low', probability: 8,
          timeWindow: 'No urges logged', peakHour: 21,
          primaryDriver: 'Insufficient data',
        );
      }

      // ── Split 14d into two 7-day windows ───────────────────────────
      final cutoff   = now.subtract(const Duration(days: 7));
      final recent   = <Map<String, dynamic>>[];
      final previous = <Map<String, dynamic>>[];
      for (final doc in snap.docs) {
        final d  = doc.data();
        final ts = (d['timestamp'] as Timestamp).toDate();
        (ts.isAfter(cutoff) ? recent : previous).add(d);
      }

      // ── Signal 1: frequency ────────────────────────────────────────
      final freqScore = (recent.length / 20.0).clamp(0.0, 1.0);

      // ── Signal 2: intensity ────────────────────────────────────────
      double totalIntensity  = 0;
      int    highCount       = 0;
      final  emotions        = <String>[];
      final  hourCounts      = <int, int>{};

      for (final d in recent) {
        final i = ((d['intensity'] ?? 5) as num).toDouble();
        totalIntensity += i;
        if (i >= 8) highCount++;
        final e = d['emotion'] as String?;
        if (e != null) emotions.add(e);
        int? h = d['hour'] as int?;
        if (h == null) {
          final ts = d['timestamp'];
          if (ts is Timestamp) h = ts.toDate().hour;
        }
        if (h != null) hourCounts[h] = (hourCounts[h] ?? 0) + 1;
      }
      final avgIntensity   = recent.isEmpty ? 5.0 : totalIntensity / recent.length;
      final intensityScore = ((avgIntensity - 1) / 9.0).clamp(0.0, 1.0);

      // ── Signal 3: velocity ─────────────────────────────────────────
      final velocity = previous.isEmpty ? 0.0
          : ((recent.length - previous.length) / previous.length.toDouble())
              .clamp(-1.0, 1.0);
      final velocityScore = ((velocity + 1) / 2.0).clamp(0.0, 1.0);

      // ── Signal 4: emotional negativity ─────────────────────────────
      final negCount     = emotions.where((e) => _negativeEmotions.contains(e)).length;
      final emotionScore = emotions.isEmpty ? 0.5
          : (negCount / emotions.length).clamp(0.0, 1.0);

      // ── Signal 5: cluster density ──────────────────────────────────
      final clusterScore = recent.isEmpty ? 0.0
          : (highCount / recent.length).clamp(0.0, 1.0);

      // ── Composite ──────────────────────────────────────────────────
      final composite   = (freqScore      * 0.30) +
                          (intensityScore * 0.25) +
                          (velocityScore  * 0.20) +
                          (emotionScore   * 0.15) +
                          (clusterScore   * 0.10);
      final probability = (composite * 100).clamp(0.0, 100.0);

      // ── Factors & primary driver ───────────────────────────────────
      final factors = <String>[];
      if (freqScore      > 0.5) factors.add('High urge frequency');
      if (intensityScore > 0.6) factors.add('Elevated urge intensity');
      if (velocity       > 0.2) factors.add('Rapidly increasing urges');
      if (emotionScore   > 0.6) factors.add('Dominant negative emotions');
      if (clusterScore   > 0.5) factors.add('Intense urge clusters detected');

      final primaryDriver = <String, double>{
        'Urge frequency':   freqScore,
        'Urge intensity':   intensityScore,
        'Rising velocity':  velocityScore,
        'Negative emotion': emotionScore,
        'Intensity spikes': clusterScore,
      }.entries.reduce((a, b) => a.value > b.value ? a : b).key;

      // ── Peak hour & window ─────────────────────────────────────────
      int peakHour = 21;
      if (hourCounts.isNotEmpty) {
        peakHour = hourCounts.entries
            .reduce((a, b) => a.value > b.value ? a : b).key;
      }
      final timeWindow = '${_fmt(peakHour)} – ${_fmt((peakHour + 2) % 24)}';

      final level = probability >= 75 ? 'Critical'
          : probability >= 55          ? 'High'
          : probability >= 35          ? 'Moderate'
          :                              'Low';

      return RiskModel(
        level:         level,
        probability:   probability,
        timeWindow:    timeWindow,
        peakHour:      peakHour,
        primaryDriver: primaryDriver,
        riskFactors:   factors,
        weeklyVelocity:velocity,
      );
    } catch (_) {
      return null;
    }
  }

  String _fmt(int h) {
    final s = h >= 12 ? 'PM' : 'AM';
    final d = h % 12 == 0 ? 12 : h % 12;
    return '$d:00 $s';
  }
}