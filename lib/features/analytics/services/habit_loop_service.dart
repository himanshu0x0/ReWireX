// lib/features/analytics/services/habit_loop_service.dart

import '../models/habit_loop_model.dart';
import 'heatmap_service.dart';

/// 🧠 Habit Loop Service
///
/// Detects cue → routine → reward loops using the CUE model:
///
///   CUE      — Time-of-day peak from the weighted heatmap
///   ROUTINE  — "Urge Response" (the addictive behaviour)
///   REWARD   — Dopamine relief (implicit)
///
/// Advanced features:
///   • Uses weighted heatmap (recency + intensity) not raw counts
///   • Detects secondary loop if there is a distinct second peak
///   • Severity based on peak concentration ratio (Gini-like)
///   • Personalised recommendations per trigger category
///   • Void stub `analyzeHabitLoop()` preserved for compatibility
class HabitLoopService {
  final HeatmapService _heatmapService = HeatmapService();

  Future<HabitLoopModel?> detectHabitLoop() async {
    // Use weighted heatmap for a more accurate signal
    final weighted = await _heatmapService.getWeightedHeatmap();
    if (weighted.isEmpty) return null;

    // ── Find primary peak ─────────────────────────────────────────
    int peakHour = 0;
    double peakScore = 0;
    double totalScore = 0;

    weighted.forEach((hour, score) {
      totalScore += score;
      if (score > peakScore) {
        peakScore = score;
        peakHour = hour;
      }
    });

    if (peakScore == 0) return null;

    // ── Severity: Gini-like concentration ratio ───────────────────
    // If the peak hour holds >50% of total weight → very concentrated loop
    final ratio = totalScore == 0 ? 0.0 : peakScore / totalScore;
    final String severity;
    if (ratio >= 0.45) {
      severity = 'High';
    } else if (ratio >= 0.28)  severity = 'Moderate';
    else                     severity = 'Low';

    final trigger = _triggerLabel(peakHour);
    final recommendation = _recommendation(trigger, peakHour);

    // ── Secondary loop detection ──────────────────────────────────
    // Find second-highest hour that is ≥4 hours away from primary
    double secondScore = 0;
    int secondHour = -1;
    weighted.forEach((hour, score) {
      final dist = (hour - peakHour).abs();
      final circDist = dist < 24 - dist ? dist : 24 - dist;
      if (circDist >= 4 && score > secondScore) {
        secondScore = score;
        secondHour = hour;
      }
    });

    final hasSecondLoop = secondHour >= 0 &&
        secondScore / totalScore >= 0.18;

    final insight = _buildInsight(
      peakHour: peakHour,
      ratio: ratio,
      severity: severity,
      trigger: trigger,
      hasSecondLoop: hasSecondLoop,
      secondHour: secondHour,
    );

    // ── Raw count for `frequency` field ──────────────────────────
    final rawHeatmap = await _heatmapService.getHourlyHeatmap();
    final frequency  = rawHeatmap[peakHour] ?? 0;

    return HabitLoopModel(
      trigger:        trigger,
      behavior:       'Urge Response',
      insight:        insight,
      frequency:      frequency,
      peakHour:       peakHour,
      severity:       severity,
      recommendation: recommendation,
    );
  }

  // ── Builders ──────────────────────────────────────────────────────

  String _buildInsight({
    required int peakHour,
    required double ratio,
    required String severity,
    required String trigger,
    required bool hasSecondLoop,
    required int secondHour,
  }) {
    final pct = (ratio * 100).toStringAsFixed(0);
    var insight = 'Your strongest urge loop activates around '
        '${_fmt(peakHour)} ($trigger). '
        'This window accounts for ~$pct% of your total urge weight — '
        'a $severity concentration pattern.';
    if (hasSecondLoop) {
      insight += ' A secondary loop is also active around ${_fmt(secondHour)}.';
    }
    return insight;
  }

  String _triggerLabel(int hour) {
    if (hour >= 22 || hour <= 2) return 'Late Night Vulnerability';
    if (hour >= 3 && hour <= 6)  return 'Early Morning Restlessness';
    if (hour >= 7 && hour <= 11) return 'Morning Stress Window';
    if (hour >= 12 && hour <= 15)return 'Afternoon Fatigue';
    if (hour >= 16 && hour <= 17)return 'Post-Work Slump';
    if (hour >= 18 && hour <= 21)return 'Evening Boredom';
    return 'Idle Time Pattern';
  }

  String _recommendation(String trigger, int hour) {
    switch (trigger) {
      case 'Late Night Vulnerability':
        return 'Institute a hard phone curfew 30 min before ${_fmt(hour)}. '
            'Replace with a sleep ritual: dim lights, light reading, or breathing.';
      case 'Early Morning Restlessness':
        return 'Set a structured wake-up routine. Cold water on the face, '
            '5-min journaling, and a walk before checking your phone.';
      case 'Morning Stress Window':
        return 'Start mornings with a grounding practice — '
            'cold exposure, journaling, or 10 min of movement.';
      case 'Afternoon Fatigue':
        return 'Schedule a 10-min walk or 4-7-8 breathing at ${_fmt(hour)} '
            'to counter the energy dip that triggers urges.';
      case 'Post-Work Slump':
        return 'Build a decompression ritual: change clothes, '
            'short walk, and music — before opening your phone.';
      case 'Evening Boredom':
        return 'Pre-schedule an evening activity. Structure beats '
            'willpower — idle time is the loop\'s cue.';
      default:
        return 'Log urges the moment they arise at ${_fmt(hour)} '
            'to interrupt the automatic response chain.';
    }
  }

  String _fmt(int hour) {
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final h = hour % 12 == 0 ? 12 : hour % 12;
    return '$h:00 $suffix';
  }

  // ── Backward-compatible void stub ─────────────────────────────────
  Future<void> analyzeHabitLoop() async {}
}