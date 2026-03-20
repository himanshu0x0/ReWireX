// lib/features/ai/models/ai_memory_model.dart

/// 🧠 AI Memory Model
class AIMemoryModel {
  final int consecutiveHighRiskDays;
  final int sessionMessageCount;
  final DateTime sessionStarted;
  final String lastTone;
  final double lastRelapseProbability;
  final DateTime? lastUpdated;

  const AIMemoryModel({
    required this.consecutiveHighRiskDays,
    this.sessionMessageCount = 0,
    required this.sessionStarted,
    this.lastTone = '',
    this.lastRelapseProbability = 0,
    this.lastUpdated,
  });
}