// lib/features/analytics/services/habit_pattern_service.dart

import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/habit_pattern_model.dart';

/// 🔄 Habit Pattern Service
///
/// Deep behavioral pattern engine operating on the last 50 urge logs.
/// Produces a rich HabitPatternModel covering:
///
///   • Dominant emotion, time block, and urge type
///   • Average intensity with standard deviation
///   • EWMA-based intensity trend (more responsive than simple split)
///   • Risk score: weighted composite of intensity, trend, and frequency
///   • Top co-occurrence pattern (emotion × time block)
///   • Full time-block distribution and emotion breakdown
///   • Actionable insight paragraph
class HabitPatternService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const _negativeEmotions = {
    'Stressed', 'Anxious', 'Lonely', 'Bored', 'Sad',
    'Angry', 'Frustrated', 'Depressed', 'Hopeless', 'Empty',
  };

  Future<HabitPatternModel?> analyzePatterns() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('urge_logs')
        .orderBy('timestamp', descending: false)
        .limit(50)
        .get();

    if (snapshot.docs.isEmpty) return null;

    // ── Aggregate ──────────────────────────────────────────────────
    final emotionCount    = <String, int>{};
    final timeBlockCount  = <String, int>{};
    final typeCount       = <String, int>{};
    final coOccurrence    = <String, int>{}; // 'emotion|block'
    final intensityList   = <double>[];
    double totalIntensity = 0;

    for (final doc in snapshot.docs) {
      final data      = doc.data();
      final emotion   = (data['emotion']   as String?) ?? 'Unknown';
      final type      = (data['type']      as String?) ?? 'Unknown';
      final intensity = ((data['intensity'] ?? 5) as num).toDouble();
      final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

      if (timestamp == null) continue;

      final block = _timeBlock(timestamp.hour);

      emotionCount[emotion]   = (emotionCount[emotion]   ?? 0) + 1;
      typeCount[type]         = (typeCount[type]         ?? 0) + 1;
      timeBlockCount[block]   = (timeBlockCount[block]   ?? 0) + 1;

      final coKey = '$emotion|$block';
      coOccurrence[coKey] = (coOccurrence[coKey] ?? 0) + 1;

      totalIntensity += intensity;
      intensityList.add(intensity);
    }

    if (intensityList.isEmpty) return null;

    // ── Dominant signals ───────────────────────────────────────────
    final dominantEmotion   = _dominant(emotionCount);
    final dominantType      = _dominant(typeCount);
    final dominantTimeBlock = _dominant(timeBlockCount);

    // ── Intensity stats ────────────────────────────────────────────
    final avgIntensity = totalIntensity / intensityList.length;
    final intensityStd = _std(intensityList, avgIntensity);

    // ── EWMA trend (α=0.6 — balanced responsiveness) ──────────────
    final trend = _ewmaTrend(intensityList);

    // ── Negative emotion ratio ────────────────────────────────────
    final totalEmotions = emotionCount.values.fold(0, (a, b) => a + b);
    final negCount = emotionCount.entries
        .where((e) => _negativeEmotions.contains(e.key))
        .fold(0, (a, b) => a + b.value);
    final negRatio = totalEmotions == 0 ? 0.5
        : negCount / totalEmotions;

    // ── Risk score (4-component weighted formula) ─────────────────
    //   45% intensity level
    //   25% trend direction
    //   20% negative emotion ratio
    //   10% frequency density
    final intensityComponent = ((avgIntensity - 1) / 9.0).clamp(0.0, 1.0);
    final trendComponent     = trend == 'Rising'     ? 1.0
                             : trend == 'Stable'     ? 0.45
                             :                         0.1;  // Decreasing
    final emotionComponent   = negRatio.clamp(0.0, 1.0);
    final freqComponent      = (intensityList.length / 50.0).clamp(0.0, 1.0);

    final rawRisk = (intensityComponent * 0.45) +
                   (trendComponent      * 0.25) +
                   (emotionComponent    * 0.20) +
                   (freqComponent       * 0.10);
    final riskScore = (rawRisk * 100).clamp(0.0, 100.0);

    // ── Top co-occurrence pattern ─────────────────────────────────
    String topCoOccurrence = '';
    if (coOccurrence.isNotEmpty) {
      final topCo = coOccurrence.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      final parts = topCo.key.split('|');
      if (parts.length == 2 && topCo.value >= 2) {
        topCoOccurrence =
            ' Strongest co-pattern: ${parts[0]} during ${parts[1].toLowerCase()} '
            '(${topCo.value} occurrences).';
      }
    }

    // ── Compose insight ───────────────────────────────────────────
    final trendPhrase = trend == 'Rising'
        ? 'Intensity is trending upward — heightened vigilance needed.'
        : trend == 'Decreasing'
            ? 'Intensity is trending downward — a positive sign.'
            : 'Intensity has been relatively stable.';

    final insight =
        'Urges predominantly occur during $dominantTimeBlock '
        'when feeling $dominantEmotion (avg intensity '
        '${avgIntensity.toStringAsFixed(1)}±${intensityStd.toStringAsFixed(1)}/10). '
        'Most common trigger type: $dominantType.$topCoOccurrence '
        '$trendPhrase';

    return HabitPatternModel(
      dominantEmotion:    dominantEmotion,
      dominantTimeBlock:  dominantTimeBlock,
      dominantUrgeType:   dominantType,
      averageIntensity:   avgIntensity,
      intensityTrend:     trend,
      insight:            insight,
      timeBlockDistribution: timeBlockCount,
      emotionBreakdown:   emotionCount,
      riskScore:          riskScore,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────

  String _dominant(Map<String, int> map) {
    if (map.isEmpty) return 'Unknown';
    return map.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  String _timeBlock(int hour) {
    if (hour >= 5  && hour <= 11) return 'Morning';
    if (hour >= 12 && hour <= 16) return 'Afternoon';
    if (hour >= 17 && hour <= 20) return 'Evening';
    return 'Night';
  }

  /// EWMA trend on intensity values (α = 0.6).
  String _ewmaTrend(List<double> intensities, {double alpha = 0.6}) {
    if (intensities.length < 5) return 'Stable';

    final ewma = List<double>.filled(intensities.length, 0.0);
    ewma[0] = intensities[0];
    for (int i = 1; i < intensities.length; i++) {
      ewma[i] = alpha * intensities[i] + (1 - alpha) * ewma[i - 1];
    }

    final mid      = intensities.length ~/ 2;
    final firstAvg = ewma.sublist(0, mid).fold(0.0, (a, b) => a + b) / mid;
    final secondAvg= ewma.sublist(mid).fold(0.0, (a, b) => a + b) /
        (intensities.length - mid);

    if (secondAvg > firstAvg + 0.5) return 'Rising';
    if (secondAvg < firstAvg - 0.5) return 'Decreasing';
    return 'Stable';
  }

  double _std(List<double> data, double mean) {
    if (data.length < 2) return 0.0;
    final variance =
        data.fold(0.0, (a, b) => a + math.pow(b - mean, 2)) / data.length;
    return math.sqrt(variance);
  }
}