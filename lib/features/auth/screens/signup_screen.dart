// ============================================================
// PATH: lib/features/auth/screens/signup_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'phone_auth_screen.dart';
import 'package:rewirex/main.dart'; // FIX: needed for AuthWrapper

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _auth        = AuthService();

  int    _step          = 1;
  bool   _loading       = false;
  bool   _obscure       = true;
  bool   _obscureC      = true;
  String _savedEmail    = '';
  String _savedPassword = '';

  late AnimationController _anim;
  late Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validate() {
    final e = _emailCtrl.text.trim();
    final p = _passCtrl.text.trim();
    final c = _confirmCtrl.text.trim();
    if (e.isEmpty)        return 'Please enter your email.';
    if (!e.contains('@')) return 'Please enter a valid email.';
    if (p.isEmpty)        return 'Please enter a password.';
    if (p.length < 6)     return 'Password must be at least 6 characters.';
    if (c != p)           return 'Passwords do not match.';
    return null;
  }

  Future<void> _create() async {
    final ve = _validate();
    if (ve != null) { _snack(ve); return; }

    setState(() => _loading = true);
    _savedEmail    = _emailCtrl.text.trim().toLowerCase();
    _savedPassword = _passCtrl.text.trim();

    final err = await _auth.signUp(
        email: _savedEmail, password: _savedPassword);
    if (!mounted) return;
    setState(() => _loading = false);

    if (err != null) { _snack(err); return; }
    _toStep(2);
  }

  // ── FIX: Navigate to AuthWrapper after successful verification ──
  Future<void> _checkVerified() async {
    setState(() => _loading = true);
    final err = await _auth.checkEmailVerified(
        email: _savedEmail, password: _savedPassword);
    if (!mounted) return;
    setState(() => _loading = false);

    if (err != null) {
      _snack(err);
    } else {
      // Force full nav reset → AuthWrapper detects signed-in state
      // → sees no username → routes to UsernameSetupScreen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
    }
  }

  Future<void> _resend() async {
    setState(() => _loading = true);
    final err = await _auth.resendVerificationEmail(
        email: _savedEmail, password: _savedPassword);
    if (!mounted) return;
    setState(() => _loading = false);
    _snack(err ?? 'Verification email resent! Check your inbox.',
        success: err == null);
  }

  Future<void> _google() async {
    setState(() => _loading = true);
    final err = await _auth.signInWithGoogle();
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) _snack(err);
  }

  Future<void> _apple() async {
    setState(() => _loading = true);
    final err = await _auth.signInWithApple();
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) _snack(err);
  }

  void _phone() => Navigator.push(context,
      MaterialPageRoute(builder: (_) => const PhoneAuthScreen()));

  void _toStep(int s) {
    _anim.reverse().then((_) {
      if (!mounted) return;
      setState(() => _step = s);
      _anim.forward();
    });
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontSize: 14)),
      backgroundColor: success
          ? Colors.green.shade600 : Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1A1A2E), size: 18),
          onPressed: _step == 2
              ? () => _toStep(1)
              : () => Navigator.pop(context))),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: _step == 1 ? _buildForm() : _buildVerify())));
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(children: [
        const SizedBox(height: 10),
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                  colors: [Color(0xFF00C4A0), Color(0xFF6C63FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              boxShadow: [BoxShadow(
                  color: const Color(0xFF00C4A0).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6))]),
          child: const Icon(Icons.person_add_alt_1_rounded,
              color: Colors.white, size: 30)),
        const SizedBox(height: 14),
        const Text('Create account',
            style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.w900,
                color: Color(0xFF1A1A2E), letterSpacing: -0.5)),
        const SizedBox(height: 6),
        Text('Join the recovery community',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        const SizedBox(height: 28),
        _steps(1),
        const SizedBox(height: 28),
        _field(_emailCtrl, 'Email address',
            Icons.mail_outline_rounded,
            type: TextInputType.emailAddress),
        const SizedBox(height: 12),
        _field(_passCtrl, 'Password',
            Icons.lock_outline_rounded,
            obscure: _obscure,
            suffix: _toggleBtn(
                _obscure, () => setState(() => _obscure = !_obscure))),
        const SizedBox(height: 12),
        _field(_confirmCtrl, 'Confirm password',
            Icons.lock_outline_rounded,
            obscure: _obscureC,
            suffix: _toggleBtn(
                _obscureC,
                () => setState(() => _obscureC = !_obscureC))),
        const SizedBox(height: 22),
        _primaryBtn(label: 'Sign Up', loading: _loading, onTap: _create),
        const SizedBox(height: 22),
        _orDivider(),
        const SizedBox(height: 18),
        _socialBtn(
            icon: _googleBadge(), label: 'Sign up with Google',
            bg: Colors.white, textColor: const Color(0xFF1A1A2E),
            borderColor: const Color(0xFFE0E0E0),
            onTap: _loading ? null : _google),
        const SizedBox(height: 10),
        _socialBtn(
            icon: const Icon(Icons.apple_rounded,
                color: Colors.white, size: 22),
            label: 'Sign up with Apple',
            bg: const Color(0xFF1A1A2E), textColor: Colors.white,
            onTap: _loading ? null : _apple),
        const SizedBox(height: 10),
        _socialBtn(
            icon: Icon(Icons.phone_rounded,
                color: Colors.grey.shade600, size: 20),
            label: 'Sign up with Phone',
            bg: Colors.white, textColor: const Color(0xFF374151),
            borderColor: const Color(0xFFE0E0E0),
            onTap: _loading ? null : _phone),
        const SizedBox(height: 32),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(color: Colors.grey.shade200))),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
            Text('Already have an account? ',
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 14)),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text('Log in',
                  style: TextStyle(
                      color: Color(0xFF6C63FF),
                      fontWeight: FontWeight.w800,
                      fontSize: 14))),
          ])),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _buildVerify() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(children: [
        const SizedBox(height: 20),
        _steps(2),
        const SizedBox(height: 36),
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6C63FF).withOpacity(0.08),
              border: Border.all(
                  color: const Color(0xFF6C63FF).withOpacity(0.2),
                  width: 2)),
          child: const Icon(Icons.mark_email_unread_outlined,
              color: Color(0xFF6C63FF), size: 36)),
        const SizedBox(height: 20),
        const Text('Check your inbox',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w900,
                color: Color(0xFF1A1A2E), letterSpacing: -0.5)),
        const SizedBox(height: 10),
        Text('We sent a verification link to\n$_savedEmail',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, color: Colors.grey.shade600,
                height: 1.6)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade200)),
          child: Row(children: [
            Icon(Icons.info_outline_rounded,
                color: Colors.amber.shade700, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Don\'t see it? Check your spam/junk folder.',
                style: TextStyle(
                    fontSize: 12, color: Colors.amber.shade800))),
          ])),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              color: const Color(0xFFF8F8FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFF6C63FF).withOpacity(0.12))),
          child: Column(children: [
            _instrRow('1', 'Open the email from ReWireX'),
            const SizedBox(height: 10),
            _instrRow('2', 'Tap the "Verify email" link'),
            const SizedBox(height: 10),
            _instrRow('3', 'Come back and tap the button below'),
          ])),
        const SizedBox(height: 24),
        _primaryBtn(
            label: '✓  I verified my email',
            loading: _loading,
            onTap: _checkVerified),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text("Didn't get it?  ",
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 14)),
          GestureDetector(
            onTap: _loading ? null : _resend,
            child: const Text('Resend',
                style: TextStyle(
                    color: Color(0xFF6C63FF),
                    fontWeight: FontWeight.w700,
                    fontSize: 14))),
        ]),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => _toStep(1),
          child: Text('Wrong email? Go back',
              style: TextStyle(
                  color: Colors.grey.shade400, fontSize: 13))),
      ]),
    );
  }

  Widget _steps(int current) {
    final labels = ['Email', 'Verify', 'Username'];
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      for (int i = 0; i < 3; i++) Row(children: [
        if (i > 0) Container(
            width: 28, height: 2,
            color: i < current
                ? const Color(0xFF00C4A0)
                : Colors.grey.shade200),
        Column(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width:  i + 1 == current ? 30 : 24,
            height: i + 1 == current ? 30 : 24,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i + 1 < current
                    ? const Color(0xFF00C4A0)
                    : i + 1 == current
                        ? const Color(0xFF6C63FF)
                        : Colors.grey.shade200),
            child: Center(child: i + 1 < current
                ? const Icon(Icons.check_rounded,
                    color: Colors.white, size: 13)
                : Text('${i + 1}',
                    style: TextStyle(
                        color: i + 1 == current
                            ? Colors.white
                            : Colors.grey.shade400,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)))),
          const SizedBox(height: 4),
          Text(labels[i],
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  color: i + 1 == current
                      ? const Color(0xFF6C63FF)
                      : i + 1 < current
                          ? const Color(0xFF00C4A0)
                          : Colors.grey.shade400)),
        ]),
      ]),
    ]);
  }

  Widget _instrRow(String num, String text) => Row(children: [
    Container(
        width: 24, height: 24,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF6C63FF).withOpacity(0.1)),
        child: Center(child: Text(num,
            style: const TextStyle(
                color: Color(0xFF6C63FF),
                fontSize: 11, fontWeight: FontWeight.w800)))),
    const SizedBox(width: 10),
    Text(text, style: const TextStyle(
        fontSize: 14, color: Color(0xFF374151))),
  ]);

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType? type, bool obscure = false, Widget? suffix}) =>
      Container(
        height: 52,
        decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8E8E8))),
        child: TextField(
          controller: ctrl, obscureText: obscure, keyboardType: type,
          style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
            prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
            suffixIcon: suffix != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: suffix)
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 16))));

  Widget _toggleBtn(bool obs, VoidCallback tap) => GestureDetector(
      onTap: tap,
      child: Text(obs ? 'Show' : 'Hide',
          style: const TextStyle(
              color: Color(0xFF6C63FF),
              fontWeight: FontWeight.w600,
              fontSize: 13)));

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
                        color: const Color(0xFF6C63FF).withOpacity(0.35),
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
    Expanded(child: Divider(color: Colors.grey.shade300)),
    Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text('OR', style: TextStyle(
            color: Colors.grey.shade500, fontSize: 12,
            fontWeight: FontWeight.w700, letterSpacing: 1))),
    Expanded(child: Divider(color: Colors.grey.shade300)),
  ]);

  Widget _socialBtn({
    required Widget icon, required String label,
    required Color bg, required Color textColor,
    Color? borderColor, VoidCallback? onTap,
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
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2))]),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
            icon, const SizedBox(width: 10),
            Text(label, style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600,
                color: textColor)),
          ])));

  Widget _googleBadge() => Container(
      width: 22, height: 22,
      decoration: const BoxDecoration(
          shape: BoxShape.circle, color: Color(0xFF4285F4)),
      child: const Center(child: Text('G', style: TextStyle(
          color: Colors.white, fontSize: 12,
          fontWeight: FontWeight.w900))));
}