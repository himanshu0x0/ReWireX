// ============================================================
// PATH: lib/features/connect/chat/models/friend_request_model.dart
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class FriendRequestModel {
  final String   id;
  final String   fromUid;
  final String   fromUsername;
  final String   fromDisplayName;
  final String   fromPhotoUrl;
  final int      fromStreak;
  final String   toUid;
  // ── NEW: recipient info stored in sent_requests so "Sent" tab
  //         can display the other person's name, not the sender's ──
  final String   toUsername;
  final String   toDisplayName;
  final String   toPhotoUrl;
  final String   status;
  final DateTime sentAt;

  const FriendRequestModel({
    required this.id,
    required this.fromUid,
    required this.fromUsername,
    required this.fromDisplayName,
    this.fromPhotoUrl  = '',
    this.fromStreak    = 0,
    required this.toUid,
    this.toUsername    = '',
    this.toDisplayName = '',
    this.toPhotoUrl    = '',
    this.status        = 'pending',
    required this.sentAt,
  });

  factory FriendRequestModel.fromMap(String id, Map<String, dynamic> d) =>
      FriendRequestModel(
        id:              id,
        fromUid:         d['fromUid']         as String? ?? '',
        fromUsername:    d['fromUsername']     as String? ?? '',
        fromDisplayName: d['fromDisplayName'] as String? ?? '',
        fromPhotoUrl:    d['fromPhotoUrl']    as String? ?? '',
        fromStreak:      (d['fromStreak']     as num?)?.toInt() ?? 0,
        toUid:           d['toUid']           as String? ?? '',
        toUsername:      d['toUsername']      as String? ?? '',
        toDisplayName:   d['toDisplayName']   as String? ?? '',
        toPhotoUrl:      d['toPhotoUrl']      as String? ?? '',
        status:          d['status']          as String? ?? 'pending',
        sentAt:          d['sentAt'] is Timestamp
            ? (d['sentAt'] as Timestamp).toDate()
            : DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
    'fromUid':         fromUid,
    'fromUsername':    fromUsername,
    'fromDisplayName': fromDisplayName,
    'fromPhotoUrl':    fromPhotoUrl,
    'fromStreak':      fromStreak,
    'toUid':           toUid,
    'toUsername':      toUsername,
    'toDisplayName':   toDisplayName,
    'toPhotoUrl':      toPhotoUrl,
    'status':          status,
    'sentAt':          FieldValue.serverTimestamp(),
  };
}