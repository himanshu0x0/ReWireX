import 'package:flutter/material.dart';
import '../models/streak_model.dart';
import 'milestone_path_sheet.dart';

/// 🏆 Milestone Progress Card
/// Tappable — opens the full "Path to Invincible" bottom sheet.
class MilestoneProgressCard extends StatelessWidget {
  final StreakModel streak;

  const MilestoneProgressCard({super.key, required this.streak});

  static const List<_Milestone> _milestones = [
    _Milestone(rank: 'Awakened',   days: 0,   icon: Icons.wb_twilight_rounded),
    _Milestone(rank: 'Seeker',     days: 3,   icon: Icons.search_rounded),
    _Milestone(rank: 'Resolute',   days: 7,   icon: Icons.anchor_rounded),
    _Milestone(rank: 'Steadfast',  days: 14,  icon: Icons.shield_outlined),
    _Milestone(rank: 'Ironclad',   days: 30,  icon: Icons.security_rounded),
    _Milestone(rank: 'Titan',      days: 60,  icon: Icons.fitness_center_rounded),
    _Milestone(rank: 'Sovereign',  days: 90,  icon: Icons.military_tech_rounded),
    _Milestone(rank: 'Ascendant',  days: 180, icon: Icons.rocket_launch_rounded),
    _Milestone(rank: 'Invincible', days: 365, icon: Icons.auto_awesome),
  ];

  _MilestoneInfo _getInfo(int currentDays) {
    int currentIndex = 0;
    for (int i = _milestones.length - 1; i >= 0; i--) {
      if (currentDays >= _milestones[i].days) {
        currentIndex = i;
        break;
      }
    }
    final nextIndex = (currentIndex + 1).clamp(0, _milestones.length - 1);
    final current = _milestones[currentIndex];
    final next = _milestones[nextIndex];
    final bool isMax = currentIndex == _milestones.length - 1;
    final double progress = isMax
        ? 1.0
        : ((currentDays - current.days) / (next.days - current.days))
            .clamp(0.0, 1.0);
    return _MilestoneInfo(
      current: current,
      next: next,
      progress: progress,
      daysToNext: isMax ? 0 : next.days - currentDays,
      isMax: isMax,
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = _getInfo(streak.currentStreak);

    return GestureDetector(
      onTap: () => showMilestonePath(context, streak),
      child: Container(
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
            Row(
              children: [
                Text(
                  'MILESTONE PROGRESS',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.5,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Text(
                      'View path',
                      style: TextStyle(
                        color: const Color(0xFF6C63FF).withOpacity(0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: const Color(0xFF6C63FF).withOpacity(0.75),
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Current → Next
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RankBadge(icon: info.current.icon, isActive: true),
                      const SizedBox(height: 10),
                      Text(info.current.rank,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      Text('Current',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.38),
                              fontSize: 12)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 22),
                  child: Icon(Icons.arrow_forward_rounded,
                      color: Colors.white.withOpacity(0.2), size: 22),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child:
                            _RankBadge(icon: info.next.icon, isActive: false),
                      ),
                      const SizedBox(height: 10),
                      Text(info.next.rank,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      Text(info.isMax ? 'Max Rank 👑' : 'Next',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.32),
                              fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // Progress label row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Progress to next rank',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 12)),
                Text(
                  info.isMax
                      ? 'Max reached! 🎉'
                      : '${streak.currentStreak} / ${info.next.days} Days',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Animated progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: info.progress),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, value, __) => LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF6C63FF)),
                ),
              ),
            ),

            if (!info.isMax) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.bolt_rounded,
                      color: Color(0xFF00C4A0), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${info.daysToNext} more day${info.daysToNext == 1 ? '' : 's'} to ${info.next.rank}',
                    style: const TextStyle(
                        color: Color(0xFF00C4A0),
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  const _RankBadge({required this.icon, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: isActive
          ? BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withOpacity(0.38),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            )
          : BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
              border: Border.all(
                  color: Colors.white.withOpacity(0.1), width: 1.5),
            ),
      child: Icon(icon,
          color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
          size: 26),
    );
  }
}

class _Milestone {
  final String rank;
  final int days;
  final IconData icon;
  const _Milestone({required this.rank, required this.days, required this.icon});
}

class _MilestoneInfo {
  final _Milestone current;
  final _Milestone next;
  final double progress;
  final int daysToNext;
  final bool isMax;
  const _MilestoneInfo({
    required this.current,
    required this.next,
    required this.progress,
    required this.daysToNext,
    required this.isMax,
  });
}