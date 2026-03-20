import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rewirex/firebase_options.dart';
import 'package:rewirex/navigation/main_navigation_screen.dart';

import 'features/auth/screens/login_screen.dart';
import 'features/streak/services/streak_service.dart';

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
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final StreakService _streakService = StreakService();
  bool _initialized = false;

  Future<void> _initializeUserSystem(User user) async {
    if (_initialized) return;

    final doc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    final snapshot = await doc.get();

    if (!snapshot.exists) {
      await doc.set({
        'currentStreak': 0,
        'longestStreak': 0,
        'totalRelapses': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await _streakService.updateDailyStreak();

    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          _initializeUserSystem(snapshot.data!);
          return const MainNavigationScreen();
        }

        return const LoginScreen();
      },
    );
  }
}