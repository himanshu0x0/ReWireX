// lib/features/streak/models/streak_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// A calendar-day based recovery streak.
///
/// `currentStreak` is the number of consecutive clean days that have been
/// successfully checked in. It is NOT a duration in seconds.
class StreakModel {
  final int currentStreak;
  final int longestStreak;
  final int totalRelapses;
  final DateTime? lastRelapseDate;

  /// Midnight of the first day of the current streak.
  final DateTime startDate;

  /// Last successful check-in write time.
  final DateTime updatedAt;

  /// Date key of the last successful check-in (`yyyy-MM-dd`).
  final String lastCheckInDate;

  final double streakHealthScore;
  final int daysToNextMilestone;
  final String nextMilestoneName;
  final bool isPersonalBest;

  const StreakModel({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalRelapses,
    this.lastRelapseDate,
    required this.startDate,
    required this.updatedAt,
    this.lastCheckInDate = '',
    this.streakHealthScore = 0,
    this.daysToNextMilestone = 0,
    this.nextMilestoneName = '',
    this.isPersonalBest = false,
  });

  factory StreakModel.fromMap(Map<String, dynamic> data) {
    final current = _int(data['currentStreak']);
    final longest = _int(data['longestStreak']);
    final relapses = _int(data['totalRelapses']);

    final rawStart = _timestamp(data['startDate']);
    final rawUpdated = _timestamp(data['updatedAt']);
    final lastCheckIn = data['lastCheckInDate'] as String? ?? '';

    // Older documents may not contain startDate. Keep the model usable without
    // inventing a running timer from the current wall-clock time.
    final fallbackToday = _midnight(DateTime.now());
    final startDate = rawStart == null ? fallbackToday : _midnight(rawStart);
    final updatedAt = rawUpdated ?? DateTime.now();

    final milestone = _nextMilestone(current);
    final health = _computeHealthScore(current, longest, relapses);

    return StreakModel(
      currentStreak: current,
      longestStreak: longest,
      totalRelapses: relapses,
      lastRelapseDate: _timestamp(data['lastRelapseDate']),
      startDate: startDate,
      updatedAt: updatedAt,
      lastCheckInDate: lastCheckIn,
      streakHealthScore: health,
      daysToNextMilestone: milestone.days,
      nextMilestoneName: milestone.name,
      isPersonalBest: current > 0 && current >= longest,
    );
  }

  static int _int(dynamic value) => value is num ? value.toInt() : 0;

  static DateTime? _timestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static DateTime _midnight(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static ({int days, String name}) _nextMilestone(int current) {
    const milestones = [
      (3, 'Seeker'),
      (7, 'Resolute'),
      (14, 'Steadfast'),
      (30, 'Ironclad'),
      (60, 'Titan'),
      (90, 'Sovereign'),
      (180, 'Ascendant'),
      (365, 'Invincible'),
    ];
    for (final m in milestones) {
      if (current < m.$1) return (days: m.$1 - current, name: m.$2);
    }
    return (days: 0, name: 'Invincible');
  }

  static double _computeHealthScore(
      int current, int longest, int relapses) {
    double score = 50.0;
    score += (current * 1.0).clamp(0, 35);
    score -= (relapses * 4.0).clamp(0, 25);
    final gap = longest > 0 ? (longest - current) / longest : 0.0;
    score -= (gap * 10).clamp(0, 10);
    return score.clamp(0, 100);
  }
}
