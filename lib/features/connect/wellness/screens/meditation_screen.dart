// ============================================================
// PATH: lib/features/connect/wellness/screens/meditation_screen.dart
// ============================================================

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MeditationScreen extends StatefulWidget {
  const MeditationScreen({super.key});
  @override State<MeditationScreen> createState() => _MeditationState();
}

class _MeditationState extends State<MeditationScreen>
    with TickerProviderStateMixin {
  late AnimationController _anim;
  int    _selected = -1;
  bool   _running  = false;
  int    _elapsed  = 0;
  Timer? _timer;

  static const _sessions = [
    {'emoji':'🧘','title':'Quick Reset',   'duration':3,
     'desc':'3-minute calm. Perfect for peak urge moments.'},
    {'emoji':'🌬️','title':'Breath Focus',  'duration':5,
     'desc':'5-minute breathing anchor. Stress melts away.'},
    {'emoji':'🌊','title':'Urge Surfing',   'duration':10,
     'desc':'10-min guided ride through the wave of craving.'},
    {'emoji':'🌙','title':'Sleep Prep',     'duration':15,
     'desc':'15-min relaxation for restorative sleep.'},
    {'emoji':'💪','title':'Morning Power', 'duration':7,
     'desc':'7-min intention setting to start clean.'},
  ];

  @override void initState() {
    super.initState();
    _anim = AnimationController(vsync: this,
        duration: const Duration(seconds: 4))..repeat(reverse: true);
  }
  @override void dispose() {
    _timer?.cancel(); _anim.dispose(); super.dispose();
  }

  void _start(int idx) {
    setState(() { _selected = idx; _running = true; _elapsed = 0; });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed++);
      final total = (_sessions[idx]['duration'] as int) * 60;
      if (_elapsed >= total) {
        _timer?.cancel();
        setState(() => _running = false);
      }
    });
  }

  void _stop() {
    _timer?.cancel();
    setState(() { _running = false; _selected = -1; _elapsed = 0; });
  }

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
      title: const Text('Meditate', style: TextStyle(
          color: Colors.white, fontSize: 20,
          fontWeight: FontWeight.w800))),
    body: _running ? _buildActive() : _buildSessions());

  Widget _buildSessions() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
    children: [
      Container(padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
              colors: [Color(0xFF1A1030), Color(0xFF0D1A25)])),
        child: Column(children: [
          AnimatedBuilder(animation: _anim, builder: (_, __) =>
              Container(width: 80, height: 80,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: const Color(0xFF6C63FF)
                      .withOpacity(0.1 + _anim.value * 0.1),
                  border: Border.all(color: const Color(0xFF6C63FF)
                      .withOpacity(0.3 + _anim.value * 0.3))),
                child: const Center(child: Text('🧘',
                    style: TextStyle(fontSize: 36))))),
          const SizedBox(height: 14),
          const Text('Choose a session', style: TextStyle(
              color: Colors.white, fontSize: 18,
              fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Science-backed techniques from clinical recovery research.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.45), fontSize: 13))])),
      const SizedBox(height: 20),
      ..._sessions.asMap().entries.map((e) => GestureDetector(
        onTap: () { HapticFeedback.mediumImpact(); _start(e.key); },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF141428),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.white.withOpacity(0.07))),
          child: Row(children: [
            Container(width: 48, height: 48,
              decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(e.value['emoji'] as String,
                  style: const TextStyle(fontSize: 24)))),
            const SizedBox(width: 14),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.value['title'] as String, style: const TextStyle(
                  color: Colors.white, fontSize: 15,
                  fontWeight: FontWeight.w700)),
              Text(e.value['desc'] as String, style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 12, height: 1.4), maxLines: 2)])),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Text('${e.value['duration']}m',
                  style: const TextStyle(
                      color: Color(0xFF6C63FF),
                      fontSize: 12,
                      fontWeight: FontWeight.w700)))]))))]);

  Widget _buildActive() {
    final session = _sessions[_selected];
    final total   = (session['duration'] as int) * 60;
    final left    = total - _elapsed;
    final prog    = _elapsed / total;
    final mins    = left ~/ 60;
    final secs    = left % 60;
    return Padding(padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center,
          children: [
        AnimatedBuilder(animation: _anim, builder: (_, __) =>
            Container(width: 160, height: 160,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: const Color(0xFF6C63FF)
                    .withOpacity(0.08 + _anim.value * 0.08),
                border: Border.all(
                    color: const Color(0xFF6C63FF)
                        .withOpacity(0.2 + _anim.value * 0.3),
                    width: 2)),
              child: Center(child: Text(session['emoji'] as String,
                  style: const TextStyle(fontSize: 64))))),
        const SizedBox(height: 32),
        Text(session['title'] as String, style: const TextStyle(
            color: Colors.white, fontSize: 22,
            fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('$mins:${secs.toString().padLeft(2, '0')} remaining',
            style: const TextStyle(
                color: Color(0xFF6C63FF), fontSize: 28,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 24),
        ClipRRect(borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: prog, minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.07),
              valueColor: const AlwaysStoppedAnimation(
                  Color(0xFF6C63FF)))),
        const SizedBox(height: 32),
        Text(session['desc'] as String, textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14, height: 1.5)),
        const SizedBox(height: 32),
        SizedBox(width: double.infinity, height: 52,
          child: OutlinedButton(
            onPressed: _stop,
            style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
            child: Text('End Session', style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontWeight: FontWeight.w600))))]));
  }
}