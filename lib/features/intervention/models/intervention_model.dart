// lib/features/intervention/models/intervention_model.dart

/// 🧠 Intervention Technique Categories
enum InterventionCategory {
  breathing,
  grounding,
  cognitive,
  physical,
  social,
  emergency,
}

/// 📋 A single guided step within a technique
class InterventionStep {
  final String instruction;   // What to do
  final String? subtext;      // Optional clarifying note
  final int durationSeconds;  // 0 = tap-to-advance, >0 = auto-advance with timer
  final bool isBreathIn;      // For breathing animations
  final bool isBreathOut;     // For breathing animations
  final bool isHold;          // For breathing hold phase

  const InterventionStep({
    required this.instruction,
    this.subtext,
    this.durationSeconds = 0,
    this.isBreathIn = false,
    this.isBreathOut = false,
    this.isHold = false,
  });
}

/// 🎯 Full intervention technique model
class InterventionModel {
  final String id;
  final String title;
  final String subtitle;
  final String message;           // Summary shown before starting
  final String actionText;        // CTA button label
  final String technique;         // Internal technique name key
  final InterventionCategory category;
  final List<InterventionStep> steps;
  final int estimatedMinutes;     // Shown in preview
  final int minIntensity;         // Suitable intensity range
  final int maxIntensity;
  final String emoji;
  final bool isEmergency;

  const InterventionModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.message,
    required this.actionText,
    required this.technique,
    required this.category,
    required this.steps,
    required this.estimatedMinutes,
    this.minIntensity = 1,
    this.maxIntensity = 10,
    this.emoji = '🧘',
    this.isEmergency = false,
  });
}