// lib/features/streak/models/streak_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔥 Streak Model
class StreakModel {
  final int currentStreak;
  final int longestStreak;
  final int totalRelapses;
  final DateTime? lastRelapseDate;
  final DateTime startDate;
  final DateTime updatedAt;

  // Extended analytics
  final double streakHealthScore;
  final int daysToNextMilestone;
  final String nextMilestoneName;
  final bool isPersonalBest;

  StreakModel({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalRelapses,
    this.lastRelapseDate,
    required this.startDate,
    required this.updatedAt,
    this.streakHealthScore = 0,
    this.daysToNextMilestone = 0,
    this.nextMilestoneName = '',
    this.isPersonalBest = false,
  });

  factory StreakModel.fromMap(Map<String, dynamic> data) {
    final current  = (data['currentStreak']  as num?)?.toInt() ?? 0;
    final longest  = (data['longestStreak']  as num?)?.toInt() ?? 0;
    final relapses = (data['totalRelapses']  as num?)?.toInt() ?? 0;

    final milestone   = _nextMilestone(current);
    final healthScore = _computeHealthScore(current, longest, relapses);

    return StreakModel(
      currentStreak:  current,
      longestStreak:  longest,
      totalRelapses:  relapses,
      lastRelapseDate: data['lastRelapseDate'] != null
          ? (data['lastRelapseDate'] as Timestamp).toDate() : null,
      startDate: data['startDate'] != null
          ? (data['startDate'] as Timestamp).toDate() : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate() : DateTime.now(),
      streakHealthScore:   healthScore,
      daysToNextMilestone: milestone.days,
      nextMilestoneName:   milestone.name,
      isPersonalBest:      current > 0 && current >= longest,
    );
  }

  // Milestone system (matches milestone_path_sheet.dart ranks)
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