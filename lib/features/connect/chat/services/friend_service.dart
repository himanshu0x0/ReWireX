// ============================================================
// PATH: lib/features/connect/chat/services/friend_service.dart
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/friend_model.dart';
import '../models/friend_request_model.dart';

class FriendService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String get _uid => _auth.currentUser!.uid;

  // ══════════════════════════════════════════════════════════════
  // SEARCH
  // Primary: prefix-match usernameLower (handles @-prefix).
  // Fallback: prefix-match displayNameLower if nothing found.
  // ══════════════════════════════════════════════════════════════
  Future<List<Map<String, dynamic>>> searchByUsername(String query) async {
    if (query.trim().isEmpty) return [];
    final raw = query.trim().replaceFirst(RegExp(r'^@'), '').toLowerCase();
    if (raw.isEmpty) return [];

    try {
      final snap = await _db
          .collection('users')
          .where('usernameLower', isGreaterThanOrEqualTo: raw)
          .where('usernameLower', isLessThan: '$raw\uf8ff')
          .limit(25)
          .get();

      final results = snap.docs
          .where((d) => d.id != _uid)
          .map((d) => <String, dynamic>{'uid': d.id, ...d.data()})
          .toList();

      if (results.isNotEmpty) return results;

      // Fallback to displayNameLower
      final snap2 = await _db
          .collection('users')
          .where('displayNameLower', isGreaterThanOrEqualTo: raw)
          .where('displayNameLower', isLessThan: '$raw\uf8ff')
          .limit(25)
          .get();

      return snap2.docs
          .where((d) => d.id != _uid)
          .map((d) => <String, dynamic>{'uid': d.id, ...d.data()})
          .toList();
    } catch (e) {
      throw Exception('Search failed: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  // BATCH RELATIONSHIP CHECK
  // Returns uid → 'friend' | 'pending' | 'none'
  // Uses whereIn in chunks of 10 (Firestore limit).
  // ══════════════════════════════════════════════════════════════
  Future<Map<String, String>> batchRelationshipCheck(List<String> uids) async {
    final result = <String, String>{for (final u in uids) u: 'none'};
    if (uids.isEmpty) return result;

    // Check friends
    for (var i = 0; i < uids.length; i += 10) {
      final chunk = uids.sublist(
        i,
        (i + 10) > uids.length ? uids.length : i + 10,
      );
      final snap = await _db
          .collection('users')
          .doc(_uid)
          .collection('friends')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        result[doc.id] = 'friend';
      }
    }

    // Check outgoing pending requests
    final pendingSnap = await _db
        .collection('users')
        .doc(_uid)
        .collection('sent_requests')
        .where('status', isEqualTo: 'pending')
        .get();
    for (final doc in pendingSnap.docs) {
      final toUid = doc.data()['toUid'] as String?;
      if (toUid != null && result[toUid] == 'none') {
        result[toUid] = 'pending';
      }
    }

    return result;
  }

  // ══════════════════════════════════════════════════════════════
  // SEND FRIEND REQUEST
  // Writes to:
  //   users/{toUid}/friend_requests/{autoId}   ← recipient sees it
  //   users/{myUid}/sent_requests/{autoId}     ← sender tracks it
  //
  // Now also stores toUsername / toDisplayName / toPhotoUrl so
  // the "Sent" tab can display the recipient's info correctly.
  // ══════════════════════════════════════════════════════════════
  Future<void> sendRequest(String toUid) async {
    if (toUid == _uid) return;
    if (await isFriend(toUid)) return;
    if (await hasPendingRequest(toUid)) return;

    // Fetch MY profile
    final mySnap = await _db.collection('users').doc(_uid).get();
    final my = mySnap.data() ?? {};
    final streak = await _streak(_uid);

    // Fetch RECIPIENT profile so we can store display info in sent_requests
    final toSnap = await _db.collection('users').doc(toUid).get();
    final toData = toSnap.data() ?? {};

    final reqRef = _db
        .collection('users')
        .doc(toUid)
        .collection('friend_requests')
        .doc(); // auto-id
    final sentRef = _db
        .collection('users')
        .doc(_uid)
        .collection('sent_requests')
        .doc(reqRef.id); // same id for easy cross-reference

    final sharedData = {
      'fromUid': _uid,
      'fromUsername': my['username'] ?? '',
      'fromDisplayName': my['displayName'] ?? '',
      'fromPhotoUrl': my['photoUrl'] ?? '',
      'fromStreak': streak,
      'toUid': toUid,
      'toUsername': toData['username'] ?? '',
      'toDisplayName': toData['displayName'] ?? '',
      'toPhotoUrl': toData['photoUrl'] ?? '',
      'sentAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    };

    final batch = _db.batch();
    batch.set(reqRef, sharedData);
    batch.set(sentRef, {...sharedData, 'requestId': reqRef.id});
    await batch.commit();
  }

  // ══════════════════════════════════════════════════════════════
  // ACCEPT FRIEND REQUEST
  // ══════════════════════════════════════════════════════════════
  Future<void> acceptRequest(FriendRequestModel req) async {
    final batch = _db.batch();
    final mySnap = await _db.collection('users').doc(_uid).get();
    final my = mySnap.data() ?? {};
    final myStr = await _streak(_uid);
    final now = FieldValue.serverTimestamp();

    // Add each other to friends subcollections
    batch.set(
      _db.collection('users').doc(_uid).collection('friends').doc(req.fromUid),
      {
        'uid': req.fromUid,
        'username': req.fromUsername,
        'displayName': req.fromDisplayName,
        'photoUrl': req.fromPhotoUrl,
        'addedAt': now,
        'currentStreak': req.fromStreak,
        'isOnline': false,
      },
    );
    batch.set(
      _db.collection('users').doc(req.fromUid).collection('friends').doc(_uid),
      {
        'uid': _uid,
        'username': my['username'] ?? '',
        'displayName': my['displayName'] ?? '',
        'photoUrl': my['photoUrl'] ?? '',
        'addedAt': now,
        'currentStreak': myStr,
        'isOnline': true,
      },
    );

    // Mark the incoming request as accepted
    batch.update(
      _db
          .collection('users')
          .doc(_uid)
          .collection('friend_requests')
          .doc(req.id),
      {'status': 'accepted'},
    );

    // Mirror acceptance in sender's sent_requests
    batch.update(
      _db
          .collection('users')
          .doc(req.fromUid)
          .collection('sent_requests')
          .doc(req.id),
      {'status': 'accepted'},
    );

    await batch.commit();

    // Fire-and-forget system message in DM thread
    _sendFriendAcceptedMessage(req, my);
  }

  // ══════════════════════════════════════════════════════════════
  // DECLINE FRIEND REQUEST
  // Updates both sides (incoming + sent) to 'declined'.
  // ══════════════════════════════════════════════════════════════
  Future<void> declineRequest(String requestId, String fromUid) async {
    final batch = _db.batch();
    batch.update(
      _db
          .collection('users')
          .doc(_uid)
          .collection('friend_requests')
          .doc(requestId),
      {'status': 'declined'},
    );
    batch.update(
      _db
          .collection('users')
          .doc(fromUid)
          .collection('sent_requests')
          .doc(requestId),
      {'status': 'declined'},
    );
    await batch.commit();
  }

  // ══════════════════════════════════════════════════════════════
  // CANCEL OUTGOING REQUEST
  // Hard-deletes from both sides.
  // ══════════════════════════════════════════════════════════════
  Future<void> cancelRequest(String toUid, String requestId) async {
    final batch = _db.batch();
    batch.delete(
      _db
          .collection('users')
          .doc(toUid)
          .collection('friend_requests')
          .doc(requestId),
    );
    batch.delete(
      _db
          .collection('users')
          .doc(_uid)
          .collection('sent_requests')
          .doc(requestId),
    );
    await batch.commit();
  }

  // ══════════════════════════════════════════════════════════════
  // REMOVE FRIEND (mutual)
  // ══════════════════════════════════════════════════════════════
  Future<void> removeFriend(String friendUid) async {
    final b = _db.batch();
    b.delete(
      _db.collection('users').doc(_uid).collection('friends').doc(friendUid),
    );
    b.delete(
      _db.collection('users').doc(friendUid).collection('friends').doc(_uid),
    );
    await b.commit();
  }

  // ══════════════════════════════════════════════════════════════
  // STREAMS
  // ══════════════════════════════════════════════════════════════
  Stream<List<FriendModel>> friendsStream() => _db
      .collection('users')
      .doc(_uid)
      .collection('friends')
      .orderBy('addedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => FriendModel.fromMap(d.data())).toList());

  /// Incoming pending requests (for the "Received" tab + badge).
  Stream<List<FriendRequestModel>> incomingRequestsStream() => _db
      .collection('users')
      .doc(_uid)
      .collection('friend_requests')
      .where('status', isEqualTo: 'pending')
      .orderBy('sentAt', descending: true)
      .snapshots()
      .map(
        (s) => s.docs
            .map((d) => FriendRequestModel.fromMap(d.id, d.data()))
            .toList(),
      );

  /// Outgoing pending requests (for the "Sent" tab).
  Stream<List<FriendRequestModel>> sentRequestsStream() => _db
      .collection('users')
      .doc(_uid)
      .collection('sent_requests')
      .where('status', isEqualTo: 'pending')
      .orderBy('sentAt', descending: true)
      .snapshots()
      .map(
        (s) => s.docs
            .map((d) => FriendRequestModel.fromMap(d.id, d.data()))
            .toList(),
      );

  /// Real-time online status for a single friend.
  Stream<bool> friendOnlineStream(String friendUid) => _db
      .collection('users')
      .doc(friendUid)
      .snapshots()
      .map((s) => (s.data()?['isOnline'] as bool?) ?? false);

  // ══════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════
  Future<bool> isFriend(String uid) async =>
      (await _db
              .collection('users')
              .doc(_uid)
              .collection('friends')
              .doc(uid)
              .get())
          .exists;

  /// True if there is already a pending outgoing request to [toUid].
  Future<bool> hasPendingRequest(String toUid) async {
    final snap = await _db
        .collection('users')
        .doc(_uid)
        .collection('sent_requests')
        .where('toUid', isEqualTo: toUid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Returns the Firestore doc ID of the pending outgoing request, or null.
  Future<String?> pendingRequestId(String toUid) async {
    final snap = await _db
        .collection('users')
        .doc(_uid)
        .collection('sent_requests')
        .where('toUid', isEqualTo: toUid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    return snap.docs.isEmpty ? null : snap.docs.first.id;
  }

  Future<void> setOnline(bool online) async {
    try {
      await _db.collection('users').doc(_uid).update({
        'isOnline': online,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<int> _streak(String uid) async {
    try {
      final s = await _db
          .collection('users')
          .doc(uid)
          .collection('stats')
          .doc('streak')
          .get();
      return (s.data()?['currentStreak'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Writes a system message to the shared DM thread when a
  /// friend request is accepted. Fire-and-forget (non-blocking).
  void _sendFriendAcceptedMessage(
    FriendRequestModel req,
    Map<String, dynamic> myData,
  ) async {
    try {
      final ids = [_uid, req.fromUid]..sort();
      final tid = '${ids[0]}_${ids[1]}';

      // Ensure thread document exists with participants
      await _db.collection('dm_threads').doc(tid).set({
        'participants': ids,
        'threadId': tid,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _db.collection('dm_threads').doc(tid).collection('messages').add({
        'senderId': 'system',
        'senderName': 'System',
        'text': '🎉 You are now friends! Say hello 👋',
        'timestamp': FieldValue.serverTimestamp(),
        'isDeleted': false,
        'isSystem': true,
        'isEdited': false,
        'status': 'read',
        'reactions': <String, dynamic>{},
      });
    } catch (_) {}
  }
}
