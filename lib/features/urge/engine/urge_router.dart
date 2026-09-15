import '../data/intervention_catalog.dart';
import '../data/urge_needs.dart';
import '../data/urge_types.dart';
import '../models/urge_intervention_model.dart';
import '../models/urge_session_model.dart';

/// Central deterministic routing layer for the Urge Rescue system.
///
/// The router decides:
/// 1. which needs are most plausible for the current urge,
/// 2. which rescue path should be used,
/// 3. which predefined interventions should be ranked first.
///
/// AI can later provide additional context or ranking signals, but this
/// router remains the safe baseline and never invents intervention content.
class UrgeRouter {
  const UrgeRouter();

  /// Routes a complete session using the information already collected.
  UrgeRouteResult route(UrgeSessionModel session) {
    final needs = suggestedNeedsFor(
      urge: session.urgeType,
      selectedNeed: session.selectedNeed,
    );

    final selectedNeed =
        session.selectedNeed ?? (needs.isNotEmpty ? needs.first : null);

    final ranked = rankInterventions(
      urge: session.urgeType,
      need: selectedNeed,
    );

    final intervention = ranked.isNotEmpty
        ? ranked.first
        : defaultInterventionForUrge(session.urgeType);

    final safetyReviewRequired =
        session.urgeType.requiresSafetyReview ||
        intervention.safetyLevel ==
            InterventionSafetyLevel.safetyReviewRequired;

    return UrgeRouteResult(
      urgeType: session.urgeType,
      rescuePath: session.urgeType.defaultRescuePath,
      suggestedNeeds: needs,
      selectedNeed: selectedNeed,
      rankedInterventions: List.unmodifiable(ranked),
      selectedIntervention: intervention,
      safetyReviewRequired: safetyReviewRequired,
      requiresConnection: intervention.requiresConnection,
    );
  }

  /// Returns needs for an urge, while preserving an explicitly selected need
  /// as the highest-priority option.
  List<NeedType> suggestedNeedsFor({
    required UrgeType urge,
    NeedType? selectedNeed,
  }) {
    final base = needsForUrge(urge);

    final values = <NeedType>[
      if (selectedNeed != null && selectedNeed != NeedType.unknown)
        selectedNeed,
      ...base,
    ];

    return prioritizeNeeds(values);
  }

  /// Returns interventions ordered from most suitable to least suitable.
  List<UrgeInterventionModel> rank({
    required UrgeType urge,
    NeedType? need,
  }) {
    return rankInterventions(
      urge: urge,
      need: need,
    );
  }

  /// Returns the safest default catalog intervention when no stronger match
  /// exists.
  UrgeInterventionModel defaultIntervention(UrgeType urge) {
    return defaultInterventionForUrge(urge);
  }

  /// Re-routes after the user changes the need.
  UrgeRouteResult rerouteForNeed({
    required UrgeType urge,
    required NeedType need,
  }) {
    final needs = suggestedNeedsFor(
      urge: urge,
      selectedNeed: need,
    );

    final ranked = rank(
      urge: urge,
      need: need,
    );

    final intervention = ranked.isNotEmpty
        ? ranked.first
        : defaultIntervention(urge);

    return UrgeRouteResult(
      urgeType: urge,
      rescuePath: urge.defaultRescuePath,
      suggestedNeeds: List.unmodifiable(needs),
      selectedNeed: need,
      rankedInterventions: List.unmodifiable(ranked),
      selectedIntervention: intervention,
      safetyReviewRequired:
          urge.requiresSafetyReview ||
          intervention.safetyLevel ==
              InterventionSafetyLevel.safetyReviewRequired,
      requiresConnection: intervention.requiresConnection,
    );
  }
}

/// Complete deterministic result produced by [UrgeRouter].
class UrgeRouteResult {
  final UrgeType urgeType;
  final UrgeRescuePath rescuePath;
  final List<NeedType> suggestedNeeds;
  final NeedType? selectedNeed;
  final List<UrgeInterventionModel> rankedInterventions;
  final UrgeInterventionModel selectedIntervention;
  final bool safetyReviewRequired;
  final bool requiresConnection;

  const UrgeRouteResult({
    required this.urgeType,
    required this.rescuePath,
    required this.suggestedNeeds,
    required this.selectedNeed,
    required this.rankedInterventions,
    required this.selectedIntervention,
    required this.safetyReviewRequired,
    required this.requiresConnection,
  });

  /// Produces the selected intervention id for analytics/persistence.
  String get interventionId => selectedIntervention.id;

  /// Produces the selected intervention title for analytics/persistence.
  String get interventionTitle => selectedIntervention.title;

  /// Whether this route should stay in the normal rescue layer rather than
  /// immediately handing control to a higher-level support layer.
  bool get isStandardRescue =>
      !safetyReviewRequired && !requiresConnection;

  /// Applies this route back onto the current session.
  ///
  /// The actual session remains immutable; callers receive a new model.
  UrgeSessionModel applyToSession(UrgeSessionModel session) {
    return session.copyWith(
      selectedNeed: selectedNeed,
      suggestedNeeds: suggestedNeeds,
      rescuePath: rescuePath,
      interventionId: selectedIntervention.id,
      interventionTitle: selectedIntervention.title,
      status: UrgeSessionStatus.interventionSelected,
      updatedAt: DateTime.now(),
    );
  }
}
