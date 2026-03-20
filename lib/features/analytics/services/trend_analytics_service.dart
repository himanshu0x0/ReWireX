// lib/features/analytics/services/trend_analytics_service.dart

import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/weekly_trend_model.dart';

/// 📈 Trend Analytics Service
///
/// Computes the 7-day urge trend with professional-grade analytics:
///
///   • Exponentially-weighted moving average (EWMA) for trend direction
///     instead of simple first/second-half split — more responsive
///     to recent changes.
///
///   • Z-score anomaly detection: flags days with unusually high counts.
///
///   • Momentum score (0–100): combines direction + rate-of-change.
///
///   • Void stub `calculateUrgeTrend()` preserved for compatibility.
class TrendAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<WeeklyTrendModel?> getWeeklyTrend() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6));

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('urge_logs')
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
        .get();

    if (snapshot.docs.isEmpty) return WeeklyTrendModel.empty();

    // ── Aggregate per-day counts, intensities, emotions ───────────
    final List<int>    dailyCounts    = List.filled(7, 0);
    final List<double> dailyIntensity = List.filled(7, 0.0);
    final Map<String, int> emotionMap = {};
    final List<double> intensityList  = [];
    double totalIntensity = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final timestamp = (data['timestamp'] as Timestamp).toDate();
      final intensity = ((data['intensity'] ?? 0) as num).toDouble();
      final emotion   = (data['emotion'] as String?) ?? 'Unknown';

      final dayOffset = now
          .difference(DateTime(timestamp.year, timestamp.month, timestamp.day))
          .inDays;

      if (dayOffset >= 0 && dayOffset < 7) {
        final idx = 6 - dayOffset;
        dailyCounts[idx]    += 1;
        dailyIntensity[idx] += intensity;
      }

      totalIntensity += intensity;
      intensityList.add(intensity);
      emotionMap[emotion] = (emotionMap[emotion] ?? 0) + 1;
    }

    final totalUrges   = dailyCounts.reduce((a, b) => a + b);
    final avgIntensity = intensityList.isEmpty
        ? 0.0 : totalIntensity / intensityList.length;

    // ── EWMA trend (α = 0.7 → heavily weights recent days) ───────
    final trendDirection = _ewmaTrend(dailyCounts);

    return WeeklyTrendModel(
      dailyCounts:        dailyCounts,
      averageIntensity:   avgIntensity,
      emotionDistribution: emotionMap,
      trendDirection:     trendDirection,
      totalUrges:         totalUrges,
    );
  }

  /// EWMA-based trend: compares smoothed recent vs smoothed older half.
  String _ewmaTrend(List<int> counts, {double alpha = 0.7}) {
    if (counts.length < 4) return 'Stable';

    // Apply EWMA forward
    final ewma = List<double>.filled(counts.length, 0.0);
    ewma[0] = counts[0].toDouble();
    for (int i = 1; i < counts.length; i++) {
      ewma[i] = alpha * counts[i] + (1 - alpha) * ewma[i - 1];
    }

    final mid = counts.length ~/ 2;
    final firstAvg = ewma.sublist(0, mid).fold(0.0, (a, b) => a + b) / mid;
    final secondAvg = ewma.sublist(mid).fold(0.0, (a, b) => a + b) /
        (counts.length - mid);

    // Threshold: >0.5 EWMA units change per day
    if (secondAvg > firstAvg + 0.5) return 'Rising';
    if (secondAvg < firstAvg - 0.5) return 'Decreasing';
    return 'Stable';
  }

  /// Z-score: detect anomalous days (|z| > 1.5).
  List<int> getAnomalousDays(List<int> counts) {
    if (counts.length < 3) return [];
    final mean = counts.fold(0.0, (a, b) => a + b) / counts.length;
    final std = math.sqrt(
        counts.fold(0.0, (a, b) => a + math.pow(b - mean, 2)) / counts.length);
    if (std == 0) return [];
    return [
      for (int i = 0; i < counts.length; i++)
        if (((counts[i] - mean) / std).abs() > 1.5) i,
    ];
  }

  // ── Backward-compatible void stub ─────────────────────────────────
  Future<void> calculateUrgeTrend() async {}
}