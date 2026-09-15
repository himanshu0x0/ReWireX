// lib/features/streak/services/streak_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/streak_model.dart';

export '../models/streak_model.dart';

/// Calendar-day streak service.
///
/// Rules:
/// 1. A user can successfully check in only once per local calendar day.
/// 2. A check-in on the day immediately after the previous check-in extends
///    the streak by one.
/// 3. If a whole calendar day was missed, the next successful check-in starts
///    a new 1-day streak.
/// 4. Opening/reopening the app never increments the streak.
/// 5. `startDate` is the midnight of the first day of the current streak.
/// 6. The timer UI uses the current streak count for DAYS and only measures
///    today's elapsed clock time for HOURS/MINS/SECS.
///
/// Firestore document:
/// users/{uid}/stats/streak
class StreakService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DocumentReference<Map<String, dynamic>> _ref(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('stats')
      .doc('streak');

  String? get currentUid => _auth.currentUser?.uid;

  Stream<StreakModel?> getStreak() {
    final uid = currentUid;
    if (uid == null) return Stream.value(null);

    return _ref(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return StreakModel.fromMap(snap.data()!);
    });
  }

  /// Call this once after authentication/app startup.
  ///
  /// It creates the record if needed and expires an old streak when the user
  /// has missed at least one complete calendar day.
  Future<void> updateDailyStreak() => repairStreak();

  Future<void> autoInitialize() => repairStreak();

  Future<void> repairStreak() async {
    final uid = currentUid;
    if (uid == null) return;

    final ref = _ref(uid);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();

      final today = _midnight(DateTime.now());
      final todayKey = _key(today);

      if (!snap.exists || data == null) {
        // First-ever app entry starts Day 1. The user still has to perform
        // the daily check-in on following calendar days to keep extending it.
        tx.set(ref, {
          'currentStreak': 1,
          'longestStreak': 1,
          'totalRelapses': 0,
          'lastRelapseDate': null,
          'startDate': Timestamp.fromDate(today),
          'lastCheckInDate': todayKey,
          'lastCheckInAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
        return;
      }

      final current = _int(data['currentStreak']);
      if (current <= 0) return;

      var lastKey = data['lastCheckInDate'] as String? ?? '';

      // Repair legacy records that have a current streak but no date key.
      if (lastKey.isEmpty) {
        final rawStart = _asDate(data['startDate']);
        if (rawStart != null) {
          final inferredLast =
              _midnight(rawStart).add(Duration(days: current - 1));
          lastKey = _key(inferredLast);
        }
      }

      final lastDate = _parseKey(lastKey);
      if (lastDate == null) {
        tx.set(ref, {
          'currentStreak': 0,
          'startDate': Timestamp.fromDate(today),
          'lastCheckInDate': '',
          'updatedAt': Timestamp.now(),
        }, SetOptions(merge: true));
        return;
      }

      final gap = today.difference(lastDate).inDays;

      // Yesterday is still an active streak: the user simply has not
      // completed today's check-in yet. Older than yesterday means the
      // streak window has expired.
      if (gap > 1) {
        tx.set(ref, {
          'currentStreak': 0,
          'startDate': Timestamp.fromDate(today),
          'lastCheckInDate': '',
          'updatedAt': Timestamp.now(),
        }, SetOptions(merge: true));
      } else if (lastKey != (data['lastCheckInDate'] as String? ?? '')) {
        // Persist the repaired legacy date without changing the count.
        tx.set(ref, {
          'lastCheckInDate': lastKey,
          'updatedAt': Timestamp.now(),
        }, SetOptions(merge: true));
      }
    });
  }

  Future<bool> hasCheckedInToday() async {
    final uid = currentUid;
    if (uid == null) return false;

    await repairStreak();

    final snap = await _ref(uid).get();
    final key = snap.data()?['lastCheckInDate'] as String? ?? '';
    return key == _todayKey();
  }

  Future<StreakCheckInResult> recordCheckIn() async {
    final uid = currentUid;
    if (uid == null) return StreakCheckInResult.notAuthenticated;

    final ref = _ref(uid);
    StreakCheckInResult result = StreakCheckInResult.success;

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? <String, dynamic>{};

      final today = _midnight(DateTime.now());
      final todayKey = _key(today);
      final lastKey = data['lastCheckInDate'] as String? ?? '';

      if (lastKey == todayKey) {
        result = StreakCheckInResult.alreadyCheckedIn;
        return;
      }

      final current = _int(data['currentStreak']);
      final longest = _int(data['longestStreak']);
      final lastDate = _parseKey(lastKey);

      final continues = lastDate != null &&
          today.difference(lastDate).inDays == 1 &&
          current > 0;

      final newStreak = continues ? current + 1 : 1;
      final startDate = continues
          ? _midnight(_asDate(data['startDate']) ?? lastDate)
          : today;

      tx.set(ref, {
        'currentStreak': newStreak,
        'longestStreak': newStreak > longest ? newStreak : longest,
        'totalRelapses': _int(data['totalRelapses']),
        'lastRelapseDate': data['lastRelapseDate'],
        'startDate': Timestamp.fromDate(startDate),
        'lastCheckInDate': todayKey,
        'lastCheckInAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));
    });

    return result;
  }

  Future<StreakRelapseResult> recordRelapse() async {
    final uid = currentUid;
    if (uid == null) return StreakRelapseResult.notAuthenticated;

    final ref = _ref(uid);
    StreakRelapseResult result = StreakRelapseResult.recorded;

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? <String, dynamic>{};

      final today = _midnight(DateTime.now());
      _key(today);
      final relapseDate = _asDate(data['lastRelapseDate']);
      final alreadyRelapsed =
          relapseDate != null && _sameDay(relapseDate, today);

      if (alreadyRelapsed) {
        result = StreakRelapseResult.alreadyRecordedToday;
        return;
      }

      final current = _int(data['currentStreak']);
      final longest = _int(data['longestStreak']);
      final relapses = _int(data['totalRelapses']);

      tx.set(ref, {
        'currentStreak': 0,
        'longestStreak': current > longest ? current : longest,
        'totalRelapses': relapses + 1,
        'lastRelapseDate': Timestamp.now(),
        'lastCheckInDate': '',
        'startDate': Timestamp.fromDate(today),
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));
    });

    return result;
  }

  String _todayKey() => _key(_midnight(DateTime.now()));

  static String _key(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static DateTime? _parseKey(String key) {
    final p = key.split('-');
    if (p.length != 3) return null;
    final y = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    final d = int.tryParse(p[2]);
    if (y == null || m == null || d == null) return null;
    try {
      final value = DateTime(y, m, d);
      return value.year == y && value.month == m && value.day == d
          ? value
          : null;
    } catch (_) {
      return null;
    }
  }

  static DateTime? _asDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static int _int(dynamic value) => value is num ? value.toInt() : 0;

  static DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Result of today's check-in.
enum StreakCheckInResult {
  success,
  alreadyCheckedIn,
  notAuthenticated,
}

/// Result of reporting a relapse.
enum StreakRelapseResult {
  recorded,
  alreadyRecordedToday,
  notAuthenticated,
}

