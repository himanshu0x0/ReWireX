// lib/features/profile/services/profile_service.dart

import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';   // ← add this line
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;

/// 👤 Profile Model
class ProfileModel {
  final String uid;
  final String email;
  final String displayName;
  final String username;
  final String bio;
  final String photoUrl;       // holds an https:// URL  OR  a base64 data URI
  final String recoveryGoal;
  final String addictionType;
  final String sobrietyStartDate;
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

  /// Returns true when the photo is a remote URL (https://...)
  bool get hasNetworkPhoto =>
      photoUrl.isNotEmpty && photoUrl.startsWith('http');

  /// Returns true when the photo is an inline base64 data URI
  bool get hasBase64Photo =>
      photoUrl.isNotEmpty && photoUrl.startsWith('data:image');

  /// True if any displayable photo is available
  bool get hasPhoto => hasNetworkPhoto || hasBase64Photo;

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

// ─────────────────────────────────────────────────────────────
/// 👤 Profile Service
/// Uses Base64 encoding stored in Firestore — NO Firebase Storage needed.
// ─────────────────────────────────────────────────────────────
class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth      _auth      = FirebaseAuth.instance;

  // Firestore doc limit is 1 MB.
  // We compress to 200×200 JPEG at quality 70 → ~15–40 KB → safe.
  static const int _targetSize   = 200;
  static const int _jpegQuality  = 70;

  // Firestore max document size guard (800 KB to stay well under 1 MB)
  static const int _maxBase64Bytes = 800 * 1024;

  DocumentReference<Map<String, dynamic>> get _ref {
    final uid = _auth.currentUser!.uid;
    return _firestore.collection('users').doc(uid);
  }

  Stream<ProfileModel?> getProfile() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);
    return _ref.snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return ProfileModel.fromMap(snap.data()!, user.uid);
    });
  }

  Future<ProfileModel?> fetchProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final snap = await _ref.get();
    if (!snap.exists || snap.data() == null) return null;
    return ProfileModel.fromMap(snap.data()!, user.uid);
  }

  Future<void> saveProfile(ProfileModel profile) async {
    final map = profile.toMap();
    await _ref.set({'createdAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true));
    await _ref.set(map, SetOptions(merge: true));
  }

  Future<void> updateField(String field, dynamic value) async {
    await _ref.update({field: value, 'updatedAt': Timestamp.now()});
  }

  /// Converts a local image file to a Base64 data URI and saves it
  /// directly in the Firestore user document under [photoUrl].
  ///
  /// Supports jpg, jpeg, png, gif, webp, bmp, heic, heif.
  /// The image is compressed to 200×200 JPEG before encoding so it
  /// always stays well under Firestore's 1 MB document limit.
  ///
  /// Returns the base64 data URI string (starts with "data:image/jpeg;base64,").
  Future<String> uploadProfilePhoto(String localPath) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in.');

    final file = File(localPath);
    if (!await file.exists()) {
      throw Exception('Selected image file not found: $localPath');
    }

    // ── Step 1: Compress to small JPEG ────────────────────
    final ext = p.extension(localPath).toLowerCase();

    // flutter_image_compress supports jpg, png, webp, heic, heif.
    // For gif/bmp we fall back to reading the raw bytes (already small).
    Uint8List compressedBytes;

    if (['.gif', '.bmp'].contains(ext)) {
      // Read raw bytes — GIFs & BMPs are typically small already
      compressedBytes = await file.readAsBytes();
    } else {
      final result = await FlutterImageCompress.compressWithFile(
        localPath,
        minWidth:  _targetSize,
        minHeight: _targetSize,
        quality:   _jpegQuality,
        format:    CompressFormat.jpeg,
      );
      if (result == null) {
        throw Exception('Image compression failed for: $localPath');
      }
      compressedBytes = result;
    }

    // ── Step 2: Guard against oversized result ─────────────
    if (compressedBytes.length > _maxBase64Bytes) {
      throw Exception(
        'Compressed image is too large '
        '(${(compressedBytes.length / 1024).toStringAsFixed(0)} KB). '
        'Please choose a smaller image.',
      );
    }

    // ── Step 3: Encode to Base64 data URI ──────────────────
    final base64Str  = base64Encode(compressedBytes);
    final mimeType   = ['.gif'].contains(ext) ? 'image/gif' : 'image/jpeg';
    final dataUri    = 'data:$mimeType;base64,$base64Str';

    // ── Step 4: Save to Firestore ──────────────────────────
    await updateField('photoUrl', dataUri);

    return dataUri;
  }

  Future<void> deleteAccountData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    // With Base64 approach there's nothing in Storage to clean up
    await _firestore.collection('users').doc(user.uid).delete();
  }
}