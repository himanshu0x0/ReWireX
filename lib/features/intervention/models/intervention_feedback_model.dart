// lib/features/intervention/models/intervention_feedback_model.dart

class InterventionFeedbackModel {
  final String emotion;
  final int intensity;
  final String technique;
  final bool wasEffective;
  final DateTime timestamp;
  final int sessionDurationSeconds; // How long they actually spent
  final int stepsCompleted;         // Out of total steps
  final int totalSteps;
  final String riskLevel;           // Risk level at time of intervention
  final int? intensityAfter;        // Self-reported intensity after (1–10)

  InterventionFeedbackModel({
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
  });

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
      // Completion rate 0.0–1.0 stored for ranking service queries
      'completionRate': totalSteps > 0
          ? (stepsCompleted / totalSteps).clamp(0.0, 1.0)
          : 0.0,
    };
  }
}