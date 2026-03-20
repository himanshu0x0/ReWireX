// lib/features/prediction/models/urge_prediction_model.dart

/// 🔮 Urge Prediction Model
class UrgePredictionModel {
  final String prediction;    // "Low" | "Moderate" | "High" | "Critical"
  final int probability;      // 0–100
  final String window;        // e.g. "9:00 PM – 11:00 PM"
  final int peakHour;
  final List<int> topRiskHours;
  final String contextLabel;

  const UrgePredictionModel({
    required this.prediction,
    required this.probability,
    required this.window,
    this.peakHour = 0,
    this.topRiskHours = const [],
    this.contextLabel = '',
  });
}