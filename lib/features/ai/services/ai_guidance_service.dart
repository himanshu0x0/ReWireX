// lib/features/ai/services/ai_guidance_service.dart

import '../../risk/services/risk_prediction_service.dart';
import '../../prediction/services/relapse_prediction_service.dart';
import '../../stability/services/stability_service.dart';
import '../models/ai_guidance_model.dart';
import 'ai_memory_service.dart';

export '../models/ai_guidance_model.dart';

/// 🤖 AI Guidance Service
///
/// Reads multi-signal risk state and memory to produce a
/// context-aware tone, message, and action recommendation.
/// Persists state back to AIMemoryService after each cycle.
class AIGuidanceService {
  final RiskPredictionService  _riskService      = RiskPredictionService();
  final RelapsePredictionService _relapseService = RelapsePredictionService();
  final StabilityService        _stabilityService = StabilityService();
  final AIMemoryService         _memoryService    = AIMemoryService();

  Future<AIGuidanceModel> generateGuidance() async {
    final results = await Future.wait([
      _riskService.analyzeRisk(),
      _relapseService.analyzeRelapseRisk(),
      _stabilityService.calculateStability(),
      _memoryService.getMemory(),
    ]);

    final risk      = results[0] as RiskModel?;
    final relapse   = results[1] as RelapsePredictionModel;
    final stability = results[2] as StabilityModel;
    final memory    = results[3] as AIMemoryModel?;

    int highRiskStreak = memory?.consecutiveHighRiskDays ?? 0;

    final bool isHighRisk = relapse.probability >= 50 ||
        risk?.level == 'High' ||
        risk?.level == 'Critical';

    if (isHighRisk) {
      highRiskStreak++;
    } else {
      highRiskStreak = 0;
    }

    final String tone;
    final String message;
    final String action;

    if (highRiskStreak >= 3) {
      tone    = 'Alert';
      message = 'Risk has remained elevated for $highRiskStreak consecutive days. '
          'Immediate awareness and support are recommended.';
      action  = 'Start Emergency Reset';
    } else if (isHighRisk) {
      tone    = 'Firm';
      message = 'Today requires discipline. Avoid known triggers and stay '
          'close to your recovery routine.';
      action  = 'Open Coping Tools';
    } else if (stability.score >= 70) {
      tone    = 'Supportive';
      message = "You're building resilience. Protect your momentum — "
          'consistency today compounds into strength tomorrow.';
      action  = 'Continue Progress';
    } else {
      tone    = 'Neutral';
      message = 'Stay mindful today. Small decisions in the right direction '
          'accumulate into lasting recovery.';
      action  = 'Check Insights';
    }

    await _memoryService.saveMemory(
      AIMemoryModel(
        consecutiveHighRiskDays: highRiskStreak,
        sessionStarted:          memory?.sessionStarted ?? DateTime.now(),
        lastTone:                tone,
        lastRelapseProbability:  relapse.probability,
        lastUpdated:             DateTime.now(),
      ),
    );

    return AIGuidanceModel(tone: tone, message: message, action: action);
  }
}