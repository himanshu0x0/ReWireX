/// ⚡ Trigger Pattern Model — Enhanced
class TriggerPatternModel {
  final String trigger;
  final String description;
  final int frequency;
  final int peakHour;
  final String riskLevel;       // "Low" | "Medium" | "High" | "Critical"
  final String actionAdvice;
  final List<int> activeHours;  // above-average hours

  TriggerPatternModel({
    required this.trigger,
    required this.description,
    required this.frequency,
    required this.peakHour,
    required this.riskLevel,
    required this.actionAdvice,
    required this.activeHours,
  });
}