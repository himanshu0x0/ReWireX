import 'package:flutter/material.dart';
import 'package:rewirex/features/streak/services/log_missed_days_screen.dart';
import 'package:rewirex/features/streak/services/streak_service.dart';
import 'package:rewirex/features/streak/widgets/checkin_dialog.dart';
import 'package:rewirex/features/streak/widgets/relapse_dialog.dart';

class DailyCheckInCard extends StatefulWidget {
  final StreakModel? streak;
  final StreakService streakService;
  final VoidCallback onRelapseRecorded;

  const DailyCheckInCard({
    super.key,
    required this.streak,
    required this.streakService,
    required this.onRelapseRecorded,
  });

  @override
  State<DailyCheckInCard> createState() => _DailyCheckInCardState();
}

class _DailyCheckInCardState extends State<DailyCheckInCard>
    with WidgetsBindingObserver {
  bool _checkedInToday = false;
  bool _loadingStatus = true;
  bool _actionInFlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCheckInStatus();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadCheckInStatus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadCheckInStatus() async {
    try {
      await widget.streakService.updateDailyStreak();
      final done = await widget.streakService.hasCheckedInToday();
      if (mounted) {
        setState(() {
          _checkedInToday = done;
          _loadingStatus = false;
        });
      }
    } catch (e) {
      debugPrint('Daily check-in status error: $e');
      if (mounted) setState(() => _loadingStatus = false);
    }
  }

  bool get _isAvailableNow => true;

  Future<void> _handleCheckIn(BuildContext context) async {
    if (_actionInFlight || _checkedInToday) return;

    setState(() => _actionInFlight = true);
    try {
      final result = await showCheckInDialog(context);
      if (!mounted || result == null || result == CheckInResult.cancelled)
        return;

      if (result == CheckInResult.confirmed) {
        final outcome = await widget.streakService.recordCheckIn();

        if (!context.mounted) return;

        if (outcome == StreakCheckInResult.alreadyCheckedIn) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'You have already checked in today. Come back tomorrow! 🌅',
                style: TextStyle(fontSize: 15), // was 14
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
          return;
        }

        setState(() => _checkedInToday = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 20,
                ), // was 18
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Day logged! Keep the streak alive 🔥',
                    style: TextStyle(fontSize: 15), // was 14
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF00C4A0),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      } else if (result == CheckInResult.relapsed) {
        if (context.mounted) await _handleRelapse(context);
      }
    } catch (e) {
      debugPrint('Daily check-in error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save today’s check-in. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _actionInFlight = false);
    }
  }

  Future<void> _handleRelapse(BuildContext context) async {
    final shouldReset = await showRelapseDialog(context);
    if (!shouldReset) return;

    try {
      final outcome = await widget.streakService.recordRelapse();
      if (!mounted) return;

      if (outcome == StreakRelapseResult.notAuthenticated) return;

      if (outcome == StreakRelapseResult.alreadyRecordedToday) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Today’s relapse has already been recorded.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      widget.onRelapseRecorded();
    } catch (e) {
      debugPrint('Relapse error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not record the relapse. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    if (mounted) setState(() => _checkedInToday = false);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(
                Icons.favorite_border_rounded,
                color: Colors.white,
                size: 20,
              ), // was 18
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "New journey starts now. You've got this 💪",
                  style: TextStyle(fontSize: 15), // was 14
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF6C63FF),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _handleLogMissedDays(BuildContext context) async {
    await Navigator.push<Map<String, int>>(
      context,
      MaterialPageRoute(builder: (_) => const LogMissedDaysScreen()),
    );
  }

  String get _buttonState {
    if (_checkedInToday) return 'done';
    if (_isAvailableNow) return 'available';
    return 'locked';
  }

  @override
  Widget build(BuildContext context) {
    final currentStreak = widget.streak?.currentStreak ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF141428),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────
          Text(
            'DAILY CHECK-IN',
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 12, // was 11
              fontWeight: FontWeight.w600,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 10),

          // ── Streak headline ──────────────────────────────
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 26)), // was 22
              const SizedBox(width: 8),
              Text(
                '$currentStreak Day${currentStreak == 1 ? '' : 's'} Streak',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28, // was 26
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Check-in button ──────────────────────────────
          if (_loadingStatus)
            const _LockedButton(
              label: 'LOADING...',
              icon: Icons.hourglass_empty_rounded,
            )
          else if (_buttonState == 'done')
            const _DoneButton()
          else if (_buttonState == 'available')
            _GradientButton(
              label: 'CHECK IN NOW',
              icon: Icons.check_circle_outline_rounded,
              onPressed: _actionInFlight ? null : () => _handleCheckIn(context),
            )
          else
            const _LockedButton(
              label: 'COME BACK TOMORROW',
              icon: Icons.lock_clock,
            ),

          const SizedBox(height: 12),

          _OutlineButton(
            label: 'LOG MISSED DAYS',
            icon: Icons.history_rounded,
            onPressed: () => _handleLogMissedDays(context),
          ),

          const SizedBox(height: 12),

          _DangerButton(
            label: 'REPORT RELAPSE',
            icon: Icons.warning_amber_rounded,
            onPressed: () => _handleRelapse(context),
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54, // was 50
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withOpacity(0.28),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20, color: Colors.white), // was 18
          label: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14, // was 13
              letterSpacing: 1.2,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}

class _DoneButton extends StatelessWidget {
  const _DoneButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 54, // was 50
      decoration: BoxDecoration(
        color: const Color(0xFF00C4A0).withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF00C4A0).withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF00C4A0),
            size: 20,
          ), // was 18
          const SizedBox(width: 8),
          const Text(
            'CHECKED IN TODAY ✓',
            style: TextStyle(
              color: Color(0xFF00C4A0),
              fontWeight: FontWeight.w700,
              fontSize: 14, // was 13
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedButton extends StatelessWidget {
  final String label;
  final IconData icon;

  const _LockedButton({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 54, // was 50
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Colors.white.withOpacity(0.25)), // was 15
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.28),
              fontWeight: FontWeight.w600,
              fontSize: 13, // was 12
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _OutlineButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54, // was 50
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 18,
          color: Colors.white.withOpacity(0.55),
        ), // was 17
        label: Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.55),
            fontWeight: FontWeight.w600,
            fontSize: 13, // was 12
            letterSpacing: 1.2,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withOpacity(0.14), width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _DangerButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54, // was 50
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: Colors.white), // was 18
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14, // was 13
            letterSpacing: 1.2,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE53935),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
