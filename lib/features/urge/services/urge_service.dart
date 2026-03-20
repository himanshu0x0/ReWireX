// lib/features/urge/services/urge_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/urge_model.dart';
import 'package:uuid/uuid.dart';

/// 📊 Aggregated stats returned by getUrgeStats()
class UrgeStats {
  final int totalUrges;
  final double avgIntensity;
  final int highIntensityCount; // intensity >= 7
  final String dominantEmotion;
  final String dominantType;
  final int peakHour; // 0–23
  final Map<String, int> emotionCounts;
  final Map<String, int> typeCounts;

  const UrgeStats({
    required this.totalUrges,
    required this.avgIntensity,
    required this.highIntensityCount,
    required this.dominantEmotion,
    required this.dominantType,
    required this.peakHour,
    required this.emotionCounts,
    required this.typeCounts,
  });
}

class UrgeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  // ── Save urge ────────────────────────────────────────────────
  Future<void> saveUrge({
    required String type,
    required int intensity,
    required String emotion,
    String trigger = '',
    String notes = '',
    String context = '',
    String bodyLocation = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final urgeId = _uuid.v4();
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';
    final hourKey = now.hour.toString();
    final timeOfDayLabel = _timeOfDayLabel(now.hour);

    final urge = UrgeModel(
      id: urgeId,
      type: type,
      intensity: intensity,
      emotion: emotion,
      trigger: trigger,
      notes: notes,
      context: context,
      bodyLocation: bodyLocation,
      timeOfDayLabel: timeOfDayLabel,
      timestamp: now,
      date: todayKey,
      hour: now.hour,
    );

    try {
      final batch = _firestore.batch();

      // 1️⃣ Urge log
      final urgeRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('urge_logs')
          .doc(urgeId);
      batch.set(urgeRef, urge.toMap());

      // 2️⃣ Daily counter
      final dailyRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('analytics')
          .doc(todayKey);
      batch.set(dailyRef, {
        'totalUrges': FieldValue.increment(1),
        'highIntensityUrges': intensity >= 7
            ? FieldValue.increment(1)
            : FieldValue.increment(0),
        'lastUpdated': Timestamp.fromDate(now),
      }, SetOptions(merge: true));

      // 3️⃣ Hourly risk signal
      final hourRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('hourly_risk')
          .doc(hourKey);
      batch.set(hourRef, {
        'count': FieldValue.increment(1),
      }, SetOptions(merge: true));

      // 4️⃣ Latest risk signal
      final riskSignalRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('risk_signals')
          .doc('latest');
      batch.set(riskSignalRef, {
        'lastEmotion': emotion,
        'lastIntensity': intensity,
        'lastHour': now.hour,
        'lastType': type,
        'lastContext': context,
        'updatedAt': Timestamp.fromDate(now),
      }, SetOptions(merge: true));

      await batch.commit().timeout(const Duration(seconds: 10));
    } catch (e) {
      rethrow;
    }
  }

  // ── Real-time stream of all urges ────────────────────────────
  Stream<List<UrgeModel>> getUrges() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('urge_logs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => UrgeModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  // ── Paginated urge history (last N days) ─────────────────────
  Future<List<UrgeModel>> getRecentUrges({int days = 30}) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final cutoff = DateTime.now().subtract(Duration(days: days));
    final snap = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('urge_logs')
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .orderBy('timestamp', descending: true)
        .get();

    return snap.docs
        .map((doc) => UrgeModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  // ── Aggregated stats ─────────────────────────────────────────
  Future<UrgeStats> getUrgeStats({int days = 30}) async {
    final urges = await getRecentUrges(days: days);
    if (urges.isEmpty) {
      return const UrgeStats(
        totalUrges: 0,
        avgIntensity: 0,
        highIntensityCount: 0,
        dominantEmotion: 'None',
        dominantType: 'None',
        peakHour: 0,
        emotionCounts: {},
        typeCounts: {},
      );
    }

    double totalIntensity = 0;
    int highCount = 0;
    final emotionCounts = <String, int>{};
    final typeCounts = <String, int>{};
    final hourCounts = <int, int>{};

    for (final u in urges) {
      totalIntensity += u.intensity;
      if (u.intensity >= 7) highCount++;
      emotionCounts[u.emotion] = (emotionCounts[u.emotion] ?? 0) + 1;
      typeCounts[u.type] = (typeCounts[u.type] ?? 0) + 1;
      hourCounts[u.hour] = (hourCounts[u.hour] ?? 0) + 1;
    }

    final dominantEmotion = emotionCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    final dominantType = typeCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    final peakHour = hourCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return UrgeStats(
      totalUrges: urges.length,
      avgIntensity: totalIntensity / urges.length,
      highIntensityCount: highCount,
      dominantEmotion: dominantEmotion,
      dominantType: dominantType,
      peakHour: peakHour,
      emotionCounts: emotionCounts,
      typeCounts: typeCounts,
    );
  }

  // ── Delete a single urge log ─────────────────────────────────
  Future<void> deleteUrge(String urgeId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('urge_logs')
        .doc(urgeId)
        .delete();
  }

  // ── Helpers ──────────────────────────────────────────────────
  String _timeOfDayLabel(int hour) {
    if (hour >= 5 && hour <= 11) return 'Morning';
    if (hour >= 12 && hour <= 16) return 'Afternoon';
    if (hour >= 17 && hour <= 21) return 'Evening';
    return 'Night';
  }
}