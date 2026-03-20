import 'package:flutter/material.dart';
import '../../risk/services/risk_prediction_service.dart';
import '../../prediction/services/relapse_prediction_service.dart';
import 'ai_memory_service.dart';

/// 🛡 AI Guardian Service
/// Monitors risk signals and triggers a guardian alert dialog
/// when critical thresholds are met.
class AIGuardianService {
  final RiskPredictionService _riskService = RiskPredictionService();
  final RelapsePredictionService _relapseService = RelapsePredictionService();
  final AIMemoryService _memoryService = AIMemoryService();

  Future<void> checkAndTriggerGuardian(BuildContext context) async {
    final risk = await _riskService.analyzeRisk();
    final relapse = await _relapseService.analyzeRelapseRisk();
    final memory = await _memoryService.getMemory();

    final int highRiskDays = memory?.consecutiveHighRiskDays ?? 0;

    bool shouldTrigger = false;
    String message = '';

    if (relapse.probability >= 80) {
      shouldTrigger = true;
      message =
          'Critical relapse probability detected. Your patterns show elevated risk right now.';
    } else if (highRiskDays >= 3) {
      shouldTrigger = true;
      message =
          'Risk has remained high for $highRiskDays consecutive days. Consider reaching out for support.';
    } else if (risk?.level == 'Critical') {
      shouldTrigger = true;
      message =
          'A high-risk time window has been detected based on your behavioral patterns.';
    }

    if (shouldTrigger && context.mounted) {
      _showGuardianDialog(context, message);
    }
  }

  void _showGuardianDialog(BuildContext context, String reason) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_outlined,
                  color: Color(0xFF6C63FF), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Guardian Mode',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reason,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tips_and_updates_outlined,
                      color: Color(0xFF00C4A0), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Remember: you\'ve overcome this before. You can do it again.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "I'm Safe",
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5), fontSize: 13),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Stay Strong',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}