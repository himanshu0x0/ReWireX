// ============================================================
// PATH: lib/features/connect/chat/services/dm_service.dart
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/dm_message_model.dart';

class DmService {
  final FirebaseFirestore _db   = FirebaseFirestore.instance;
  final FirebaseAuth      _auth = FirebaseAuth.instance;
  String get _uid => _auth.currentUser!.uid;

  // ── Thread ID (deterministic, sorted) ────────────────────────
  String threadId(String otherUid) {
    final ids = [_uid, otherUid]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  // ══════════════════════════════════════════════════════════════
  // SEND MESSAGE
  // Also ensures the root dm_threads/{tid} document exists with
  // a `participants` array so Firestore rules can validate access.
  // ══════════════════════════════════════════════════════════════
  Future<void> sendMessage({
    required String otherUid,
    required String otherUsername,
    required String otherDisplayName,
    required String otherPhotoUrl,
    required String text,
    String? replyToId,
    String? replyPreview,
    String? replyToName,
  }) async {
    if (text.trim().isEmpty) return;

    final my   = (await _db.collection('users').doc(_uid).get()).data() ?? {};
    final name = my['displayName'] as String? ?? 'User';
    final tid  = threadId(otherUid);
    final ids  = [_uid, otherUid]..sort();

    // ── 1. Ensure root thread document exists with participants ──
    // SetOptions(merge:true) is idempotent — safe to call every send.
    await _db.collection('dm_threads').doc(tid).set({
      'participants':   ids,
      'threadId':       tid,
      'createdAt':      FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // ── 2. Write the message ──────────────────────────────────
    final msgRef = await _db
        .collection('dm_threads')
        .doc(tid)
        .collection('messages')
        .add({
      'senderId':     _uid,
      'senderName':   name,
      'text':         text.trim(),
      'timestamp':    FieldValue.serverTimestamp(),
      'isDeleted':    false,
      'isSystem':     false,
      'isEdited':     false,
      'status':       'sent',
      'replyToId':    replyToId,
      'replyPreview': replyPreview,
      'replyToName':  replyToName,
      'reactions':    <String, dynamic>{},
    });

    // Immediately mark sender's own message as delivered
    await msgRef.update({'status': 'delivered'});

    // ── 3. Update inbox index for both users ──────────────────
    final preview = text.trim().length > 60
        ? '${text.trim().substring(0, 60)}…'
        : text.trim();

    await Future.wait([
      _updateInboxEntry(
        forUid:           _uid,
        otherUid:         otherUid,
        otherUsername:    otherUsername,
        otherDisplayName: otherDisplayName,
        otherPhotoUrl:    otherPhotoUrl,
        lastMessage:      preview,
        lastSenderId:     _uid,
        incrementUnread:  false,
      ),
      _updateInboxEntry(
        forUid:           otherUid,
        otherUid:         _uid,
        otherUsername:    my['username']    as String? ?? '',
        otherDisplayName: name,
        otherPhotoUrl:    my['photoUrl']    as String? ?? '',
        lastMessage:      preview,
        lastSenderId:     _uid,
        incrementUnread:  true,
      ),
    ]);
  }

  // ══════════════════════════════════════════════════════════════
  // TYPING INDICATOR
  // Stored at: dm_threads/{tid}/typing/{myUid}
  // ══════════════════════════════════════════════════════════════
  Future<void> setTyping(String otherUid, bool isTyping) async {
    final tid = threadId(otherUid);
    try {
      await _db
          .collection('dm_threads')
          .doc(tid)
          .collection('typing')
          .doc(_uid)
          .set({
        'isTyping':  isTyping,
        'uid':       _uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Typing is non-critical — swallow errors silently.
    }
  }

  /// Stream of whether the OTHER user is typing.
  Stream<bool> typingStream(String otherUid) {
    final tid = threadId(otherUid);
    return _db
        .collection('dm_threads')
        .doc(tid)
        .collection('typing')
        .doc(otherUid)
        .snapshots()
        .map((s) => (s.data()?['isTyping'] as bool?) ?? false);
  }

  // ══════════════════════════════════════════════════════════════
  // MESSAGE STREAMS
  // ══════════════════════════════════════════════════════════════
  Stream<List<DmMessageModel>> messagesStream(String otherUid) => _db
      .collection('dm_threads')
      .doc(threadId(otherUid))
      .collection('messages')
      .orderBy('timestamp')
      .snapshots()
      .map((s) => s.docs
          .map((d) => DmMessageModel.fromMap(d.id, d.data()))
          .toList());

  Stream<List<DmThreadModel>> inboxStream() => _db
      .collection('users')
      .doc(_uid)
      .collection('dm_threads')
      .orderBy('lastMessageAt', descending: true)
      .snapshots()
      .map((s) => s.docs
          .map((d) => DmThreadModel.fromMap(d.data()))
          .toList());

  Stream<int> totalUnreadStream() => _db
      .collection('users')
      .doc(_uid)
      .collection('dm_threads')
      .snapshots()
      .map((s) => s.docs.fold<int>(
          0, (sum, d) =>
              sum + ((d.data()['unreadCount'] as num?)?.toInt() ?? 0)));

  // ══════════════════════════════════════════════════════════════
  // MARK AS READ
  // Resets unread counter AND batch-updates all messages from
  // the other user to status=read so blue ticks appear.
  // ══════════════════════════════════════════════════════════════
  Future<void> markAsRead(String otherUid) async {
    final tid = threadId(otherUid);

    // Reset unread counter in inbox index
    try {
      await _db
          .collection('users')
          .doc(_uid)
          .collection('dm_threads')
          .doc(tid)
          .update({'unreadCount': 0});
    } catch (_) {}

    // Batch-update unread messages → read
    try {
      final unread = await _db
          .collection('dm_threads')
          .doc(tid)
          .collection('messages')
          .where('senderId', isEqualTo: otherUid)
          .where('status', whereIn: ['sent', 'delivered'])
          .get();

      if (unread.docs.isEmpty) return;
      final batch = _db.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {'status': 'read'});
      }
      await batch.commit();
    } catch (_) {}
  }

  // ══════════════════════════════════════════════════════════════
  // MARK DELIVERED
  // Called when the recipient opens the app / screen — updates
  // any 'sent' messages from the other user to 'delivered'.
  // ══════════════════════════════════════════════════════════════
  Future<void> markDelivered(String otherUid) async {
    final tid = threadId(otherUid);
    try {
      final sent = await _db
          .collection('dm_threads')
          .doc(tid)
          .collection('messages')
          .where('senderId', isEqualTo: otherUid)
          .where('status',   isEqualTo: 'sent')
          .get();

      if (sent.docs.isEmpty) return;
      final batch = _db.batch();
      for (final doc in sent.docs) {
        batch.update(doc.reference, {'status': 'delivered'});
      }
      await batch.commit();
    } catch (_) {}
  }

  // ══════════════════════════════════════════════════════════════
  // EDIT MESSAGE
  // Only the sender can edit; enforced by Firestore rules too.
  // ══════════════════════════════════════════════════════════════
  Future<void> editMessage(
      String otherUid, String msgId, String newText) async {
    if (newText.trim().isEmpty) return;
    await _db
        .collection('dm_threads')
        .doc(threadId(otherUid))
        .collection('messages')
        .doc(msgId)
        .update({
      'text':      newText.trim(),
      'isEdited':  true,
      'editedAt':  FieldValue.serverTimestamp(),
    });
  }

  // ══════════════════════════════════════════════════════════════
  // TOGGLE REACTION
  // Uses a Firestore transaction so concurrent taps are safe.
  // reactions field: { '❤️': ['uid1','uid2'], '😂': ['uid3'] }
  // ══════════════════════════════════════════════════════════════
  Future<void> toggleReaction(
      String otherUid, String msgId, String emoji) async {
    final ref = _db
        .collection('dm_threads')
        .doc(threadId(otherUid))
        .collection('messages')
        .doc(msgId);

    await _db.runTransaction((tx) async {
      final snap      = await tx.get(ref);
      final rawMap    = Map<String, dynamic>.from(
          (snap.data()?['reactions'] as Map<String, dynamic>?) ?? {});
      final List<String> uids =
          List<String>.from((rawMap[emoji] as List<dynamic>?) ?? []);

      if (uids.contains(_uid)) {
        uids.remove(_uid);
      } else {
        uids.add(_uid);
      }

      if (uids.isEmpty) {
        rawMap.remove(emoji);
      } else {
        rawMap[emoji] = uids;
      }

      tx.update(ref, {'reactions': rawMap});
    });
  }

  // ══════════════════════════════════════════════════════════════
  // SOFT DELETE
  // ══════════════════════════════════════════════════════════════
  Future<void> deleteMessage(String otherUid, String msgId) async => _db
      .collection('dm_threads')
      .doc(threadId(otherUid))
      .collection('messages')
      .doc(msgId)
      .update({
    'isDeleted': true,
    'text':      'This message was deleted',
    'reactions': <String, dynamic>{},
  });

  // ══════════════════════════════════════════════════════════════
  // HELPER — update inbox entry for one user
  // ══════════════════════════════════════════════════════════════
  Future<void> _updateInboxEntry({
    required String   forUid,
    required String   otherUid,
    required String   otherUsername,
    required String   otherDisplayName,
    required String   otherPhotoUrl,
    required String   lastMessage,
    required String   lastSenderId,
    required bool     incrementUnread,
  }) async {
    final ref = _db
        .collection('users')
        .doc(forUid)
        .collection('dm_threads')
        .doc(threadId(otherUid));

    final cur =
        ((await ref.get()).data()?['unreadCount'] as num?)?.toInt() ?? 0;

    await ref.set({
      'threadId':         threadId(otherUid),
      'otherUid':         otherUid,
      'otherUsername':    otherUsername,
      'otherDisplayName': otherDisplayName,
      'otherPhotoUrl':    otherPhotoUrl,
      'lastMessage':      lastMessage,
      'lastMessageAt':    FieldValue.serverTimestamp(),
      'lastSenderId':     lastSenderId,
      'unreadCount':      incrementUnread ? cur + 1 : cur,
    }, SetOptions(merge: true));
  }
}