// ============================================================
// PATH: lib/features/auth/screens/phone_auth_screen.dart
//
// FLOW:
//   New user (no existing account) → OTP verified →
//     ask for email → send verification → verify email →
//     username setup → home
//
//   Existing user (phone already linked to account) →
//     OTP verified → straight to home via AuthWrapper
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'package:rewirex/main.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});
  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneCtrl  = TextEditingController();
  final _otpCtrl    = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _auth       = AuthService();
  final _firebaseAuth = FirebaseAuth.instance;

  // Steps:
  // 1 = enter phone
  // 2 = enter OTP
  // 3 = enter email + password (new users only)
  // 4 = verify email (new users only)
  int    _step           = 1;
  bool   _loading        = false;
  bool   _obscure        = true;
  bool   _isNewUser      = false;
  String _verificationId = '';
  String _countryCode    = '+91';
  String _savedEmail     = '';
  String _savedPassword  = '';

  static const _codes = [
    '+1',  '+7',  '+20', '+27', '+30', '+31', '+32', '+33',
    '+34', '+36', '+39', '+40', '+41', '+44', '+45', '+46',
    '+47', '+48', '+49', '+51', '+52', '+54', '+55', '+56',
    '+57', '+58', '+60', '+61', '+62', '+63', '+64', '+65',
    '+66', '+81', '+82', '+84', '+86', '+90', '+91', '+92',
    '+93', '+94', '+95', '+98',
  ];

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ── Step 1: Send OTP ────────────────────────────────────────────
  Future<void> _sendOtp() async {
    if (_phoneCtrl.text.trim().isEmpty) {
      _snack('Enter your phone number.');
      return;
    }
    setState(() => _loading = true);

    final fullNumber = '$_countryCode${_phoneCtrl.text.trim()}';
    final err = await _auth.sendPhoneOtp(
      phoneNumber: fullNumber,
      onCodeSent: (vId) {
        if (!mounted) return;
        setState(() {
          _verificationId = vId;
          _step           = 2;
          _loading        = false;
        });
        _snack('OTP sent to $fullNumber', success: true);
      },
      onError: (e) {
        if (!mounted) return;
        setState(() => _loading = false);
        _snack(e);
      },
    );

    if (err != null && mounted) {
      setState(() => _loading = false);
      _snack(err);
    }
  }

  // ── Step 2: Verify OTP ──────────────────────────────────────────
  // After OTP, check if this is a new or existing user.
  // New user  → go to Step 3 (email setup)
  // Old user  → go straight to home via AuthWrapper
  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.trim().length < 6) {
      _snack('Enter the 6-digit code.');
      return;
    }
    setState(() => _loading = true);

    final err = await _auth.verifyPhoneOtp(
      verificationId: _verificationId,
      smsCode:        _otpCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (err != null) {
      _snack(err);
      return;
    }

    // OTP verified — now check if this is a new or existing user
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      _snack('Something went wrong. Please try again.');
      return;
    }

    // Check if user has email set in Firestore (existing user)
    final doc = await _auth.getUserDocument(user.uid);
    final existingEmail = (doc?['email'] as String? ?? '').trim();
    final hasUsername   = (doc?['username'] as String? ?? '').trim().isNotEmpty;

    if (existingEmail.isNotEmpty && hasUsername) {
      // ── Existing user — go straight to home ──────────────────
      setState(() => _isNewUser = false);
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (route) => false,
        );
      }
    } else {
      // ── New user — must link email before entering app ────────
      setState(() {
        _isNewUser = true;
        _step      = 3;
      });
    }
  }

  // ── Step 3: Link Email to phone account ─────────────────────────
  Future<void> _linkEmail() async {
    final email = _emailCtrl.text.trim().toLowerCase();
    final pass  = _passCtrl.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _snack('Enter a valid email address.');
      return;
    }
    if (pass.length < 6) {
      _snack('Password must be at least 6 characters.');
      return;
    }

    setState(() => _loading = true);

    final err = await _auth.linkEmailToPhoneAccount(
      email:    email,
      password: pass,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (err != null) {
      _snack(err);
      return;
    }

    // Email linked — save for verification step
    _savedEmail    = email;
    _savedPassword = pass;
    setState(() => _step = 4);
  }

  // ── Step 4: Check email verified ────────────────────────────────
  Future<void> _checkEmailVerified() async {
    setState(() => _loading = true);
    final err = await _auth.checkEmailVerifiedForPhone(
      email:    _savedEmail,
      password: _savedPassword,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (err != null) {
      _snack(err);
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
    }
  }

  // ── Resend verification email ────────────────────────────────────
  Future<void> _resendEmail() async {
    setState(() => _loading = true);
    final err = await _auth.resendVerificationEmail(
      email:    _savedEmail,
      password: _savedPassword,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    _snack(err ?? 'Verification email resent!', success: err == null);
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
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
          onPressed: () {
            if (_step > 1) {
              setState(() => _step = _step - 1);
            } else {
              Navigator.pop(context);
            }
          })),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: _buildCurrentStep())));
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 1: return _buildPhoneStep();
      case 2: return _buildOtpStep();
      case 3: return _buildEmailStep();
      case 4: return _buildVerifyEmailStep();
      default: return _buildPhoneStep();
    }
  }

  // ══════════════════════════════════════════════════════════════
  // STEP 1 — Enter Phone Number
  // ══════════════════════════════════════════════════════════════
  Widget _buildPhoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _iconBox(Icons.phone_rounded, [
            const Color(0xFF6C63FF), const Color(0xFF00C4A0)]),
        const SizedBox(height: 18),
        const Text('Your phone number',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w900,
                color: Color(0xFF1A1A2E), letterSpacing: -0.5)),
        const SizedBox(height: 8),
        Text('We\'ll send a one-time verification code',
            style: TextStyle(
                fontSize: 14, color: Colors.grey.shade500, height: 1.5)),
        const SizedBox(height: 32),
        Row(children: [
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8E8E8))),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _countryCode,
                dropdownColor: Colors.white,
                style: const TextStyle(
                    color: Color(0xFF1A1A2E),
                    fontSize: 15, fontWeight: FontWeight.w600),
                items: _codes.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c, style: const TextStyle(
                        color: Color(0xFF1A1A2E), fontSize: 14))))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _countryCode = v ?? '+91')))),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8E8E8))),
              child: TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                autofocus: true,
                inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                    fontSize: 15, color: Color(0xFF1A1A2E)),
                decoration: InputDecoration(
                  hintText: 'Phone number',
                  hintStyle: TextStyle(
                      color: Colors.grey.shade400, fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16))))),
        ]),
        const SizedBox(height: 24),
        _primaryBtn(
            label: 'Send Code',
            loading: _loading,
            onTap: _loading ? null : _sendOtp),
      ]);
  }

  // ══════════════════════════════════════════════════════════════
  // STEP 2 — Enter OTP
  // ══════════════════════════════════════════════════════════════
  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _iconBox(Icons.lock_outline_rounded, [
            const Color(0xFF6C63FF), const Color(0xFF00C4A0)]),
        const SizedBox(height: 18),
        const Text('Enter the code',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w900,
                color: Color(0xFF1A1A2E), letterSpacing: -0.5)),
        const SizedBox(height: 8),
        Text('We sent a 6-digit code to\n$_countryCode ${_phoneCtrl.text.trim()}',
            style: TextStyle(
                fontSize: 14, color: Colors.grey.shade500, height: 1.5)),
        const SizedBox(height: 32),
        Container(
          height: 60,
          decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF6C63FF).withOpacity(0.4))),
          child: TextField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            autofocus: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
                fontSize: 30, fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E), letterSpacing: 14),
            decoration: InputDecoration(
              counterText: '',
              hintText: '------',
              hintStyle: TextStyle(
                  color: Colors.grey.shade300,
                  fontSize: 28, letterSpacing: 10),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16)))),
        const SizedBox(height: 24),
        _primaryBtn(
            label: 'Verify & Continue',
            loading: _loading,
            onTap: _loading ? null : _verifyOtp),
        const SizedBox(height: 16),
        Center(child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
          Text("Didn't receive it?  ",
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 14)),
          GestureDetector(
            onTap: _loading ? null : _sendOtp,
            child: const Text('Resend',
                style: TextStyle(
                    color: Color(0xFF6C63FF),
                    fontWeight: FontWeight.w700,
                    fontSize: 14))),
        ])),
      ]);
  }

  // ══════════════════════════════════════════════════════════════
  // STEP 3 — Link Email (new users only)
  // ══════════════════════════════════════════════════════════════
  Widget _buildEmailStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _iconBox(Icons.mail_outline_rounded, [
              const Color(0xFF00C4A0), const Color(0xFF6C63FF)]),
          const SizedBox(height: 18),
          const Text('Add your email',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A2E), letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Text(
            'For security, please link an email to your account.\n'
            'You\'ll need to verify it before accessing the app.',
            style: TextStyle(
                fontSize: 14, color: Colors.grey.shade500, height: 1.5)),
          const SizedBox(height: 24),
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF6C63FF).withOpacity(0.15))),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded,
                  color: Color(0xFF6C63FF), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your phone number is verified. Now link an email '
                  'to complete your account setup.',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      height: 1.5))),
            ])),
          const SizedBox(height: 24),
          // Email field
          _field(ctrl: _emailCtrl,
              hint: 'Email address',
              icon: Icons.mail_outline_rounded,
              type: TextInputType.emailAddress),
          const SizedBox(height: 12),
          // Password field
          _field(
            ctrl: _passCtrl,
            hint: 'Create a password',
            icon: Icons.lock_outline_rounded,
            obscure: _obscure,
            suffix: GestureDetector(
              onTap: () => setState(() => _obscure = !_obscure),
              child: Text(_obscure ? 'Show' : 'Hide',
                  style: const TextStyle(
                      color: Color(0xFF6C63FF),
                      fontWeight: FontWeight.w600,
                      fontSize: 13)))),
          const SizedBox(height: 24),
          _primaryBtn(
              label: 'Send Verification Email',
              loading: _loading,
              onTap: _loading ? null : _linkEmail),
          const SizedBox(height: 16),
        ]));
  }

  // ══════════════════════════════════════════════════════════════
  // STEP 4 — Verify Email (new users only)
  // ══════════════════════════════════════════════════════════════
  Widget _buildVerifyEmailStep() {
    return Column(
      children: [
        const SizedBox(height: 30),
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
                fontSize: 14, color: Colors.grey.shade600, height: 1.6)),
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
        const SizedBox(height: 24),
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
            onTap: _loading ? null : _checkEmailVerified),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text("Didn't get it?  ",
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 14)),
          GestureDetector(
            onTap: _loading ? null : _resendEmail,
            child: const Text('Resend',
                style: TextStyle(
                    color: Color(0xFF6C63FF),
                    fontWeight: FontWeight.w700,
                    fontSize: 14))),
        ]),
      ]);
  }

  // ── Shared widgets ─────────────────────────────────────────────
  Widget _iconBox(IconData icon, List<Color> colors) => Container(
    width: 60, height: 60,
    decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight)),
    child: Icon(icon, color: Colors.white, size: 28));

  Widget _field({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    TextInputType? type,
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
          keyboardType: type,
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
    Expanded(child: Text(text, style: const TextStyle(
        fontSize: 14, color: Color(0xFF374151)))),
  ]);

  Widget _primaryBtn({
    required String label,
    required bool loading,
    required VoidCallback? onTap,
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
}