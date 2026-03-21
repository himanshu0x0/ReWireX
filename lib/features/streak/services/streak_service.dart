// lib/features/streak/services/streak_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/streak_model.dart';

export '../models/streak_model.dart';

/// 🔥 Streak Service
///
/// One check-in per calendar day (midnight–midnight).
/// Firestore doc: users/{uid}/stats/streak
/// Key field added: lastCheckInDate (String "yyyy-MM-dd")
class StreakService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth      _auth      = FirebaseAuth.instance;

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

  // ── Has the user already checked in today? ────────────────────
  /// Returns true if lastCheckInDate == today's date string.
  Future<bool> hasCheckedInToday() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final snap = await _firestore
        .collection('users').doc(user.uid)
        .collection('stats').doc('streak')
        .get();

    final data              = snap.data() ?? {};
    final lastCheckIn       = data['lastCheckInDate'] as String? ?? '';
    final todayKey          = _todayKey();
    return lastCheckIn == todayKey;
  }

  // ── Record check-in ──────────────────────────────────────────
  /// Only increments streak if the user has NOT checked in today.
  /// Stores lastCheckInDate = "yyyy-MM-dd" to enforce one-per-day.
  Future<StreakCheckInResult> recordCheckIn() async {
    final user = _auth.currentUser;
    if (user == null) return StreakCheckInResult.notAuthenticated;

    final ref = _firestore
        .collection('users').doc(user.uid)
        .collection('stats').doc('streak');

    StreakCheckInResult result = StreakCheckInResult.success;

    await _firestore.runTransaction((tx) async {
      final snap    = await tx.get(ref);
      final data    = snap.data() ?? {};

      final lastCheckIn = data['lastCheckInDate'] as String? ?? '';
      final today       = _todayKey();

      // ── Guard: already checked in today ──────────────────────
      if (lastCheckIn == today) {
        result = StreakCheckInResult.alreadyCheckedIn;
        return; // abort transaction — no write
      }

      final current   = (data['currentStreak'] as num?)?.toInt() ?? 0;
      final longest   = (data['longestStreak']  as num?)?.toInt() ?? 0;
      final newStreak = current + 1;

      tx.set(ref, {
        'currentStreak':   newStreak,
        'longestStreak':   newStreak > longest ? newStreak : longest,
        'totalRelapses':   data['totalRelapses'] ?? 0,
        'lastRelapseDate': data['lastRelapseDate'],
        // startDate = midnight of today for first check-in, preserved after that
        'startDate':       data['startDate'] ?? Timestamp.fromDate(
            DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)),
        'lastCheckInDate': today,           // ← persisted for next-day guard
        'updatedAt':       Timestamp.now(),
      }, SetOptions(merge: true));
    });

    return result;
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
        'currentStreak':   0,
        'longestStreak':   current > longest ? current : longest,
        'totalRelapses':   relapses + 1,
        'lastRelapseDate': Timestamp.now(),
        'lastCheckInDate': '',              // ← reset so today doesn't block new streak
        'startDate':       Timestamp.fromDate(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)),
        'updatedAt':       Timestamp.now(),
      }, SetOptions(merge: true));
    });
  }

  // ── Update daily streak (called on app launch) ───────────────
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
        'currentStreak':   0,
        'longestStreak':   0,
        'totalRelapses':   0,
        'lastRelapseDate': null,
        'lastCheckInDate': '',
        'startDate':       Timestamp.fromDate(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)),
        'updatedAt':       Timestamp.now(),
      });
    }
  }

  // ── Helper: today's date key ──────────────────────────────────
  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

/// Result of recordCheckIn()
enum StreakCheckInResult {
  success,
  alreadyCheckedIn,
  notAuthenticated,
}