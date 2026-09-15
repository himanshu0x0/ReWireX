// ============================================================
// PATH: lib/features/connect/chat/services/presence_service.dart
// ============================================================

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

/// App-wide presence.
///
/// Firestore is used as the source of truth. A heartbeat prevents an old
/// `isOnline: true` value from living forever after a crash/force-close.
/// UI also treats presence as offline when `lastSeenAt` is older than 75s.
class PresenceService with WidgetsBindingObserver {
  PresenceService._();
  static final PresenceService instance = PresenceService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Timer? _heartbeat;
  bool _started = false;
  bool _online = false;

  String? get _uid => _auth.currentUser?.uid;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    await setOnline(true);
    _heartbeat = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_online) setOnline(true);
    });
  }

  Future<void> setOnline(bool online) async {
    final uid = _uid;
    if (uid == null) return;
    _online = online;
    try {
      await _db.collection('users').doc(uid).set({
        'isOnline': online,
        'lastSeenAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        setOnline(true);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        setOnline(false);
        break;
      case AppLifecycleState.hidden:
        setOnline(false);
        break;
    }
  }

  Future<void> stop() async {
    _heartbeat?.cancel();
    _heartbeat = null;
    if (_started) {
      WidgetsBinding.instance.removeObserver(this);
    }
    _started = false;
    await setOnline(false);
  }
}
