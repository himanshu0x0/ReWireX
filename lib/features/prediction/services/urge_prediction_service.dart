// lib/features/prediction/services/urge_prediction_service.dart

import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/urge_prediction_model.dart';

export '../models/urge_prediction_model.dart';

/// 🔮 Urge Prediction Service
///
/// Combines three temporal signals:
///   1. Historical hour distribution  — which hours urges peak
///   2. Day-of-week weighting         — weekends / evenings 1.3×
///   3. Recency decay                 — last 7d logs weigh 2×
///
/// Applies Gaussian smoothing (σ=1.5h) to eliminate noise from
/// sparse data. Returns [UrgePredictionModel] from models file.
class UrgePredictionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth           = FirebaseAuth.instance;

  Future<UrgePredictionModel> predictUrge() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return _fallback();

      final now  = DateTime.now();
      final snap = await _firestore
          .collection('users').doc(user.uid).collection('urge_logs')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(
              now.subtract(const Duration(days: 30))))
          .get();

      if (snap.docs.isEmpty) return _fallback();

      // ── Weighted hourly distribution ───────────────────────────────
      final hourWeight   = List<double>.filled(24, 0.0);
      final cutoffRecent = now.subtract(const Duration(days: 7));

      for (final doc in snap.docs) {
        final data    = doc.data();
        int?  hour    = data['hour'] as int?;
        DateTime? logTime;
        final ts = data['timestamp'];
        if (ts is Timestamp) logTime = ts.toDate();
        if (hour == null && logTime != null) hour = logTime.hour;
        if (hour == null) continue;

        final recencyW   = (logTime != null && logTime.isAfter(cutoffRecent)) ? 2.0 : 1.0;
        final dayW       = (logTime != null &&
            (logTime.weekday == 6 || logTime.weekday == 7)) ? 1.3 : 1.0;
        final intensity  = ((data['intensity'] ?? 5) as num).toDouble();
        final intensityW = 1.0 + (intensity - 5) / 10.0;

        hourWeight[hour] += recencyW * dayW * intensityW;
      }

      // ── Gaussian smoothing ─────────────────────────────────────────
      final smoothed = _gaussianSmooth(hourWeight, sigma: 1.5);

      // ── Top 3 risk hours ───────────────────────────────────────────
      final indexed = List.generate(24, (i) => MapEntry(i, smoothed[i]))
        ..sort((a, b) => b.value.compareTo(a.value));
      final topHours  = indexed.take(3).map((e) => e.key).toList();
      final peakHour  = topHours.first;
      final peakWeight= smoothed[peakHour];
      final totalW    = smoothed.fold(0.0, (a, b) => a + b);

      // ── Probability ────────────────────────────────────────────────
      final ratio   = totalW == 0 ? 0.0 : peakWeight / totalW;
      final rawProb = (ratio * 250).clamp(5.0, 95.0);
      final dist    = _circDist(now.hour, peakHour);
      final boost   = dist <= 2 ? 1.15 : 1.0;
      final prob    = (rawProb * boost).round().clamp(5, 95);

      final endHour = (peakHour + 2) % 24;
      final window  = '${_fmt(peakHour)} – ${_fmt(endHour)}';

      final prediction = prob >= 75 ? 'Critical'
          : prob >= 55               ? 'High'
          : prob >= 35               ? 'Moderate'
          :                            'Low';

      return UrgePredictionModel(
        prediction:   prediction,
        probability:  prob,
        window:       window,
        peakHour:     peakHour,
        topRiskHours: topHours,
        contextLabel: _contextLabel(peakHour),
      );
    } catch (_) {
      return _fallback();
    }
  }

  List<double> _gaussianSmooth(List<double> data, {required double sigma}) {
    final n   = data.length;
    final out = List<double>.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      double sum = 0, wTotal = 0;
      for (int j = -4; j <= 4; j++) {
        final idx = (i + j + n) % n;
        final w   = math.exp(-(j * j) / (2 * sigma * sigma));
        sum    += data[idx] * w;
        wTotal += w;
      }
      out[i] = wTotal == 0 ? 0 : sum / wTotal;
    }
    return out;
  }

  int    _circDist(int a, int b) { final d = (a - b).abs(); return d < 24 - d ? d : 24 - d; }
  String _fmt(int h) { final s = h >= 12 ? 'PM' : 'AM'; final d = h % 12 == 0 ? 12 : h % 12; return '$d:00 $s'; }
  String _contextLabel(int h) {
    if (h >= 22 || h <= 2)  return 'Late-night isolation window';
    if (h >= 3  && h <= 6)  return 'Early-morning restlessness';
    if (h >= 7  && h <= 11) return 'Morning stress window';
    if (h >= 12 && h <= 15) return 'Afternoon fatigue window';
    if (h >= 16 && h <= 18) return 'Post-work decompression';
    return 'Evening vulnerability window';
  }

  UrgePredictionModel _fallback() => const UrgePredictionModel(
    prediction: 'Low', probability: 10,
    window: 'next 2 hours', contextLabel: 'Insufficient data',
  );
}