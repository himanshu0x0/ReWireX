/// 🔄 Habit Pattern Model
/// Deep behavioral pattern analysis from last 30 urge logs.
class HabitPatternModel {
  final String dominantEmotion;
  final String dominantTimeBlock;
  final String dominantUrgeType;
  final double averageIntensity;
  final String intensityTrend; // "Rising" | "Decreasing" | "Stable"
  final String insight;
  final Map<String, int> timeBlockDistribution;
  final Map<String, int> emotionBreakdown;
  final double riskScore; // 0-100

  HabitPatternModel({
    required this.dominantEmotion,
    required this.dominantTimeBlock,
    required this.dominantUrgeType,
    required this.averageIntensity,
    required this.intensityTrend,
    required this.insight,
    required this.timeBlockDistribution,
    required this.emotionBreakdown,
    required this.riskScore,
  });
}