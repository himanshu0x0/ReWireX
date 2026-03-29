// ============================================================
// PATH: lib/features/connect/wellness/screens/breathing_screen.dart
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});
  @override State<BreathingScreen> createState() => _BreathingState();
}

class _BreathingState extends State<BreathingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;
  int    _phase  = 0; // 0=inhale 1=hold 2=exhale
  int    _secs   = 4;
  int    _cycles = 0;
  bool   _active = false;
  Timer? _timer;

  static const _labels    = ['Inhale', 'Hold', 'Exhale'];
  static const _durations = [4, 7, 8];
  static const _colors    = [
    Color(0xFF6C63FF), Color(0xFF00C4A0), Color(0xFF4FC3F7)];

  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 4));
    _anim = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override void dispose() {
    _timer?.cancel(); _ctrl.dispose(); super.dispose();
  }

  void _start() {
    setState(() { _active = true; _phase = 0; _secs = 4; _cycles = 0; });
    _ctrl.forward(from: 0);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secs--);
      if (_secs <= 0) {
        _phase = (_phase + 1) % 3;
        _secs  = _durations[_phase];
        if (_phase == 0) {
          _cycles++;
          if (_cycles >= 3) {
            _timer?.cancel();
            setState(() => _active = false);
            return;
          }
        }
        if (_phase == 0) _ctrl.forward(from: 0);
        else if (_phase == 2) _ctrl.reverse(from: 1);
        else _ctrl.stop();
      }
    });
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
      title: const Text('4-7-8 Breathing', style: TextStyle(
          color: Colors.white, fontSize: 20,
          fontWeight: FontWeight.w800))),
    body: Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center,
          children: [
        AnimatedBuilder(animation: _anim, builder: (_, __) {
          final color = _active
              ? _colors[_phase] : const Color(0xFF6C63FF);
          final scale = _active ? _anim.value : 0.75;
          return GestureDetector(
            onTap: _active ? null : _start,
            child: Stack(alignment: Alignment.center, children: [
              AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 180 * scale + 20,
                  height: 180 * scale + 20,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: color.withOpacity(0.07))),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 160 * scale, height: 160 * scale,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: color.withOpacity(0.1),
                    border: Border.all(
                        color: color.withOpacity(0.5), width: 2.5)),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Text(_active ? _labels[_phase] : 'TAP\nTO START',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: color,
                          fontSize: _active ? 16 : 13,
                          fontWeight: FontWeight.w800)),
                  if (_active) ...[
                    const SizedBox(height: 4),
                    Text('$_secs', style: TextStyle(
                        color: color.withOpacity(0.7),
                        fontSize: 32,
                        fontWeight: FontWeight.w900))]]))]));}),
        const SizedBox(height: 32),
        if (_active)
          Row(mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) => Container(
              width: 10, height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(shape: BoxShape.circle,
                  color: i < _cycles
                      ? const Color(0xFF00C4A0)
                      : Colors.white.withOpacity(0.15)))))
        else
          Text('3 cycles · Reduces craving by up to 40%',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 13))]))));
}