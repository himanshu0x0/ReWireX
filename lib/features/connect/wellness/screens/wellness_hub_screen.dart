// ============================================================
// PATH: lib/features/connect/wellness/screens/wellness_hub_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rewirex/features/connect/wellness/screens/breathing_screen.dart';
import 'package:rewirex/features/connect/wellness/screens/journal_screen.dart';
import 'package:rewirex/features/connect/wellness/screens/meditation_screen.dart';
import 'package:rewirex/features/connect/wellness/screens/mood_music_screen.dart';
import 'package:rewirex/features/connect/wellness/screens/wellness_card_screen.dart';


class WellnessHubScreen extends StatelessWidget {
  const WellnessHubScreen({super.key});

  static const _affirmations = [
    'Every day I choose recovery is a day I choose myself.',
    'I am stronger than my urges. I have proved this before.',
    'Progress, not perfection. One moment at a time.',
    'My brain is healing every day. The rewiring is real.',
    'I am not my addiction. I am the warrior fighting it.',
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0D0D1A),
    appBar: AppBar(
      backgroundColor: const Color(0xFF0D0D1A), elevation: 0,
      leading: IconButton(
        icon: Container(width: 36, height: 36,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.arrow_back_ios_new_rounded, size: 15,
              color: Colors.white.withOpacity(0.7))),
        onPressed: () => Navigator.pop(context)),
      title: ShaderMask(
        shaderCallback: (b) => const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)])
            .createShader(b),
        child: const Text('Wellness', style: TextStyle(
            color: Colors.white, fontSize: 22,
            fontWeight: FontWeight.w800)))),
    body: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        _moodBanner(context),
        const SizedBox(height: 24),
        Text('TOOLS', style: TextStyle(
            color: Colors.white.withOpacity(0.35), fontSize: 12,
            fontWeight: FontWeight.w700, letterSpacing: 2.5)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: WellnessCard(
              emoji: '🧘', title: 'Meditate',
              sub: 'Guided sessions',
              color: const Color(0xFF6C63FF),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const MeditationScreen())))),
          const SizedBox(width: 12),
          Expanded(child: WellnessCard(
              emoji: '🎵', title: 'Music Mood',
              sub: 'Playlists for you',
              color: const Color(0xFF00C4A0),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const MoodMusicScreen())))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: WellnessCard(
              emoji: '🌬️', title: 'Breathe',
              sub: '4-7-8 technique',
              color: const Color(0xFF4FC3F7),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const BreathingScreen())))),
          const SizedBox(width: 12),
          Expanded(child: WellnessCard(
              emoji: '📓', title: 'Journal',
              sub: 'Write it out',
              color: const Color(0xFFFFB74D),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const JournalScreen())))),
        ]),
        const SizedBox(height: 24),
        Text('DAILY AFFIRMATIONS', style: TextStyle(
            color: Colors.white.withOpacity(0.35), fontSize: 12,
            fontWeight: FontWeight.w700, letterSpacing: 2.5)),
        const SizedBox(height: 12),
        ..._affirmations.map((a) => _AffirmCard(text: a))])));

  Widget _moodBanner(BuildContext ctx) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: const LinearGradient(
          colors: [Color(0xFF1A1A35), Color(0xFF1A2A35)])),
    child: Row(children: [
      const Text('🌤️', style: TextStyle(fontSize: 36)),
      const SizedBox(width: 14),
      Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('How are you feeling?', style: TextStyle(
            color: Colors.white, fontSize: 16,
            fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Your wellness, tracked daily.',
            style: TextStyle(
                color: Colors.white.withOpacity(0.45), fontSize: 13))])),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFF6C63FF).withOpacity(0.3))),
        child: const Text('Check in', style: TextStyle(
            color: Color(0xFF6C63FF), fontSize: 13,
            fontWeight: FontWeight.w700)))]));
}

// ── Affirmation card ───────────────────────────────────────────

class _AffirmCard extends StatelessWidget {
  final String text;
  const _AffirmCard({required this.text});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color(0xFF141428),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07))),
    child: Row(children: [
      const Text('✨', style: TextStyle(fontSize: 18)),
      const SizedBox(width: 12),
      Expanded(child: Text(text, style: TextStyle(
          color: Colors.white.withOpacity(0.75),
          fontSize: 13, height: 1.5)))]));
}