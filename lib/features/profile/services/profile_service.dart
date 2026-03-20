// lib/features/profile/services/profile_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 👤 Profile Model
class ProfileModel {
  final String uid;
  final String email;
  final String displayName;
  final String username;
  final String bio;
  final String photoUrl;
  final String recoveryGoal;       // e.g. "90 days clean"
  final String addictionType;      // e.g. "Alcohol", "Pornography"
  final String sobrietyStartDate;  // ISO string
  final String gender;
  final String dateOfBirth;
  final String country;
  final String phone;
  final bool notificationsEnabled;
  final bool guardianModeEnabled;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProfileModel({
    required this.uid,
    required this.email,
    this.displayName       = '',
    this.username          = '',
    this.bio               = '',
    this.photoUrl          = '',
    this.recoveryGoal      = '',
    this.addictionType     = '',
    this.sobrietyStartDate = '',
    this.gender            = '',
    this.dateOfBirth       = '',
    this.country           = '',
    this.phone             = '',
    this.notificationsEnabled = true,
    this.guardianModeEnabled  = true,
    this.createdAt         = null,
    this.updatedAt         = null,
  });

  /// Completion score 0–100.
  /// Each completed field contributes a weighted share.
  int get completionScore {
    final fields = <String, int>{
      displayName:       15,
      username:          10,
      bio:               10,
      recoveryGoal:      15,
      addictionType:     15,
      sobrietyStartDate: 10,
      gender:            5,
      dateOfBirth:       5,
      country:           5,
      phone:             5,
      photoUrl:          5,
    };
    int score = 0;
    fields.forEach((value, weight) {
      if (value.trim().isNotEmpty) score += weight;
    });
    return score.clamp(0, 100);
  }

  /// Fields still empty — used to show specific prompts.
  List<String> get missingFields {
    final out = <String>[];
    if (displayName.isEmpty)       out.add('Full name');
    if (username.isEmpty)          out.add('Username');
    if (bio.isEmpty)               out.add('Bio');
    if (recoveryGoal.isEmpty)      out.add('Recovery goal');
    if (addictionType.isEmpty)     out.add('Addiction type');
    if (sobrietyStartDate.isEmpty) out.add('Sobriety start date');
    if (photoUrl.isEmpty)          out.add('Profile photo');
    return out;
  }

  factory ProfileModel.fromMap(Map<String, dynamic> data, String uid) {
    return ProfileModel(
      uid:               uid,
      email:             (data['email']             as String?) ?? '',
      displayName:       (data['displayName']        as String?) ?? '',
      username:          (data['username']           as String?) ?? '',
      bio:               (data['bio']                as String?) ?? '',
      photoUrl:          (data['photoUrl']           as String?) ?? '',
      recoveryGoal:      (data['recoveryGoal']       as String?) ?? '',
      addictionType:     (data['addictionType']      as String?) ?? '',
      sobrietyStartDate: (data['sobrietyStartDate']  as String?) ?? '',
      gender:            (data['gender']             as String?) ?? '',
      dateOfBirth:       (data['dateOfBirth']        as String?) ?? '',
      country:           (data['country']            as String?) ?? '',
      phone:             (data['phone']              as String?) ?? '',
      notificationsEnabled: (data['notificationsEnabled'] as bool?) ?? true,
      guardianModeEnabled:  (data['guardianModeEnabled']  as bool?) ?? true,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate() : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'email':               email,
    'displayName':         displayName,
    'username':            username,
    'bio':                 bio,
    'photoUrl':            photoUrl,
    'recoveryGoal':        recoveryGoal,
    'addictionType':       addictionType,
    'sobrietyStartDate':   sobrietyStartDate,
    'gender':              gender,
    'dateOfBirth':         dateOfBirth,
    'country':             country,
    'phone':               phone,
    'notificationsEnabled':notificationsEnabled,
    'guardianModeEnabled': guardianModeEnabled,
    'updatedAt':           Timestamp.now(),
  };

  ProfileModel copyWith({
    String? displayName, String? username, String? bio, String? photoUrl,
    String? recoveryGoal, String? addictionType, String? sobrietyStartDate,
    String? gender, String? dateOfBirth, String? country, String? phone,
    bool? notificationsEnabled, bool? guardianModeEnabled,
  }) => ProfileModel(
    uid:               uid,
    email:             email,
    displayName:       displayName       ?? this.displayName,
    username:          username          ?? this.username,
    bio:               bio               ?? this.bio,
    photoUrl:          photoUrl          ?? this.photoUrl,
    recoveryGoal:      recoveryGoal      ?? this.recoveryGoal,
    addictionType:     addictionType     ?? this.addictionType,
    sobrietyStartDate: sobrietyStartDate ?? this.sobrietyStartDate,
    gender:            gender            ?? this.gender,
    dateOfBirth:       dateOfBirth       ?? this.dateOfBirth,
    country:           country           ?? this.country,
    phone:             phone             ?? this.phone,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    guardianModeEnabled:  guardianModeEnabled  ?? this.guardianModeEnabled,
    createdAt:         createdAt,
    updatedAt:         updatedAt,
  );
}

/// 👤 Profile Service
class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth      _auth      = FirebaseAuth.instance;

  DocumentReference<Map<String, dynamic>> get _ref {
    final uid = _auth.currentUser!.uid;
    return _firestore.collection('users').doc(uid);
  }

  /// Real-time stream of the current user's profile.
  Stream<ProfileModel?> getProfile() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);
    return _ref.snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return ProfileModel.fromMap(snap.data()!, user.uid);
    });
  }

  /// One-shot fetch.
  Future<ProfileModel?> fetchProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final snap = await _ref.get();
    if (!snap.exists || snap.data() == null) return null;
    return ProfileModel.fromMap(snap.data()!, user.uid);
  }

  /// Save / merge profile fields.
  Future<void> saveProfile(ProfileModel profile) async {
    final map = profile.toMap();
    // Preserve createdAt if already set
    await _ref.set({'createdAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true));
    await _ref.set(map, SetOptions(merge: true));
  }

  /// Update a single field without loading the whole profile.
  Future<void> updateField(String field, dynamic value) async {
    await _ref.update({field: value, 'updatedAt': Timestamp.now()});
  }

  /// Delete account data (does NOT delete Firebase Auth user — handle separately).
  Future<void> deleteAccountData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).delete();
  }
}