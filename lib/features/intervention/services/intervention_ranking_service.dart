import 'dart:math';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InterventionRankingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔒 Tunable Intelligence Parameters
  static const double minConfidence = 0.6;
  static const double explorationChance = 0.1;
  static const double minWeightedSamples = 10.0;
  static const double decayRate = 0.05;

  String _getCurrentTimeBlock() {
    final hour = DateTime.now().hour;
    return _getBlockFromHour(hour);
  }

  String _getBlockFromHour(int hour) {
    if (hour >= 5 && hour <= 11) return "Morning";
    if (hour >= 12 && hour <= 16) return "Afternoon";
    if (hour >= 17 && hour <= 20) return "Evening";
    return "Night";
  }

  double _getRiskMultiplier(String riskLevel) {
    switch (riskLevel) {
      case "Critical":
        return 1.5;
      case "High":
        return 1.2;
      case "Medium":
        return 1.0;
      case "Low":
        return 0.8;
      default:
        return 1.0;
    }
  }

  Future<String?> getBestTechniqueForEmotion(String emotion) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final currentTimeBlock = _getCurrentTimeBlock();

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('intervention_feedback')
        .where('emotion', isEqualTo: emotion)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final Map<String, double> weightedSuccess = {};
    final Map<String, double> weightedTotal = {};

    final now = DateTime.now();

    for (var doc in snapshot.docs) {
      final data = doc.data();

      final String? technique = data['technique'] as String?;
      final bool wasEffective = data['wasEffective'] == true;
      final int intensityValue = (data['intensity'] ?? 5) as int;
      final Timestamp? ts = data['timestamp'] as Timestamp?;
      final String riskLevel = data['riskLevel'] ?? "Low";

      if (technique == null || ts == null) continue;

      final DateTime timestamp = ts.toDate();

      // 🕒 Time block filtering
      final feedbackBlock = _getBlockFromHour(timestamp.hour);
      if (feedbackBlock != currentTimeBlock) continue;

      // ⏳ Recency decay
      final daysOld = now.difference(timestamp).inDays;
      final decayMultiplier = math.exp(-decayRate * daysOld);

      // ⚡ Risk multiplier
      final riskMultiplier = _getRiskMultiplier(riskLevel);

      // 🎯 Final adjusted weight
      final adjustedWeight =
          intensityValue * decayMultiplier * riskMultiplier;

      weightedTotal[technique] =
          (weightedTotal[technique] ?? 0) + adjustedWeight;

      if (wasEffective) {
        weightedSuccess[technique] =
            (weightedSuccess[technique] ?? 0) + adjustedWeight;
      }
    }

    if (weightedTotal.isEmpty) return null;

    final Map<String, double> scores = {};

    weightedTotal.forEach((technique, totalWeight) {
      if (totalWeight >= minWeightedSamples) {
        final successWeight = weightedSuccess[technique] ?? 0;
        scores[technique] = successWeight / totalWeight;
      }
    });

    if (scores.isEmpty) return null;

    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final best = sorted.first;

    // 🎯 Confidence threshold
    if (best.value < minConfidence) return null;

    // 🎲 Exploration system
    if (Random().nextDouble() < explorationChance) {
      return null;
    }

    return best.key;
  }
}