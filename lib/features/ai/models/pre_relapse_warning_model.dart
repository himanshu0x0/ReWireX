// lib/features/ai/models/pre_relapse_warning_model.dart

/// ⚠️ Pre-Relapse Warning Model
class PreRelapseWarningModel {
  final String severity; // "Moderate" | "High" | "Critical"
  final String message;
  final List<String> warningSignals;

  const PreRelapseWarningModel({
    required this.severity,
    required this.message,
    this.warningSignals = const [],
  });
}