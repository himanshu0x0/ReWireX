// lib/features/urge/engine/urge_intervention_bridge.dart

import '../data/urge_types.dart';
import '../models/urge_intervention_model.dart';
import '../../intervention/data/intervention_techniques.dart';
import '../../intervention/models/intervention_model.dart';

/// Bridges the new urge-based intervention architecture with the existing
/// guided intervention library.
///
/// Flow:
///   UrgeEngine -> UrgeInterventionModel -> this bridge -> InterventionModel
///
/// The bridge maps only to predefined interventions. It never creates a
/// new intervention at runtime.
class UrgeInterventionBridge {
  const UrgeInterventionBridge();

  /// Converts a selected urge intervention into the existing InterventionModel
  /// consumed by the legacy InterventionScreen.
  InterventionModel toLegacyIntervention(
    UrgeInterventionModel intervention,
  ) {
    return byInterventionId(intervention.id) ??
        _fallbackForPath(intervention.rescuePath);
  }

  /// Converts a selected intervention for a specific urge.
  InterventionModel forUrge({
    required UrgeType urge,
    required UrgeInterventionModel intervention,
  }) {
    return byInterventionId(intervention.id) ??
        _fallbackForPath(urge.defaultRescuePath);
  }

  /// Maps stable UrgeInterventionModel ids to the existing intervention
  /// library. Keep these ids stable because sessions may persist them.
  InterventionModel? byInterventionId(String id) {
    switch (id) {
      case 'message_shield':
        return InterventionTechniques.cognitiveReframing;
      case 'distance_and_release':
        return InterventionTechniques.physicalDischarge;
      case 'recovery_rescue':
        return InterventionTechniques.breathing446;
      case 'connection_rescue':
        return InterventionTechniques.socialRedirect;
      case 'environment_reset':
        return InterventionTechniques.microReset;
      case 'thought_reset':
        return InterventionTechniques.cognitiveReframing;
      case 'activation_rescue':
        return InterventionTechniques.physicalDischarge;
      case 'basic_grounding':
        return InterventionTechniques.grounding54321;

      // Legacy technique ids are also accepted to make migration safer.
      case 'emergency_reset':
        return InterventionTechniques.emergencyReset;
      case 'breathing_446':
        return InterventionTechniques.breathing446;
      case 'grounding_54321':
        return InterventionTechniques.grounding54321;
      case 'cognitive_reframe':
        return InterventionTechniques.cognitiveReframing;
      case 'social_redirect':
        return InterventionTechniques.socialRedirect;
      case 'physical_discharge':
        return InterventionTechniques.physicalDischarge;
      case 'micro_reset':
        return InterventionTechniques.microReset;
      default:
        return null;
    }
  }

  /// Conservative fallback for a rescue path that has no explicit bridge
  /// mapping yet.
  InterventionModel _fallbackForPath(UrgeRescuePath path) {
    switch (path) {
      case UrgeRescuePath.messageShield:
      case UrgeRescuePath.thoughtReset:
        return InterventionTechniques.cognitiveReframing;

      case UrgeRescuePath.distanceAndRelease:
      case UrgeRescuePath.activationRescue:
        return InterventionTechniques.physicalDischarge;

      case UrgeRescuePath.recoveryRescue:
        return InterventionTechniques.breathing446;

      case UrgeRescuePath.connectionRescue:
        return InterventionTechniques.socialRedirect;

      case UrgeRescuePath.environmentReset:
        return InterventionTechniques.microReset;

      case UrgeRescuePath.basicGrounding:
        return InterventionTechniques.grounding54321;
    }
  }

  /// Returns true when the urge intervention has a direct mapping to the
  /// existing intervention library.
  bool hasDirectMapping(String interventionId) {
    return byInterventionId(interventionId) != null;
  }
}
