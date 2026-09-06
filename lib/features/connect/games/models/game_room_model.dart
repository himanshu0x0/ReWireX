import 'package:cloud_firestore/cloud_firestore.dart';

enum GameRoomStatus {
  waiting,
  playing,
  finished,
}

enum GameRoomType {
  public,
  private,
}

class GamePlayer {
  final String uid;
  final String anonName;
  final String emoji;
  // NEW: player-chosen gender for the room, editable in-room via
  // GameRoomScreen settings. Free-form-ish but UI restricts to a
  // fixed set of chip values ('', 'male', 'female', 'other').
  final String gender;
  // NEW: player-chosen "interest" for the room (what they're here
  // for), editable alongside gender in the same settings sheet.
  final String interest;
  final bool isHost;
  final bool isOnline;
  final int score;
  final DateTime joinedAt;

  const GamePlayer({
    required this.uid,
    required this.anonName,
    required this.emoji,
    this.gender = '',
    this.interest = '',
    this.isHost = false,
    this.isOnline = true,
    this.score = 0,
    required this.joinedAt,
  });

  factory GamePlayer.fromMap(
    Map<String, dynamic> d,
  ) {
    return GamePlayer(
      uid: d['uid'] as String? ?? '',
      anonName:
          d['anonName'] as String? ?? 'Player',
      emoji: d['emoji'] as String? ?? '🎮',
      gender: d['gender'] as String? ?? '',
      interest: d['interest'] as String? ?? '',
      isHost:
          d['isHost'] as bool? ?? false,
      isOnline:
          d['isOnline'] as bool? ?? true,
      score:
          (d['score'] as num?)?.toInt() ?? 0,
      joinedAt:
          d['joinedAt'] is Timestamp
              ? (d['joinedAt'] as Timestamp)
                  .toDate()
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'anonName': anonName,
      'emoji': emoji,
      'gender': gender,
      'interest': interest,
      'isHost': isHost,
      'isOnline': isOnline,
      'score': score,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }

  GamePlayer copyWith({
    String? anonName,
    String? emoji,
    String? gender,
    String? interest,
  }) =>
      GamePlayer(
        uid: uid,
        anonName: anonName ?? this.anonName,
        emoji: emoji ?? this.emoji,
        gender: gender ?? this.gender,
        interest: interest ?? this.interest,
        isHost: isHost,
        isOnline: isOnline,
        score: score,
        joinedAt: joinedAt,
      );
}

class GameRoomModel {
  final String id;
  final String name;

  final GameRoomType type;
  final GameRoomStatus status;

  final String hostUid;
  final String hostName;

  final String? roomCode;

  final int maxPlayers;
  final int playerCount;
  final List<String> playerUids;

  final String category;

  final String currentTurnUid;
  final String currentTurnName;

  final int roundNumber;
  final int totalRounds;

  final DateTime createdAt;
  final DateTime lastActivity;

  // IMPORTANT
  // Only rooms created by the current game system have this true.
  final bool isActive;

  const GameRoomModel({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.hostUid,
    required this.hostName,
    this.roomCode,
    this.maxPlayers = 8,
    this.playerCount = 1,
    this.playerUids = const [],
    this.category = 'mixed',
    this.currentTurnUid = '',
    this.currentTurnName = '',
    this.roundNumber = 0,
    this.totalRounds = 10,
    required this.createdAt,
    required this.lastActivity,
    this.isActive = false,
  });

  factory GameRoomModel.fromMap(
    String id,
    Map<String, dynamic> d,
  ) {
    return GameRoomModel(
      id: id,

      name:
          d['name'] as String? ?? 'Game Room',

      type:
          d['type'] == 'private'
              ? GameRoomType.private
              : GameRoomType.public,

      status:
          _statusFromString(
        d['status'] as String? ?? 'waiting',
      ),

      hostUid:
          d['hostUid'] as String? ?? '',

      hostName:
          d['hostName'] as String? ?? '',

      roomCode:
          d['roomCode'] as String?,

      maxPlayers:
          (d['maxPlayers'] as num?)?.toInt() ?? 8,

      playerCount:
          (d['playerCount'] as num?)?.toInt() ?? 1,

      playerUids:
          List<String>.from(
        d['playerUids'] ?? const [],
      ),

      category:
          d['category'] as String? ?? 'mixed',

      currentTurnUid:
          d['currentTurnUid'] as String? ?? '',

      currentTurnName:
          d['currentTurnName'] as String? ?? '',

      roundNumber:
          (d['roundNumber'] as num?)?.toInt() ?? 0,

      totalRounds:
          (d['totalRounds'] as num?)?.toInt() ?? 10,

      createdAt:
          d['createdAt'] is Timestamp
              ? (d['createdAt'] as Timestamp)
                  .toDate()
              : DateTime.now(),

      lastActivity:
          d['lastActivity'] is Timestamp
              ? (d['lastActivity'] as Timestamp)
                  .toDate()
              : DateTime.now(),

      // Old rooms don't have this field.
      // Therefore they automatically become inactive.
      isActive:
          d['isActive'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type.name,
      'status': status.name,

      'hostUid': hostUid,
      'hostName': hostName,

      if (roomCode != null)
        'roomCode': roomCode,

      'maxPlayers': maxPlayers,
      'playerCount': playerCount,
      'playerUids': playerUids,

      'category': category,

      'currentTurnUid':
          currentTurnUid,

      'currentTurnName':
          currentTurnName,

      'roundNumber': roundNumber,
      'totalRounds': totalRounds,

      'createdAt':
          Timestamp.fromDate(createdAt),

      'lastActivity':
          Timestamp.fromDate(lastActivity),

      'isActive': isActive,
    };
  }

  bool get isFull =>
      playerCount >= maxPlayers;

  bool get canStart =>
      playerCount >= 2 &&
      status == GameRoomStatus.waiting;

  static GameRoomStatus _statusFromString(
    String value,
  ) {
    switch (value) {
      case 'playing':
        return GameRoomStatus.playing;

      case 'finished':
        return GameRoomStatus.finished;

      default:
        return GameRoomStatus.waiting;
    }
  }
}