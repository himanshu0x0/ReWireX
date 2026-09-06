import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/game_room_model.dart';
import '../models/game_question_model.dart';

class GameRoomService {
  final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>>
      get _rooms =>
          _db.collection('game_rooms');

  String get _uid {
    final uid = _auth.currentUser?.uid;

    if (uid == null || uid.isEmpty) {
      throw StateError(
        'You must be logged in to play.',
      );
    }

    return uid;
  }

  // ============================================================
  // CREATE ROOM
  // ============================================================

  Future<GameRoomModel> createRoom({
    required String name,
    required GameRoomType type,
    required String anonName,
    required String emoji,
    String category = 'mixed',
    int maxPlayers = 8,
    int totalRounds = 10,
  }) async {
    final uid = _uid;
    final now = DateTime.now();

    final safeMaxPlayers =
        maxPlayers.clamp(2, 12).toInt();

    final safeRounds =
        totalRounds.clamp(1, 50).toInt();

    final roomRef = _rooms.doc();

    String? roomCode;

    if (type == GameRoomType.private) {
      roomCode = _generateRoomCode();
    }

    final room = GameRoomModel(
      id: roomRef.id,
      name: name.trim(),
      type: type,
      status: GameRoomStatus.waiting,

      hostUid: uid,
      hostName: anonName.trim(),

      roomCode: roomCode,

      maxPlayers: safeMaxPlayers,

      playerCount: 1,

      playerUids: [uid],

      category: category,

      currentTurnUid: uid,
      currentTurnName: anonName.trim(),

      roundNumber: 0,

      totalRounds: safeRounds,

      createdAt: now,
      lastActivity: now,

      // THIS IS CRITICAL.
      isActive: true,
    );

    final playerRef =
        roomRef.collection('players').doc(uid);

    final player = GamePlayer(
      uid: uid,
      anonName: anonName.trim(),
      emoji: emoji,
      isHost: true,
      isOnline: true,
      score: 0,
      joinedAt: now,
    );

    // Create room + first player atomically.
    final batch = _db.batch();

    batch.set(
      roomRef,
      room.toMap(),
    );

    batch.set(
      playerRef,
      player.toMap(),
    );

    await batch.commit();

    // Verify the room actually exists before returning.
    final verify =
        await roomRef.get();

    if (!verify.exists ||
        verify.data() == null) {
      throw StateError(
        'Room was created but could not be loaded.',
      );
    }

    return GameRoomModel.fromMap(
      roomRef.id,
      verify.data()!,
    );
  }

  // ============================================================
  // JOIN PUBLIC/ROOM BY ID
  // ============================================================

  Future<bool> joinRoom(
    String roomId,
    String anonName,
    String emoji,
  ) async {
    final uid = _uid;

    final roomRef =
        _rooms.doc(roomId);

    final playerRef =
        roomRef.collection('players').doc(uid);

    return _db.runTransaction<bool>(
      (transaction) async {
        final roomSnap =
            await transaction.get(roomRef);

        if (!roomSnap.exists ||
            roomSnap.data() == null) {
          return false;
        }

        final room =
            GameRoomModel.fromMap(
          roomSnap.id,
          roomSnap.data()!,
        );

        if (!room.isActive) {
          return false;
        }

        if (room.status !=
            GameRoomStatus.waiting) {
          return false;
        }

        if (room.isFull &&
            !room.playerUids.contains(uid)) {
          return false;
        }

        // Already joined.
        if (room.playerUids.contains(uid)) {
          final playerSnap =
              await transaction.get(
            playerRef,
          );

          if (!playerSnap.exists) {
            transaction.set(
              playerRef,
              GamePlayer(
                uid: uid,
                anonName: anonName.trim(),
                emoji: emoji,
                isHost:
                    room.hostUid == uid,
                joinedAt: DateTime.now(),
              ).toMap(),
            );
          }

          return true;
        }

        final now = DateTime.now();

        final updatedUids = [
          ...room.playerUids,
          uid,
        ];

        transaction.update(
          roomRef,
          {
            'playerUids': updatedUids,
            'playerCount':
                updatedUids.length,
            'lastActivity':
                Timestamp.fromDate(now),
          },
        );

        transaction.set(
          playerRef,
          GamePlayer(
            uid: uid,
            anonName: anonName.trim(),
            emoji: emoji,
            isHost: false,
            joinedAt: now,
          ).toMap(),
        );

        return true;
      },
    );
  }

  // ============================================================
  // JOIN PRIVATE ROOM BY CODE
  // ============================================================

  Future<GameRoomModel?> joinByCode(
    String code,
    String anonName,
    String emoji,
  ) async {
    final normalized =
        code.trim().toUpperCase();

    if (normalized.length != 6) {
      return null;
    }

    final result = await _rooms
        .where(
          'roomCode',
          isEqualTo: normalized,
        )
        .limit(1)
        .get();

    if (result.docs.isEmpty) {
      return null;
    }

    final doc = result.docs.first;

    final room =
        GameRoomModel.fromMap(
      doc.id,
      doc.data(),
    );

    if (!room.isActive ||
        room.type != GameRoomType.private ||
        room.status !=
            GameRoomStatus.waiting ||
        room.isFull) {
      return null;
    }

    final joined =
        await joinRoom(
      room.id,
      anonName,
      emoji,
    );

    if (!joined) {
      return null;
    }

    final updated =
        await roomStream(room.id).first;

    return updated;
  }

  // ============================================================
  // START GAME
  // ============================================================

  Future<void> startGame(
    String roomId,
  ) async {
    final uid = _uid;

    final roomRef =
        _rooms.doc(roomId);

    await _db.runTransaction(
      (transaction) async {
        final snap =
            await transaction.get(roomRef);

        if (!snap.exists ||
            snap.data() == null) {
          throw StateError(
            'Room no longer exists.',
          );
        }

        final room =
            GameRoomModel.fromMap(
          snap.id,
          snap.data()!,
        );

        if (room.hostUid != uid) {
          throw StateError(
            'Only the host can start the game.',
          );
        }

        if (!room.canStart) {
          throw StateError(
            'At least 2 players are required.',
          );
        }

        transaction.update(
          roomRef,
          {
            'status':
                GameRoomStatus.playing.name,
            'roundNumber': 1,
            'currentTurnUid':
                room.playerUids.first,
            'currentTurnName':
                room.hostName,
            'lastActivity':
                Timestamp.now(),
          },
        );
      },
    );
  }

  // ============================================================
  // COMPLETE TURN
  // ============================================================

  Future<void> completeTurn({
    required String roomId,
    required bool completed,
    required String questionText,
    required QuestionType questionType,
  }) async {
    final uid = _uid;

    final roomRef =
        _rooms.doc(roomId);

    await _db.runTransaction(
      (transaction) async {
        final roomSnap =
            await transaction.get(roomRef);

        if (!roomSnap.exists ||
            roomSnap.data() == null) {
          throw StateError(
            'Room no longer exists.',
          );
        }

        final room =
            GameRoomModel.fromMap(
          roomSnap.id,
          roomSnap.data()!,
        );

        if (room.status !=
            GameRoomStatus.playing) {
          throw StateError(
            'Game is not currently playing.',
          );
        }

        if (room.currentTurnUid != uid) {
          throw StateError(
            'It is not your turn.',
          );
        }

        final playerRefs =
            room.playerUids.map(
          (playerUid) =>
              roomRef
                  .collection('players')
                  .doc(playerUid),
        );

        final playerSnapshots =
            <DocumentSnapshot<
                Map<String, dynamic>>>[];

        for (final ref in playerRefs) {
          playerSnapshots.add(
            await transaction.get(ref),
          );
        }

        final players =
            playerSnapshots
                .where(
                  (s) =>
                      s.exists &&
                      s.data() != null,
                )
                .map(
                  (s) =>
                      GamePlayer.fromMap(
                    s.data()!,
                  ),
                )
                .toList()
              ..sort(
                (a, b) =>
                    a.joinedAt.compareTo(
                  b.joinedAt,
                ),
              );

        if (players.length < 2) {
          throw StateError(
            'At least 2 players are required.',
          );
        }

        final currentIndex =
            players.indexWhere(
          (p) => p.uid == uid,
        );

        if (currentIndex < 0) {
          throw StateError(
            'Current player not found.',
          );
        }

        final nextIndex =
            (currentIndex + 1) %
                players.length;

        final nextPlayer =
            players[nextIndex];

        final nextRound =
            nextIndex == 0
                ? room.roundNumber + 1
                : room.roundNumber;

        final turnRef =
            roomRef
                .collection('turns')
                .doc();

        transaction.set(
          turnRef,
          {
            'uid': uid,
            'question': questionText,
            'type': questionType.name,
            'completed': completed,
            'round':
                room.roundNumber,
            'timestamp':
                Timestamp.now(),
          },
        );

        if (completed) {
          final currentPlayer =
              players[currentIndex];

          transaction.update(
            roomRef
                .collection('players')
                .doc(uid),
            {
              'score':
                  currentPlayer.score + 1,
            },
          );
        }

        if (nextRound >
            room.totalRounds) {
          transaction.update(
            roomRef,
            {
              'status':
                  GameRoomStatus.finished.name,
              'lastActivity':
                  Timestamp.now(),
            },
          );

          return;
        }

        transaction.update(
          roomRef,
          {
            'currentTurnUid':
                nextPlayer.uid,
            'currentTurnName':
                nextPlayer.anonName,
            'roundNumber':
                nextRound,
            'lastActivity':
                Timestamp.now(),
          },
        );
      },
    );
  }

  // ============================================================
  // LEAVE ROOM
  // ============================================================
  //
  // IMPORTANT:
  //
  // If host leaves and other players remain:
  //     first remaining player becomes host.
  //
  // If last player leaves:
  //     entire room is deleted.
  //
  // Therefore the public lobby automatically removes it.
  // ============================================================

  Future<void> leaveRoom(
    String roomId,
  ) async {
    final uid = _uid;

    final roomRef =
        _rooms.doc(roomId);

    final myPlayerRef =
        roomRef
            .collection('players')
            .doc(uid);

    await _db.runTransaction(
      (transaction) async {
        // READ FIRST.
        final roomSnap =
            await transaction.get(roomRef);

        if (!roomSnap.exists ||
            roomSnap.data() == null) {
          return;
        }

        final room =
            GameRoomModel.fromMap(
          roomSnap.id,
          roomSnap.data()!,
        );

        if (!room.playerUids.contains(uid)) {
          return;
        }

        final remaining =
            room.playerUids
                .where(
                  (id) => id != uid,
                )
                .toList();

        // --------------------------------------------------------
        // LAST PLAYER LEAVES
        // --------------------------------------------------------

        if (remaining.isEmpty) {
          transaction.delete(
            myPlayerRef,
          );

          transaction.delete(
            roomRef,
          );

          return;
        }

        // --------------------------------------------------------
        // HOST LEAVES
        // --------------------------------------------------------

        if (room.hostUid == uid) {
          // Read remaining player documents BEFORE any writes.
          final candidateRefs =
              remaining.map(
            (playerUid) =>
                roomRef
                    .collection('players')
                    .doc(playerUid),
          );

          final candidateSnapshots =
              <DocumentSnapshot<
                  Map<String, dynamic>>>[];

          for (final ref in candidateRefs) {
            candidateSnapshots.add(
              await transaction.get(ref),
            );
          }

          final candidates =
              candidateSnapshots
                  .where(
                    (s) =>
                        s.exists &&
                        s.data() != null,
                  )
                  .map(
                    (s) =>
                        GamePlayer.fromMap(
                      s.data()!,
                    ),
                  )
                  .toList()
                ..sort(
                  (a, b) =>
                      a.joinedAt.compareTo(
                    b.joinedAt,
                  ),
                );

          if (candidates.isEmpty) {
            transaction.delete(
              myPlayerRef,
            );

            transaction.delete(
              roomRef,
            );

            return;
          }

          final newHost =
              candidates.first;

          String nextTurnUid =
              room.currentTurnUid;

          String nextTurnName =
              room.currentTurnName;

          if (room.currentTurnUid ==
              uid) {
            nextTurnUid =
                newHost.uid;

            nextTurnName =
                newHost.anonName;
          }

          // Remove old host.
          transaction.delete(
            myPlayerRef,
          );

          // Promote new host in room document.
          //
          // We intentionally DON'T update the new player's
          // isHost field here. The game uses room.hostUid as
          // the authoritative host value.
          transaction.update(
            roomRef,
            {
              'hostUid':
                  newHost.uid,

              'hostName':
                  newHost.anonName,

              'playerUids':
                  remaining,

              'playerCount':
                  remaining.length,

              'currentTurnUid':
                  nextTurnUid,

              'currentTurnName':
                  nextTurnName,

              'lastActivity':
                  Timestamp.now(),
            },
          );

          return;
        }

        // --------------------------------------------------------
        // NORMAL PLAYER LEAVES
        // --------------------------------------------------------

        transaction.delete(
          myPlayerRef,
        );

        String nextTurnUid =
            room.currentTurnUid;

        String nextTurnName =
            room.currentTurnName;

        if (room.currentTurnUid ==
            uid) {
          final nextPlayerRef =
              roomRef
                  .collection('players')
                  .doc(remaining.first);

          final nextPlayerSnap =
              await transaction.get(
            nextPlayerRef,
          );

          nextTurnUid =
              remaining.first;

          if (nextPlayerSnap.exists &&
              nextPlayerSnap.data() !=
                  null) {
            nextTurnName =
                nextPlayerSnap.data()![
                    'anonName'] as String? ??
                'Player';
          }
        }

        transaction.update(
          roomRef,
          {
            'playerUids':
                remaining,

            'playerCount':
                remaining.length,

            'currentTurnUid':
                nextTurnUid,

            'currentTurnName':
                nextTurnName,

            'lastActivity':
                Timestamp.now(),
          },
        );
      },
    );
  }

  // ============================================================
  // PUBLIC ROOMS STREAM
  // ============================================================

  Stream<List<GameRoomModel>>
      publicRoomsStream() {
    return _rooms
        .where(
          'isActive',
          isEqualTo: true,
        )
        .snapshots()
        .map(
          (snapshot) {
            final rooms =
                snapshot.docs
                    .map(
                      (doc) =>
                          GameRoomModel.fromMap(
                        doc.id,
                        doc.data(),
                      ),
                    )
                    .where(
                      (room) =>
                          room.isActive &&
                          room.type ==
                              GameRoomType.public &&
                          room.status ==
                              GameRoomStatus.waiting &&
                          room.playerCount > 0 &&
                          room.playerUids
                              .isNotEmpty &&
                          room.hostUid.isNotEmpty &&
                          !room.isFull,
                    )
                    .toList();

            rooms.sort(
              (a, b) =>
                  b.lastActivity.compareTo(
                a.lastActivity,
              ),
            );

            return rooms;
          },
        );
  }

  // ============================================================
  // ROOM STREAM
  // ============================================================

  Stream<GameRoomModel?> roomStream(
    String roomId,
  ) {
    return _rooms
        .doc(roomId)
        .snapshots()
        .map(
          (snapshot) {
            if (!snapshot.exists ||
                snapshot.data() == null) {
              return null;
            }

            return GameRoomModel.fromMap(
              snapshot.id,
              snapshot.data()!,
            );
          },
        );
  }

  // ============================================================
  // PLAYERS STREAM
  // ============================================================

  Stream<List<GamePlayer>> playersStream(
    String roomId,
  ) {
    return _rooms
        .doc(roomId)
        .collection('players')
        .orderBy('joinedAt')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) =>
                        GamePlayer.fromMap(
                      doc.data(),
                    ),
                  )
                  .toList(),
        );
  }

  // ============================================================
  // QUESTION PICKER
  // ============================================================

  GameQuestion pickQuestion(
    QuestionType type,
    List<String> usedIds,
  ) {
    final available =
        QuestionBank.all
            .where(
              (q) =>
                  q.type == type &&
                  !usedIds.contains(q.id),
            )
            .toList();

    if (available.isEmpty) {
      final fallback =
          QuestionBank.all
              .where(
                (q) => q.type == type,
              )
              .toList();

      return fallback[
        Random.secure().nextInt(
          fallback.length,
        )
      ];
    }

    return available[
      Random.secure().nextInt(
        available.length,
      )
    ];
  }

  // ============================================================
  // PRIVATE ROOM CODE
  // ============================================================

  String _generateRoomCode() {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

    final random = Random.secure();

    return List.generate(
      6,
      (_) => chars[
          random.nextInt(
            chars.length,
          )
        ],
    ).join();
  }
}