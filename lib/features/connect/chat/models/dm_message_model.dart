// ============================================================
// PATH: lib/features/connect/chat/models/dm_message_model.dart
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageStatus { sent, delivered, read }

class DmMessageModel {
  final String        id;
  final String        senderId;
  final String        senderName;
  final String        text;
  final DateTime      timestamp;
  final bool          isDeleted;
  final bool          isSystem;   // "You are now friends 🎉" etc.
  final bool          isEdited;
  final DateTime?     editedAt;
  final MessageStatus status;
  final String?       replyToId;
  final String?       replyPreview;
  final String?       replyToName;
  /// reactions: { '❤️': ['uid1','uid2'], '😂': ['uid3'] }
  /// Stored as a flat map of emoji → list of UIDs.
  final Map<String, List<String>> reactions;

  const DmMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.isDeleted    = false,
    this.isSystem     = false,
    this.isEdited     = false,
    this.editedAt,
    this.status       = MessageStatus.sent,
    this.replyToId,
    this.replyPreview,
    this.replyToName,
    this.reactions    = const {},
  });

  factory DmMessageModel.fromMap(String id, Map<String, dynamic> m) {
    // ── timestamp ─────────────────────────────────────────────
    DateTime ts;
    final raw = m['timestamp'];
    if (raw == null) {
      ts = DateTime.now();
    } else if (raw is Timestamp) {
      ts = raw.toDate();
    } else if (raw is int) {
      ts = DateTime.fromMillisecondsSinceEpoch(raw);
    } else {
      try {
        ts = (raw as dynamic).toDate() as DateTime;
      } catch (_) {
        ts = DateTime.now();
      }
    }

    // ── editedAt ───────────────────────────────────────────────
    DateTime? editedAt;
    final rawEdited = m['editedAt'];
    if (rawEdited != null) {
      try {
        editedAt = rawEdited is Timestamp
            ? rawEdited.toDate()
            : (rawEdited as dynamic).toDate() as DateTime;
      } catch (_) {}
    }

    // ── status ─────────────────────────────────────────────────
    MessageStatus status;
    try {
      status = MessageStatus.values.byName(m['status'] as String? ?? 'sent');
    } catch (_) {
      status = MessageStatus.sent;
    }

    // ── reactions ── { emoji: [uid, uid, ...] } ───────────────
    final Map<String, List<String>> reactions = {};
    final rawReactions = m['reactions'];
    if (rawReactions is Map) {
      rawReactions.forEach((key, value) {
        if (value is List) {
          reactions[key.toString()] =
              value.map((e) => e.toString()).toList();
        }
      });
    }

    return DmMessageModel(
      id:           id,
      senderId:     m['senderId']     as String? ?? '',
      senderName:   m['senderName']   as String? ?? '',
      text:         m['text']         as String? ?? '',
      timestamp:    ts,
      isDeleted:    m['isDeleted']    as bool?   ?? false,
      isSystem:     m['isSystem']     as bool?   ?? false,
      isEdited:     m['isEdited']     as bool?   ?? false,
      editedAt:     editedAt,
      status:       status,
      replyToId:    m['replyToId']    as String?,
      replyPreview: m['replyPreview'] as String?,
      replyToName:  m['replyToName']  as String?,
      reactions:    reactions,
    );
  }

  Map<String, dynamic> toMap() => {
    'senderId':     senderId,
    'senderName':   senderName,
    'text':         text,
    'timestamp':    FieldValue.serverTimestamp(),
    'isDeleted':    isDeleted,
    'isSystem':     isSystem,
    'isEdited':     isEdited,
    if (editedAt != null) 'editedAt': Timestamp.fromDate(editedAt!),
    'status':       status.name,
    'replyToId':    replyToId,
    'replyPreview': replyPreview,
    'replyToName':  replyToName,
    'reactions':    reactions,
  };
}

// ══════════════════════════════════════════════════════════════
// DM THREAD MODEL
// ══════════════════════════════════════════════════════════════
class DmThreadModel {
  final String    threadId;
  final String    otherUid;
  final String    otherUsername;
  final String    otherDisplayName;
  final String    otherPhotoUrl;
  final String    lastMessage;
  final DateTime? lastMessageAt;
  final int       unreadCount;
  final String?   lastMsgId;
  final String?   lastSenderId;

  const DmThreadModel({
    required this.threadId,
    required this.otherUid,
    required this.otherUsername,
    required this.otherDisplayName,
    required this.otherPhotoUrl,
    required this.lastMessage,
    this.lastMessageAt,
    this.unreadCount   = 0,
    this.lastMsgId,
    this.lastSenderId,
  });

  factory DmThreadModel.fromMap(Map<String, dynamic> m) {
    DateTime? lat;
    final raw = m['lastMessageAt'];
    if (raw != null) {
      try {
        lat = raw is Timestamp ? raw.toDate() : (raw as dynamic).toDate();
      } catch (_) {}
    }

    return DmThreadModel(
      threadId:         m['threadId']         as String? ?? '',
      otherUid:         m['otherUid']         as String? ?? '',
      otherUsername:    m['otherUsername']     as String? ?? '',
      otherDisplayName: m['otherDisplayName'] as String? ?? '',
      otherPhotoUrl:    m['otherPhotoUrl']    as String? ?? '',
      lastMessage:      m['lastMessage']      as String? ?? '',
      lastMessageAt:    lat,
      unreadCount:      (m['unreadCount'] as num?)?.toInt() ?? 0,
      lastMsgId:        m['lastMsgId']        as String?,
      lastSenderId:     m['lastSenderId']     as String?,
    );
  }
}