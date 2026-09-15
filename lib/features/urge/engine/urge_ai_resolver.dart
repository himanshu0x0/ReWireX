// lib/features/urge/engine/urge_ai_resolver.dart

import '../data/intervention_catalog.dart';
import '../data/urge_needs.dart';
import '../data/urge_types.dart';
import '../models/urge_intervention_model.dart';
import '../models/urge_session_model.dart';
import 'need_engine.dart';

/// One simple decision produced for the user-facing Urge Rescue flow.
///
/// This is deliberately small. The user does not need to understand the
/// routing tree underneath it. Later, an LLM/AI service can provide additional
/// signals, but the final intervention must still come from the predefined
/// catalog.
class UrgeResolution {
  const UrgeResolution({
    required this.need,
    required this.intervention,
    required this.reason,
    required this.alternateNeeds,
    required this.requiresSafetyReview,
  });

  final NeedType need;
  final UrgeInterventionModel intervention;
  final String reason;
  final List<NeedType> alternateNeeds;
  final bool requiresSafetyReview;
}

/// Backend-ready, explainable decision layer for Urge Rescue.
///
/// Current version is deterministic so the app remains fast and safe while the
/// AI layer is being built. It considers the urge, emotion, trigger, context,
/// intensity and selected need, then chooses exactly ONE predefined rescue.
class UrgeAiResolver {
  const UrgeAiResolver({this.needEngine = const NeedEngine()});

  final NeedEngine needEngine;

  UrgeResolution resolve(UrgeSessionModel session) {
    final inference = needEngine.inferFromSession(session);
    final selectedNeed = session.selectedNeed ?? inference.selectedNeed;

    final rankedNeeds = <NeedType>[
      selectedNeed,
      ...inference.rankedNeeds,
      ...needsForUrge(session.urgeType),
    ];

    final uniqueNeeds = <NeedType>[];
    final seenNeeds = <NeedType>{};
    for (final need in rankedNeeds) {
      if (need == NeedType.unknown) continue;
      if (seenNeeds.add(need)) uniqueNeeds.add(need);
    }

    final rankedInterventions = rankInterventions(
      urge: session.urgeType,
      need: selectedNeed,
    );

    final intervention = _chooseIntervention(
      rankedInterventions,
      urge: session.urgeType,
      need: selectedNeed,
      intensity: session.urgeBefore,
    );

    return UrgeResolution(
      need: selectedNeed,
      intervention: intervention,
      reason: _reason(
        need: selectedNeed,
        intervention: intervention,
        emotion: session.emotion,
        trigger: session.trigger,
        intensity: session.urgeBefore,
      ),
      alternateNeeds: uniqueNeeds
          .where((need) => need != selectedNeed)
          .take(3)
          .toList(growable: false),
      requiresSafetyReview:
          session.urgeType.requiresSafetyReview ||
          intervention.safetyLevel ==
              InterventionSafetyLevel.safetyReviewRequired,
    );
  }

  UrgeInterventionModel _chooseIntervention(
    List<UrgeInterventionModel> ranked, {
    required UrgeType urge,
    required NeedType need,
    required int? intensity,
  }) {
    if (ranked.isEmpty) {
      return defaultInterventionForUrge(urge);
    }

    // Connection needs should move directly toward a connection-capable rescue.
    if (need == NeedType.connection || need == NeedType.validation) {
      final connection = ranked.where((item) => item.requiresConnection);
      if (connection.isNotEmpty) return connection.first;
    }

    // At very high intensity, favor the safest available predefined action.
    if ((intensity ?? 5) >= 8) {
      final safe = ranked.where(
        (item) => item.safetyLevel == InterventionSafetyLevel.standard,
      );
      if (safe.isNotEmpty) return safe.first;
    }

    return ranked.first;
  }

  String _reason({
    required NeedType need,
    required UrgeInterventionModel intervention,
    required String emotion,
    required String trigger,
    required int? intensity,
  }) {
    final details = <String>[];

    if (need != NeedType.unknown) {
      details.add('it targets ${need.title.toLowerCase()}');
    }
    if (intervention.supportsNeed(need)) {
      details.add('it matches the current urge pattern');
    }
    if ((intensity ?? 0) >= 8) {
      details.add('the intensity is high, so the rescue stays simple and immediate');
    }
    if (emotion.trim().isNotEmpty || trigger.trim().isNotEmpty) {
      details.add('your emotion and trigger were considered');
    }

    if (details.isEmpty) {
      return 'ReWireX chose the closest predefined rescue for this moment.';
    }

    return 'ReWireX chose this because ${details.join(', ')}.';
  }
}
