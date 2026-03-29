// ============================================================
// PATH: lib/features/connect/games/services/game_room_service.dart
// ============================================================

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/game_room_model.dart';

class GameRoomService {
  final FirebaseFirestore _db   = FirebaseFirestore.instance;
  final FirebaseAuth      _auth = FirebaseAuth.instance;
  String get _uid => _auth.currentUser?.uid ?? '';

  String _code() {
    const c = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => c[Random.secure().nextInt(c.length)]).join();
  }

  // ── Create room ───────────────────────────────────────────────
  Future<GameRoomModel> createRoom({
    required String name, required GameRoomType type,
    required String anonName, required String emoji,
    String category = 'mixed', int maxPlayers = 8, int totalRounds = 10,
  }) async {
    final now  = DateTime.now();
    final code = type == GameRoomType.private ? _code() : null;
    final data = GameRoomModel(
      id: '', name: name, type: type, status: GameRoomStatus.waiting,
      hostUid: _uid, hostName: anonName, roomCode: code,
      maxPlayers: maxPlayers, playerCount: 1, playerUids: [_uid],
      category: category, currentTurnUid: _uid, currentTurnName: anonName,
      totalRounds: totalRounds, createdAt: now, lastActivity: now,
    );
    final ref = await _db.collection('game_rooms').add(data.toMap());
    await ref.collection('players').doc(_uid).set(GamePlayer(
        uid: _uid, anonName: anonName, emoji: emoji, isHost: true, joinedAt: now).toMap());
    return GameRoomModel.fromMap(ref.id, data.toMap());
  }

  // ── Join by ID ────────────────────────────────────────────────
  Future<bool> joinRoom(String roomId, String anonName, String emoji) async {
    final snap = await _db.collection('game_rooms').doc(roomId).get();
    if (!snap.exists) return false;
    final room = GameRoomModel.fromMap(snap.id, snap.data()!);
    if (room.isFull || room.status != GameRoomStatus.waiting) return false;
    if (room.playerUids.contains(_uid)) return true;
    final b = _db.batch();
    b.update(_db.collection('game_rooms').doc(roomId), {
      'playerUids': FieldValue.arrayUnion([_uid]),
      'playerCount': FieldValue.increment(1), 'lastActivity': Timestamp.now()});
    b.set(_db.collection('game_rooms').doc(roomId).collection('players').doc(_uid),
        GamePlayer(uid: _uid, anonName: anonName, emoji: emoji, joinedAt: DateTime.now()).toMap());
    await b.commit(); return true;
  }

  // ── Join by code (private room) ───────────────────────────────
  Future<GameRoomModel?> joinByCode(String code, String anonName, String emoji) async {
    final snap = await _db.collection('game_rooms')
        .where('roomCode', isEqualTo: code.toUpperCase())
        .where('status', isEqualTo: 'waiting').limit(1).get();
    if (snap.docs.isEmpty) return null;
    final doc  = snap.docs.first;
    final room = GameRoomModel.fromMap(doc.id, doc.data());
    if (room.isFull) return null;
    final ok = await joinRoom(doc.id, anonName, emoji);
    return ok ? room : null;
  }

  // ── Start game ────────────────────────────────────────────────
  Future<void> startGame(String roomId) async => _db.collection('game_rooms').doc(roomId)
      .update({'status': 'playing', 'roundNumber': 1, 'lastActivity': Timestamp.now()});

  // ── Complete turn & advance ───────────────────────────────────
  Future<void> completeTurn({
    required String roomId, required GameRoomModel room,
    required List<GamePlayer> players, required bool completed,
    required String questionText, required QuestionType questionType,
  }) async {
    await _db.collection('game_rooms').doc(roomId).collection('turns').add({
      'uid': _uid, 'question': questionText, 'type': questionType.name,
      'completed': completed, 'round': room.roundNumber, 'timestamp': Timestamp.now()});
    if (completed) await _db.collection('game_rooms').doc(roomId)
        .collection('players').doc(_uid).update({'score': FieldValue.increment(1)});

    final idx   = players.indexWhere((p) => p.uid == room.currentTurnUid);
    final nextP = players[(idx + 1) % players.length];
    final nextR = (idx + 1) % players.length == 0 ? room.roundNumber + 1 : room.roundNumber;

    if (nextR > room.totalRounds) {
      await _db.collection('game_rooms').doc(roomId)
          .update({'status': 'finished', 'lastActivity': Timestamp.now()});
      return;
    }
    await _db.collection('game_rooms').doc(roomId).update({
      'currentTurnUid': nextP.uid, 'currentTurnName': nextP.anonName,
      'roundNumber': nextR, 'lastActivity': Timestamp.now()});
  }

  // ── Leave room ────────────────────────────────────────────────
  Future<void> leaveRoom(String roomId) async {
    final b = _db.batch();
    b.update(_db.collection('game_rooms').doc(roomId), {
      'playerUids': FieldValue.arrayRemove([_uid]), 'playerCount': FieldValue.increment(-1)});
    b.delete(_db.collection('game_rooms').doc(roomId).collection('players').doc(_uid));
    await b.commit();
  }

  // ── Streams ───────────────────────────────────────────────────
  Stream<List<GameRoomModel>> publicRoomsStream() => _db.collection('game_rooms')
      .where('type', isEqualTo: 'public').where('status', isEqualTo: 'waiting')
      .orderBy('lastActivity', descending: true).snapshots()
      .map((s) => s.docs.map((d) => GameRoomModel.fromMap(d.id, d.data())).toList());

  Stream<GameRoomModel?> roomStream(String roomId) => _db.collection('game_rooms')
      .doc(roomId).snapshots()
      .map((s) => s.exists ? GameRoomModel.fromMap(s.id, s.data()!) : null);

  Stream<List<GamePlayer>> playersStream(String roomId) => _db.collection('game_rooms')
      .doc(roomId).collection('players').orderBy('joinedAt').snapshots()
      .map((s) => s.docs.map((d) => GamePlayer.fromMap(d.data())).toList());

  // ── Pick question ─────────────────────────────────────────────
  GameQuestion pickQuestion(QuestionType type, List<String> usedIds) {
    final pool = QuestionBank.all.where((q) => q.type == type && !usedIds.contains(q.id)).toList();
    if (pool.isEmpty) {
      final all = QuestionBank.all.where((q) => q.type == type).toList();
      return all[Random().nextInt(all.length)];
    }
    return pool[Random().nextInt(pool.length)];
  }
}