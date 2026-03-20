// lib/features/analytics/services/heatmap_service.dart

import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 🔥 Heatmap Service
///
/// Builds a 24-hour urge heatmap using:
///   • Recency weighting: logs from the last 7 days count 2x
///   • Intensity weighting: high-intensity logs contribute more
///   • Gaussian smoothing across adjacent hours to reduce noise
///
/// Additional helpers expose:
///   • Top-N risk hours (with counts)
///   • Risk zone classification per hour
///   • Day-of-week patterns
class HeatmapService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Raw hourly counts (integer) ───────────────────────────────────
  /// Returns Map<hour(0-23), count> — the same contract as before.
  Future<Map<int, int>> getHourlyHeatmap() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    final snap = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('urge_logs')
        .get();

    final Map<int, int> hourlyCount = {};
    for (final doc in snap.docs) {
      final hour = _extractHour(doc.data());
      if (hour == null) continue;
      hourlyCount[hour] = (hourlyCount[hour] ?? 0) + 1;
    }
    return hourlyCount;
  }

  // ── Weighted heatmap (double scores) ─────────────────────────────
  Future<Map<int, double>> getWeightedHeatmap() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    final now = DateTime.now();
    final cutoffRecent = now.subtract(const Duration(days: 7));

    final snap = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('urge_logs')
        .get();

    final raw = List<double>.filled(24, 0.0);
    for (final doc in snap.docs) {
      final data = doc.data();
      final hour = _extractHour(data);
      if (hour == null) continue;

      final intensity = ((data['intensity'] ?? 5) as num).toDouble();
      final ts = data['timestamp'];
      DateTime? logTime;
      if (ts is Timestamp) logTime = ts.toDate();

      final recency = (logTime != null && logTime.isAfter(cutoffRecent))
          ? 2.0 : 1.0;
      final intensityW = 1.0 + (intensity - 5) / 10.0;

      raw[hour] += recency * intensityW;
    }

    // Gaussian smoothing
    final smoothed = _smooth(raw);
    return {for (int i = 0; i < 24; i++) i: smoothed[i]};
  }

  // ── Top-N riskiest hours by raw count ────────────────────────────
  Future<List<MapEntry<int, int>>> getTopRiskHours({int top = 3}) async {
    final heatmap = await getHourlyHeatmap();
    final sorted = heatmap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(top).toList();
  }

  // ── Risk zone per hour ────────────────────────────────────────────
  /// Returns one of: "Critical" | "High" | "Moderate" | "Low"
  Future<Map<int, String>> getHourRiskZones() async {
    final weighted = await getWeightedHeatmap();
    if (weighted.isEmpty) return {};

    final values = weighted.values.toList();
    final maxVal = values.fold(0.0, math.max);
    if (maxVal == 0) return {for (int i = 0; i < 24; i++) i: 'Low'};

    return weighted.map((hour, score) {
      final ratio = score / maxVal;
      final zone = ratio >= 0.75 ? 'Critical'
          : ratio >= 0.50        ? 'High'
          : ratio >= 0.25        ? 'Moderate'
          :                        'Low';
      return MapEntry(hour, zone);
    });
  }

  // ── Day-of-week breakdown ─────────────────────────────────────────
  Future<Map<String, int>> getDayOfWeekPattern() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    final snap = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('urge_logs')
        .get();

    final days = <String, int>{
      'Mon': 0, 'Tue': 0, 'Wed': 0, 'Thu': 0,
      'Fri': 0, 'Sat': 0, 'Sun': 0,
    };
    const labels = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];

    for (final doc in snap.docs) {
      final ts = doc.data()['timestamp'];
      if (ts is Timestamp) {
        final dow = ts.toDate().weekday - 1; // 0=Mon … 6=Sun
        if (dow >= 0 && dow < 7) {
          days[labels[dow]] = (days[labels[dow]] ?? 0) + 1;
        }
      }
    }
    return days;
  }

  // ── Void stub preserved for backward compatibility ────────────────
  Future<void> generateHeatmap() async {}

  // ── Private helpers ───────────────────────────────────────────────

  int? _extractHour(Map<String, dynamic> data) {
    int? hour = data['hour'] as int?;
    if (hour == null) {
      final ts = data['timestamp'];
      if (ts is Timestamp) hour = ts.toDate().hour;
    }
    return (hour != null && hour >= 0 && hour <= 23) ? hour : null;
  }

  List<double> _smooth(List<double> data, {double sigma = 1.5}) {
    final n = data.length;
    final out = List<double>.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      double sum = 0, wTotal = 0;
      for (int j = -3; j <= 3; j++) {
        final idx = (i + j + n) % n;
        final w = math.exp(-(j * j) / (2 * sigma * sigma));
        sum += data[idx] * w;
        wTotal += w;
      }
      out[i] = wTotal == 0 ? 0 : sum / wTotal;
    }
    return out;
  }
}