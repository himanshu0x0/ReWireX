// lib/features/ai/models/recovery_score_model.dart

/// 📊 Recovery Score Model
class RecoveryScoreModel {
  final double score;  // 0–100
  final String level;  // "Critical" | "Low" | "Moderate" | "Good" | "Excellent"
  final String explanation;
  final Map<String, double> componentScores;
  final double weekOverWeekChange;
  final String momentum; // "Gaining" | "Stable" | "Losing"

  const RecoveryScoreModel({
    required this.score,
    required this.level,
    this.explanation = '',
    this.componentScores = const {},
    this.weekOverWeekChange = 0,
    this.momentum = 'Stable',
  });
}