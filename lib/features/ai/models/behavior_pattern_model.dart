// lib/features/ai/models/behavior_pattern_model.dart

/// 🔄 Behavior Pattern Model
///
/// Rich structured output from BehaviorPatternService.analyzeBehavior().
/// Used by InsightsScreen to display the AI behavioral pattern card.
class BehaviorPatternModel {
  final String pattern;        // e.g. "Evening Stress Loop"
  final String trigger;        // dominant emotional trigger
  final String riskWindow;     // e.g. "9:00 PM – 11:00 PM"
  final int    confidence;     // 0–100
  final String recommendation; // personalised action advice
  final String dominantBlock;  // time block
  final String intensityTrend; // "Improving" | "Stable" | "Worsening"
  final String topCoPattern;   // e.g. "Anxious during Evening"

  const BehaviorPatternModel({
    required this.pattern,
    required this.trigger,
    required this.riskWindow,
    required this.confidence,
    required this.recommendation,
    this.dominantBlock  = '',
    this.intensityTrend = 'Stable',
    this.topCoPattern   = '',
  });
}