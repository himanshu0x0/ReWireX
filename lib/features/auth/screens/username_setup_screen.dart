// ============================================================
// PATH: lib/features/auth/screens/username_setup_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:rewirex/main.dart'; // FIX: needed for AuthWrapper

class UsernameSetupScreen extends StatefulWidget {
  const UsernameSetupScreen({super.key});
  @override
  State<UsernameSetupScreen> createState() => _UsernameSetupScreenState();
}

class _UsernameSetupScreenState extends State<UsernameSetupScreen> {
  final _usernameCtrl = TextEditingController();
  final _nameCtrl     = TextEditingController();
  final _auth         = AuthService();

  bool    _loading       = false;
  bool    _checking      = false;
  bool    _available     = false;
  String? _usernameError;

  static final _validUsername = RegExp(r'^[a-zA-Z0-9._]{3,20}$');

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _onUsernameChanged(String value) async {
    final trimmed = value.trim().toLowerCase();

    if (trimmed.isEmpty) {
      setState(() {
        _usernameError = null;
        _available     = false;
      });
      return;
    }

    if (!_validUsername.hasMatch(trimmed)) {
      setState(() {
        _usernameError =
            'Only letters, numbers, dots & underscores (3–20 chars)';
        _available = false;
      });
      return;
    }

    setState(() {
      _checking      = true;
      _usernameError = null;
      _available     = false;
    });

    final taken = await _auth.isUsernameTaken(trimmed);
    if (!mounted) return;

    setState(() {
      _checking      = false;
      _available     = !taken;
      _usernameError = taken ? '@$trimmed is already taken' : null;
    });
  }

  // ── FIX: Navigate to AuthWrapper after saving username ──────────
  // The old code used popUntil(isFirst) which doesn't work when
  // UsernameSetupScreen is pushed directly by AuthWrapper as root.
  // pushAndRemoveUntil with a fresh AuthWrapper forces a full
  // re-evaluation: username is now set → routes to MainNavigationScreen.
  Future<void> _save() async {
    final username = _usernameCtrl.text.trim();
    final name     = _nameCtrl.text.trim();

    if (username.isEmpty) {
      setState(() => _usernameError = 'Please enter a username.');
      return;
    }
    if (!_available) {
      setState(() => _usernameError = 'Please choose an available username.');
      return;
    }
    if (name.isEmpty) {
      _snack('Please enter your display name.');
      return;
    }

    setState(() => _loading = true);

    final err = await _auth.setUsername(
        username: username, displayName: name);

    if (!mounted) return;
    setState(() => _loading = false);

    if (err != null) {
      _snack(err);
    } else {
      // FIX: Force full navigation reset → AuthWrapper re-evaluates
      // → username is now set → routes to MainNavigationScreen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20)));
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _available && !_loading && !_checking;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),

              Center(
                child: Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                      boxShadow: [BoxShadow(
                          color: const Color(0xFF6C63FF).withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6))]),
                  child: const Icon(Icons.alternate_email_rounded,
                      color: Colors.white, size: 34))),
              const SizedBox(height: 20),

              const Center(
                child: Text('Choose your username',
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A2E),
                        letterSpacing: -0.5))),
              const SizedBox(height: 8),
              Center(
                child: Text(
                    'Pick a unique @username.\nOthers will use this to find you.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                        height: 1.5))),

              const SizedBox(height: 36),

              _label('Your name'),
              const SizedBox(height: 8),
              Container(
                height: 52,
                decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8E8E8))),
                child: TextField(
                  controller: _nameCtrl,
                  style: const TextStyle(
                      fontSize: 15, color: Color(0xFF1A1A2E)),
                  decoration: InputDecoration(
                    hintText: 'e.g. Himanshu',
                    hintStyle: TextStyle(
                        color: Colors.grey.shade400, fontSize: 15),
                    prefixIcon: Icon(Icons.person_outline_rounded,
                        color: Colors.grey.shade400, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16)))),

              const SizedBox(height: 20),

              _label('Username'),
              const SizedBox(height: 8),
              Container(
                height: 52,
                decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _usernameError != null
                            ? Colors.red.shade400
                            : _available
                                ? Colors.green.shade400
                                : const Color(0xFFE8E8E8))),
                child: Row(children: [
                  const SizedBox(width: 14),
                  Text('@', style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: Colors.grey.shade500)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: _usernameCtrl,
                      onChanged: _onUsernameChanged,
                      style: const TextStyle(
                          fontSize: 15, color: Color(0xFF1A1A2E)),
                      decoration: InputDecoration(
                        hintText: 'yourname',
                        hintStyle: TextStyle(
                            color: Colors.grey.shade400, fontSize: 15),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 0, vertical: 16)))),
                  Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: _checking
                        ? SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.grey.shade400))
                        : _available
                            ? const Icon(Icons.check_circle_rounded,
                                color: Colors.green, size: 20)
                            : _usernameError != null
                                ? const Icon(Icons.cancel_rounded,
                                    color: Colors.red, size: 20)
                                : const SizedBox.shrink()),
                ])),

              const SizedBox(height: 6),
              _usernameError != null
                  ? Text(_usernameError!,
                      style: TextStyle(
                          color: Colors.red.shade600, fontSize: 12))
                  : _available && _usernameCtrl.text.isNotEmpty
                      ? Text(
                          '@${_usernameCtrl.text.trim().toLowerCase()} is available!',
                          style: const TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w600))
                      : Text(
                          'Letters, numbers, dots, underscores • 3–20 characters',
                          style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12)),

              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity, height: 50,
                child: _loading
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(colors: [
                              Color(0xFF6C63FF),
                              Color(0xFF00C4A0)])),
                        child: const Center(child: SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5))))
                    : DecoratedBox(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                                colors: canSave
                                    ? [const Color(0xFF6C63FF),
                                       const Color(0xFF00C4A0)]
                                    : [Colors.grey.shade300,
                                       Colors.grey.shade400]),
                            boxShadow: canSave
                                ? [BoxShadow(
                                    color: const Color(0xFF6C63FF)
                                        .withOpacity(0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5))]
                                : []),
                        child: ElevatedButton(
                          onPressed: canSave ? _save : null,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12))),
                          child: const Text('Get Started →',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white))))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: Color(0xFF374151)));
}