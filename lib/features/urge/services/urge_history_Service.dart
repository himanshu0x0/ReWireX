// lib/features/urge/services/urge_history_service.dart
//
// NOTE: Most history + stats logic now lives in UrgeService directly,
// which gives a single source of truth for Firestore reads.
// This class is kept for any legacy callers and for convenience
// methods that don't belong in the core UrgeService.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/urge_model.dart';

class UrgeHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Returns all urge logs for the current user, newest first.
  /// Returns typed [UrgeModel] list (not raw maps).
  Future<List<UrgeModel>> getUrgeHistory() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('urge_logs') // ✅ corrected collection name
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => UrgeModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Returns urge logs within the past [days] days.
  Future<List<UrgeModel>> getUrgeHistoryForDays({int days = 7}) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final cutoff = DateTime.now().subtract(Duration(days: days));

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('urge_logs')
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => UrgeModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Returns total urge count for today.
  Future<int> getTodayUrgeCount() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('urge_logs')
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .get();

    return snapshot.docs.length;
  }
}