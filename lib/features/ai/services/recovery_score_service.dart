// lib/features/ai/services/recovery_score_service.dart

import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recovery_score_model.dart';

export '../models/recovery_score_model.dart';

/// 📊 Recovery Score Service
///
/// Five-dimension composite model:
///   C1  Streak strength      (30%) — log-scaled + milestone bonuses
///   C2  Urge control         (25%) — frequency & intensity last 30d
///   C3  Emotional resilience (20%) — positive emotion ratio
///   C4  Stability            (15%) — low variance in daily urge counts
///   C5  Recovery momentum    (10%) — week-over-week urge trend
class RecoveryScoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth           = FirebaseAuth.instance;

  static const _positiveEmotions = {
    'Calm', 'Happy', 'Motivated', 'Proud', 'Grateful',
    'Hopeful', 'Strong', 'Confident', 'Peaceful', 'Content',
  };

  Future<RecoveryScoreModel> calculateRecoveryScore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return const RecoveryScoreModel(score: 0, level: 'Unknown', explanation: 'Not signed in.');
      }

      final now = DateTime.now();
      final results = await Future.wait([
        _firestore
            .collection('users').doc(user.uid).collection('urge_logs')
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(
                now.subtract(const Duration(days: 30))))
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

      final docs = urgeSnap.docs;

      // ── C1: Streak strength ────────────────────────────────────────
      double streakBonus = 0;
      for (final m in [7, 30, 90, 180, 365]) {
        if (currentStreak >= m) streakBonus += 0.05;
      }
      final streakRaw      = math.log(currentStreak + 1) / math.log(366);
      final historyPenalty = (totalRelapses * 0.03).clamp(0.0, 0.4);
      final c1             = (streakRaw + streakBonus - historyPenalty).clamp(0.0, 1.0);

      if (docs.isEmpty) {
        final score = (c1 * 70 + 30).clamp(0.0, 100.0);
        return RecoveryScoreModel(
          score: score,
          level: _level(score),
          explanation: _explanation(score, currentStreak, 'Stable'),
          componentScores: {'Streak strength': c1 * 100},
        );
      }

      // ── C2: Urge control ───────────────────────────────────────────
      double totalIntensity  = 0;
      final  emotions        = <String>[];
      final  dailyCounts     = <int, int>{};

      for (final doc in docs) {
        final data = doc.data();
        final ts   = (data['timestamp'] as Timestamp).toDate();
        final day  = now.difference(DateTime(ts.year, ts.month, ts.day)).inDays;
        if (day >= 0 && day <= 29) dailyCounts[day] = (dailyCounts[day] ?? 0) + 1;
        totalIntensity += ((data['intensity'] ?? 5) as num).toDouble();
        final e = data['emotion'] as String?;
        if (e != null) emotions.add(e);
      }

      final count        = docs.length;
      final avgIntensity = totalIntensity / count;
      final freqScore    = 1.0 - (count / 60.0).clamp(0.0, 1.0);
      final intScore     = 1.0 - ((avgIntensity - 1) / 9.0).clamp(0.0, 1.0);
      final c2           = (freqScore * 0.5 + intScore * 0.5).clamp(0.0, 1.0);

      // ── C3: Emotional resilience ───────────────────────────────────
      final posCount = emotions.where((e) => _positiveEmotions.contains(e)).length;
      final c3       = emotions.isEmpty ? 0.5 : (posCount / emotions.length).clamp(0.0, 1.0);

      // ── C4: Stability ──────────────────────────────────────────────
      final countList = List<double>.generate(30, (i) => (dailyCounts[i] ?? 0).toDouble());
      final meanC     = countList.fold(0.0, (a, b) => a + b) / 30;
      final variance  = countList.fold(0.0, (a, b) => a + math.pow(b - meanC, 2)) / 30;
      final c4        = (1.0 - (math.sqrt(variance) / 5.0)).clamp(0.0, 1.0);

      // ── C5: Momentum ───────────────────────────────────────────────
      final week1      = docs.where((d) => now.difference((d.data()['timestamp'] as Timestamp).toDate()).inDays >= 7).length;
      final week2      = count - week1;
      final momentumRaw = week1 == 0 ? 0.0 : ((week1 - week2) / week1.toDouble()).clamp(-1.0, 1.0);
      final c5          = ((momentumRaw + 1) / 2.0).clamp(0.0, 1.0);
      final momentum    = momentumRaw > 0.1 ? 'Gaining' : momentumRaw < -0.1 ? 'Losing' : 'Stable';

      // ── Weighted composite ─────────────────────────────────────────
      final composite = (c1 * 0.30) + (c2 * 0.25) + (c3 * 0.20) + (c4 * 0.15) + (c5 * 0.10);
      final score     = (composite * 100).clamp(0.0, 100.0);

      return RecoveryScoreModel(
        score: score,
        level: _level(score),
        explanation: _explanation(score, currentStreak, momentum),
        componentScores: {
          'Streak strength':      c1 * 100,
          'Urge control':         c2 * 100,
          'Emotional resilience': c3 * 100,
          'Stability':            c4 * 100,
          'Momentum':             c5 * 100,
        },
        weekOverWeekChange: momentumRaw * 100,
        momentum:           momentum,
      );
    } catch (_) {
      return const RecoveryScoreModel(score: 0, level: 'Unknown', explanation: 'Could not load data.');
    }
  }

  String _level(double s) => s >= 80 ? 'Excellent'
      : s >= 65 ? 'Good'
      : s >= 45 ? 'Moderate'
      : s >= 25 ? 'Low'
      :            'Critical';

  String _explanation(double score, int streak, String momentum) {
    if (score >= 80) return 'Outstanding recovery. $streak-day streak is showing. Keep protecting this momentum.';
    if (score >= 65) return 'Good recovery health. Your consistency is building real resilience.';
    if (score >= 45) return 'Moderate recovery. Focus on reducing urge frequency and building positive habits.';
    if (score >= 25) return 'Recovery needs attention. Track urges daily and avoid high-risk windows.';
    return 'Critical — immediate action needed. Reach out to your support system today.';
  }
}