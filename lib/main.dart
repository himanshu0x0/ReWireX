// ============================================================
// PATH: lib/main.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rewirex/firebase_options.dart';
import 'package:rewirex/navigation/main_navigation_screen.dart';
import 'package:rewirex/features/auth/screens/login_screen.dart';
import 'package:rewirex/features/auth/screens/username_setup_screen.dart';
import 'package:rewirex/features/streak/services/streak_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ReWireX());
}

class ReWireX extends StatelessWidget {
  const ReWireX({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'SF Pro Display'),
      home: const AuthWrapper(),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// AUTH WRAPPER
// FIX: Memoize the _setup() future per user UID so it doesn't
//      re-run on every widget rebuild, preventing navigation loops
//      and repeated Firestore writes.
//
// Routes:
//   Not logged in           → LoginScreen
//   Logged in, no username  → UsernameSetupScreen
//   Logged in, has username → MainNavigationScreen
// ══════════════════════════════════════════════════════════════
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final StreakService _streakService = StreakService();

  // Memoize: only re-run _setup when the UID actually changes
  String?         _lastUid;
  Future<bool>?   _setupFuture;

  Future<bool> _setup(User user) async {
    final ref  = FirebaseFirestore.instance
        .collection('users').doc(user.uid);
    final snap = await ref.get();
    final data = snap.data() ?? {};

    final needsSkeleton = !snap.exists ||
        !data.containsKey('email') ||
        !data.containsKey('usernameLower');

    if (needsSkeleton) {
      await ref.set({
        'uid':           user.uid,
        'email':         (user.email ?? '').toLowerCase(),
        'displayName':   data['displayName']   ?? user.displayName ?? '',
        'username':      data['username']      ?? '',
        'usernameLower': data['usernameLower'] ?? '',
        'bio':           data['bio']           ?? '',
        'photoUrl':      data['photoUrl']      ?? user.photoURL ?? '',
        'phone':         data['phone']         ?? '',
        'recoveryGoal':  data['recoveryGoal']  ?? '',
        'addictionType': data['addictionType'] ?? '',
        'sobrietyStartDate': data['sobrietyStartDate'] ?? '',
        'gender':        data['gender']        ?? '',
        'dateOfBirth':   data['dateOfBirth']   ?? '',
        'country':       data['country']       ?? '',
        'isOnline':      true,
        'notificationsEnabled': data['notificationsEnabled'] ?? true,
        'guardianModeEnabled':  data['guardianModeEnabled']  ?? true,
        'currentStreak': data['currentStreak'] ?? 0,
        'longestStreak': data['longestStreak'] ?? 0,
        'totalRelapses': data['totalRelapses'] ?? 0,
        'createdAt':     data['createdAt']     ?? FieldValue.serverTimestamp(),
        'updatedAt':     FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      await ref.update({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }

    // Update daily streak (non-blocking — don't let this crash the flow)
    try {
      await _streakService.updateDailyStreak();
    } catch (_) {}

    // Check if username is set
    final fresh    = await ref.get();
    final username = (fresh.data()?['username'] as String? ?? '').trim();
    return username.isEmpty; // true = needs username setup
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }

        // Not logged in
        if (!snapshot.hasData || snapshot.data == null) {
          // Clear memoized future on logout
          _lastUid     = null;
          _setupFuture = null;
          return const LoginScreen();
        }

        final user = snapshot.data!;

        // FIX: Only create a new future when the user UID changes.
        // This prevents _setup() from re-running on every rebuild.
        if (_lastUid != user.uid) {
          _lastUid     = user.uid;
          _setupFuture = _setup(user);
        }

        return FutureBuilder<bool>(
          future: _setupFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const _Splash();
            }
            // On error, still try to navigate rather than staying stuck
            if (snap.hasError) {
              return const MainNavigationScreen();
            }
            if (snap.data == true) {
              return const UsernameSetupScreen();
            }
            return const MainNavigationScreen();
          },
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0D0D1A),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF6C63FF), strokeWidth: 2.5),
      ),
    );
  }
}