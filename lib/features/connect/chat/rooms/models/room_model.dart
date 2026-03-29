// ============================================================
// PATH: lib/features/connect/rooms/models/room_model.dart
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

enum RoomCategory { addiction, emotion, timeOfDay }

class RoomModel {
  final String       id, name, description, emoji, categoryTag;
  final RoomCategory category;
  final int          onlineCount, totalMessages;
  final DateTime     lastActivity;
  final bool         isPinned;

  const RoomModel({
    required this.id, required this.name, required this.description,
    required this.emoji, required this.category, required this.categoryTag,
    this.onlineCount = 0, this.totalMessages = 0,
    required this.lastActivity, this.isPinned = false,
  });

  factory RoomModel.fromMap(String id, Map<String, dynamic> d) => RoomModel(
    id: id, name: d['name'] as String? ?? '',
    description:   d['description']   as String? ?? '',
    emoji:         d['emoji']         as String? ?? '💬',
    category:      _c(d['category']  as String? ?? 'emotion'),
    categoryTag:   d['categoryTag']   as String? ?? '',
    onlineCount:   (d['onlineCount']   as num?)?.toInt() ?? 0,
    totalMessages: (d['totalMessages'] as num?)?.toInt() ?? 0,
    lastActivity:  d['lastActivity'] is Timestamp
        ? (d['lastActivity'] as Timestamp).toDate() : DateTime.now(),
    isPinned:      d['isPinned'] as bool? ?? false,
  );

  Map<String, dynamic> toMap() => {
    'name': name, 'description': description, 'emoji': emoji,
    'category': category.name, 'categoryTag': categoryTag,
    'onlineCount': onlineCount, 'totalMessages': totalMessages,
    'lastActivity': Timestamp.fromDate(lastActivity), 'isPinned': isPinned,
  };

  static RoomCategory _c(String s) => s == 'addiction'
      ? RoomCategory.addiction : s == 'timeOfDay'
      ? RoomCategory.timeOfDay : RoomCategory.emotion;
}

// ============================================================
// PATH: lib/features/connect/rooms/models/room_message_model.dart
// (included in same file for brevity — split if preferred)
// ============================================================

class RoomMessageModel {
  final String   id, senderUid, anonName, text;
  final DateTime timestamp;
  final bool     isSystem, likedByMe;
  final int      likeCount;

  const RoomMessageModel({
    required this.id, required this.senderUid, required this.anonName,
    required this.text, required this.timestamp,
    this.isSystem = false, this.likedByMe = false, this.likeCount = 0,
  });

  factory RoomMessageModel.fromMap(String id, Map<String, dynamic> d, String myUid) {
    final likes = (d['likedBy'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    return RoomMessageModel(
      id: id, senderUid: d['senderUid'] as String? ?? '',
      anonName:  d['anonName']  as String? ?? 'Anonymous',
      text:      d['text']      as String? ?? '',
      timestamp: d['timestamp'] is Timestamp
          ? (d['timestamp'] as Timestamp).toDate() : DateTime.now(),
      isSystem:  d['isSystem']  as bool? ?? false,
      likeCount: likes.length, likedByMe: likes.contains(myUid),
    );
  }

  Map<String, dynamic> toMap() => {
    'senderUid': senderUid, 'anonName': anonName, 'text': text,
    'timestamp': Timestamp.fromDate(timestamp),
    'isSystem': isSystem, 'likedBy': [],
  };
}