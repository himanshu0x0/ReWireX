// lib/features/urge/models/urge_solution_model.dart

import '../data/urge_needs.dart';
import 'urge_intervention_model.dart';

/// Types of user-facing actions that ReWireX can recommend for an urge.
///
/// The solution engine should only select from the predefined actions in the
/// solution catalog. It should not create a new action dynamically.
enum UrgeSolutionActionType {
  chat,
  truthDare,
  recoveryStories,
  music,
  journal,
  meditation,
  grounding,
  guidedRescue,
  environmentReset,
  movement,
}

/// A single predefined solution that can be shown to the user.
class UrgeSolutionAction {
  const UrgeSolutionAction({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.emoji,
    required this.estimatedMinutes,
    this.available = true,
    this.interventionId,
    this.priority = 0,
  });

  /// Stable identifier used for analytics and feedback.
  final String id;

  /// Internal solution category used by the ranking engine and UI.
  final UrgeSolutionActionType type;

  /// Main user-facing title.
  final String title;

  /// One-line explanation shown below the title.
  final String subtitle;

  /// Longer explanation shown when the user starts the action.
  final String description;

  /// Small visual identifier used by the solution screen.
  final String emoji;

  /// Approximate duration in minutes for quick-tool actions.
  final int estimatedMinutes;

  /// Whether the action can currently be started.
  ///
  /// For example, the future Connect/Chat action is kept in the catalog but
  /// is currently unavailable.
  final bool available;

  /// Optional ID of an existing UrgeInterventionModel.
  ///
  /// When present, the solution screen can open the corresponding guided
  /// intervention instead of showing a quick tool.
  final String? interventionId;

  /// Base ranking weight used by [UrgeSolutionEngine].
  final int priority;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is UrgeSolutionAction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Complete decision returned by the solution engine.
class UrgeSolutionPlan {
  const UrgeSolutionPlan({
    required this.need,
    required this.primary,
    required this.alternatives,
    required this.reason,
    this.intervention,
  });

  /// Need inferred internally from the urge/session context.
  final NeedType need;

  /// The single best action to show first.
  final UrgeSolutionAction primary;

  /// Up to two alternative predefined actions.
  final List<UrgeSolutionAction> alternatives;

  /// Human-readable explanation for why the primary action was selected.
  final String reason;

  /// Existing guided intervention connected to the primary action, when one
  /// exists in the intervention catalog.
  final UrgeInterventionModel? intervention;
}
