import '../data/urge_needs.dart';
import '../data/urge_types.dart';

/// A single step inside an intervention.
///
/// Keep steps concrete and actionable. The Intervention Engine should be able
/// to present them one at a time and optionally record completion.
class InterventionStep {
  final String id;
  final String title;
  final String instruction;
  final String? helperText;
  final int estimatedSeconds;
  final bool skippable;

  const InterventionStep({
    required this.id,
    required this.title,
    required this.instruction,
    this.helperText,
    this.estimatedSeconds = 30,
    this.skippable = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'instruction': instruction,
        'helperText': helperText,
        'estimatedSeconds': estimatedSeconds,
        'skippable': skippable,
      };

  factory InterventionStep.fromMap(Map<String, dynamic> map) {
    return InterventionStep(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      instruction: map['instruction']?.toString() ?? '',
      helperText: _nullableString(map['helperText']),
      estimatedSeconds:
          _positiveInt(map['estimatedSeconds'], fallback: 30),
      skippable: map['skippable'] as bool? ?? false,
    );
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static int _positiveInt(dynamic value, {required int fallback}) {
    final parsed = value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '');
    if (parsed == null || parsed <= 0) return fallback;
    return parsed;
  }
}

/// High-level safety level used by the routing engine.
///
/// This is NOT a diagnosis.
/// It tells the app whether the intervention can remain in the normal
/// self-guided rescue flow or should first be reviewed by the safety layer.
enum InterventionSafetyLevel {
  standard,
  caution,
  safetyReviewRequired,
}

extension InterventionSafetyLevelX on InterventionSafetyLevel {
  String get key => switch (this) {
        InterventionSafetyLevel.standard => 'standard',
        InterventionSafetyLevel.caution => 'caution',
        InterventionSafetyLevel.safetyReviewRequired =>
          'safety_review_required',
      };

  static InterventionSafetyLevel fromKey(String? value) {
    final key = value?.trim().toLowerCase();

    for (final level in InterventionSafetyLevel.values) {
      if (level.key == key) return level;
    }

    return InterventionSafetyLevel.standard;
  }
}

/// Result produced after the user completes or exits an intervention.
enum InterventionCompletionOutcome {
  completed,
  partiallyCompleted,
  skipped,
  abandoned,
  escalated,
}

extension InterventionCompletionOutcomeX
    on InterventionCompletionOutcome {
  String get key => switch (this) {
        InterventionCompletionOutcome.completed => 'completed',
        InterventionCompletionOutcome.partiallyCompleted =>
          'partially_completed',
        InterventionCompletionOutcome.skipped => 'skipped',
        InterventionCompletionOutcome.abandoned => 'abandoned',
        InterventionCompletionOutcome.escalated => 'escalated',
      };

  static InterventionCompletionOutcome fromKey(String? value) {
    final key = value?.trim().toLowerCase();

    for (final outcome in InterventionCompletionOutcome.values) {
      if (outcome.key == key) return outcome;
    }

    return InterventionCompletionOutcome.abandoned;
  }
}

/// Defines a reusable rescue intervention.
///
/// This is the contract between:
///   Urge Router → Intervention Engine → Rescue UI
///
/// The catalog will provide concrete interventions such as:
/// - Message Shield
/// - Recovery Rescue
/// - Connection Rescue
/// - Environment Reset
/// - Thought Reset
/// - Activation Rescue
///
/// AI should select/rank these predefined interventions rather than inventing
/// arbitrary instructions at runtime.
class UrgeInterventionModel {
  final String id;
  final String title;
  final String subtitle;
  final String description;

  /// The rescue family represented by this intervention.
  final UrgeRescuePath rescuePath;

  /// Urges this intervention is designed for.
  final List<UrgeType> supportedUrges;

  /// Needs this intervention can satisfy.
  final List<NeedType> supportedNeeds;

  /// Ordered actions presented to the user.
  final List<InterventionStep> steps;

  /// Typical total duration shown in UI.
  final int estimatedDurationSeconds;

  /// Whether the user can safely use this without first going through the
  /// safety router.
  final InterventionSafetyLevel safetyLevel;

  /// Whether this intervention changes the environment, rather than only
  /// changing thoughts/emotions.
  final bool isEnvironmental;

  /// Whether the intervention involves another person / connection.
  final bool requiresConnection;

  /// Whether the intervention may be shown automatically as a first response.
  final bool canAutoStart;

  /// Ordering preference inside an intervention catalog.
  final int priority;

  final String? completionMessage;
  final String? fallbackMessage;

  const UrgeInterventionModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.rescuePath,
    required this.supportedUrges,
    required this.supportedNeeds,
    required this.steps,
    required this.estimatedDurationSeconds,
    this.safetyLevel = InterventionSafetyLevel.standard,
    this.isEnvironmental = false,
    this.requiresConnection = false,
    this.canAutoStart = true,
    this.priority = 0,
    this.completionMessage,
    this.fallbackMessage,
  });

  /// Whether this intervention is a good match for [urge].
  bool supportsUrge(UrgeType urge) => supportedUrges.contains(urge);

  /// Whether this intervention can address [need].
  bool supportsNeed(NeedType need) => supportedNeeds.contains(need);

  /// Simple deterministic match score.
  ///
  /// The Intervention Engine can add user-history signals on top of this
  /// score. This model intentionally remains deterministic and explainable.
  int matchScore({
    required UrgeType urge,
    NeedType? need,
  }) {
    var score = 0;

    if (supportsUrge(urge)) score += 50;
    if (need != null && supportsNeed(need)) score += 30;
    if (safetyLevel == InterventionSafetyLevel.standard) score += 5;
    score += priority.clamp(-20, 20);

    return score;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'description': description,
        'rescuePath': rescuePath.key,
        'supportedUrges': supportedUrges.map((e) => e.key).toList(),
        'supportedNeeds': supportedNeeds.map((e) => e.key).toList(),
        'steps': steps.map((e) => e.toMap()).toList(),
        'estimatedDurationSeconds': estimatedDurationSeconds,
        'safetyLevel': safetyLevel.key,
        'isEnvironmental': isEnvironmental,
        'requiresConnection': requiresConnection,
        'canAutoStart': canAutoStart,
        'priority': priority,
        'completionMessage': completionMessage,
        'fallbackMessage': fallbackMessage,
      };

  factory UrgeInterventionModel.fromMap(Map<String, dynamic> map) {
    final urgeValues = <UrgeType>[];
    final rawUrges = map['supportedUrges'];

    if (rawUrges is Iterable) {
      for (final value in rawUrges) {
        urgeValues.add(UrgeTypeX.fromKey(value?.toString()));
      }
    }

    final needValues = <NeedType>[];
    final rawNeeds = map['supportedNeeds'];

    if (rawNeeds is Iterable) {
      for (final value in rawNeeds) {
        needValues.add(NeedTypeX.fromKey(value?.toString()));
      }
    }

    final stepValues = <InterventionStep>[];
    final rawSteps = map['steps'];

    if (rawSteps is Iterable) {
      for (final value in rawSteps) {
        if (value is Map) {
          stepValues.add(
            InterventionStep.fromMap(
              Map<String, dynamic>.from(value),
            ),
          );
        }
      }
    }

    return UrgeInterventionModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      subtitle: map['subtitle']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      rescuePath:
          UrgeRescuePathX.fromKey(map['rescuePath']?.toString()),
      supportedUrges: List.unmodifiable(urgeValues),
      supportedNeeds: List.unmodifiable(needValues),
      steps: List.unmodifiable(stepValues),
      estimatedDurationSeconds:
          _positiveInt(map['estimatedDurationSeconds'], fallback: 60),
      safetyLevel: InterventionSafetyLevelX.fromKey(
        map['safetyLevel']?.toString(),
      ),
      isEnvironmental: map['isEnvironmental'] as bool? ?? false,
      requiresConnection: map['requiresConnection'] as bool? ?? false,
      canAutoStart: map['canAutoStart'] as bool? ?? true,
      priority: _intValue(map['priority']),
      completionMessage: _nullableString(map['completionMessage']),
      fallbackMessage: _nullableString(map['fallbackMessage']),
    );
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static int _intValue(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _positiveInt(dynamic value, {required int fallback}) {
    final parsed = value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '');
    if (parsed == null || parsed <= 0) return fallback;
    return parsed;
  }
}
