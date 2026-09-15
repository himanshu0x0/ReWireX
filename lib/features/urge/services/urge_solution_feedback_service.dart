// lib/features/urge/services/urge_solution_feedback_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/urge_session_model.dart';
import '../models/urge_solution_model.dart';

/// Stores completed solution outcomes so the future personalization layer can
/// learn which kinds of actions reduce this user's urges in similar contexts.
class UrgeSolutionFeedbackService {
  UrgeSolutionFeedbackService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> record({
    required UrgeSessionModel session,
    required UrgeSolutionAction action,
    required int urgeAfter,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final before = (session.urgeBefore ?? 5).clamp(1, 10);
    final after = urgeAfter.clamp(0, 10);
    final reduction = before - after;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('intervention_feedback')
        .add({
      'emotion': session.emotion,
      'intensity': before,
      'technique': action.id,
      'wasEffective': reduction > 0,
      'timestamp': FieldValue.serverTimestamp(),
      'sessionDurationSeconds': session.duration?.inSeconds ?? 0,
      'stepsCompleted': action.type == UrgeSolutionActionType.guidedRescue ? 1 : 0,
      'totalSteps': 1,
      'riskLevel': 'Low',
      'intensityAfter': after,
      'urgeType': session.urgeType.name,
      'selectedNeed': session.selectedNeed?.name,
      'rescuePath': session.rescuePath.name,
      'interventionId': session.interventionId,
      'urgeBefore': before,
      'urgeAfter': after,
      'urgeOutcome': session.outcome.name,
      'urgeReduction': reduction,
      'urgeReductionRatio': before > 0 ? (reduction / before).clamp(0.0, 1.0) : 0.0,
      'solutionActionType': action.type.name,
    });
  }
}
