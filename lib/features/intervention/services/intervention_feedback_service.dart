// lib/features/intervention/services/intervention_feedback_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/intervention_feedback_model.dart';

/// 💾 Saves intervention session feedback to Firestore.
/// The richer data is used by InterventionRankingService for
/// better personalization over time.
class InterventionFeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveFeedback(InterventionFeedbackModel feedback) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final map = feedback.toMap();

    // Convert DateTime → Timestamp for Firestore
    map['timestamp'] = Timestamp.fromDate(feedback.timestamp);

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('intervention_feedback')
        .add(map);
  }
}