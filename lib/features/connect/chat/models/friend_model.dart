// ============================================================
// PATH: lib/features/connect/chat/models/friend_model.dart
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendStatus { pending, accepted, blocked }

class FriendModel {
  final String       uid;
  final String       username;
  final String       displayName;
  final String       photoUrl;
  final FriendStatus status;
  final DateTime     addedAt;
  final bool         isOnline;
  final String       lastSeen;
  final int          currentStreak;

  const FriendModel({
    required this.uid,
    required this.username,
    required this.displayName,
    this.photoUrl      = '',
    this.status        = FriendStatus.accepted,
    required this.addedAt,
    this.isOnline      = false,
    this.lastSeen      = '',
    this.currentStreak = 0,
  });

  factory FriendModel.fromMap(Map<String, dynamic> d) => FriendModel(
        uid:           d['uid']          as String? ?? '',
        username:      d['username']     as String? ?? '',
        displayName:   d['displayName']  as String? ?? '',
        photoUrl:      d['photoUrl']     as String? ?? '',
        status:        _s(d['status']   as String? ?? 'accepted'),
        addedAt:       d['addedAt'] is Timestamp
            ? (d['addedAt'] as Timestamp).toDate()
            : DateTime.now(),
        isOnline:      d['isOnline']     as bool?   ?? false,
        lastSeen:      d['lastSeen']     as String? ?? '',
        currentStreak: (d['currentStreak'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'uid': uid, 'username': username, 'displayName': displayName,
        'photoUrl': photoUrl, 'status': status.name,
        'addedAt': Timestamp.fromDate(addedAt),
        'isOnline': isOnline, 'lastSeen': lastSeen,
        'currentStreak': currentStreak,
      };

  static FriendStatus _s(String s) {
    switch (s) {
      case 'pending': return FriendStatus.pending;
      case 'blocked': return FriendStatus.blocked;
      default:        return FriendStatus.accepted;
    }
  }
}