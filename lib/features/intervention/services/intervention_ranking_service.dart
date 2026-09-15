import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Personalizes predefined interventions using the user's historical feedback.
///
/// This service never creates intervention content. It only ranks interventions
/// that already exist in the app catalog.
class InterventionRankingService {
  InterventionRankingService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // Intelligence parameters.
  static const double minConfidence = 0.55;
  static const double explorationChance = 0.05;
  static const double minWeightedSamples = 3.0;
  static const double decayRate = 0.05;

  static const double emotionWeight = 0.20;
  static const double urgeWeight = 0.30;
  static const double needWeight = 0.20;
  static const double intensityWeight = 0.10;
  static const double outcomeWeight = 0.20;

  String _getCurrentTimeBlock() {
    return _getBlockFromHour(DateTime.now().hour);
  }

  String _getBlockFromHour(int hour) {
    if (hour >= 5 && hour <= 11) return 'Morning';
    if (hour >= 12 && hour <= 16) return 'Afternoon';
    if (hour >= 17 && hour <= 20) return 'Evening';
    return 'Night';
  }

  double _getRiskMultiplier(String? riskLevel) {
    switch (riskLevel) {
      case 'Critical':
        return 1.5;
      case 'High':
        return 1.2;
      case 'Medium':
        return 1.0;
      case 'Low':
        return 0.8;
      default:
        return 1.0;
    }
  }

  int _readInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse('$value') ?? fallback;
  }

  // ignore: unused_element
  double _readDouble(dynamic value, {double fallback = 0.0}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? fallback;
  }

  Timestamp? _readTimestamp(dynamic value) {
    if (value is Timestamp) return value;
    if (value is DateTime) return Timestamp.fromDate(value);
    return null;
  }

  double _clamp01(double value) => value.clamp(0.0, 1.0).toDouble();

  double _intensitySimilarity(int? requested, int? historical) {
    if (requested == null || historical == null) return 0.5;

    final distance = (requested - historical).abs();
    return _clamp01(1.0 - (distance / 10.0));
  }

  double _outcomeScore(Map<String, dynamic> data) {
    final before = _readInt(data['urgeBefore'], fallback: -1);
    final after = _readInt(data['urgeAfter'], fallback: -1);

    if (before > 0 && after >= 0) {
      return _clamp01((before - after) / before);
    }

    if (data['wasEffective'] == true) return 1.0;
    return 0.0;
  }

  double _contextMatchScore({
    required Map<String, dynamic> data,
    String? emotion,
    String? urgeType,
    String? need,
    int? intensity,
    String? timeBlock,
  }) {
    var score = 0.0;
    var totalWeight = 0.0;

    final historicalEmotion = data['emotion'] as String?;
    if (emotion != null && historicalEmotion != null) {
      totalWeight += emotionWeight;
      if (historicalEmotion.toLowerCase().trim() ==
          emotion.toLowerCase().trim()) {
        score += emotionWeight;
      }
    }

    final historicalUrge = data['urgeType'] as String?;
    if (urgeType != null && historicalUrge != null) {
      totalWeight += urgeWeight;
      if (historicalUrge == urgeType) score += urgeWeight;
    }

    final historicalNeed = data['selectedNeed'] as String?;
    if (need != null && historicalNeed != null) {
      totalWeight += needWeight;
      if (historicalNeed == need) score += needWeight;
    }

    final historicalIntensity = data['urgeBefore'] ?? data['intensity'];
    if (intensity != null && historicalIntensity != null) {
      totalWeight += intensityWeight;
      score += intensityWeight *
          _intensitySimilarity(
            intensity,
            _readInt(historicalIntensity),
          );
    }

    final timestamp = _readTimestamp(data['timestamp']);
    if (timeBlock != null && timestamp != null) {
      totalWeight += 0.10;
      if (_getBlockFromHour(timestamp.toDate().hour) == timeBlock) {
        score += 0.10;
      }
    }

    if (totalWeight == 0) return 0.5;
    return _clamp01(score / totalWeight);
  }

  double _recordWeight({
    required Map<String, dynamic> data,
    required DateTime now,
  }) {
    final timestamp = _readTimestamp(data['timestamp']);
    if (timestamp == null) return 0.0;

    final ageDays = math.max(
      0,
      now.difference(timestamp.toDate()).inHours,
    ) / 24.0;

    final recency = math.exp(-decayRate * ageDays);
    final intensity = _readInt(
      data['urgeBefore'] ?? data['intensity'],
      fallback: 5,
    ).clamp(1, 10).toDouble();
    final risk = _getRiskMultiplier(data['riskLevel'] as String?);

    return intensity * recency * risk;
  }

  /// Preserves the original emotion-only API.
  Future<String?> getBestTechniqueForEmotion(String emotion) async {
    return getBestInterventionForContext(emotion: emotion);
  }

  /// Returns the best historical intervention/technique for the current
  /// situation. The result is only returned when historical confidence is
  /// strong enough; callers can safely fall back to the predefined catalog.
  Future<String?> getBestInterventionForContext({
    String? emotion,
    String? urgeType,
    String? need,
    int? intensity,
    String? rescuePath,
    String? timeBlock,
    bool requireUrgeContext = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('intervention_feedback')
        .get();

    if (snapshot.docs.isEmpty) return null;

    final currentTimeBlock = timeBlock ?? _getCurrentTimeBlock();
    final now = DateTime.now();

    final weightedOutcome = <String, double>{};
    final weightedTotal = <String, double>{};
    final effectiveSamples = <String, double>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final interventionId =
          (data['interventionId'] ?? data['technique']) as String?;
      if (interventionId == null || interventionId.isEmpty) continue;

      if (requireUrgeContext &&
          data['urgeType'] == null &&
          data['interventionId'] == null) {
        continue;
      }

      if (rescuePath != null &&
          data['rescuePath'] != null &&
          data['rescuePath'] != rescuePath) {
        continue;
      }

      final weight = _recordWeight(data: data, now: now);
      if (weight <= 0) continue;

      final contextScore = _contextMatchScore(
        data: data,
        emotion: emotion,
        urgeType: urgeType,
        need: need,
        intensity: intensity,
        timeBlock: currentTimeBlock,
      );

      final outcome = _outcomeScore(data);

      // Favor interventions that both fit the current context and actually
      // reduced the user's urge in previous sessions.
      final adjustedWeight = weight * (0.55 + 0.45 * contextScore);
      weightedTotal[interventionId] =
          (weightedTotal[interventionId] ?? 0.0) + adjustedWeight;
      weightedOutcome[interventionId] =
          (weightedOutcome[interventionId] ?? 0.0) +
              (adjustedWeight * outcome);
      effectiveSamples[interventionId] =
          (effectiveSamples[interventionId] ?? 0.0) + 1.0;
    }

    if (weightedTotal.isEmpty) return null;

    final scores = <String, double>{};
    for (final entry in weightedTotal.entries) {
      if (entry.value < minWeightedSamples) continue;

      final averageOutcome =
          (weightedOutcome[entry.key] ?? 0.0) / entry.value;
      final sampleFactor = _clamp01(
        (effectiveSamples[entry.key] ?? 0.0) / 10.0,
      );

      // Confidence grows with both outcome quality and historical sample size.
      scores[entry.key] =
          (averageOutcome * 0.8) + (sampleFactor * 0.2);
    }

    if (scores.isEmpty) return null;

    final ranked = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final best = ranked.first;
    if (best.value < minConfidence) return null;

    // Small exploration rate prevents permanent overfitting to one technique.
    if (ranked.length > 1 && math.Random().nextDouble() < explorationChance) {
      final candidate = ranked[1];
      if (candidate.value >= minConfidence * 0.9) {
        return candidate.key;
      }
    }

    return best.key;
  }

  /// Returns a ranked list instead of only the winner.
  Future<List<InterventionRankingResult>> rankInterventions({
    String? emotion,
    String? urgeType,
    String? need,
    int? intensity,
    String? rescuePath,
    int limit = 5,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return const [];

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('intervention_feedback')
        .get();

    if (snapshot.docs.isEmpty) return const [];

    final now = DateTime.now();
    final currentTimeBlock = _getCurrentTimeBlock();
    final totals = <String, double>{};
    final outcomes = <String, double>{};
    final samples = <String, int>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final interventionId =
          (data['interventionId'] ?? data['technique']) as String?;
      if (interventionId == null || interventionId.isEmpty) continue;

      if (rescuePath != null &&
          data['rescuePath'] != null &&
          data['rescuePath'] != rescuePath) {
        continue;
      }

      final baseWeight = _recordWeight(data: data, now: now);
      if (baseWeight <= 0) continue;

      final context = _contextMatchScore(
        data: data,
        emotion: emotion,
        urgeType: urgeType,
        need: need,
        intensity: intensity,
        timeBlock: currentTimeBlock,
      );

      final weight = baseWeight * (0.55 + 0.45 * context);
      totals[interventionId] = (totals[interventionId] ?? 0) + weight;
      outcomes[interventionId] =
          (outcomes[interventionId] ?? 0) + (weight * _outcomeScore(data));
      samples[interventionId] = (samples[interventionId] ?? 0) + 1;
    }

    final results = <InterventionRankingResult>[];
    for (final entry in totals.entries) {
      if (entry.value < minWeightedSamples) continue;

      final outcome = (outcomes[entry.key] ?? 0) / entry.value;
      final sampleFactor = _clamp01((samples[entry.key] ?? 0) / 10.0);
      final confidence = _clamp01((outcome * 0.8) + (sampleFactor * 0.2));

      results.add(
        InterventionRankingResult(
          interventionId: entry.key,
          confidence: confidence,
          weightedSamples: entry.value,
          sampleCount: samples[entry.key] ?? 0,
        ),
      );
    }

    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    return results.take(limit.clamp(1, 20)).toList(growable: false);
  }
}

class InterventionRankingResult {
  const InterventionRankingResult({
    required this.interventionId,
    required this.confidence,
    required this.weightedSamples,
    required this.sampleCount,
  });

  final String interventionId;
  final double confidence;
  final double weightedSamples;
  final int sampleCount;
}
