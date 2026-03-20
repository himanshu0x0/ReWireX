// lib/features/terms/screens/terms_screen.dart

import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded,
                size: 15, color: Colors.white.withOpacity(0.7)),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)],
          ).createShader(bounds),
          child: const Text(
            'Terms of Service',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Last updated
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFF6C63FF).withOpacity(0.25), width: 1),
              ),
              child: const Text(
                'Last updated: March 2026',
                style: TextStyle(
                    color: Color(0xFF6C63FF),
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 20),

            _intro(
              'Welcome to ReWireX. By using this app, you agree to these Terms of Service. '
              'Please read them carefully before using our services.',
            ),
            const SizedBox(height: 24),

            _section('1. Acceptance of Terms',
              'By downloading, installing, or using ReWireX, you agree to be bound by these '
              'Terms of Service and our Privacy Policy. If you do not agree to these terms, '
              'please do not use the app.'),

            _section('2. Description of Service',
              'ReWireX is an AI-powered addiction recovery companion that provides behavioral '
              'analytics, streak tracking, risk prediction, and AI coaching tools. The app is '
              'designed to support your recovery journey but does not replace professional '
              'medical or psychological treatment.'),

            _section('3. Medical Disclaimer',
              'ReWireX is not a medical device and does not provide medical advice, diagnosis, '
              'or treatment. The AI Coach and risk predictions are informational tools only. '
              'Always consult a qualified healthcare professional for medical concerns or '
              'addiction treatment decisions.\n\n'
              'In case of a mental health crisis or emergency, please contact emergency '
              'services or a crisis helpline immediately.'),

            _section('4. User Accounts',
              'You are responsible for:\n'
              '• Maintaining the confidentiality of your account credentials\n'
              '• All activity that occurs under your account\n'
              '• Ensuring your account information is accurate and up to date\n'
              '• Notifying us immediately of any unauthorized use of your account'),

            _section('5. User Data & Privacy',
              'Your recovery data, urge logs, and behavioral patterns are stored securely '
              'on Firebase. We do not sell your personal data to third parties. Your data '
              'is used solely to provide and improve the ReWireX service.\n\n'
              'You retain ownership of all data you input into the app. You may request '
              'deletion of your data at any time through the app settings.'),

            _section('6. AI Coach Limitations',
              'The AI Coach feature provides general guidance based on your logged data. '
              'It should be used as a supportive tool, not as a replacement for human '
              'therapists, counselors, or medical professionals.\n\n'
              'AI responses may not always be accurate or appropriate for your specific '
              'situation. Use your judgment and consult professionals when needed.'),

            _section('7. Prohibited Uses',
              'You agree not to:\n'
              '• Use the app for any unlawful purpose\n'
              '• Attempt to reverse-engineer or extract the app\'s source code\n'
              '• Share your account with others\n'
              '• Input false or misleading information\n'
              '• Use the app to harm yourself or others'),

            _section('8. Subscription & Payments',
              'ReWireX may offer premium features through in-app purchases or subscriptions. '
              'All purchases are final unless required by applicable law. Subscription fees '
              'are billed in advance and are non-refundable except where required by law.'),

            _section('9. Intellectual Property',
              'All content, features, and functionality of ReWireX — including but not limited '
              'to text, graphics, algorithms, and AI models — are owned by ReWireX and are '
              'protected by applicable intellectual property laws.'),

            _section('10. Limitation of Liability',
              'ReWireX is provided "as is" without warranties of any kind. We are not liable '
              'for any indirect, incidental, or consequential damages arising from your use '
              'of the app, including any relapse or health outcome.\n\n'
              'Our total liability to you for any claims arising from these terms shall not '
              'exceed the amount you paid for the app in the past 12 months.'),

            _section('11. Changes to Terms',
              'We reserve the right to modify these terms at any time. We will notify you '
              'of significant changes through the app. Continued use of ReWireX after '
              'changes constitutes acceptance of the new terms.'),

            _section('12. Termination',
              'We may suspend or terminate your account at our discretion if you violate '
              'these terms. You may delete your account at any time through the Profile '
              'settings. Upon termination, your data will be deleted within 30 days.'),

            _section('13. Governing Law',
              'These terms are governed by the laws of India. Any disputes shall be resolved '
              'through binding arbitration in accordance with applicable law.'),

            _section('14. Contact Us',
              'If you have questions about these Terms of Service, please contact us at:\n\n'
              'Email: support@rewirex.app\n'
              'Website: www.rewirex.app'),

            const SizedBox(height: 24),

            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF141428),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.white.withOpacity(0.07), width: 1),
              ),
              child: Column(
                children: [
                  const Icon(Icons.verified_outlined,
                      color: Color(0xFF00C4A0), size: 28),
                  const SizedBox(height: 10),
                  const Text(
                    'Your recovery journey is safe with us',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'We are committed to your privacy, safety, and recovery.',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 13,
                        height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _intro(String text) {
    return Text(
      text,
      style: TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontSize: 14,
          height: 1.6),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.3),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF141428),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Colors.white.withOpacity(0.06), width: 1),
            ),
            child: Text(
              body,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                  height: 1.65),
            ),
          ),
        ],
      ),
    );
  }
}