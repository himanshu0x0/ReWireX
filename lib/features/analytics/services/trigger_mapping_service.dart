// lib/features/analytics/services/trigger_mapping_service.dart

import '../models/trigger_pattern_model.dart';
import 'heatmap_service.dart';

/// ⚡ Trigger Mapping Service
///
/// Multi-dimensional trigger analysis:
///
///   Dimension 1 — Temporal trigger (peak hour from weighted heatmap)
///   Dimension 2 — Risk level using a dual-threshold (ratio + absolute count)
///   Dimension 3 — Active hours: all hours above 60% of peak weight
///   Dimension 4 — Spread index: narrow vs diffuse trigger windows
///   Dimension 5 — Action advice tailored to trigger category + spread
///
/// Void stub `mapTriggers()` preserved for backward compatibility.
class TriggerMappingService {
  final HeatmapService _heatmapService = HeatmapService();

  Future<TriggerPatternModel?> detectTriggerPattern() async {
    final weighted = await _heatmapService.getWeightedHeatmap();
    final rawCounts = await _heatmapService.getHourlyHeatmap();

    if (weighted.isEmpty) return null;

    // ── Find peak ─────────────────────────────────────────────────
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

    final peakCount = rawCounts[peakHour] ?? 0;
    final totalCount = rawCounts.values.fold(0, (a, b) => a + b);

    // ── Risk level (dual threshold) ───────────────────────────────
    final ratio = totalScore == 0 ? 0.0 : peakScore / totalScore;
    final riskLevel = _riskLevel(ratio, peakCount, totalCount);

    // ── Active hours: above 60% of peak weight ────────────────────
    final threshold = peakScore * 0.60;
    final activeHours = weighted.entries
        .where((e) => e.value >= threshold)
        .map((e) => e.key)
        .toList()
      ..sort();

    // ── Spread index: number of active hours ──────────────────────
    // Narrow (1–2h) = concentrated loop. Wide (5+h) = diffuse.
    final spread = activeHours.length;
    final spreadLabel = spread <= 2 ? 'narrow (concentrated)'
        : spread <= 4               ? 'moderate'
        :                             'broad (diffuse)';

    final trigger     = _triggerLabel(peakHour);
    final actionAdvice = _actionAdvice(trigger, spreadLabel);

    final description =
        'ReWireX detected a $riskLevel-risk behavioral trigger '
        'centred around ${_fmt(peakHour)} ($trigger). '
        'The pattern has a $spreadLabel spread across '
        '${activeHours.length} active hour${activeHours.length == 1 ? '' : 's'}, '
        'appearing $peakCount time${peakCount == 1 ? '' : 's'} at peak.';

    return TriggerPatternModel(
      trigger:     trigger,
      description: description,
      frequency:   peakCount,
      peakHour:    peakHour,
      riskLevel:   riskLevel,
      actionAdvice:actionAdvice,
      activeHours: activeHours,
    );
  }

  // ── Builders ──────────────────────────────────────────────────────

  String _riskLevel(double ratio, int peakCount, int totalCount) {
    // Dual threshold: ratio-based AND absolute-count-based
    if (ratio >= 0.50 || peakCount >= 10) return 'Critical';
    if (ratio >= 0.35 || peakCount >= 6)  return 'High';
    if (ratio >= 0.20 || peakCount >= 3)  return 'Medium';
    return 'Low';
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

  String _actionAdvice(String trigger, String spreadLabel) {
    final spreadTip = spreadLabel.startsWith('broad')
        ? ' Given the broad spread, consider an all-evening structured plan.'
        : spreadLabel.startsWith('narrow')
            ? ' The concentrated window makes targeted intervention highly effective.'
            : '';

    switch (trigger) {
      case 'Late Night Vulnerability':
        return 'Set a hard device curfew. Build a sleep ritual (no screens, dim lights, breathing).$spreadTip';
      case 'Early Morning Restlessness':
        return 'Create a morning anchor routine before touching your phone.$spreadTip';
      case 'Morning Stress Window':
        return 'Protect mornings with movement, journaling, or cold exposure.$spreadTip';
      case 'Afternoon Fatigue':
        return 'Plan a 10-min walk or nap at your peak window. Hydrate and move.$spreadTip';
      case 'Post-Work Slump':
        return 'Design a decompression ritual to replace the urge habit.$spreadTip';
      case 'Evening Boredom':
        return 'Pre-schedule structured evening activities. Idle time is the trigger.$spreadTip';
      default:
        return 'Log urges immediately when triggered to interrupt the automatic chain.$spreadTip';
    }
  }

  String _fmt(int hour) {
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final h = hour % 12 == 0 ? 12 : hour % 12;
    return '$h:00 $suffix';
  }

  // ── Backward-compatible void stub ─────────────────────────────────
  Future<void> mapTriggers() async {}
}