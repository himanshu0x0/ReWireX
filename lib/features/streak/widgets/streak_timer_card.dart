import 'dart:async';
import 'package:flutter/material.dart';
import '../models/streak_model.dart';

class StreakTimerCard extends StatefulWidget {
  final StreakModel? streak;
  const StreakTimerCard({super.key, required this.streak});

  @override
  State<StreakTimerCard> createState() => _StreakTimerCardState();
}

class _StreakTimerCardState extends State<StreakTimerCard>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _recalcElapsed();
    _startTimer();
  }

  @override
  void didUpdateWidget(StreakTimerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.streak?.startDate != oldWidget.streak?.startDate) {
      _recalcElapsed();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _recalcElapsed();
  }

  void _recalcElapsed() {
    final start = widget.streak?.startDate;
    if (start != null) {
      setState(() => _elapsed = DateTime.now().difference(start));
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final start = widget.streak?.startDate;
      setState(() {
        _elapsed = start != null
            ? DateTime.now().difference(start)
            : _elapsed + const Duration(seconds: 1);
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final days  = _elapsed.inDays;
    final hours = _elapsed.inHours  % 24;
    final mins  = _elapsed.inMinutes % 60;
    final secs  = _elapsed.inSeconds % 60;
    final streak = widget.streak;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: const Color(0xFF141428),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF6C63FF).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.12),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'CURRENT STREAK',
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 13,        // was 12
              fontWeight: FontWeight.w600,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 22),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _TimerUnit(value: days.toString(), label: 'DAYS'),
              _Divider(),
              _TimerUnit(value: _pad(hours), label: 'HOURS'),
              _Divider(),
              _TimerUnit(value: _pad(mins),  label: 'MINS'),
              _Divider(),
              _TimerUnit(value: _pad(secs),  label: 'SECS'),
            ],
          ),

          if (streak != null) ...[
            const SizedBox(height: 22),
            Container(height: 1, color: Colors.white.withOpacity(0.06)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _pulseAnim,
                  child: Container(
                    width: 9, height: 9, // was 8
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF00C4A0),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${streak.currentStreak} day streak  •  Best: ${streak.longestStreak} days',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 14,        // was 13
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TimerUnit extends StatelessWidget {
  final String value;
  final String label;
  const _TimerUnit({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 42,        // was 39
            fontWeight: FontWeight.w800,
            height: 1.0,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.35),
            fontSize: 12,        // was 11
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Text(
        ':',
        style: TextStyle(
          color: Colors.white.withOpacity(0.2),
          fontSize: 34,        // was 31
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }
}