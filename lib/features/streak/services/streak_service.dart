// lib/features/streak/services/streak_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/streak_model.dart';

export '../models/streak_model.dart';

/// 🔥 Streak Service
///
/// Manages the Firestore streak document at users/{uid}/stats/streak.
/// Uses transactions for atomic read-modify-write on check-in and relapse.
class StreakService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth           = FirebaseAuth.instance;

  // ── Real-time stream ─────────────────────────────────────────
  Stream<StreakModel?> getStreak() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection('users').doc(user.uid)
        .collection('stats').doc('streak')
        .snapshots()
        .map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return StreakModel.fromMap(snap.data()!);
    });
  }

  // ── Record check-in ──────────────────────────────────────────
  Future<void> recordCheckIn() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final ref = _firestore
        .collection('users').doc(user.uid)
        .collection('stats').doc('streak');

    await _firestore.runTransaction((tx) async {
      final snap    = await tx.get(ref);
      final data    = snap.data() ?? {};
      final current = (data['currentStreak'] as num?)?.toInt() ?? 0;
      final longest = (data['longestStreak']  as num?)?.toInt() ?? 0;
      final newStreak = current + 1;

      tx.set(ref, {
        'currentStreak':  newStreak,
        'longestStreak':  newStreak > longest ? newStreak : longest,
        'totalRelapses':  data['totalRelapses'] ?? 0,
        'lastRelapseDate':data['lastRelapseDate'],
        'startDate':      data['startDate'] ?? Timestamp.now(),
        'updatedAt':      Timestamp.now(),
      }, SetOptions(merge: true));
    });
  }

  // ── Record relapse ────────────────────────────────────────────
  Future<void> recordRelapse() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final ref = _firestore
        .collection('users').doc(user.uid)
        .collection('stats').doc('streak');

    await _firestore.runTransaction((tx) async {
      final snap     = await tx.get(ref);
      final data     = snap.data() ?? {};
      final current  = (data['currentStreak'] as num?)?.toInt() ?? 0;
      final longest  = (data['longestStreak']  as num?)?.toInt() ?? 0;
      final relapses = (data['totalRelapses']  as num?)?.toInt() ?? 0;

      tx.set(ref, {
        'currentStreak':  0,
        'longestStreak':  current > longest ? current : longest,
        'totalRelapses':  relapses + 1,
        'lastRelapseDate':Timestamp.now(),
        'startDate':      Timestamp.now(),
        'updatedAt':      Timestamp.now(),
      }, SetOptions(merge: true));
    });
  }

  // ── Update daily streak (called on app launch) ───────────────
  /// Checks if the user has already logged today. If not, and the streak
  /// was active yesterday, keeps it alive. If more than 1 day has passed
  /// without a log, the streak does NOT auto-break — the user must
  /// explicitly check in. This just ensures the Firestore doc exists.
  Future<void> updateDailyStreak() async {
    await autoInitialize();
  }

  // ── Auto-initialise if missing ────────────────────────────────
  Future<void> autoInitialize() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final ref = _firestore
        .collection('users').doc(user.uid)
        .collection('stats').doc('streak');

    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'currentStreak': 0,
        'longestStreak': 0,
        'totalRelapses': 0,
        'lastRelapseDate': null,
        'startDate': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    }
  }
}