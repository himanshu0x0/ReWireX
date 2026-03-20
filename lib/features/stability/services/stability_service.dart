// lib/features/stability/services/stability_service.dart

import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/stability_model.dart';

export '../models/stability_model.dart';

/// ⚖️ Stability Service
///
/// Four-dimension behavioral stability model:
///   D1 — Frequency stability    (CV of daily urge counts)       30%
///   D2 — Intensity variance     (std dev of urge intensities)   25%
///   D3 — Emotional consistency  (positive emotion ratio)        25%
///   D4 — Trend direction        (linear regression on 4 weeks)  20%
class StabilityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth           = FirebaseAuth.instance;

  static const _negativeEmotions = {
    'Stressed', 'Anxious', 'Lonely', 'Bored', 'Sad',
    'Angry', 'Frustrated', 'Depressed', 'Hopeless', 'Empty',
  };

  Future<StabilityModel> calculateStability() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return const StabilityModel(score: 50, level: 'Moderate');

      final now  = DateTime.now();
      final snap = await _firestore
          .collection('users').doc(user.uid).collection('urge_logs')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(
              now.subtract(const Duration(days: 30))))
          .orderBy('timestamp', descending: false)
          .get();

      if (snap.docs.isEmpty) {
        return const StabilityModel(score: 75, level: 'High', trend: 'Stable');
      }

      // ── Daily buckets ──────────────────────────────────────────────
      final dailyCounts     = <int, int>{};
      final emotionCount    = <String, int>{};
      final intensities     = <double>[];

      for (final doc in snap.docs) {
        final data      = doc.data();
        final ts        = (data['timestamp'] as Timestamp).toDate();
        final day       = now.difference(DateTime(ts.year, ts.month, ts.day)).inDays;
        if (day < 0 || day > 29) continue;
        final intensity = ((data['intensity'] ?? 5) as num).toDouble();
        dailyCounts[day]= (dailyCounts[day] ?? 0) + 1;
        intensities.add(intensity);
        final emotion   = (data['emotion'] as String?) ?? 'Unknown';
        emotionCount[emotion] = (emotionCount[emotion] ?? 0) + 1;
      }

      // ── D1: Frequency stability ────────────────────────────────────
      final counts    = List<int>.generate(30, (i) => dailyCounts[i] ?? 0);
      final meanCount = counts.fold(0, (a, b) => a + b) / 30.0;
      final countStd  = _std(counts.map((c) => c.toDouble()).toList(), meanCount);
      final cv        = meanCount == 0 ? 2.0 : (countStd / meanCount).clamp(0.0, 2.0);
      final freqStability = 1.0 - (cv / 2.0);

      // ── D2: Intensity variance ─────────────────────────────────────
      final meanIntensity      = intensities.isEmpty ? 5.0
          : intensities.fold(0.0, (a, b) => a + b) / intensities.length;
      final intensityStd       = intensities.isEmpty ? 0.0 : _std(intensities, meanIntensity);
      final intensityStability = 1.0 - (intensityStd / 4.5).clamp(0.0, 1.0);

      // ── D3: Emotional consistency ──────────────────────────────────
      final totalEmotions  = emotionCount.values.fold(0, (a, b) => a + b);
      final negativeCount  = emotionCount.entries
          .where((e) => _negativeEmotions.contains(e.key))
          .fold(0, (a, b) => a + b.value);
      final emotionStability = totalEmotions == 0 ? 0.5
          : (1.0 - (negativeCount / totalEmotions)).clamp(0.0, 1.0);

      // ── D4: Trend (linear regression on 4-week buckets) ───────────
      final weekBuckets = List<double>.filled(4, 0.0);
      for (final doc in snap.docs) {
        final ts  = (doc.data()['timestamp'] as Timestamp).toDate();
        final day = now.difference(DateTime(ts.year, ts.month, ts.day)).inDays;
        if (day >= 0 && day <= 27) weekBuckets[day ~/ 7] += 1;
      }
      final slope = _linearSlope(weekBuckets);
      final String trend;
      final double trendScore;
      if (slope < -0.5)     { trend = 'Improving'; trendScore = 1.0; }
      else if (slope > 0.5) { trend = 'Declining'; trendScore = 0.2; }
      else                  { trend = 'Stable';    trendScore = 0.6; }

      // ── Composite ──────────────────────────────────────────────────
      final composite = (freqStability      * 0.30) +
                        (intensityStability * 0.25) +
                        (emotionStability   * 0.25) +
                        (trendScore         * 0.20);
      final score = (composite * 100).clamp(0.0, 100.0);
      final level = score >= 70 ? 'High' : score >= 45 ? 'Moderate' : 'Low';

      return StabilityModel(
        score:               score,
        level:               level,
        emotionDistribution: emotionCount,
        consistencyScore:    freqStability,
        intensityVariance:   intensityStd,
        trend:               trend,
      );
    } catch (_) {
      return const StabilityModel(score: 50, level: 'Moderate');
    }
  }

  double _std(List<double> data, double mean) {
    if (data.isEmpty) return 0;
    final variance = data.fold(0.0, (a, b) => a + math.pow(b - mean, 2)) / data.length;
    return math.sqrt(variance);
  }

  double _linearSlope(List<double> y) {
    if (y.length < 2) return 0;
    final n = y.length.toDouble();
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (int i = 0; i < y.length; i++) {
      sumX  += i; sumY += y[i]; sumXY += i * y[i]; sumX2 += i * i.toDouble();
    }
    final denom = n * sumX2 - sumX * sumX;
    return denom == 0 ? 0 : (n * sumXY - sumX * sumY) / denom;
  }
}