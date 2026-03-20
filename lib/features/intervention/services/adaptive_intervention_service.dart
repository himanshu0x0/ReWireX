// lib/features/intervention/services/adaptive_intervention_service.dart

import '../models/intervention_model.dart';
import '../data/intervention_techniques.dart';
import '../../risk/services/risk_prediction_service.dart';
import 'intervention_ranking_service.dart';

/// 🧠 Adaptive Intervention Service
///
/// Selection priority:
///   1. Personalized best technique from ranking (if confidence ≥ 0.6)
///   2. Emergency override (intensity ≥ 9 OR risk = Critical)
///   3. Emotion + intensity matrix
///   4. Default micro reset
class AdaptiveInterventionService {
  final InterventionRankingService _rankingService =
      InterventionRankingService();

  Future<InterventionModel> generateIntervention({
    required String emotion,
    required int intensity,
  }) async {
    final risk = await RiskPredictionService().analyzeRisk();
    final String riskLevel = risk?.level ?? 'Low';

    // ── 1. Personalized best technique ───────────────────────────
    final bestTechnique =
        await _rankingService.getBestTechniqueForEmotion(emotion);

    if (bestTechnique != null) {
      final personalized = InterventionTechniques.byTechnique[bestTechnique];
      if (personalized != null) return personalized;
    }

    // ── 2. Emergency override ─────────────────────────────────────
    if (intensity >= 9 || riskLevel == 'Critical') {
      return InterventionTechniques.emergencyReset;
    }

    // ── 3. Emotion + intensity matrix ─────────────────────────────
    switch (emotion) {
      case 'Lonely':
        return InterventionTechniques.socialRedirect;

      case 'Angry':
      case 'Frustrated':
        // High intensity → physical discharge first; moderate → breathing
        return intensity >= 7
            ? InterventionTechniques.physicalDischarge
            : InterventionTechniques.breathing446;

      case 'Anxious':
      case 'Stressed':
        return InterventionTechniques.grounding54321;

      case 'Overthinking':
      case 'Depressed':
      case 'Hopeless':
        return InterventionTechniques.cognitiveReframing;

      case 'Bored':
        return InterventionTechniques.physicalDischarge;

      case 'Sad':
      case 'Empty':
        return intensity >= 6
            ? InterventionTechniques.cognitiveReframing
            : InterventionTechniques.socialRedirect;

      default:
        // Intensity-based fallback
        if (intensity >= 7) return InterventionTechniques.breathing446;
        return InterventionTechniques.microReset;
    }
  }

  /// Returns a ranked list of all suitable techniques for given
  /// emotion + intensity (used by "Try a Different Technique" flow).
  List<InterventionModel> getAlternatives({
    required String emotion,
    required int intensity,
    String? excludeTechnique,
  }) {
    return InterventionTechniques.all
        .where((t) =>
            t.technique != excludeTechnique &&
            intensity >= t.minIntensity &&
            intensity <= t.maxIntensity)
        .toList();
  }
}