// ============================================================
// PATH: lib/features/auth/services/auth_service.dart
// ============================================================

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  final FirebaseAuth      _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db   = FirebaseFirestore.instance;

  static const _hostingUrl = 'https://rewirex-c639d.web.app';

  ActionCodeSettings get _actionCodeSettings => ActionCodeSettings(
    url: '$_hostingUrl/__/auth/action',
    handleCodeInApp: false,
  );

  bool _googleInitialized = false;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize();
    _googleInitialized = true;
  }

  User? get currentUser => _auth.currentUser;

  // ── Get user document from Firestore ───────────────────────────
  // Used by PhoneAuthScreen to check if user is new or existing.
  Future<Map<String, dynamic>?> getUserDocument(String uid) async {
    try {
      final snap = await _db.collection('users').doc(uid).get();
      return snap.data();
    } catch (_) {
      return null;
    }
  }

  // ── Write skeleton doc ─────────────────────────────────────────
  Future<void> _writeSkeletonDoc(User user) async {
    final ref  = _db.collection('users').doc(user.uid);
    final snap = await ref.get();
    final old  = snap.data() ?? {};

    await ref.set({
      'uid':           user.uid,
      'email':         (user.email  ?? old['email']  ?? '').toLowerCase(),
      'displayName':   old['displayName']    ?? user.displayName ?? '',
      'username':      old['username']       ?? '',
      'usernameLower': old['usernameLower']  ?? '',
      'bio':           old['bio']            ?? '',
      'photoUrl':      old['photoUrl']       ?? user.photoURL ?? '',
      'phone':         old['phone']          ?? user.phoneNumber ?? '',
      'recoveryGoal':  old['recoveryGoal']   ?? '',
      'addictionType': old['addictionType']  ?? '',
      'sobrietyStartDate': old['sobrietyStartDate'] ?? '',
      'gender':        old['gender']         ?? '',
      'dateOfBirth':   old['dateOfBirth']    ?? '',
      'country':       old['country']        ?? '',
      'isOnline':      true,
      'notificationsEnabled': old['notificationsEnabled'] ?? true,
      'guardianModeEnabled':  old['guardianModeEnabled']  ?? true,
      'currentStreak': old['currentStreak']  ?? 0,
      'longestStreak': old['longestStreak']  ?? 0,
      'totalRelapses': old['totalRelapses']  ?? 0,
      'createdAt':     old['createdAt']      ?? FieldValue.serverTimestamp(),
      'updatedAt':     FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ══════════════════════════════════════════════════════════════
  // EMAIL SIGN UP
  // ══════════════════════════════════════════════════════════════
  Future<String?> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email:    email.trim().toLowerCase(),
        password: password.trim(),
      );
      await _writeSkeletonDoc(cred.user!);
      try {
        await cred.user!.sendEmailVerification(_actionCodeSettings);
      } catch (e) {
        await _auth.signOut();
        return 'Account created but failed to send verification email. '
               'Please use the "Resend" button on the next screen.';
      }
      await _auth.signOut();
      return null;
    } on FirebaseAuthException catch (e) {
      return _err(e.code);
    } catch (_) {
      return 'Failed to create account. Please try again.';
    }
  }

  // ══════════════════════════════════════════════════════════════
  // CHECK EMAIL VERIFIED (for email sign up flow)
  // ══════════════════════════════════════════════════════════════
  Future<String?> checkEmailVerified({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email:    email.trim().toLowerCase(),
        password: password.trim(),
      );
      await cred.user!.reload();
      await cred.user!.getIdToken(true);
      final fresh = _auth.currentUser!;
      if (!fresh.emailVerified) {
        await _auth.signOut();
        return 'Email not verified yet.\n\n'
               'Please click the link in your inbox '
               '(check spam too), then tap this button again.';
      }
      await _db.collection('users').doc(fresh.uid).set({
        'email':     fresh.email!.toLowerCase(),
        'isOnline':  true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return null;
    } on FirebaseAuthException catch (e) {
      return _err(e.code);
    } catch (_) {
      return 'Verification check failed. Please try again.';
    }
  }

  // ══════════════════════════════════════════════════════════════
  // LINK EMAIL TO PHONE ACCOUNT (new phone users)
  //
  // After phone OTP is verified, new users must link an email.
  // This creates an email+password credential and links it to
  // the existing phone-auth Firebase account, then sends
  // a verification email.
  // ══════════════════════════════════════════════════════════════
  Future<String?> linkEmailToPhoneAccount({
    required String email,
    required String password,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'Not signed in. Please try again.';

      final emailCred = EmailAuthProvider.credential(
        email:    email.trim().toLowerCase(),
        password: password.trim(),
      );

      // Link email credential to phone account
      await user.linkWithCredential(emailCred);

      // Update Firestore with email
      await _db.collection('users').doc(user.uid).set({
        'email':     email.trim().toLowerCase(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Send verification email
      await user.sendEmailVerification(_actionCodeSettings);

      // Sign out — user must verify email before entering app
      await _auth.signOut();

      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'This email is already linked to another account.\n'
               'Please use a different email.';
      }
      if (e.code == 'provider-already-linked') {
        return 'An email is already linked to this account.';
      }
      return _err(e.code);
    } catch (_) {
      return 'Failed to link email. Please try again.';
    }
  }

  // ══════════════════════════════════════════════════════════════
  // CHECK EMAIL VERIFIED (for phone flow — signs back in with
  // email+password after user clicks the verification link)
  // ══════════════════════════════════════════════════════════════
  Future<String?> checkEmailVerifiedForPhone({
    required String email,
    required String password,
  }) async {
    try {
      // Sign back in with email+password
      final cred = await _auth.signInWithEmailAndPassword(
        email:    email.trim().toLowerCase(),
        password: password.trim(),
      );

      await cred.user!.reload();
      await cred.user!.getIdToken(true);
      final fresh = _auth.currentUser!;

      if (!fresh.emailVerified) {
        await _auth.signOut();
        return 'Email not verified yet.\n\n'
               'Please click the link in your inbox '
               '(check spam too), then tap this button again.';
      }

      // Sync to Firestore
      await _db.collection('users').doc(fresh.uid).set({
        'email':     fresh.email!.toLowerCase(),
        'isOnline':  true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return null; // AuthWrapper takes over → routes to username setup
    } on FirebaseAuthException catch (e) {
      return _err(e.code);
    } catch (_) {
      return 'Verification check failed. Please try again.';
    }
  }

  // ── Resend verification email ──────────────────────────────────
  Future<String?> resendVerificationEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email:    email.trim().toLowerCase(),
        password: password.trim(),
      );
      if (!cred.user!.emailVerified) {
        await cred.user!.sendEmailVerification(_actionCodeSettings);
      }
      await _auth.signOut();
      return null;
    } on FirebaseAuthException catch (e) {
      return _err(e.code);
    } catch (_) {
      return 'Failed to resend. Please try again.';
    }
  }

  // ══════════════════════════════════════════════════════════════
  // SIGN IN — Email OR Username + Password
  // ══════════════════════════════════════════════════════════════
  Future<String?> signIn({
    required String emailOrUsername,
    required String password,
  }) async {
    try {
      String email = emailOrUsername.trim();

      if (!email.contains('@')) {
        final rawUsername = email.startsWith('@')
            ? email.substring(1)
            : email;
        final resolved = await _emailFromUsername(rawUsername);
        if (resolved == null) {
          return 'No account found for @$rawUsername.\n'
                 'Check the username or sign in with your email.';
        }
        if (resolved.isEmpty) {
          return 'Account found but email is not set up.\n'
                 'Please sign in with your email address.';
        }
        email = resolved;
      }

      final cred = await _auth.signInWithEmailAndPassword(
        email:    email.trim().toLowerCase(),
        password: password.trim(),
      );

      await cred.user!.reload();
      await cred.user!.getIdToken(true);
      final fresh = _auth.currentUser!;

      if (!fresh.emailVerified) {
        await _auth.signOut();
        return 'UNVERIFIED:${email.trim().toLowerCase()}';
      }

      await _db.collection('users').doc(fresh.uid).set({
        'email':     fresh.email!.toLowerCase(),
        'isOnline':  true,
        'lastSeen':  FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return null;
    } on FirebaseAuthException catch (e) {
      return _err(e.code);
    } catch (_) {
      return 'Sign in failed. Please try again.';
    }
  }

  // ── Resolves username → email ──────────────────────────────────
  Future<String?> _emailFromUsername(String username) async {
    try {
      final q = username.trim().toLowerCase();
      final snap = await _db
          .collection('users')
          .where('usernameLower', isEqualTo: q)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        return (snap.docs.first.data()['email'] as String? ?? '');
      }
      final snap2 = await _db
          .collection('users')
          .where('username', isEqualTo: q)
          .limit(1)
          .get();
      if (snap2.docs.isNotEmpty) {
        return (snap2.docs.first.data()['email'] as String? ?? '');
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // GOOGLE SIGN IN
  // ══════════════════════════════════════════════════════════════
  Future<String?> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();
      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();
      final String? idToken = googleUser.authentication.idToken;
      final GoogleSignInClientAuthorization? authorization =
          await googleUser.authorizationClient
              .authorizationForScopes(['email', 'profile']);
      final String? accessToken = authorization?.accessToken;
      if (idToken == null) {
        return 'Google sign in failed. Could not get ID token.';
      }
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken:     idToken,
        accessToken: accessToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      await _writeSkeletonDoc(cred.user!);
      return null;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      return 'Google sign in failed: ${e.description ?? e.code.name}';
    } on FirebaseAuthException catch (e) {
      return _err(e.code);
    } catch (e) {
      return 'Google sign in failed. Please try again.';
    }
  }

  Future<void> _signOutGoogle() async {
    try {
      await _ensureGoogleInitialized();
      _googleInitialized = false;
    } catch (_) {}
  }

  // ══════════════════════════════════════════════════════════════
  // APPLE SIGN IN
  // ══════════════════════════════════════════════════════════════
  Future<String?> signInWithApple() async {
    try {
      final rawNonce = _nonce();
      final nonce    = _sha256(rawNonce);
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );
      final oauthCred = OAuthProvider('apple.com').credential(
        idToken:     apple.identityToken,
        rawNonce:    rawNonce,
        accessToken: apple.authorizationCode,
      );
      final cred = await _auth.signInWithCredential(oauthCred);
      if (apple.givenName != null) {
        final name =
            '${apple.givenName ?? ''} ${apple.familyName ?? ''}'.trim();
        if (name.isNotEmpty) {
          await cred.user!.updateDisplayName(name);
        }
      }
      await _writeSkeletonDoc(cred.user!);
      return null;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      return 'Apple sign in failed. Please try again.';
    } on FirebaseAuthException catch (e) {
      return _err(e.code);
    } catch (_) {
      return 'Apple sign in failed. Please try again.';
    }
  }

  // ══════════════════════════════════════════════════════════════
  // PHONE OTP
  // ══════════════════════════════════════════════════════════════
  Future<String?> sendPhoneOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
    int? forceResendingToken,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber:         phoneNumber.trim(),
        timeout:             const Duration(seconds: 120),
        forceResendingToken: forceResendingToken,
        verificationCompleted: (PhoneAuthCredential cred) async {
          try {
            final result = await _auth.signInWithCredential(cred);
            await _writeSkeletonDoc(result.user!);
          } catch (_) {}
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(_err(e.code));
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (_) {},
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _err(e.code);
    } catch (_) {
      return 'OTP failed. Ensure:\n'
             '• Phone Auth enabled in Firebase\n'
             '• SHA-256 fingerprint added to Firebase\n'
             '• Number format: +91xxxxxxxxxx';
    }
  }

  Future<String?> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode:        smsCode.trim(),
      );
      final result = await _auth.signInWithCredential(cred);
      await _writeSkeletonDoc(result.user!);
      return null;
    } on FirebaseAuthException catch (e) {
      return _err(e.code);
    } catch (_) {
      return 'OTP verification failed. Please try again.';
    }
  }

  // ══════════════════════════════════════════════════════════════
  // LINK PHONE NUMBER to existing account
  // ══════════════════════════════════════════════════════════════
  Future<String?> linkPhoneToAccount({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'Not signed in.';
      final cred = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode:        smsCode.trim(),
      );
      await user.linkWithCredential(cred);
      final phone = user.phoneNumber ?? '';
      if (phone.isNotEmpty) {
        await _db.collection('users').doc(user.uid).update({
          'phone':     phone,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'provider-already-linked') {
        return 'This phone is already linked to your account.';
      }
      if (e.code == 'credential-already-in-use') {
        return 'This phone number is already used by another account.';
      }
      return _err(e.code);
    } catch (_) {
      return 'Failed to link phone. Please try again.';
    }
  }

  // ══════════════════════════════════════════════════════════════
  // SET USERNAME
  // ══════════════════════════════════════════════════════════════
  Future<bool> isUsernameTaken(String username) async {
    final uid = _auth.currentUser?.uid;
    final q   = username.trim().toLowerCase();
    if (q.isEmpty) return false;
    final snap = await _db
        .collection('users')
        .where('usernameLower', isEqualTo: q)
        .limit(2)
        .get();
    return snap.docs.any((d) => d.id != uid);
  }

  Future<String?> setUsername({
    required String username,
    required String displayName,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 'Not signed in.';
    final trimmed = username.trim().toLowerCase();
    final valid = RegExp(r'^[a-zA-Z0-9._]{3,20}$');
    if (!valid.hasMatch(trimmed)) {
      return 'Username: 3–20 chars, letters/numbers/dots/underscores only.';
    }
    final taken = await isUsernameTaken(trimmed);
    if (taken) return '@$trimmed is already taken. Choose another.';
    await _db.collection('users').doc(uid).update({
      'username':      trimmed,
      'usernameLower': trimmed,
      'displayName':   displayName.trim(),
      'updatedAt':     FieldValue.serverTimestamp(),
    });
    return null;
  }

  // ══════════════════════════════════════════════════════════════
  // FORGOT PASSWORD
  // ══════════════════════════════════════════════════════════════
  Future<String?> sendPasswordResetEmail(String emailOrUsername) async {
    try {
      String email = emailOrUsername.trim();
      if (!email.contains('@')) {
        final rawUsername = email.startsWith('@')
            ? email.substring(1)
            : email;
        final resolved = await _emailFromUsername(rawUsername);
        if (resolved == null || resolved.isEmpty) {
          return 'No account found for @$rawUsername.\n'
                 'Try entering your email address instead.';
        }
        email = resolved;
      }
      await _auth.sendPasswordResetEmail(
        email: email.toLowerCase(),
        actionCodeSettings: _actionCodeSettings,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _err(e.code);
    } catch (_) {
      return 'Failed to send reset email. Please try again.';
    }
  }

  // ══════════════════════════════════════════════════════════════
  // SIGN OUT
  // ══════════════════════════════════════════════════════════════
  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      try {
        await _db.collection('users').doc(uid).update({
          'isOnline': false,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
    await _signOutGoogle();
    await _auth.signOut();
  }

  Future<void> ensureUserDocument() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _writeSkeletonDoc(user);
  }

  // ── Helpers ────────────────────────────────────────────────────
  String _nonce([int length = 32]) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._';
    final random = Random.secure();
    return List.generate(
        length, (_) => chars[random.nextInt(chars.length)]).join();
  }

  String _sha256(String input) =>
      sha256.convert(utf8.encode(input)).toString();

  String _err(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found. Check your email or username.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'No internet connection.';
      case 'invalid-verification-code':
        return 'Incorrect OTP. Please try again.';
      case 'invalid-phone-number':
        return 'Invalid phone number. Use format: +91xxxxxxxxxx';
      case 'session-expired':
        return 'OTP expired. Please request a new code.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Try again later.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'missing-phone-number':
        return 'Please enter a phone number.';
      case 'captcha-check-failed':
        return 'Verification failed. Please try again.';
      default:
        return 'Something went wrong ($code). Please try again.';
    }
  }
}