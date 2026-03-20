import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/risk_model.dart';
import 'package:rewirex/features/intervention/screens/intevention_screen.dart';

class PreRiskService {
  /// Checks if alert should trigger
  Future<bool> shouldTriggerAlert(RiskModel risk) async {
    if (risk.level == "Low" || risk.level == "Medium") {
      return false;
    }

    final now = DateTime.now();
    final peakHour = risk.peakHour;

    // 60 mins before peak hour
    final difference = peakHour - now.hour;

    if (difference != 1 && difference != 0) {
      return false;
    }

    // Prevent multiple alerts per day
    final prefs = await SharedPreferences.getInstance();
    final lastShownDate = prefs.getString("last_pre_risk_alert");

    final todayKey = "${now.year}-${now.month}-${now.day}";

    if (lastShownDate == todayKey) {
      return false;
    }

    await prefs.setString("last_pre_risk_alert", todayKey);

    return true;
  }

  /// Show alert dialog
  void showPreRiskDialog(BuildContext context, RiskModel risk) {
    showDialog(
      context: context,
      barrierDismissible: false, // forces conscious decision
      builder: (dialogContext) => AlertDialog(
        title: const Text("⚠ High Risk Period Approaching"),
        content: Text(
          "Your predicted high-risk window (${risk.timeWindow}) "
          "is approaching.\n\nTake a moment to reset. You are stronger than your urges.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text("Dismiss"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);

              // Delay to avoid navigation conflict
              Future.delayed(const Duration(milliseconds: 200), () {
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InterventionScreen(
                        emotion: "Preventive",
                        intensity: 5,
                      ),
                    ),
                  );
                }
              });
            },
            child: const Text("Start Reset"),
          ),
        ],
      ),
    );
  }
}
