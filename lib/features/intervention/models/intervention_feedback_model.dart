// lib/features/intervention/models/intervention_feedback_model.dart

/// Feedback recorded after a guided intervention.
///
/// The original fields remain unchanged for backward compatibility with the
/// existing emotion-based ranking system. The optional Urge Rescue fields let
/// the same feedback power the newer urge/need/intervention personalization
/// layer without forcing older callers to provide new data.
class InterventionFeedbackModel {
  final String emotion;
  final int intensity;
  final String technique;
  final bool wasEffective;
  final DateTime timestamp;
  final int sessionDurationSeconds;
  final int stepsCompleted;
  final int totalSteps;
  final String riskLevel;
  final int? intensityAfter;

  // ── Urge Rescue context (optional for backward compatibility) ───────────
  final String? urgeType;
  final String? selectedNeed;
  final String? rescuePath;
  final String? interventionId;
  final int? urgeBefore;
  final int? urgeAfter;
  final String? urgeOutcome;

  const InterventionFeedbackModel({
    required this.emotion,
    required this.intensity,
    required this.technique,
    required this.wasEffective,
    required this.timestamp,
    this.sessionDurationSeconds = 0,
    this.stepsCompleted = 0,
    this.totalSteps = 0,
    this.riskLevel = 'Low',
    this.intensityAfter,
    this.urgeType,
    this.selectedNeed,
    this.rescuePath,
    this.interventionId,
    this.urgeBefore,
    this.urgeAfter,
    this.urgeOutcome,
  });

  /// True when this feedback came through the newer Urge Rescue flow.
  bool get hasUrgeContext => urgeType != null || interventionId != null;

  /// Absolute change in urge intensity, when both scores are available.
  int? get urgeReduction {
    final before = urgeBefore;
    final after = urgeAfter;
    if (before == null || after == null) return null;
    return before - after;
  }

  /// Proportional urge reduction from 0.0 to 1.0, when measurable.
  double? get urgeReductionRatio {
    final before = urgeBefore;
    final reduction = urgeReduction;
    if (before == null || reduction == null || before <= 0) return null;

    return (reduction / before).clamp(0.0, 1.0).toDouble();
  }

  Map<String, dynamic> toMap() {
    return {
      'emotion': emotion,
      'intensity': intensity,
      'technique': technique,
      'wasEffective': wasEffective,
      'timestamp': timestamp,
      'sessionDurationSeconds': sessionDurationSeconds,
      'stepsCompleted': stepsCompleted,
      'totalSteps': totalSteps,
      'riskLevel': riskLevel,
      if (intensityAfter != null) 'intensityAfter': intensityAfter,

      // Completion rate 0.0–1.0 for the existing ranking service.
      'completionRate': totalSteps > 0
          ? (stepsCompleted / totalSteps).clamp(0.0, 1.0).toDouble()
          : 0.0,

      // Urge Rescue fields are omitted when unavailable, keeping old records
      // and old callers fully compatible.
      if (urgeType != null) 'urgeType': urgeType,
      if (selectedNeed != null) 'selectedNeed': selectedNeed,
      if (rescuePath != null) 'rescuePath': rescuePath,
      if (interventionId != null) 'interventionId': interventionId,
      if (urgeBefore != null) 'urgeBefore': urgeBefore,
      if (urgeAfter != null) 'urgeAfter': urgeAfter,
      if (urgeOutcome != null) 'urgeOutcome': urgeOutcome,
      if (urgeReduction != null) 'urgeReduction': urgeReduction,
      if (urgeReductionRatio != null)
        'urgeReductionRatio': urgeReductionRatio,
    };
  }
}
