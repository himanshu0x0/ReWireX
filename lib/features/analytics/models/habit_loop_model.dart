/// 🧠 Habit Loop Model
/// Describes a detected cue → routine → reward behavioral loop.
class HabitLoopModel {
  final String trigger;
  final String behavior;
  final String insight;
  final int frequency;
  final int peakHour;
  final String severity; // "Low" | "Moderate" | "High"
  final String recommendation;

  HabitLoopModel({
    required this.trigger,
    required this.behavior,
    required this.insight,
    required this.frequency,
    required this.peakHour,
    required this.severity,
    required this.recommendation,
  });
}