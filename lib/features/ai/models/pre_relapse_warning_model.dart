// lib/features/ai/models/pre_relapse_warning_model.dart
//
// ⚠️ Pre-Relapse Warning Model
//
// This model carries everything the UI needs to render a deeply
// personalised, actionable warning — not just a severity badge.
// It is the data contract between the PreRelapseWarningService
// (which does the science) and the dashboard card (which shows it).

/// Severity tier — maps to colour, icon, and urgency of copy.
enum WarningSeverity { moderate, high, critical }

/// One intervention strategy suggested to the user.
class InterventionStep {
  final String emoji;
  final String title;
  final String description;

  const InterventionStep({
    required this.emoji,
    required this.title,
    required this.description,
  });
}

/// ⚠️ Pre-Relapse Warning Model
class PreRelapseWarningModel {
  // ── Core fields ────────────────────────────────────────────────

  /// Severity tier: 'Moderate' | 'High' | 'Critical'
  final String severity;

  /// Primary headline message shown to the user.
  final String message;

  /// Short motivational sub-message below the headline.
  final String subMessage;

  /// Signals that contributed to this warning (shown as bullet list).
  final List<String> warningSignals;

  // ── Quantitative context ───────────────────────────────────────

  /// Internal composite risk score 0–100 (for the progress bar).
  final double riskScore;

  /// Relapse probability percentage driving this warning.
  final double relapseProbability;

  /// How many consecutive high-risk days triggered escalation.
  final int consecutiveHighRiskDays;

  // ── Time intelligence ──────────────────────────────────────────

  /// The user's historically riskiest hour (e.g. 21 → "9:00 PM").
  final int peakRiskHour;

  /// Whether the user is currently inside their peak risk window.
  final bool isInPeakWindow;

  /// Predicted duration the risk window will last (in hours).
  final int estimatedWindowHours;

  // ── Personalisation ────────────────────────────────────────────

  /// The dominant negative emotion fuelling this risk.
  final String dominantEmotion;

  /// The primary behavioural trigger identified.
  final String primaryTrigger;

  // ── Intervention ───────────────────────────────────────────────

  /// Ordered list of concrete steps the user should take right now.
  final List<InterventionStep> interventionSteps;

  /// Label for the primary CTA button.
  final String actionLabel;

  const PreRelapseWarningModel({
    required this.severity,
    required this.message,
    this.subMessage                = '',
    this.warningSignals            = const [],
    this.riskScore                 = 0.0,
    this.relapseProbability        = 0.0,
    this.consecutiveHighRiskDays   = 0,
    this.peakRiskHour              = 21,
    this.isInPeakWindow            = false,
    this.estimatedWindowHours      = 2,
    this.dominantEmotion           = '',
    this.primaryTrigger            = '',
    this.interventionSteps         = const [],
    this.actionLabel               = 'Start Prevention',
  });

  /// Convenience getter for the enum representation.
  WarningSeverity get severityEnum {
    switch (severity) {
      case 'Critical': return WarningSeverity.critical;
      case 'High':     return WarningSeverity.high;
      default:         return WarningSeverity.moderate;
    }
  }
}