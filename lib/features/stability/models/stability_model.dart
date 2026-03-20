// lib/features/stability/models/stability_model.dart

/// ⚖️ Stability Model
class StabilityModel {
  final double score;
  final String level;       // "Low" | "Moderate" | "High"
  final String explanation; // human-readable insight for UI
  final Map<String, int>? emotionDistribution;
  final double consistencyScore;
  final double intensityVariance;
  final String trend; // "Improving" | "Stable" | "Declining"

  const StabilityModel({
    required this.score,
    required this.level,
    this.explanation       = '',
    this.emotionDistribution,
    this.consistencyScore  = 0.5,
    this.intensityVariance = 0.0,
    this.trend             = 'Stable',
  });
}