// lib/features/prediction/models/relapse_prediction_model.dart

/// ⚠️ Relapse Prediction Model
class RelapsePredictionModel {
  final double probability;
  final String level;             // "Low" | "Moderate" | "High" | "Critical"
  final String reason;            // human-readable explanation for UI
  final String primaryWarningSign;
  final List<String> warningSignals;
  final double confidenceScore;

  const RelapsePredictionModel({
    required this.probability,
    required this.level,
    this.reason             = '',
    this.primaryWarningSign = '',
    this.warningSignals     = const [],
    this.confidenceScore    = 0.5,
  });
}