// ============================================================
// PATH: lib/features/connect/rooms/services/room_service.dart
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/room_model.dart';

class RoomService {
  final FirebaseFirestore _db   = FirebaseFirestore.instance;
  final FirebaseAuth      _auth = FirebaseAuth.instance;
  String get _uid => _auth.currentUser?.uid ?? '';

  Future<void> seedRoomsIfNeeded() async {
    if ((await _db.collection('chat_rooms').limit(1).get()).docs.isNotEmpty) return;
    final b = _db.batch();
    for (final r in _rooms) b.set(_db.collection('chat_rooms').doc(), r.toMap());
    await b.commit();
  }

  Stream<List<RoomModel>> allStream() => _db.collection('chat_rooms')
      .orderBy('onlineCount', descending: true).snapshots()
      .map((s) => s.docs.map((d) => RoomModel.fromMap(d.id, d.data())).toList());

  Stream<List<RoomModel>> byCategoryStream(RoomCategory cat) => _db
      .collection('chat_rooms').where('category', isEqualTo: cat.name)
      .orderBy('onlineCount', descending: true).snapshots()
      .map((s) => s.docs.map((d) => RoomModel.fromMap(d.id, d.data())).toList());

  Future<void> joinRoom(String roomId, String name) async {
    final roomRef = _db.collection('chat_rooms').doc(roomId);
    final memberRef = roomRef.collection('room_members').doc(_uid);

    await _db.runTransaction((tx) async {
      final member = await tx.get(memberRef);
      tx.set(memberRef, {
        'uid': _uid,
        'anonName': name,
        'isOnline': true,
        'lastSeenAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!member.exists || member.data()?['isOnline'] != true) {
        tx.update(roomRef, {'onlineCount': FieldValue.increment(1)});
      }
    });
    await _sys(roomId, '$name joined the room 👋');
  }

  Future<void> heartbeatRoom(String roomId, String name) async {
    await _db.collection('chat_rooms').doc(roomId)
        .collection('room_members').doc(_uid).set({
      'uid': _uid,
      'anonName': name,
      'isOnline': true,
      'lastSeenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> leaveRoom(String roomId) async {
    final roomRef = _db.collection('chat_rooms').doc(roomId);
    final memberRef = roomRef.collection('room_members').doc(_uid);
    await _db.runTransaction((tx) async {
      // Firestore transactions require reads before writes.
      final member = await tx.get(memberRef);
      final room = await tx.get(roomRef);
      if (!member.exists) return;
      tx.delete(memberRef);
      final count = (room.data()?['onlineCount'] as num?)?.toInt() ?? 0;
      tx.update(roomRef, {'onlineCount': math.max(0, count - 1)});
    });
  }

  Future<void> sendMessage(String roomId, String name, String text) async {
    if (text.trim().isEmpty) return;
    final b = _db.batch();
    b.set(_db.collection('chat_rooms').doc(roomId).collection('messages').doc(), {
      'senderUid': _uid, 'anonName': name, 'text': text.trim(),
      'timestamp': Timestamp.now(), 'isSystem': false, 'likedBy': [],
    });
    b.update(_db.collection('chat_rooms').doc(roomId),
        {'totalMessages': FieldValue.increment(1), 'lastActivity': Timestamp.now()});
    await b.commit();
  }

  Future<void> toggleLike(String roomId, String msgId) async {
    final ref   = _db.collection('chat_rooms').doc(roomId).collection('messages').doc(msgId);
    final likes = List<String>.from(((await ref.get()).data()?['likedBy'] as List<dynamic>? ?? [])
        .map((e) => e.toString()));
    likes.contains(_uid) ? likes.remove(_uid) : likes.add(_uid);
    await ref.update({'likedBy': likes});
  }

  Stream<List<RoomMessageModel>> messagesStream(String roomId) => _db
      .collection('chat_rooms').doc(roomId).collection('messages')
      .orderBy('timestamp').limitToLast(200).snapshots()
      .map((s) => s.docs.map((d) => RoomMessageModel.fromMap(d.id, d.data(), _uid)).toList());

  Future<void> reportMessage(String roomId, String msgId, String reason) async =>
      _db.collection('reports').add({'roomId': roomId, 'messageId': msgId,
          'reportedBy': _uid, 'reason': reason, 'at': Timestamp.now()});

  Future<void> _sys(String roomId, String text) async =>
      _db.collection('chat_rooms').doc(roomId).collection('messages').add({
        'senderUid': 'system', 'anonName': 'System', 'text': text,
        'timestamp': Timestamp.now(), 'isSystem': true, 'likedBy': [],
      });

  static final _rooms = [
    RoomModel(id:'', name:'No-Fap Warriors', emoji:'⚔️', isPinned:true,
        description:'Safe space for those fighting porn/compulsive behaviour.',
        category:RoomCategory.addiction, categoryTag:'No-Fap', lastActivity:DateTime.now()),
    RoomModel(id:'', name:'Alcohol Free Zone', emoji:'🥤',
        description:'Connecting people on the sobriety journey.',
        category:RoomCategory.addiction, categoryTag:'Alcohol', lastActivity:DateTime.now()),
    RoomModel(id:'', name:'Gaming Detox', emoji:'🎮',
        description:'Breaking free from gaming addiction together.',
        category:RoomCategory.addiction, categoryTag:'Gaming', lastActivity:DateTime.now()),
    RoomModel(id:'', name:'Social Media Cleanse', emoji:'📵',
        description:'Reclaiming real life from infinite scroll.',
        category:RoomCategory.addiction, categoryTag:'Social Media', lastActivity:DateTime.now()),
    RoomModel(id:'', name:'Nicotine Free', emoji:'🚭',
        description:'Quitting nicotine — you don\'t have to do it alone.',
        category:RoomCategory.addiction, categoryTag:'Nicotine', lastActivity:DateTime.now()),
    RoomModel(id:'', name:'Drug Recovery', emoji:'💊',
        description:'Judgement-free zone for substance use recovery.',
        category:RoomCategory.addiction, categoryTag:'Drugs', lastActivity:DateTime.now()),
    RoomModel(id:'', name:'Feeling Lonely', emoji:'🤝', isPinned:true,
        description:'You are not alone in feeling alone.',
        category:RoomCategory.emotion, categoryTag:'Lonely', lastActivity:DateTime.now()),
    RoomModel(id:'', name:'Anxiety Support', emoji:'🧘',
        description:'Calm space for anxiety and stress.',
        category:RoomCategory.emotion, categoryTag:'Anxious', lastActivity:DateTime.now()),
    RoomModel(id:'', name:'Anger Room', emoji:'🔥',
        description:'Vent safely and find healthier outlets.',
        category:RoomCategory.emotion, categoryTag:'Angry', lastActivity:DateTime.now()),
    RoomModel(id:'', name:'Depression Corner', emoji:'🌧️',
        description:'For the heavy days. No toxic positivity.',
        category:RoomCategory.emotion, categoryTag:'Depressed', lastActivity:DateTime.now()),
    RoomModel(id:'', name:'Motivation Station', emoji:'🚀',
        description:'Share energy, wins, and inspire others.',
        category:RoomCategory.emotion, categoryTag:'Motivated', lastActivity:DateTime.now()),
    RoomModel(id:'', name:'Gratitude Space', emoji:'✨',
        description:'Share what you\'re grateful for today.',
        category:RoomCategory.emotion, categoryTag:'Grateful', lastActivity:DateTime.now()),
    RoomModel(id:'', name:'Late Night Lounge', emoji:'🌙', isPinned:true,
        description:'For warriors fighting through the night.',
        category:RoomCategory.timeOfDay, categoryTag:'Late Night', lastActivity:DateTime.now()),
    RoomModel(id:'', name:'Morning Warriors', emoji:'☀️',
        description:'Start your day strong with accountability.',
        category:RoomCategory.timeOfDay, categoryTag:'Morning', lastActivity:DateTime.now()),
    RoomModel(id:'', name:'Afternoon Check-In', emoji:'👋',
        description:'Mid-day accountability. How\'s the day going?',
        category:RoomCategory.timeOfDay, categoryTag:'Afternoon', lastActivity:DateTime.now()),
    RoomModel(id:'', name:'Evening Wind Down', emoji:'🌅',
        description:'Decompress, reflect, and share your wins.',
        category:RoomCategory.timeOfDay, categoryTag:'Evening', lastActivity:DateTime.now()),
  ];
}