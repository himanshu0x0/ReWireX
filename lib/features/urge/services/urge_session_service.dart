import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/urge_types.dart';
import '../models/urge_session_model.dart';

/// Firestore persistence for complete Urge Rescue sessions.
///
/// Collection:
/// users/{uid}/urge_sessions/{sessionId}
///
/// The service keeps the rescue journey separate from the older `urge_logs`
/// collection. An urge log records the event; an urge session records what
/// happened after that event: need, intervention, recheck, and outcome.
class UrgeSessionService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  UrgeSessionService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _sessions {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('User must be authenticated.');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('urge_sessions');
  }

  DocumentReference<Map<String, dynamic>> _sessionRef(String sessionId) {
    return _sessions.doc(sessionId);
  }

  /// Creates or replaces the complete session document.
  Future<void> createSession(UrgeSessionModel session) async {
    _validateOwnership(session);

    final data = session.toMap();

    await _sessionRef(session.id).set(
      _withServerTimestamps(
        data,
        includeCreatedAt: true,
      ),
    );
  }

  /// Updates only the fields that are allowed to change during a rescue.
  ///
  /// This is useful after:
  /// - selecting a need,
  /// - selecting an intervention,
  /// - starting the intervention,
  /// - completing the intervention,
  /// - recording the recheck.
  Future<void> updateSession(UrgeSessionModel session) async {
    _validateOwnership(session);

    final data = session.toServerUpdateMap();

    await _sessionRef(session.id).set(
      _withServerTimestamps(
        data,
        includeCreatedAt: false,
      ),
      SetOptions(merge: true),
    );
  }

  /// Creates the session if it does not exist; otherwise merges the update.
  Future<void> saveSession(UrgeSessionModel session) async {
    _validateOwnership(session);

    final ref = _sessionRef(session.id);
    final snapshot = await ref.get();

    if (snapshot.exists) {
      await updateSession(session);
    } else {
      await createSession(session);
    }
  }

  /// Reads one session.
  Future<UrgeSessionModel?> getSession(String sessionId) async {
    final snapshot = await _sessionRef(sessionId).get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return UrgeSessionModel.fromMap(
      snapshot.id,
      snapshot.data()!,
    );
  }

  /// Real-time stream of one rescue session.
  Stream<UrgeSessionModel?> watchSession(String sessionId) {
    return _sessionRef(sessionId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }

      return UrgeSessionModel.fromMap(
        snapshot.id,
        snapshot.data()!,
      );
    });
  }

  /// Reads recent rescue sessions.
  ///
  /// The default query avoids requiring a Firestore composite index.
  Future<List<UrgeSessionModel>> getRecentSessions({
    int limit = 30,
  }) async {
    final safeLimit = limit.clamp(1, 100);

    final snapshot = await _sessions
        .orderBy('startedAt', descending: true)
        .limit(safeLimit)
        .get();

    return snapshot.docs
        .map(
          (doc) => UrgeSessionModel.fromMap(
            doc.id,
            doc.data(),
          ),
        )
        .toList();
  }

  /// Stream of recent rescue sessions.
  Stream<List<UrgeSessionModel>> watchRecentSessions({
    int limit = 30,
  }) {
    final safeLimit = limit.clamp(1, 100);

    return _sessions
        .orderBy('startedAt', descending: true)
        .limit(safeLimit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => UrgeSessionModel.fromMap(
                  doc.id,
                  doc.data(),
                ),
              )
              .toList(),
        );
  }

  /// Returns sessions that finished with a useful result.
  Future<List<UrgeSessionModel>> getCompletedSessions({
    int limit = 30,
  }) async {
    final sessions = await getRecentSessions(limit: limit);

    return sessions
        .where(
          (session) =>
              session.status == UrgeSessionStatus.completed ||
              session.status == UrgeSessionStatus.escalated,
        )
        .toList();
  }

  /// Returns sessions for one intervention.
  Future<List<UrgeSessionModel>> getSessionsForIntervention(
    String interventionId, {
    int limit = 50,
  }) async {
    final sessions = await getRecentSessions(limit: limit);

    return sessions
        .where((session) => session.interventionId == interventionId)
        .toList();
  }

  /// Returns sessions for one urge type.
  Future<List<UrgeSessionModel>> getSessionsForUrgeType(
    UrgeType urgeType, {
    int limit = 50,
  }) async {
    final sessions = await getRecentSessions(limit: limit);

    return sessions
        .where((session) => session.urgeType == urgeType)
        .toList();
  }

  /// Deletes a session.
  ///
  /// This only removes rescue-session history. It does not touch the separate
  /// `urge_logs` event or streak data.
  Future<void> deleteSession(String sessionId) async {
    await _sessionRef(sessionId).delete();
  }

  /// Deletes several sessions by id.
  Future<void> deleteSessions(Iterable<String> sessionIds) async {
    final ids = sessionIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (ids.isEmpty) return;

    for (var start = 0; start < ids.length; start += 450) {
      final end = (start + 450).clamp(0, ids.length);
      final batch = _firestore.batch();

      for (final id in ids.sublist(start, end)) {
        batch.delete(_sessionRef(id));
      }

      await batch.commit();
    }
  }

  /// Basic aggregate metrics for intervention personalization.
  Future<UrgeSessionStats> getStats({
    int limit = 100,
  }) async {
    final sessions = await getRecentSessions(limit: limit);

    if (sessions.isEmpty) {
      return const UrgeSessionStats.empty();
    }

    var completed = 0;
    var reduced = 0;
    var resolved = 0;
    var unchanged = 0;
    var stronger = 0;
    var escalated = 0;

    final interventionCounts = <String, int>{};
    final interventionSuccesses = <String, int>{};

    for (final session in sessions) {
      if (session.status == UrgeSessionStatus.completed ||
          session.status == UrgeSessionStatus.escalated) {
        completed++;
      }

      switch (session.outcome) {
        case UrgeOutcome.resolved:
          resolved++;
          break;
        case UrgeOutcome.reduced:
          reduced++;
          break;
        case UrgeOutcome.unchanged:
          unchanged++;
          break;
        case UrgeOutcome.stronger:
          stronger++;
          break;
        case UrgeOutcome.escalated:
          escalated++;
          break;
        case UrgeOutcome.unknown:
          break;
      }

      final interventionId = session.interventionId;

      if (interventionId != null && interventionId.trim().isNotEmpty) {
        interventionCounts[interventionId] =
            (interventionCounts[interventionId] ?? 0) + 1;

        if (session.outcome == UrgeOutcome.resolved ||
            session.outcome == UrgeOutcome.reduced) {
          interventionSuccesses[interventionId] =
              (interventionSuccesses[interventionId] ?? 0) + 1;
        }
      }
    }

    return UrgeSessionStats(
      totalSessions: sessions.length,
      completedSessions: completed,
      resolvedSessions: resolved,
      reducedSessions: reduced,
      unchangedSessions: unchanged,
      strongerSessions: stronger,
      escalatedSessions: escalated,
      interventionUsage: Map.unmodifiable(interventionCounts),
      interventionSuccesses: Map.unmodifiable(interventionSuccesses),
    );
  }

  Map<String, dynamic> _withServerTimestamps(
    Map<String, dynamic> data, {
    required bool includeCreatedAt,
  }) {
    final result = Map<String, dynamic>.from(data);

    result['updatedAt'] = FieldValue.serverTimestamp();

    if (includeCreatedAt) {
      result['createdAt'] = FieldValue.serverTimestamp();
    }

    return result;
  }

  void _validateOwnership(UrgeSessionModel session) {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('User must be authenticated.');
    }

    if (session.userId != user.uid) {
      throw StateError(
        'Urge session userId does not match the authenticated user.',
      );
    }
  }
}

/// Lightweight analytics derived from rescue-session history.
class UrgeSessionStats {
  final int totalSessions;
  final int completedSessions;
  final int resolvedSessions;
  final int reducedSessions;
  final int unchangedSessions;
  final int strongerSessions;
  final int escalatedSessions;
  final Map<String, int> interventionUsage;
  final Map<String, int> interventionSuccesses;

  const UrgeSessionStats({
    required this.totalSessions,
    required this.completedSessions,
    required this.resolvedSessions,
    required this.reducedSessions,
    required this.unchangedSessions,
    required this.strongerSessions,
    required this.escalatedSessions,
    required this.interventionUsage,
    required this.interventionSuccesses,
  });

  const UrgeSessionStats.empty()
      : totalSessions = 0,
        completedSessions = 0,
        resolvedSessions = 0,
        reducedSessions = 0,
        unchangedSessions = 0,
        strongerSessions = 0,
        escalatedSessions = 0,
        interventionUsage = const {},
        interventionSuccesses = const {};

  double get completionRate {
    if (totalSessions == 0) return 0;
    return completedSessions / totalSessions;
  }

  double get helpfulRate {
    if (completedSessions == 0) return 0;
    return (resolvedSessions + reducedSessions) / completedSessions;
  }

  String? get mostUsedIntervention {
    if (interventionUsage.isEmpty) return null;

    return interventionUsage.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  String? get mostHelpfulIntervention {
    if (interventionSuccesses.isEmpty) return null;

    return interventionSuccesses.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }
}
