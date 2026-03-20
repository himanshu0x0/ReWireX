// lib/features/ai/services/pre_relapse_warning_service.dart

import '../../risk/services/risk_prediction_service.dart';
import '../../prediction/services/relapse_prediction_service.dart';
import '../models/pre_relapse_warning_model.dart';

export '../models/pre_relapse_warning_model.dart';

/// ⚠️ Pre-Relapse Warning Service
///
/// Combines risk level and relapse probability to produce a
/// contextual warning when the user is approaching a high-risk state.
/// Returns null when no warning is needed (Low/Moderate).
class PreRelapseWarningService {
  final RiskPredictionService _riskService =
      RiskPredictionService();
  final RelapsePredictionService _relapseService =
      RelapsePredictionService();

  Future<PreRelapseWarningModel?> checkWarning() async {
    try {
      final results = await Future.wait([
        _riskService.analyzeRisk(),
        _relapseService.analyzeRelapseRisk(),
      ]);

      final risk    = results[0] as RiskModel?;
      final relapse = results[1] as RelapsePredictionModel;

      final riskLevel = risk?.level ?? 'Low';
      final prob      = relapse.probability;

      // Only surface warning for High / Critical states
      if (riskLevel == 'Low' || riskLevel == 'Moderate') {
        if (prob < 50) return null;
      }

      final String severity;
      final String message;
      final List<String> signals = [];

      if (prob >= 80 || riskLevel == 'Critical') {
        severity = 'Critical';
        message  = 'Critical relapse risk detected. Your behavioral patterns '
            'indicate you are in a high-danger window. Take immediate action.';
      } else if (prob >= 60 || riskLevel == 'High') {
        severity = 'High';
        message  = 'Elevated relapse risk. Urge patterns are intensifying. '
            'Stay connected to your recovery plan and avoid known triggers.';
      } else {
        severity = 'Moderate';
        message  = 'Moderate warning: urge frequency is rising. '
            'Be intentional about your environment and routine today.';
      }

      if (riskLevel == 'High' || riskLevel == 'Critical') {
        signals.add('High behavioral risk detected');
      }
      if (prob >= 50) signals.add('Elevated relapse probability (${prob.toStringAsFixed(0)}%)');
      if (relapse.warningSignals.isNotEmpty) signals.addAll(relapse.warningSignals.take(2));

      return PreRelapseWarningModel(
        severity:       severity,
        message:        message,
        warningSignals: signals,
      );
    } catch (_) {
      return null;
    }
  }
}