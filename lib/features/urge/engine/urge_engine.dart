import '../models/urge_session_model.dart';
import '../models/urge_intervention_model.dart';
import '../data/urge_needs.dart';
import '../data/urge_types.dart';
import 'urge_router.dart';
import 'need_engine.dart';
import 'intervention_engine.dart';

/// Unified orchestration layer for the Urge Rescue Engine.
///
/// This class keeps the rescue pipeline in one place:
///
///   Session -> Route -> Need inference -> Intervention decision
///
/// The individual engines remain deterministic and testable, while screens
/// and services can depend on this single facade instead of reproducing the
/// routing logic themselves.
class UrgeEngine {
  const UrgeEngine({
    this.router = const UrgeRouter(),
    this.needEngine = const NeedEngine(),
    this.interventionEngine = const InterventionEngine(),
  });

  final UrgeRouter router;
  final NeedEngine needEngine;
  final InterventionEngine interventionEngine;

  /// Runs the complete rescue analysis for a session.
  UrgeEngineResult analyze(UrgeSessionModel session) {
    final route = router.route(session);
    final needInference = needEngine.inferFromSession(session);
    final interventionDecision = interventionEngine.decide(session);

    return UrgeEngineResult(
      session: session,
      route: route,
      needInference: needInference,
      interventionDecision: interventionDecision,
    );
  }

  /// Applies the deterministic routing result to the session.
  ///
  /// This is useful before persisting a session or moving to the intervention
  /// selection/rescue screen.
  UrgeSessionModel prepareSession(UrgeSessionModel session) {
    final route = router.route(session);
    final decision = interventionEngine.decide(session);

    return session.copyWith(
      selectedNeed: decision.selectedNeed,
      suggestedNeeds: route.suggestedNeeds,
      rescuePath: route.rescuePath,
      interventionId: decision.interventionId,
      interventionTitle: decision.interventionTitle,
      status: UrgeSessionStatus.interventionSelected,
      updatedAt: DateTime.now(),
    );
  }

  /// Returns the best predefined intervention for a session.
  UrgeInterventionModel selectIntervention(UrgeSessionModel session) {
    return interventionEngine.selectForSession(session);
  }

  /// Returns the needs ranked for the current urge/session.
  List<NeedType> rankedNeeds(UrgeSessionModel session) {
    return needEngine
        .inferFromSession(session)
        .rankedNeeds
        .toList(growable: false);
  }

  /// Returns whether the current rescue decision requires an explicit safety
  /// review before continuing.
  bool requiresSafetyReview(UrgeSessionModel session) {
    return interventionEngine.decide(session).safetyReviewRequired;
  }

  /// Returns whether connection support is part of the recommended rescue.
  bool requiresConnection(UrgeSessionModel session) {
    return interventionEngine.decide(session).requiresConnection;
  }
}

/// Complete result of the unified urge analysis pipeline.
class UrgeEngineResult {
  const UrgeEngineResult({
    required this.session,
    required this.route,
    required this.needInference,
    required this.interventionDecision,
  });

  final UrgeSessionModel session;
  final UrgeRouteResult route;
  final NeedInference needInference;
  final InterventionDecision interventionDecision;

  UrgeType get urgeType => session.urgeType;
  NeedType get selectedNeed => interventionDecision.selectedNeed;
  UrgeInterventionModel get selectedIntervention =>
      interventionDecision.selected;

  String get interventionId => interventionDecision.interventionId;
  String get interventionTitle => interventionDecision.interventionTitle;

  bool get safetyReviewRequired =>
      interventionDecision.safetyReviewRequired;

  bool get requiresConnection => interventionDecision.requiresConnection;

  bool get isStandardRescue =>
      !safetyReviewRequired && !requiresConnection;

  String get rationale => interventionDecision.rationale;
}
