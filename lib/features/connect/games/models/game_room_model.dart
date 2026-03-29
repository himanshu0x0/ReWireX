// ============================================================
// PATH: lib/features/connect/games/models/game_room_model.dart
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

enum GameRoomStatus { waiting, playing, finished }
enum GameRoomType   { public, private }

class GamePlayer {
  final String uid, anonName, emoji;
  final bool   isHost, isOnline;
  final int    score;
  final DateTime joinedAt;

  const GamePlayer({required this.uid, required this.anonName, required this.emoji,
      this.isHost = false, this.isOnline = true, this.score = 0, required this.joinedAt});

  factory GamePlayer.fromMap(Map<String, dynamic> d) => GamePlayer(
    uid: d['uid'] as String? ?? '', anonName: d['anonName'] as String? ?? 'Player',
    emoji: d['emoji'] as String? ?? '🎮', isHost: d['isHost'] as bool? ?? false,
    isOnline: d['isOnline'] as bool? ?? true, score: (d['score'] as num?)?.toInt() ?? 0,
    joinedAt: d['joinedAt'] is Timestamp ? (d['joinedAt'] as Timestamp).toDate() : DateTime.now());

  Map<String, dynamic> toMap() => {'uid': uid, 'anonName': anonName, 'emoji': emoji,
      'isHost': isHost, 'isOnline': isOnline, 'score': score, 'joinedAt': Timestamp.fromDate(joinedAt)};
}

class GameRoomModel {
  final String         id, name, hostUid, hostName, category, currentTurnUid, currentTurnName;
  final GameRoomType   type;
  final GameRoomStatus status;
  final String?        roomCode;
  final int            maxPlayers, playerCount, roundNumber, totalRounds;
  final List<String>   playerUids;
  final DateTime       createdAt, lastActivity;

  const GameRoomModel({
    required this.id, required this.name, required this.type, required this.status,
    required this.hostUid, required this.hostName, this.roomCode,
    this.maxPlayers = 8, this.playerCount = 1, this.playerUids = const [],
    this.category = 'mixed', this.currentTurnUid = '', this.currentTurnName = '',
    this.roundNumber = 0, this.totalRounds = 10,
    required this.createdAt, required this.lastActivity,
  });

  factory GameRoomModel.fromMap(String id, Map<String, dynamic> d) => GameRoomModel(
    id: id, name: d['name'] as String? ?? 'Game Room',
    type:            d['type'] == 'private' ? GameRoomType.private : GameRoomType.public,
    status:          _st(d['status'] as String? ?? 'waiting'),
    hostUid:         d['hostUid']         as String? ?? '',
    hostName:        d['hostName']        as String? ?? '',
    roomCode:        d['roomCode']        as String?,
    maxPlayers:      (d['maxPlayers']     as num?)?.toInt() ?? 8,
    playerCount:     (d['playerCount']    as num?)?.toInt() ?? 1,
    playerUids:      List<String>.from(d['playerUids'] ?? []),
    category:        d['category']        as String? ?? 'mixed',
    currentTurnUid:  d['currentTurnUid']  as String? ?? '',
    currentTurnName: d['currentTurnName'] as String? ?? '',
    roundNumber:     (d['roundNumber']    as num?)?.toInt() ?? 0,
    totalRounds:     (d['totalRounds']    as num?)?.toInt() ?? 10,
    createdAt:       d['createdAt'] is Timestamp ? (d['createdAt'] as Timestamp).toDate() : DateTime.now(),
    lastActivity:    d['lastActivity'] is Timestamp ? (d['lastActivity'] as Timestamp).toDate() : DateTime.now());

  Map<String, dynamic> toMap() => {
    'name': name, 'type': type.name, 'status': status.name,
    'hostUid': hostUid, 'hostName': hostName, if (roomCode != null) 'roomCode': roomCode,
    'maxPlayers': maxPlayers, 'playerCount': playerCount, 'playerUids': playerUids,
    'category': category, 'currentTurnUid': currentTurnUid, 'currentTurnName': currentTurnName,
    'roundNumber': roundNumber, 'totalRounds': totalRounds,
    'createdAt': Timestamp.fromDate(createdAt), 'lastActivity': Timestamp.fromDate(lastActivity)};

  bool get isFull   => playerCount >= maxPlayers;
  bool get canStart => playerCount >= 2;
  static GameRoomStatus _st(String s) => s == 'playing' ? GameRoomStatus.playing
      : s == 'finished' ? GameRoomStatus.finished : GameRoomStatus.waiting;
}

// ============================================================
// PATH: lib/features/connect/games/models/game_question_model.dart
// ============================================================

enum QuestionType     { truth, dare }
enum QuestionLevel    { easy, medium, hard }
enum QCategory        { fun, spicy, recovery }

class GameQuestion {
  final String    id;
  final QuestionType  type;
  final QuestionLevel level;
  final QCategory     category;
  final String    text;
  final int       timeSeconds;
  const GameQuestion({required this.id, required this.type, required this.level,
      required this.category, required this.text, this.timeSeconds = 0});
}

class QuestionBank {
  static const truths = <GameQuestion>[
    GameQuestion(id:'t01',type:QuestionType.truth,level:QuestionLevel.easy,category:QCategory.fun,text:'What is the most embarrassing thing you\'ve ever done in public?'),
    GameQuestion(id:'t02',type:QuestionType.truth,level:QuestionLevel.easy,category:QCategory.fun,text:'What\'s the weirdest dream you\'ve ever had?'),
    GameQuestion(id:'t03',type:QuestionType.truth,level:QuestionLevel.easy,category:QCategory.fun,text:'What\'s a song you secretly love but are embarrassed to admit?'),
    GameQuestion(id:'t04',type:QuestionType.truth,level:QuestionLevel.easy,category:QCategory.fun,text:'What\'s the most childish thing you still do?'),
    GameQuestion(id:'t05',type:QuestionType.truth,level:QuestionLevel.easy,category:QCategory.fun,text:'Have you ever blamed someone else for something you did?'),
    GameQuestion(id:'t06',type:QuestionType.truth,level:QuestionLevel.easy,category:QCategory.fun,text:'What food could you eat every single day and never get bored of?'),
    GameQuestion(id:'t07',type:QuestionType.truth,level:QuestionLevel.easy,category:QCategory.fun,text:'What is something you pretend to like but actually hate?'),
    GameQuestion(id:'t08',type:QuestionType.truth,level:QuestionLevel.easy,category:QCategory.fun,text:'What is the strangest thing you have ever eaten?'),
    GameQuestion(id:'t09',type:QuestionType.truth,level:QuestionLevel.medium,category:QCategory.fun,text:'What\'s the worst lie you\'ve ever told to get out of trouble?'),
    GameQuestion(id:'t10',type:QuestionType.truth,level:QuestionLevel.medium,category:QCategory.fun,text:'What is the most ridiculous thing you\'ve ever cried about?'),
    GameQuestion(id:'t11',type:QuestionType.truth,level:QuestionLevel.medium,category:QCategory.fun,text:'Have you ever walked into the wrong room and pretended you meant to do it?'),
    GameQuestion(id:'t12',type:QuestionType.truth,level:QuestionLevel.medium,category:QCategory.fun,text:'What\'s a habit you have that you find disgusting but can\'t stop?'),
    GameQuestion(id:'t13',type:QuestionType.truth,level:QuestionLevel.medium,category:QCategory.fun,text:'What\'s the most awkward situation you\'ve ever been in?'),
    GameQuestion(id:'t14',type:QuestionType.truth,level:QuestionLevel.medium,category:QCategory.fun,text:'What\'s the silliest reason you\'ve ever had an argument with someone?'),
    GameQuestion(id:'t15',type:QuestionType.truth,level:QuestionLevel.hard,category:QCategory.spicy,text:'What is the pettiest thing you have ever done to get revenge?'),
    GameQuestion(id:'t16',type:QuestionType.truth,level:QuestionLevel.hard,category:QCategory.spicy,text:'What\'s the biggest secret you\'ve kept from your family?'),
    GameQuestion(id:'t17',type:QuestionType.truth,level:QuestionLevel.hard,category:QCategory.spicy,text:'What\'s a mean thought you\'ve had about someone that you\'re not proud of?'),
    GameQuestion(id:'t18',type:QuestionType.truth,level:QuestionLevel.easy,category:QCategory.recovery,text:'What is one small thing you are proud of yourself for this week?'),
    GameQuestion(id:'t19',type:QuestionType.truth,level:QuestionLevel.easy,category:QCategory.recovery,text:'What is one thing you do to calm yourself when you feel stressed?'),
    GameQuestion(id:'t20',type:QuestionType.truth,level:QuestionLevel.medium,category:QCategory.recovery,text:'What\'s a moment you chose yourself over your addiction and how did it feel?'),
    GameQuestion(id:'t21',type:QuestionType.truth,level:QuestionLevel.medium,category:QCategory.recovery,text:'What does your best day look like now compared to before?'),
    GameQuestion(id:'t22',type:QuestionType.truth,level:QuestionLevel.medium,category:QCategory.recovery,text:'If you could give your past self one piece of advice what would it be?'),
    GameQuestion(id:'t23',type:QuestionType.truth,level:QuestionLevel.easy,category:QCategory.fun,text:'What superpower would you choose and what\'s the first thing you\'d do with it?'),
    GameQuestion(id:'t24',type:QuestionType.truth,level:QuestionLevel.easy,category:QCategory.fun,text:'If you could live inside any movie world for a week which would you pick?'),
    GameQuestion(id:'t25',type:QuestionType.truth,level:QuestionLevel.easy,category:QCategory.fun,text:'If your life had a theme song what would it be right now?'),
  ];

  static const dares = <GameQuestion>[
    GameQuestion(id:'d01',type:QuestionType.dare,level:QuestionLevel.easy,category:QCategory.fun,text:'Do your best impression of a famous person and hold it for 30 seconds.',timeSeconds:30),
    GameQuestion(id:'d02',type:QuestionType.dare,level:QuestionLevel.easy,category:QCategory.fun,text:'Speak in a different accent for the next 2 minutes.',timeSeconds:120),
    GameQuestion(id:'d03',type:QuestionType.dare,level:QuestionLevel.easy,category:QCategory.fun,text:'Do 10 jumping jacks right now. Go!',timeSeconds:30),
    GameQuestion(id:'d04',type:QuestionType.dare,level:QuestionLevel.easy,category:QCategory.fun,text:'Send a compliment to the first person in your contacts right now.'),
    GameQuestion(id:'d05',type:QuestionType.dare,level:QuestionLevel.easy,category:QCategory.fun,text:'Sing the chorus of your favourite song out loud right now.'),
    GameQuestion(id:'d06',type:QuestionType.dare,level:QuestionLevel.easy,category:QCategory.fun,text:'Do your best robot dance for 20 seconds.',timeSeconds:20),
    GameQuestion(id:'d07',type:QuestionType.dare,level:QuestionLevel.easy,category:QCategory.fun,text:'Talk like a pirate for the next 3 rounds.'),
    GameQuestion(id:'d08',type:QuestionType.dare,level:QuestionLevel.easy,category:QCategory.fun,text:'Narrate everything you do for the next 60 seconds like a sports commentator.',timeSeconds:60),
    GameQuestion(id:'d09',type:QuestionType.dare,level:QuestionLevel.easy,category:QCategory.fun,text:'Tell a joke — if nobody laughs you do 5 push-ups.'),
    GameQuestion(id:'d10',type:QuestionType.dare,level:QuestionLevel.medium,category:QCategory.fun,text:'Do 20 push-ups right now. We\'re counting.',timeSeconds:60),
    GameQuestion(id:'d11',type:QuestionType.dare,level:QuestionLevel.medium,category:QCategory.fun,text:'Write a poem about the last person who spoke in 60 seconds.',timeSeconds:60),
    GameQuestion(id:'d12',type:QuestionType.dare,level:QuestionLevel.medium,category:QCategory.fun,text:'Do your best catwalk strut across the room and back.'),
    GameQuestion(id:'d13',type:QuestionType.dare,level:QuestionLevel.medium,category:QCategory.fun,text:'Speak only in questions for the next 2 minutes.',timeSeconds:120),
    GameQuestion(id:'d14',type:QuestionType.dare,level:QuestionLevel.medium,category:QCategory.fun,text:'Give each player in the room a genuine compliment right now.'),
    GameQuestion(id:'d15',type:QuestionType.dare,level:QuestionLevel.hard,category:QCategory.spicy,text:'Let the group roast you for 60 seconds. No defending yourself.',timeSeconds:60),
    GameQuestion(id:'d16',type:QuestionType.dare,level:QuestionLevel.hard,category:QCategory.spicy,text:'Show the group your most recent Google search.'),
    GameQuestion(id:'d17',type:QuestionType.dare,level:QuestionLevel.hard,category:QCategory.spicy,text:'Read the last 3 messages in your most used chat out loud.'),
    GameQuestion(id:'d18',type:QuestionType.dare,level:QuestionLevel.easy,category:QCategory.recovery,text:'Do 3 rounds of 4-7-8 breathing right now. Everyone join in.',timeSeconds:90),
    GameQuestion(id:'d19',type:QuestionType.dare,level:QuestionLevel.easy,category:QCategory.recovery,text:'Say one thing out loud that you are genuinely grateful for today.'),
    GameQuestion(id:'d20',type:QuestionType.dare,level:QuestionLevel.medium,category:QCategory.recovery,text:'Give a genuine word of encouragement to every other player in this room.'),
    GameQuestion(id:'d21',type:QuestionType.dare,level:QuestionLevel.easy,category:QCategory.fun,text:'Say the alphabet backwards as fast as you can.',timeSeconds:30),
    GameQuestion(id:'d22',type:QuestionType.dare,level:QuestionLevel.easy,category:QCategory.fun,text:'Make the most dramatic exit and re-entry from the room.',timeSeconds:20),
    GameQuestion(id:'d23',type:QuestionType.dare,level:QuestionLevel.medium,category:QCategory.fun,text:'Tell an original joke you make up on the spot right now.'),
    GameQuestion(id:'d24',type:QuestionType.dare,level:QuestionLevel.easy,category:QCategory.fun,text:'Balance a small object on your head for 30 seconds.',timeSeconds:30),
    GameQuestion(id:'d25',type:QuestionType.dare,level:QuestionLevel.medium,category:QCategory.fun,text:'Do your best impression of a strict school teacher scolding the group.'),
  ];

  static List<GameQuestion> get all => [...truths, ...dares];
}