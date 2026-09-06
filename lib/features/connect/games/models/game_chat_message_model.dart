// ============================================================
// PATH: lib/features/connect/games/models/game_chat_message_model.dart
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

/// A single chat message inside a game room — used for players to
/// answer truths / react to dares / banter during a round.
class GameChatMessage {
  final String id;
  final String senderUid;
  final String senderName;
  final String senderEmoji;
  final String text;
  final DateTime timestamp;

  const GameChatMessage({
    required this.id,
    required this.senderUid,
    required this.senderName,
    required this.senderEmoji,
    required this.text,
    required this.timestamp,
  });

  factory GameChatMessage.fromMap(String id, Map<String, dynamic> d) {
    return GameChatMessage(
      id: id,
      senderUid: d['senderUid'] as String? ?? '',
      senderName: d['senderName'] as String? ?? 'Player',
      senderEmoji: d['senderEmoji'] as String? ?? '🎮',
      text: d['text'] as String? ?? '',
      timestamp: d['timestamp'] is Timestamp
          ? (d['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'senderUid': senderUid,
        'senderName': senderName,
        'senderEmoji': senderEmoji,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      };
}