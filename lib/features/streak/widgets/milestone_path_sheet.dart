import 'package:flutter/material.dart';
import '../models/streak_model.dart';

class _MilestoneDef {
  final String rank;
  final String subtitle;
  final int days;
  final IconData icon;

  const _MilestoneDef({
    required this.rank, required this.subtitle,
    required this.days, required this.icon,
  });
}

const List<_MilestoneDef> kMilestonePath = [
  _MilestoneDef(rank: 'Awakened',   subtitle: 'The journey begins.',               days: 0,   icon: Icons.wb_twilight_rounded),
  _MilestoneDef(rank: 'Seeker',     subtitle: 'Curiosity becomes commitment.',      days: 3,   icon: Icons.search_rounded),
  _MilestoneDef(rank: 'Resolute',   subtitle: 'Your will is taking shape.',         days: 7,   icon: Icons.anchor_rounded),
  _MilestoneDef(rank: 'Steadfast',  subtitle: 'Two weeks of unbroken resolve.',     days: 14,  icon: Icons.shield_outlined),
  _MilestoneDef(rank: 'Ironclad',   subtitle: 'A month of forged discipline.',      days: 30,  icon: Icons.security_rounded),
  _MilestoneDef(rank: 'Titan',      subtitle: 'You are built differently now.',     days: 60,  icon: Icons.fitness_center_rounded),
  _MilestoneDef(rank: 'Sovereign',  subtitle: 'Three months — total self-mastery.', days: 90,  icon: Icons.military_tech_rounded),
  _MilestoneDef(rank: 'Ascendant',  subtitle: 'Half a year of transformation.',     days: 180, icon: Icons.rocket_launch_rounded),
  _MilestoneDef(rank: 'Invincible', subtitle: 'A full year. Nothing can stop you.', days: 365, icon: Icons.auto_awesome),
];

void showMilestonePath(BuildContext context, StreakModel streak) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MilestonePathSheet(streak: streak),
  );
}

class _MilestonePathSheet extends StatelessWidget {
  final StreakModel streak;
  const _MilestonePathSheet({required this.streak});

  int get _currentDays => streak.currentStreak;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF12121F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              _buildHeader(context),
              Divider(color: Colors.white.withOpacity(0.06), height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  itemCount: kMilestonePath.length,
                  itemBuilder: (_, i) {
                    final milestone  = kMilestonePath[i];
                    final isLast      = i == kMilestonePath.length - 1;
                    final isCompleted = _currentDays >= milestone.days;
                    final isCurrent   = _isCurrentRank(i);
                    return _TimelineItem(
                      milestone: milestone,
                      isCompleted: isCompleted,
                      isCurrent: isCurrent,
                      isLast: isLast,
                      currentDays: _currentDays,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isCurrentRank(int index) {
    for (int i = kMilestonePath.length - 1; i >= 0; i--) {
      if (_currentDays >= kMilestonePath[i].days) return i == index;
    }
    return index == 0;
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
      child: Row(
        children: [
          Container(
            width: 48, height: 48, // was 44
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22), // was 20
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'The Path to Invincible',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,        // was 18
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'Your complete 365-day transformation.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 13,        // was 12
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.close_rounded,
                  color: Colors.white.withOpacity(0.5), size: 19), // was 18
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final _MilestoneDef milestone;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLast;
  final int currentDays;

  const _TimelineItem({
    required this.milestone, required this.isCompleted,
    required this.isCurrent, required this.isLast, required this.currentDays,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60, // was 56
            child: Column(
              children: [
                _buildBadge(),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: isCompleted
                            ? const LinearGradient(
                                colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              )
                            : null,
                        color: isCompleted ? null : Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 8 : 28, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        milestone.rank,
                        style: TextStyle(
                          color: isCompleted || isCurrent
                              ? Colors.white
                              : Colors.white.withOpacity(0.38),
                          fontSize: 17,        // was 16
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'YOU ARE HERE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                      if (isCompleted && !isCurrent) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF00C4A0), size: 16), // was 15
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    milestone.subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(
                          isCompleted || isCurrent ? 0.5 : 0.22),
                      fontSize: 13,        // was 12
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Requires ${milestone.days} day${milestone.days == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: isCurrent
                          ? const Color(0xFF6C63FF)
                          : isCompleted
                              ? const Color(0xFF00C4A0).withOpacity(0.7)
                              : Colors.white.withOpacity(0.2),
                      fontSize: 13,        // was 12
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge() {
    if (isCurrent) {
      return Container(
        width: 56, height: 56, // was 52
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withOpacity(0.45),
              blurRadius: 18, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(milestone.icon, color: Colors.white, size: 26), // was 24
      );
    }
    if (isCompleted) {
      return Container(
        width: 56, height: 56, // was 52
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF00C4A0).withOpacity(0.12),
          border: Border.all(color: const Color(0xFF00C4A0).withOpacity(0.4), width: 1.5),
        ),
        child: Icon(milestone.icon,
            color: const Color(0xFF00C4A0).withOpacity(0.8), size: 24), // was 22
      );
    }
    return Container(
      width: 56, height: 56, // was 52
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
      ),
      child: Icon(milestone.icon,
          color: Colors.white.withOpacity(0.2), size: 24), // was 22
    );
  }
}