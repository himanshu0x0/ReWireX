// lib/features/risk/models/risk_model.dart

/// 🚦 Risk Model
///
/// Canonical model used by:
///   • RiskPredictionService  (produced)
///   • PreRiskService          (consumed — peakHour, timeWindow)
///   • RiskCard widget         (consumed — level, probability, timeWindow)
///   • AIGuardianService       (consumed — level)
///   • AIGuidanceService       (consumed — level)
class RiskModel {
  final String level;         // "Low" | "Moderate" | "High" | "Critical"
  final double probability;   // 0–100
  final String timeWindow;    // e.g. "9:00 PM – 11:00 PM"
  final int peakHour;         // 0–23
  final String primaryDriver; // top contributing signal
  final List<String> riskFactors;
  final double weeklyVelocity;

  const RiskModel({
    required this.level,
    required this.probability,
    required this.timeWindow,
    required this.peakHour,
    this.primaryDriver = '',
    this.riskFactors = const [],
    this.weeklyVelocity = 0.0,
  });
}