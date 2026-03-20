import 'package:flutter/material.dart';
import 'package:rewirex/features/streak/models/streak_model.dart';
import 'package:rewirex/features/streak/services/streak_service.dart';
import 'package:rewirex/features/streak/widgets/checkin_dialog.dart';
import 'package:rewirex/features/streak/widgets/relapse_dialog.dart';
import 'package:rewirex/features/streak/services/log_missed_days_screen.dart';

/// 📅 Daily Check-In Card
class DailyCheckInCard extends StatelessWidget {
  final StreakModel? streak;
  final StreakService streakService;
  final VoidCallback onRelapseRecorded;

  const DailyCheckInCard({
    super.key,
    required this.streak,
    required this.streakService,
    required this.onRelapseRecorded,
  });

  bool get _isAfter9PM => DateTime.now().hour >= 21;

  // ── Check-in flow ────────────────────────────────────────
  Future<void> _handleCheckIn(BuildContext context) async {
    final result = await showCheckInDialog(context);
    if (result == null || result == CheckInResult.cancelled) return;

    if (result == CheckInResult.confirmed) {
      // Record the check-in so the streak increments in Firestore
      await streakService.recordCheckIn();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.local_fire_department_rounded,
                  color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Day logged! Keep the streak alive 🔥'),
            ]),
            backgroundColor: const Color(0xFF00C4A0),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } else if (result == CheckInResult.relapsed) {
      if (context.mounted) await _handleRelapse(context);
    }
  }

  // ── Relapse flow ─────────────────────────────────────────
  Future<void> _handleRelapse(BuildContext context) async {
    final shouldReset = await showRelapseDialog(context);
    if (!shouldReset) return;

    await streakService.recordRelapse();
    onRelapseRecorded();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.favorite_border_rounded,
                color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text("New journey starts now. You've got this 💪"),
          ]),
          backgroundColor: const Color(0xFF6C63FF),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  // ── Log missed days ──────────────────────────────────────
  Future<void> _handleLogMissedDays(BuildContext context) async {
    await Navigator.push<Map<String, int>>(
      context,
      MaterialPageRoute(builder: (_) => const LogMissedDaysScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentStreak = streak?.currentStreak ?? 0;

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
          // Header
          Text(
            'DAILY CHECK-IN',
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 10),

          // Streak headline
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                '$currentStreak Day${currentStreak == 1 ? '' : 's'} Streak',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Check-in button (active only after 9 PM)
          _isAfter9PM
              ? _GradientButton(
                  label: 'CHECK IN NOW',
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: () => _handleCheckIn(context),
                )
              : const _LockedButton(
                  label: 'AVAILABLE AFTER 9 PM',
                  icon: Icons.lock_clock,
                ),

          const SizedBox(height: 12),

          // Log missed days
          _OutlineButton(
            label: 'LOG MISSED DAYS',
            icon: Icons.history_rounded,
            onPressed: () => _handleLogMissedDays(context),
          ),

          const SizedBox(height: 12),

          // Report relapse
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

// ── Button sub-widgets ────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
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
          icon: Icon(icon, size: 18, color: Colors.white),
          label: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 1.2,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
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
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: Colors.white.withOpacity(0.25)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.28),
              fontWeight: FontWeight.w600,
              fontSize: 12,
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
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17, color: Colors.white.withOpacity(0.55)),
        label: Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.55),
            fontWeight: FontWeight.w600,
            fontSize: 12,
            letterSpacing: 1.2,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withOpacity(0.14), width: 1),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
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
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 1.2,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE53935),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}