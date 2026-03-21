// lib/features/streak/models/streak_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔥 Streak Model
class StreakModel {
  final int currentStreak;
  final int longestStreak;
  final int totalRelapses;
  final DateTime? lastRelapseDate;
  final DateTime startDate;    // ← when this streak began (used by timer)
  final DateTime updatedAt;    // ← last write time (NOT used by timer)

  // Extended analytics
  final double streakHealthScore;
  final int    daysToNextMilestone;
  final String nextMilestoneName;
  final bool   isPersonalBest;

  StreakModel({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalRelapses,
    this.lastRelapseDate,
    required this.startDate,
    required this.updatedAt,
    this.streakHealthScore   = 0,
    this.daysToNextMilestone = 0,
    this.nextMilestoneName   = '',
    this.isPersonalBest      = false,
  });

  factory StreakModel.fromMap(Map<String, dynamic> data) {
    final current  = (data['currentStreak']  as num?)?.toInt() ?? 0;
    final longest  = (data['longestStreak']  as num?)?.toInt() ?? 0;
    final relapses = (data['totalRelapses']  as num?)?.toInt() ?? 0;

    // ── startDate: when the current streak began ──────────────
    // Always derive from currentStreak count to guarantee timer accuracy.
    // Stored startDate can be wrong if it was set at check-in time (not midnight).
    // Formula: startDate = midnight of (today - (currentStreak - 1) days)
    // e.g. 1 day streak → startDate = today midnight
    //      12 day streak → startDate = 11 days ago midnight
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = current > 0
        ? today.subtract(Duration(days: current - 1))
        : today;

    final updatedAt = data['updatedAt'] != null
        ? (data['updatedAt'] as Timestamp).toDate()
        : DateTime.now();

    final milestone   = _nextMilestone(current);
    final healthScore = _computeHealthScore(current, longest, relapses);

    return StreakModel(
      currentStreak:       current,
      longestStreak:       longest,
      totalRelapses:       relapses,
      lastRelapseDate:     data['lastRelapseDate'] != null
          ? (data['lastRelapseDate'] as Timestamp).toDate() : null,
      startDate:           startDate,
      updatedAt:           updatedAt,
      streakHealthScore:   healthScore,
      daysToNextMilestone: milestone.days,
      nextMilestoneName:   milestone.name,
      isPersonalBest:      current > 0 && current >= longest,
    );
  }

  // ── Milestone system ──────────────────────────────────────────
  static ({int days, String name}) _nextMilestone(int current) {
    const milestones = [
      (3,   'Seeker'),
      (7,   'Resolute'),
      (14,  'Steadfast'),
      (30,  'Ironclad'),
      (60,  'Titan'),
      (90,  'Sovereign'),
      (180, 'Ascendant'),
      (365, 'Invincible'),
    ];
    for (final m in milestones) {
      if (current < m.$1) return (days: m.$1 - current, name: m.$2);
    }
    return (days: 0, name: 'Invincible');
  }

  static double _computeHealthScore(int current, int longest, int relapses) {
    double score = 50.0;
    score += (current * 1.0).clamp(0, 35);
    score -= (relapses * 4.0).clamp(0, 25);
    final gap = longest > 0 ? (longest - current) / longest : 0.0;
    score -= (gap * 10).clamp(0, 10);
    return score.clamp(0, 100);
  }
}