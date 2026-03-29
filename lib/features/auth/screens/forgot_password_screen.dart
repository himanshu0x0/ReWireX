// ============================================================
// PATH: lib/features/auth/screens/forgot_password_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _ctrl  = TextEditingController();
  final _auth  = AuthService();

  bool _loading = false;
  bool _sent    = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final val = _ctrl.text.trim();
    if (val.isEmpty) {
      _snack('Enter your email or username.');
      return;
    }

    setState(() => _loading = true);
    final err = await _auth.sendPasswordResetEmail(val);
    if (!mounted) return;
    setState(() => _loading = false);

    if (err != null) {
      _snack(err);
    } else {
      setState(() => _sent = true);
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1A1A2E), size: 18),
          onPressed: () => Navigator.pop(context))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: _sent ? _buildSent() : _buildForm())));
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight)),
          child: const Icon(Icons.lock_reset_rounded,
              color: Colors.white, size: 28)),
        const SizedBox(height: 18),

        const Text('Forgot password?',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w900,
                color: Color(0xFF1A1A2E), letterSpacing: -0.5)),
        const SizedBox(height: 8),
        Text('Enter your email or @username and we\'ll '
            'send a password reset link.',
            style: TextStyle(
                fontSize: 14, color: Colors.grey.shade500,
                height: 1.5)),
        const SizedBox(height: 32),

        Container(
          height: 52,
          decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8E8E8))),
          child: TextField(
            controller: _ctrl,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            style: const TextStyle(
                fontSize: 15, color: Color(0xFF1A1A2E)),
            decoration: InputDecoration(
              hintText: 'Email or @username',
              hintStyle: TextStyle(
                  color: Colors.grey.shade400, fontSize: 15),
              prefixIcon: Icon(Icons.alternate_email_rounded,
                  color: Colors.grey.shade400, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16)))),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity, height: 50,
          child: _loading
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
                    onPressed: _send,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: const Text('Send Reset Link',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white))))),
      ]);
  }

  Widget _buildSent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.shade50,
              border: Border.all(
                  color: Colors.green.shade200, width: 2)),
          child: Icon(Icons.mark_email_read_outlined,
              color: Colors.green.shade600, size: 36)),
        const SizedBox(height: 24),

        const Text('Check your inbox!',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w900,
                color: Color(0xFF1A1A2E))),
        const SizedBox(height: 10),
        Text(
            'We sent a password reset link to\n${_ctrl.text.trim()}',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, color: Colors.grey.shade600,
                height: 1.6)),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity, height: 50,
          child: DecoratedBox(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(colors: [
                  Color(0xFF6C63FF), Color(0xFF00C4A0)])),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text('Back to Log In',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: Colors.white))))),
        const SizedBox(height: 14),

        GestureDetector(
          onTap: () => setState(() => _sent = false),
          child: Text('Resend email',
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 14))),
      ]);
  }
}