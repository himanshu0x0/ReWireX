import 'package:rewirex/features/intervention/services/intervention_ranking_service.dart';

import '../data/intervention_catalog.dart';
import '../data/urge_needs.dart';
import '../data/urge_types.dart';
import '../models/urge_intervention_model.dart';
import '../models/urge_session_model.dart';
import 'need_engine.dart';

/// Deterministic selector for predefined, safe urge interventions.
///
/// The engine never creates intervention content. It only ranks interventions
/// that already exist in [urgeInterventionCatalog]. This keeps rescue actions
/// explainable, testable, and bounded by the safety rules in the catalog.
class InterventionEngine {
  const InterventionEngine({
    this.needEngine = const NeedEngine(),
    this.rankingService,
  });

  final NeedEngine needEngine;
  final InterventionRankingService? rankingService;

  /// Returns ranked interventions for an urge and optional need.
  List<UrgeInterventionModel> rank({
    required UrgeType urge,
    NeedType? need,
    bool safetyReviewOnly = false,
    bool connectionOnly = false,
  }) {
    final ranked = rankInterventions(urge: urge, need: need);

    final filtered = ranked.where((item) {
      if (safetyReviewOnly && item.safetyLevel != InterventionSafetyLevel.safetyReviewRequired) {
        return false;
      }
      if (connectionOnly && !item.requiresConnection) {
        return false;
      }
      return true;
    }).toList();

    return filtered.isNotEmpty ? filtered : ranked;
  }

  /// Selects the safest best-fit predefined intervention.
  UrgeInterventionModel select({
    required UrgeType urge,
    NeedType? need,
  }) {
    final ranked = rank(urge: urge, need: need);
    return ranked.first;
  }

  /// Selects an intervention from a complete session, inferring the need when
  /// the user has not explicitly selected one.
  UrgeInterventionModel selectForSession(UrgeSessionModel session) {
    NeedType? need = session.selectedNeed;

    if (need == null) {
      need = needEngine.inferFromSession(session).selectedNeed;
    }

    return select(urge: session.urgeType, need: need);
  }

  /// Produces a personalized decision by combining the safe static catalog
  /// with the user's historical intervention outcomes.
  ///
  /// The learned ranking is only allowed to reorder interventions already
  /// present in the predefined catalog. If there is not enough historical
  /// confidence, the deterministic catalog ranking remains the fallback.
  Future<InterventionDecision> decidePersonalized(
    UrgeSessionModel session,
  ) async {
    final inference = needEngine.inferFromSession(session);
    final effectiveNeed = session.selectedNeed ?? inference.selectedNeed;
    final staticRanked = rank(
      urge: session.urgeType,
      need: effectiveNeed,
    );

    if (staticRanked.isEmpty) {
      throw StateError(
        'No predefined intervention exists for ${session.urgeType.name}.',
      );
    }

    final learned = await (rankingService ?? InterventionRankingService()).rankInterventions(
      emotion: session.emotion,
      urgeType: session.urgeType.name,
      need: effectiveNeed.name,
      intensity: session.urgeBefore,
      rescuePath: session.rescuePath.name,
      limit: staticRanked.length,
    );

    final learnedById = <String, InterventionRankingResult>{
      for (final result in learned) result.interventionId: result,
    };

    final personalized = <UrgeInterventionModel>[];
    final remaining = <UrgeInterventionModel>[];

    for (final intervention in staticRanked) {
      if (learnedById.containsKey(intervention.id)) {
        personalized.add(intervention);
      } else {
        remaining.add(intervention);
      }
    }

    personalized.sort((a, b) {
      final aScore = learnedById[a.id]?.confidence ?? -1.0;
      final bScore = learnedById[b.id]?.confidence ?? -1.0;
      return bScore.compareTo(aScore);
    });

    final ranked = <UrgeInterventionModel>[...
      personalized,
      ...remaining,
    ];
    final selected = ranked.first;
    final learnedResult = learnedById[selected.id];

    return InterventionDecision(
      selected: selected,
      ranked: ranked,
      selectedNeed: effectiveNeed,
      needInference: inference,
      safetyReviewRequired:
          selected.safetyLevel == InterventionSafetyLevel.safetyReviewRequired ||
              (selected.supportsUrge(session.urgeType) &&
                  session.urgeType.requiresSafetyReview),
      requiresConnection: selected.requiresConnection,
      usedPersonalization: learnedResult != null,
      learnedConfidence: learnedResult?.confidence,
      rationale: _buildPersonalizedRationale(
        intervention: selected,
        urge: session.urgeType,
        need: effectiveNeed,
        learnedConfidence: learnedResult?.confidence,
      ),
    );
  }

  /// Returns personalized interventions while preserving the catalog as the
  /// source of truth for all actual intervention content.
  Future<List<UrgeInterventionModel>> rankPersonalized(
    UrgeSessionModel session,
  ) async {
    return (await decidePersonalized(session)).ranked;
  }

  /// Produces a full, explainable decision for the rescue flow.
  InterventionDecision decide(UrgeSessionModel session) {
    final inference = needEngine.inferFromSession(session);
    final effectiveNeed = session.selectedNeed ?? inference.selectedNeed;
    final ranked = rank(urge: session.urgeType, need: effectiveNeed);
    final selected = ranked.first;

    return InterventionDecision(
      selected: selected,
      ranked: ranked,
      selectedNeed: effectiveNeed,
      needInference: inference,
      safetyReviewRequired:
          selected.safetyLevel == InterventionSafetyLevel.safetyReviewRequired ||
              (selected.supportsUrge(session.urgeType) &&
                  session.urgeType.requiresSafetyReview),
      requiresConnection: selected.requiresConnection,
      rationale: _buildRationale(
        intervention: selected,
        urge: session.urgeType,
        need: effectiveNeed,
      ),
    );
  }

  String _buildPersonalizedRationale({
    required UrgeInterventionModel intervention,
    required UrgeType urge,
    required NeedType need,
    double? learnedConfidence,
  }) {
    final base = _buildRationale(
      intervention: intervention,
      urge: urge,
      need: need,
    );

    if (learnedConfidence == null) {
      return '$base Using the predefined catalog because there is not enough personal history to override it.';
    }

    final percent = (learnedConfidence * 100).round();
    return '$base Your previous sessions give this intervention a $percent% personalization confidence.';
  }

  String _buildRationale({
    required UrgeInterventionModel intervention,
    required UrgeType urge,
    required NeedType need,
  }) {
    final parts = <String>[];

    if (intervention.supportsUrge(urge)) {
      parts.add('matches the urge pattern');
    }
    if (intervention.supportsNeed(need)) {
      parts.add('targets the selected need');
    }
    if (intervention.requiresConnection) {
      parts.add('can involve connection support');
    }
    if (intervention.safetyLevel == InterventionSafetyLevel.caution) {
      parts.add('uses a more cautious rescue path');
    }

    if (parts.isEmpty) {
      return 'selected as the best available predefined rescue intervention';
    }

    return 'Selected because it ${parts.join(', ')}.';
  }

  /// Checks whether the catalog still contains a valid fallback for every
  /// supported urge type.
  List<UrgeType> unsupportedUrges() {
    return UrgeType.values.where((urge) {
      return rank(urge: urge).isEmpty;
    }).toList();
  }

  /// Checks whether a specific need can be served by at least one catalog item
  /// for the given urge.
  bool hasInterventionFor({
    required UrgeType urge,
    required NeedType need,
  }) {
    return rank(urge: urge, need: need).isNotEmpty;
  }
}

class InterventionDecision {
  const InterventionDecision({
    required this.selected,
    required this.ranked,
    required this.selectedNeed,
    required this.needInference,
    required this.safetyReviewRequired,
    required this.requiresConnection,
    required this.rationale,
    this.usedPersonalization = false,
    this.learnedConfidence,
  });

  final UrgeInterventionModel selected;
  final List<UrgeInterventionModel> ranked;
  final NeedType selectedNeed;
  final NeedInference needInference;
  final bool safetyReviewRequired;
  final bool requiresConnection;
  final String rationale;
  final bool usedPersonalization;
  final double? learnedConfidence;

  String get interventionId => selected.id;
  String get interventionTitle => selected.title;
}
