// lib/features/ai/services/behavior_pattern_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/behavior_pattern_model.dart';

export '../models/behavior_pattern_model.dart';

/// 🔄 Behavior Pattern Service
///
/// Two public methods:
///   analyzeBehavior()       → BehaviorPatternModel?  (used by InsightsScreen)
///   analyzeBehaviorPattern()→ String?                (used by AIEngineContext)
///
/// Analyses last 50 urge logs for:
///   • Dominant time-of-day block & emotional trigger
///   • Co-occurrence patterns (emotion × time block)
///   • Intensity trend (EWMA-based)
///   • Confidence score from data volume
class BehaviorPatternService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth           = FirebaseAuth.instance;

  // ── Structured model (InsightsScreen) ─────────────────────────
  Future<BehaviorPatternModel?> analyzeBehavior() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final snap = await _firestore
          .collection('users').doc(user.uid).collection('urge_logs')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      if (snap.docs.isEmpty) return null;

      final emotionCount   = <String, int>{};
      final timeBlockCount = <String, int>{};
      final coOccurrence   = <String, int>{};
      final intensities    = <double>[];

      for (final doc in snap.docs) {
        final data      = doc.data();
        final emotion   = (data['emotion']   as String?) ?? 'Unknown';
        final intensity = ((data['intensity'] ?? 5) as num).toDouble();
        intensities.add(intensity);
        emotionCount[emotion] = (emotionCount[emotion] ?? 0) + 1;

        int? hour = data['hour'] as int?;
        final ts  = data['timestamp'];
        if (hour == null && ts is Timestamp) hour = ts.toDate().hour;

        if (hour != null) {
          final block = _block(hour);
          timeBlockCount[block] = (timeBlockCount[block] ?? 0) + 1;
          final coKey = '$emotion|$block';
          coOccurrence[coKey] = (coOccurrence[coKey] ?? 0) + 1;
        }
      }

      final dominantEmotion = _dominant(emotionCount);
      final dominantBlock   = _dominant(timeBlockCount);
      final trend           = _intensityTrend(intensities);

      // ── Top co-occurrence ─────────────────────────────────────
      String topCoPattern = '';
      String riskWindow   = '$dominantBlock hours';
      if (coOccurrence.isNotEmpty) {
        final topCo   = coOccurrence.entries.reduce((a, b) => a.value > b.value ? a : b);
        final parts   = topCo.key.split('|');
        if (parts.length == 2) {
          topCoPattern = '${parts[0]} during ${parts[1]}';
          riskWindow   = '${parts[1]} hours';
        }
      }

      // ── Pattern label ─────────────────────────────────────────
      final patternLabel = _patternLabel(dominantEmotion, dominantBlock);

      // ── Confidence: based on data volume + trend consistency ──
      final confidence = ((snap.docs.length / 50.0) * 85 + 15).round().clamp(20, 95);

      // ── Recommendation ────────────────────────────────────────
      final recommendation = _recommendation(dominantEmotion, dominantBlock);

      return BehaviorPatternModel(
        pattern:        patternLabel,
        trigger:        dominantEmotion,
        riskWindow:     riskWindow,
        confidence:     confidence,
        recommendation: recommendation,
        dominantBlock:  dominantBlock,
        intensityTrend: trend,
        topCoPattern:   topCoPattern,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Natural-language string (AIEngineContext) ──────────────────
  Future<String?> analyzeBehaviorPattern() async {
    try {
      final model = await analyzeBehavior();
      if (model == null) return null;
      return 'Urges predominantly occur during ${model.dominantBlock} '
          'with ${model.trigger} as the dominant emotional state. '
          '${model.topCoPattern.isNotEmpty ? "Strongest pattern: ${model.topCoPattern}. " : ""}'
          'Intensity trend: ${model.intensityTrend}.';
    } catch (_) {
      return null;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────
  String _block(int hour) {
    if (hour >= 5  && hour <= 11) return 'Morning';
    if (hour >= 12 && hour <= 16) return 'Afternoon';
    if (hour >= 17 && hour <= 21) return 'Evening';
    return 'Night';
  }

  String _dominant(Map<String, int> map) {
    if (map.isEmpty) return 'Unknown';
    return map.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  String _intensityTrend(List<double> intensities, {double alpha = 0.6}) {
    if (intensities.length < 5) return 'Stable';
    final ewma = List<double>.filled(intensities.length, 0.0);
    ewma[0] = intensities[0];
    for (int i = 1; i < intensities.length; i++) {
      ewma[i] = alpha * intensities[i] + (1 - alpha) * ewma[i - 1];
    }
    final mid       = intensities.length ~/ 2;
    final firstAvg  = ewma.sublist(0, mid).fold(0.0, (a, b) => a + b) / mid;
    final secondAvg = ewma.sublist(mid).fold(0.0, (a, b) => a + b) / (intensities.length - mid);
    if (secondAvg < firstAvg - 0.5) return 'Improving';
    if (secondAvg > firstAvg + 0.5) return 'Worsening';
    return 'Stable';
  }

  String _patternLabel(String emotion, String block) {
    if (block == 'Night')     return '$emotion Night Loop';
    if (block == 'Evening')   return '$emotion Evening Pattern';
    if (block == 'Morning')   return '$emotion Morning Trigger';
    return '$emotion $block Pattern';
  }

  String _recommendation(String emotion, String block) {
    final lowerBlock = block.toLowerCase();
    if (block == 'Night') {
      return 'Set a hard device curfew. Build a sleep ritual to interrupt the $lowerBlock loop.';
    }
    if (block == 'Evening') {
      return 'Pre-schedule structured evening activities. Idle $lowerBlock time is the primary cue.';
    }
    if (block == 'Morning') {
      return 'Start mornings with a grounding practice — journaling, movement, or cold exposure.';
    }
    return 'Log urges immediately when triggered in the $lowerBlock to interrupt the response chain.';
  }
}