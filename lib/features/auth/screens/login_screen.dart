// ============================================================
// PATH: lib/features/auth/screens/login_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';
import 'phone_auth_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idCtrl   = TextEditingController(); // email or username
  final _pwdCtrl  = TextEditingController();
  final _auth     = AuthService();

  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _idCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  // ── Email / Username + Password ────────────────────────────────
  Future<void> _login() async {
    final id  = _idCtrl.text.trim();
    final pwd = _pwdCtrl.text.trim();
    if (id.isEmpty)  { _snack('Enter your email or username.'); return; }
    if (pwd.isEmpty) { _snack('Enter your password.'); return; }

    setState(() => _loading = true);
    final result = await _auth.signIn(
        emailOrUsername: id, password: pwd);
    if (!mounted) return;
    setState(() => _loading = false);

    if (result == null) return; // success — AuthWrapper navigates

    // Unverified email — offer resend
    if (result.startsWith('UNVERIFIED:')) {
      final email = result.split(':').last;
      _showUnverifiedDialog(email, pwd);
    } else {
      _snack(result);
    }
  }

  // ── Google ──────────────────────────────────────────────────────
  Future<void> _google() async {
    setState(() => _loading = true);
    final err = await _auth.signInWithGoogle();
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) _snack(err);
  }

  // ── Apple ───────────────────────────────────────────────────────
  Future<void> _apple() async {
    setState(() => _loading = true);
    final err = await _auth.signInWithApple();
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) _snack(err);
  }

  // ── Phone ────────────────────────────────────────────────────────
  void _phone() => Navigator.push(context,
      MaterialPageRoute(builder: (_) => PhoneAuthScreen()));

  // ── Forgot ───────────────────────────────────────────────────────
  void _forgot() => Navigator.push(context,
      MaterialPageRoute(builder: (_) => ForgotPasswordScreen()));

  // ── Unverified dialog ─────────────────────────────────────────────
  void _showUnverifiedDialog(String email, String password) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.mark_email_unread_outlined,
            color: Color(0xFF6C63FF), size: 40),
        title: const Text('Verify your email',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 18)),
        content: Text(
            'Please verify $email before signing in.\n\n'
            'Check your inbox and click the verification link.',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 14, height: 1.5,
                color: Color(0xFF6B7280))),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: Colors.grey.shade500))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _loading = true);
              final err = await _auth.resendVerificationEmail(
                  email: email, password: password);
              if (!mounted) return;
              setState(() => _loading = false);
              _snack(err ?? 'Verification email sent! Check your inbox.',
                  success: err == null);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Resend Email',
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700))),
        ]));
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontSize: 14)),
      backgroundColor: success
          ? Colors.green.shade600 : Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(children: [
            const SizedBox(height: 60),

            // ── Logo ───────────────────────────────────────────
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                boxShadow: [BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8))]),
              child: const Icon(Icons.bolt_rounded,
                  color: Colors.white, size: 44)),
            const SizedBox(height: 14),
            const Text('ReWireX',
                style: TextStyle(
                    fontSize: 32, fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A2E), letterSpacing: -0.5)),
            const SizedBox(height: 6),
            Text('Recovery community',
                style: TextStyle(
                    fontSize: 14, color: Colors.grey.shade500)),
            const SizedBox(height: 40),

            // ── Email / Username field ─────────────────────────
            _field(
              ctrl:  _idCtrl,
              hint:  'Email or @username',
              icon:  Icons.person_outline_rounded),
            const SizedBox(height: 12),

            // ── Password field ─────────────────────────────────
            _field(
              ctrl:    _pwdCtrl,
              hint:    'Password',
              icon:    Icons.lock_outline_rounded,
              obscure: _obscure,
              suffix:  GestureDetector(
                onTap: () => setState(() => _obscure = !_obscure),
                child: Text(_obscure ? 'Show' : 'Hide',
                    style: const TextStyle(
                        color: Color(0xFF6C63FF),
                        fontWeight: FontWeight.w600,
                        fontSize: 13)))),
            const SizedBox(height: 8),

            // ── Forgot password ────────────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _forgot,
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: const Text('Forgot password?',
                    style: TextStyle(
                        color: Color(0xFF6C63FF),
                        fontWeight: FontWeight.w600,
                        fontSize: 13)))),
            const SizedBox(height: 20),

            // ── Log In button ──────────────────────────────────
            _primaryBtn(
                label: 'Log In',
                loading: _loading,
                onTap: _login),
            const SizedBox(height: 22),

            // ── OR ─────────────────────────────────────────────
            _orDivider(),
            const SizedBox(height: 20),

            // ── Google ─────────────────────────────────────────
            _socialBtn(
              onTap: _loading ? null : _google,
              icon: _googleBadge(),
              label: 'Continue with Google',
              bg: Colors.white,
              textColor: const Color(0xFF1A1A2E),
              borderColor: const Color(0xFFE0E0E0)),
            const SizedBox(height: 10),

            // ── Apple ──────────────────────────────────────────
            _socialBtn(
              onTap: _loading ? null : _apple,
              icon: const Icon(Icons.apple_rounded,
                  color: Colors.white, size: 22),
              label: 'Continue with Apple',
              bg: const Color(0xFF1A1A2E),
              textColor: Colors.white),
            const SizedBox(height: 10),

            // ── Phone ──────────────────────────────────────────
            _socialBtn(
              onTap: _loading ? null : _phone,
              icon: Icon(Icons.phone_rounded,
                  color: Colors.grey.shade600, size: 20),
              label: 'Continue with Phone',
              bg: Colors.white,
              textColor: Color(0xFF374151),
              borderColor: const Color(0xFFE0E0E0)),

            const SizedBox(height: 40),

            // ── Sign up ────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                  border: Border(top: BorderSide(
                      color: Colors.grey.shade200))),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                Text("Don't have an account? ",
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14)),
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => SignUpScreen())),
                  child: const Text('Sign up',
                      style: TextStyle(
                          color: Color(0xFF6C63FF),
                          fontWeight: FontWeight.w800,
                          fontSize: 14))),
              ])),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  // ── Shared widgets ─────────────────────────────────────────────
  Widget _field({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) =>
      Container(
        height: 52,
        decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8E8E8))),
        child: TextField(
          controller: ctrl,
          obscureText: obscure,
          style: const TextStyle(
              fontSize: 15, color: Color(0xFF1A1A2E)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: Colors.grey.shade400, fontSize: 15),
            prefixIcon: Icon(icon,
                color: Colors.grey.shade400, size: 20),
            suffixIcon: suffix != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: suffix)
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 16))));

  Widget _primaryBtn({
    required String label,
    required bool loading,
    required VoidCallback onTap,
  }) =>
      SizedBox(
        width: double.infinity, height: 50,
        child: loading
            ? DecoratedBox(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(colors: [
                      Color(0xFF6C63FF), Color(0xFF00C4A0)])),
                child: const Center(child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))))
            : DecoratedBox(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(colors: [
                      Color(0xFF6C63FF), Color(0xFF00C4A0)]),
                    boxShadow: [BoxShadow(
                        color: const Color(0xFF6C63FF)
                            .withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 5))]),
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: Text(label, style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: Colors.white)))));

  Widget _orDivider() => Row(children: [
    Expanded(child: Divider(
        color: Colors.grey.shade300, thickness: 1)),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Text('OR', style: TextStyle(
          color: Colors.grey.shade500, fontSize: 12,
          fontWeight: FontWeight.w700, letterSpacing: 1))),
    Expanded(child: Divider(
        color: Colors.grey.shade300, thickness: 1)),
  ]);

  Widget _socialBtn({
    required Widget icon,
    required String label,
    required Color bg,
    required Color textColor,
    Color? borderColor,
    VoidCallback? onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 50, width: double.infinity,
          decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: borderColor != null
                  ? Border.all(color: borderColor) : null,
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2))]),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
            icon,
            const SizedBox(width: 10),
            Text(label, style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600,
                color: textColor)),
          ])));

  Widget _googleBadge() => Container(
      width: 22, height: 22,
      decoration: const BoxDecoration(
          shape: BoxShape.circle, color: Color(0xFF4285F4)),
      child: const Center(
          child: Text('G', style: TextStyle(
              color: Colors.white, fontSize: 12,
              fontWeight: FontWeight.w900))));
}