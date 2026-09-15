import 'dart:async';
import 'package:flutter/material.dart';
import '../models/streak_model.dart';

/// Displays a calendar-day streak.
///
/// IMPORTANT:
/// - DAYS comes from `currentStreak`, never from elapsed seconds.
/// - HOURS/MINS/SECS show progress through the current calendar day.
/// - When a new day begins, the clock resets to 00:00 while the streak day
///   remains unchanged until the user completes today's check-in.
/// - Reopening the app recalculates immediately.
class StreakTimerCard extends StatefulWidget {
  final StreakModel? streak;
  const StreakTimerCard({super.key, required this.streak});

  @override
  State<StreakTimerCard> createState() => _StreakTimerCardState();
}

class _StreakTimerCardState extends State<StreakTimerCard>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  Timer? _timer;
  Duration _todayElapsed = Duration.zero;

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

    _recalculate();
    _startTimer();
  }

  @override
  void didUpdateWidget(StreakTimerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streak?.currentStreak != widget.streak?.currentStreak ||
        oldWidget.streak?.lastCheckInDate != widget.streak?.lastCheckInDate ||
        oldWidget.streak?.startDate != widget.streak?.startDate) {
      _recalculate();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _recalculate();
    }
  }

  void _recalculate() {
    if (!mounted) return;
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final elapsed = now.difference(midnight);
    setState(() {
      _todayElapsed = elapsed.isNegative ? Duration.zero : elapsed;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _recalculate();
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
    final streak = widget.streak;
    final days = streak?.currentStreak ?? 0;

    final hours = _todayElapsed.inHours % 24;
    final mins = _todayElapsed.inMinutes % 60;
    final secs = _todayElapsed.inSeconds % 60;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: const Color(0xFF141428),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF6C63FF).withOpacity(0.2),
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
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _TimerUnit(value: days.toString(), label: 'DAYS'),
              const _Divider(),
              _TimerUnit(value: _pad(hours), label: 'HOURS'),
              const _Divider(),
              _TimerUnit(value: _pad(mins), label: 'MINS'),
              const _Divider(),
              _TimerUnit(value: _pad(secs), label: 'SECS'),
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
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF00C4A0),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '$days day${days == 1 ? '' : 's'} streak  •  Best: ${streak.longestStreak} days',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (days == 0) ...[
              const SizedBox(height: 8),
              Text(
                'Complete today’s check-in to start your streak.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.28),
                  fontSize: 11,
                ),
              ),
            ],
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
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
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
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
        ],
      );
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Text(
          ':',
          style: TextStyle(
            color: Colors.white.withOpacity(0.2),
            fontSize: 34,
            fontWeight: FontWeight.w300,
          ),
        ),
      );
}
