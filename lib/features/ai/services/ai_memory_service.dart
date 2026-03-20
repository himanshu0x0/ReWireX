// lib/features/ai/services/ai_memory_service.dart

import '../models/ai_memory_model.dart';

export '../models/ai_memory_model.dart';

/// 🧠 AI Memory Service
///
/// Singleton. Two memory layers:
///   Layer 1 — Session conversation history (rolling 24 messages)
///   Layer 2 — Lightweight in-memory state (risk signals, tone, probability)
///
/// saveMemory() is called by AIGuidanceService after each guidance cycle.
class AIMemoryService {
  static final AIMemoryService _instance = AIMemoryService._internal();
  factory AIMemoryService() => _instance;
  AIMemoryService._internal() : _sessionStarted = DateTime.now();

  // ── Session history ────────────────────────────────────────────
  final List<Map<String, String>> _history = [];
  static const int _maxHistory = 24;

  void addUserMessage(String message) {
    _history.add({'role': 'user', 'content': message});
    if (_history.length > _maxHistory) _history.removeAt(0);
    _sessionMessageCount++;
  }

  void addAIMessage(String message) {
    _history.add({'role': 'assistant', 'content': message});
    if (_history.length > _maxHistory) _history.removeAt(0);
  }

  List<Map<String, String>> getHistory() => List.unmodifiable(_history);

  void clearHistory() {
    _history.clear();
    _sessionMessageCount = 0;
  }

  // ── Persistent lightweight state ───────────────────────────────
  int      _consecutiveHighRiskDays    = 0;
  int      _sessionMessageCount        = 0;
  String   _lastTone                   = '';
  double   _lastRelapseProbability     = 0;
  DateTime? _lastUpdated;
  final DateTime _sessionStarted;

  /// Returns the current memory snapshot.
  Future<AIMemoryModel?> getMemory() async {
    return AIMemoryModel(
      consecutiveHighRiskDays: _consecutiveHighRiskDays,
      sessionMessageCount:     _sessionMessageCount,
      sessionStarted:          _sessionStarted,
      lastTone:                _lastTone,
      lastRelapseProbability:  _lastRelapseProbability,
      lastUpdated:             _lastUpdated,
    );
  }

  /// Saves a memory snapshot from AIGuidanceService.
  Future<void> saveMemory(AIMemoryModel model) async {
    _consecutiveHighRiskDays = model.consecutiveHighRiskDays;
    _lastTone                = model.lastTone;
    _lastRelapseProbability  = model.lastRelapseProbability;
    _lastUpdated             = model.lastUpdated;
  }

  void recordHighRiskDay() => _consecutiveHighRiskDays++;
  void resetHighRiskDays() => _consecutiveHighRiskDays = 0;

  bool get isExtendedSession      => _sessionMessageCount > 15;
  int  get sessionDurationMinutes => DateTime.now().difference(_sessionStarted).inMinutes;
}