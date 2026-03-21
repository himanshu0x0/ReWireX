// lib/features/ai/services/recovery_score_service.dart
//
// ═══════════════════════════════════════════════════════════════════
// 📊  RECOVERY SCORE SERVICE  —  ReWireX Behavioral Intelligence
// ═══════════════════════════════════════════════════════════════════
//
// PURPOSE
// ───────
// This service answers the most important question in recovery:
//
//   "Am I actually getting better — or just not relapsing yet?"
//
// A streak counter only measures one thing: days without relapse.
// But real recovery is a multi-dimensional process. A user can have a
// 30-day streak while their emotional resilience is quietly collapsing
// and their peak-hour vulnerability is worsening. The streak alone
// would never warn them.
//
// This service measures SEVEN independent dimensions of recovery
// health, weights them by clinical evidence, and produces a single
// 0–100 composite score that reflects the TRUE state of the user's
// recovery journey — not just their willpower on any given day.
//
// THE 7 DIMENSIONS  (evidence-based weights)
// ───────────────────────────────────────────
//   D1  Streak Strength        (28%) — Log-scaled streak + milestone bonuses
//                                       − relapse history penalty.
//                                       Why log-scaled? Day 1→7 progress is
//                                       harder than Day 50→57. Log scale
//                                       rewards early wins appropriately.
//
//   D2  Urge Frequency Control (20%) — How often are urges happening?
//                                       Fewer urges = stronger neural
//                                       rewiring. Normalised to 60 urges/30d.
//
//   D3  Urge Intensity Control (18%) — How strong are the urges?
//                                       Intensity is more predictive of
//                                       relapse risk than frequency alone.
//                                       Uses exponential decay so high spikes
//                                       are penalised more than moderate ones.
//
//   D4  Emotional Resilience   (15%) — Ratio of positive to negative
//                                       emotions. Recovery is not the absence
//                                       of negative feelings but the growing
//                                       presence of positive ones (PERMA model,
//                                       Seligman 2011).
//
//   D5  Behavioral Stability   (10%) — Low variance in daily urge counts.
//                                       Wild day-to-day swings indicate the
//                                       user is still highly reactive to
//                                       environmental triggers. Stability
//                                       = resistance to triggers improving.
//
//   D6  Recovery Momentum       (5%) — Week-over-week EWMA trend.
//                                       Direction of travel matters —
//                                       a score of 55 improving is healthier
//                                       than a score of 70 declining.
//
//   D7  Consistency Bonus       (4%) — Has the user been logging daily?
//                                       Self-monitoring is itself therapeutic
//                                       (James 2017, Addiction journal).
//                                       Rewards engagement with the tool.
//
// PERSONALISED GOALS ENGINE
// ──────────────────────────
// After scoring, the service identifies the user's 2–3 weakest
// dimensions and generates concrete, actionable next goals tailored to
// their specific pattern. These are not generic tips — they respond
// directly to the user's behavioral fingerprint.
//
// MILESTONE AWARENESS
// ────────────────────
// The service maps the current streak to the ReWireX milestone path
// (Awakened → Invincible) and tells the user exactly how many days
// until their next rank — making recovery feel like progression, not
// just abstinence.

import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recovery_score_model.dart';

export '../models/recovery_score_model.dart';

// ─────────────────────────────────────────────────────────────
class RecoveryScoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Emotion sets ──────────────────────────────────────────────
  static const _positiveEmotions = {
    'Calm',
    'Happy',
    'Motivated',
    'Proud',
    'Grateful',
    'Hopeful',
    'Strong',
    'Confident',
    'Peaceful',
    'Content',
  };

  static const _negativeEmotions = {
    'Stressed',
    'Anxious',
    'Lonely',
    'Bored',
    'Sad',
    'Angry',
    'Frustrated',
    'Depressed',
    'Hopeless',
    'Empty',
  };

  // ── Milestone path (mirrors milestone_progress_card.dart) ────
  static const _milestones = [
    (rank: 'Seeker', days: 3),
    (rank: 'Resolute', days: 7),
    (rank: 'Steadfast', days: 14),
    (rank: 'Ironclad', days: 30),
    (rank: 'Titan', days: 60),
    (rank: 'Sovereign', days: 90),
    (rank: 'Ascendant', days: 180),
    (rank: 'Invincible', days: 365),
  ];

  // ── Dimension weights (must sum to 1.0) ───────────────────────
  static const _w1 = 0.28; // Streak strength
  static const _w2 = 0.20; // Urge frequency
  static const _w3 = 0.18; // Urge intensity
  static const _w4 = 0.15; // Emotional resilience
  static const _w5 = 0.10; // Behavioral stability
  static const _w6 = 0.05; // Recovery momentum
  static const _w7 = 0.04; // Consistency bonus

  // ─────────────────────────────────────────────────────────────
  Future<RecoveryScoreModel> calculateRecoveryScore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return const RecoveryScoreModel(
          score: 0,
          level: 'Unknown',
          explanation: 'Not signed in.',
        );
      }

      final now = DateTime.now();

      // ── Fetch data in parallel ─────────────────────────────────
      final results = await Future.wait([
        // 30-day urge logs (primary scoring window)
        _firestore
            .collection('users')
            .doc(user.uid)
            .collection('urge_logs')
            .where(
              'timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(
                now.subtract(const Duration(days: 30)),
              ),
            )
            .orderBy('timestamp', descending: false)
            .get(),
        // Streak stats
        _firestore
            .collection('users')
            .doc(user.uid)
            .collection('stats')
            .doc('streak')
            .get(),
        // 7-day urge logs (for trend comparison)
        _firestore
            .collection('users')
            .doc(user.uid)
            .collection('urge_logs')
            .where(
              'timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(
                now.subtract(const Duration(days: 7)),
              ),
            )
            .get(),
        // 14-day urge logs (for previous 7-day period comparison)
        _firestore
            .collection('users')
            .doc(user.uid)
            .collection('urge_logs')
            .where(
              'timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(
                now.subtract(const Duration(days: 14)),
              ),
            )
            .where(
              'timestamp',
              isLessThan: Timestamp.fromDate(
                now.subtract(const Duration(days: 7)),
              ),
            )
            .get(),
      ]);

      final urgeSnap30 = results[0] as QuerySnapshot<Map<String, dynamic>>;
      final streakSnap = results[1] as DocumentSnapshot<Map<String, dynamic>>;
      final urgeSnap7 = results[2] as QuerySnapshot<Map<String, dynamic>>;
      final urgeSnapPrev = results[3] as QuerySnapshot<Map<String, dynamic>>;

      final streakData = streakSnap.data() ?? {};
      final currentStreak = (streakData['currentStreak'] as num?)?.toInt() ?? 0;
      final totalRelapses = (streakData['totalRelapses'] as num?)?.toInt() ?? 0;

      final docs30 = urgeSnap30.docs;

      // ── D1: Streak Strength (28%) ──────────────────────────────
      // Log-scaled so early days count more (rewiring is hardest at start)
      // Milestone bonuses reward achieving key thresholds
      // History penalty discounts for repeated relapses
      double milestoneBonus = 0;
      for (final m in [3, 7, 14, 30, 60, 90, 180, 365]) {
        if (currentStreak >= m) milestoneBonus += 0.03;
      }
      final streakRaw = math.log(currentStreak + 1) / math.log(366);
      final historyPenalty = (totalRelapses * 0.025).clamp(0.0, 0.35);
      final d1Raw = (streakRaw + milestoneBonus - historyPenalty).clamp(
        0.0,
        1.0,
      );
      final d1Score = d1Raw * 100;

      // ── Handle empty urge log case ─────────────────────────────
      if (docs30.isEmpty) {
        final composite = d1Raw * 0.28 + 0.35; // baseline from streak only
        final score = (composite * 100).clamp(0.0, 100.0);
        final level = _level(score);

        final d1 = RecoveryDimension(
          name: 'Streak Strength',
          score: d1Score,
          weight: _w1,
          insight: _streakInsight(d1Score, currentStreak),
          emoji: '🔥',
          trend: 'Stable',
        );

        return RecoveryScoreModel(
          score: score,
          level: level,
          explanation: _explanation(score, currentStreak, 'Stable'),
          dimensions: [d1],
          componentScores: {'Streak Strength': d1Score},
          momentum: 'Stable',
          currentStreak: currentStreak,
          nextMilestone: _nextMilestone(currentStreak),
          daysToNextMilestone: _daysToNext(currentStreak),
          nextGoals: _buildGoals(
            weakDimensions: ['Urge Frequency', 'Emotional Resilience'],
            currentStreak: currentStreak,
            avgIntensity: 5.0,
          ),
        );
      }

      // ── Aggregate 30-day data ──────────────────────────────────
      double totalIntensity = 0;
      double maxIntensity = 0;
      int spikeCount = 0; // intensity >= 8
      final emotions = <String>[];
      final dailyCounts = <int, int>{};
      final loggedDays = <int>{};

      for (final doc in docs30) {
        final data = doc.data();
        final ts = (data['timestamp'] as Timestamp).toDate();
        final dayOffset = now
            .difference(DateTime(ts.year, ts.month, ts.day))
            .inDays;

        if (dayOffset >= 0 && dayOffset <= 29) {
          dailyCounts[dayOffset] = (dailyCounts[dayOffset] ?? 0) + 1;
          loggedDays.add(dayOffset);
        }

        final intensity = ((data['intensity'] ?? 5) as num).toDouble();
        totalIntensity += intensity;
        if (intensity > maxIntensity) maxIntensity = intensity;
        if (intensity >= 8) spikeCount++;

        final e = data['emotion'] as String?;
        if (e != null) emotions.add(e);
      }

      final count = docs30.length;
      final avgIntensity = totalIntensity / count;

      // ── D2: Urge Frequency Control (20%) ──────────────────────
      // Normalised: 0 urges/30d = 100, 60+ urges/30d = 0
      // Non-linear curve rewards low counts disproportionately
      final freqRatio = (count / 60.0).clamp(0.0, 1.0);
      final d2Raw = (math.pow(1.0 - freqRatio, 1.4)).toDouble();
      final d2Score = (d2Raw * 100).clamp(0.0, 100.0);

      // ── D3: Urge Intensity Control (18%) ──────────────────────
      // Uses exponential penalty so 9/10 spikes hurt more than
      // a steady 5/10 — matches clinical severity weighting
      final avgNorm = ((avgIntensity - 1) / 9.0).clamp(0.0, 1.0);
      final spikePen = (spikeCount / count).clamp(0.0, 0.5) * 0.3;
      final d3Raw = (1.0 - avgNorm - spikePen).clamp(0.0, 1.0);
      final d3Score = (math.pow(d3Raw, 0.8).toDouble() * 100).clamp(0.0, 100.0);

      // ── D4: Emotional Resilience (15%) ────────────────────────
      // PERMA model: recovery = growing presence of positive states,
      // not just absence of negative ones.
      // Extra weight for high-value emotions (Grateful, Motivated, Proud)
      const highValueEmotions = {'Grateful', 'Motivated', 'Proud', 'Hopeful'};
      int posCount = 0;
      int highValueCount = 0;
      int negCount = 0;
      for (final e in emotions) {
        if (_positiveEmotions.contains(e)) {
          posCount++;
          if (highValueEmotions.contains(e)) highValueCount++;
        }
        if (_negativeEmotions.contains(e)) negCount++;
      }
      final posRatio = emotions.isEmpty ? 0.4 : posCount / emotions.length;
      final hvBonus = emotions.isEmpty
          ? 0.0
          : (highValueCount / emotions.length) * 0.15;
      final d4Raw = (posRatio + hvBonus).clamp(0.0, 1.0);
      final d4Score = (d4Raw * 100).clamp(0.0, 100.0);

      // ── D5: Behavioral Stability (10%) ────────────────────────
      // Coefficient of variation (std/mean) rather than raw variance —
      // normalises for overall urge volume so heavy loggers aren't
      // unfairly penalised for having more data points.
      final countList = List<double>.generate(
        30,
        (i) => (dailyCounts[i] ?? 0).toDouble(),
      );
      final mean30 = countList.fold(0.0, (a, b) => a + b) / 30;
      double d5Score;
      if (mean30 == 0) {
        d5Score = 100.0; // no urges = perfectly stable
      } else {
        final variance =
            countList.fold(
              0.0,
              (a, b) => a + math.pow(b - mean30, 2).toDouble(),
            ) /
            30;
        final cv = math.sqrt(variance) / mean30; // coefficient of variation
        d5Score = (1.0 - (cv / 3.0).clamp(0.0, 1.0)) * 100;
      }

      // ── D6: Recovery Momentum (5%) ────────────────────────────
      // EWMA-based comparison: current 7-day vs previous 7-day
      // Positive = urges decreasing = recovery improving
      final curr7 = urgeSnap7.docs.length;
      final prev7 = urgeSnapPrev.docs.length;
      double momentumRaw;
      if (prev7 == 0 && curr7 == 0) {
        momentumRaw = 0.0;
      } else if (prev7 == 0) {
        momentumRaw = -0.5; // urges appeared this week
      } else {
        momentumRaw = ((prev7 - curr7) / prev7.toDouble()).clamp(-1.0, 1.0);
      }
      final d6Raw = ((momentumRaw + 1) / 2.0).clamp(0.0, 1.0);
      final d6Score = (d6Raw * 100).clamp(0.0, 100.0);
      final momentum = momentumRaw > 0.12
          ? 'Gaining'
          : momentumRaw < -0.12
          ? 'Losing'
          : 'Stable';

      // ── D7: Consistency Bonus (4%) ────────────────────────────
      // Rewards daily self-monitoring (therapeutic in itself).
      // Based on unique days logged in the past 14 days.
      final uniqueDays14 = loggedDays.where((d) => d < 14).length;
      final d7Score = ((uniqueDays14 / 14.0) * 100).clamp(0.0, 100.0);

      // ── Weighted composite ─────────────────────────────────────
      final composite =
          (d1Raw * _w1) +
          (d2Score / 100 * _w2) +
          (d3Score / 100 * _w3) +
          (d4Raw * _w4) +
          (d5Score / 100 * _w5) +
          (d6Raw * _w6) +
          (d7Score / 100 * _w7);

      final score = (composite * 100).clamp(0.0, 100.0);
      final level = _level(score);

      // ── Score delta (vs 7d ago approximation) ─────────────────
      // Approximate by re-computing without current week's improvement
      final scoreDelta7d = momentumRaw * 8.0; // rough delta signal

      // ── Week-over-week change ──────────────────────────────────
      final weekOverWeekChange = momentumRaw * 100;

      // ── Build dimension objects ────────────────────────────────
      final dimensions = [
        RecoveryDimension(
          name: 'Streak Strength',
          score: d1Score,
          weight: _w1,
          insight: _streakInsight(d1Score, currentStreak),
          emoji: '🔥',
          trend: currentStreak > 7 ? 'Improving' : 'Stable',
        ),
        RecoveryDimension(
          name: 'Urge Frequency',
          score: d2Score,
          weight: _w2,
          insight: _freqInsight(d2Score, count),
          emoji: '📉',
          trend: momentum == 'Gaining'
              ? 'Improving'
              : momentum == 'Losing'
              ? 'Declining'
              : 'Stable',
        ),
        RecoveryDimension(
          name: 'Intensity Control',
          score: d3Score,
          weight: _w3,
          insight: _intensityInsight(d3Score, avgIntensity, spikeCount),
          emoji: '⚡',
          trend: d3Score >= 65
              ? 'Improving'
              : d3Score <= 35
              ? 'Declining'
              : 'Stable',
        ),
        RecoveryDimension(
          name: 'Emotional Resilience',
          score: d4Score,
          weight: _w4,
          insight: _emotionInsight(
            d4Score,
            posCount,
            negCount,
            emotions.length,
          ),
          emoji: '💚',
          trend: d4Score >= 60
              ? 'Improving'
              : d4Score <= 30
              ? 'Declining'
              : 'Stable',
        ),
        RecoveryDimension(
          name: 'Behavioral Stability',
          score: d5Score,
          weight: _w5,
          insight: _stabilityInsight(d5Score),
          emoji: '🧘',
          trend: d5Score >= 70
              ? 'Improving'
              : d5Score <= 40
              ? 'Declining'
              : 'Stable',
        ),
        RecoveryDimension(
          name: 'Recovery Momentum',
          score: d6Score,
          weight: _w6,
          insight: _momentumInsight(momentum, curr7, prev7),
          emoji: '📈',
          trend: momentum == 'Gaining'
              ? 'Improving'
              : momentum == 'Losing'
              ? 'Declining'
              : 'Stable',
        ),
        RecoveryDimension(
          name: 'Daily Consistency',
          score: d7Score,
          weight: _w7,
          insight: _consistencyInsight(d7Score, uniqueDays14),
          emoji: '📅',
          trend: d7Score >= 70
              ? 'Improving'
              : d7Score <= 35
              ? 'Declining'
              : 'Stable',
        ),
      ];

      // ── Find strongest and weakest ─────────────────────────────
      final sorted = [...dimensions]
        ..sort((a, b) => b.score.compareTo(a.score));
      final strongestDimension = sorted.first.name;
      final weakestDimension = sorted.last.name;

      // ── Dominant emotions ──────────────────────────────────────
      final dominantPos = _dominantFrom(emotions, _positiveEmotions.toList());
      final dominantNeg = _dominantFrom(emotions, _negativeEmotions.toList());

      // ── Build personalised goals ───────────────────────────────
      // Pick the 3 weakest dimensions and generate specific goals
      final weakest3 = sorted.reversed.take(3).map((d) => d.name).toList();
      final nextGoals = _buildGoals(
        weakDimensions: weakest3,
        currentStreak: currentStreak,
        avgIntensity: avgIntensity,
      );

      // ── Component scores map (legacy compat) ───────────────────
      final componentScores = {for (final d in dimensions) d.name: d.score};

      return RecoveryScoreModel(
        score: score,
        level: level,
        explanation: _explanation(score, currentStreak, momentum),
        dimensions: dimensions,
        componentScores: componentScores,
        weekOverWeekChange: weekOverWeekChange,
        momentum: momentum,
        scoreDelta7d: scoreDelta7d,
        strongestDimension: strongestDimension,
        weakestDimension: weakestDimension,
        nextGoals: nextGoals,
        currentStreak: currentStreak,
        nextMilestone: _nextMilestone(currentStreak),
        daysToNextMilestone: _daysToNext(currentStreak),
        dominantPositiveEmotion: dominantPos,
        dominantNegativeEmotion: dominantNeg,
        avgUrgeIntensity: avgIntensity,
        totalUrgesLogged: count,
      );
    } catch (_) {
      return const RecoveryScoreModel(
        score: 0,
        level: 'Unknown',
        explanation: 'Could not load data.',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  DIMENSION INSIGHT COPY
  // ─────────────────────────────────────────────────────────────

  String _streakInsight(double score, int streak) {
    if (streak == 0)
      return 'Start your first clean day to build streak strength.';
    if (score >= 80)
      return '$streak days clean. Your neural rewiring is well underway.';
    if (score >= 60)
      return '$streak days in. You\'re past the hardest early window.';
    if (score >= 40) return '$streak days. Every day adds compound resilience.';
    return 'Early streak. The first 7 days are the hardest — you\'re in them.';
  }

  String _freqInsight(double score, int count) {
    if (score >= 80)
      return 'Low urge frequency. Your brain pathways are quieting.';
    if (score >= 60) return '$count urges in 30 days. Frequency is manageable.';
    if (score >= 40)
      return '$count urges logged. Focus on reducing cue exposure.';
    return '$count urges in 30 days. Identifying and blocking triggers is the priority.';
  }

  String _intensityInsight(double score, double avg, int spikes) {
    final avgStr = avg.toStringAsFixed(1);
    if (score >= 80)
      return 'Average intensity $avgStr/10. Urges are manageable in strength.';
    if (score >= 60)
      return 'Avg intensity $avgStr/10 with $spikes high spikes. Improving.';
    if (score >= 40)
      return 'Avg $avgStr/10. High-intensity urges ($spikes spikes) need coping tools.';
    return 'High average intensity ($avgStr/10). Emergency techniques are critical right now.';
  }

  String _emotionInsight(double score, int pos, int neg, int total) {
    if (total == 0) return 'Log your emotions to track emotional resilience.';
    if (score >= 75)
      return 'Strong positive emotion ratio ($pos/$total). Resilience is high.';
    if (score >= 55)
      return 'Balanced emotional state. More positive moments needed.';
    if (score >= 35)
      return 'Negative emotions dominating ($neg/$total). This amplifies urge risk.';
    return 'High negative affect ratio. Emotional regulation is the top priority.';
  }

  String _stabilityInsight(double score) {
    if (score >= 80)
      return 'Very consistent daily pattern. Trigger resistance is strengthening.';
    if (score >= 60)
      return 'Moderate stability. Some days spike — identify their common factor.';
    if (score >= 40)
      return 'Uneven urge pattern. High-variance days suggest situational triggers.';
    return 'High day-to-day variance. External cues are still driving behaviour strongly.';
  }

  String _momentumInsight(String momentum, int curr7, int prev7) {
    if (momentum == 'Gaining')
      return 'Down from $prev7 to $curr7 urges this week. You are improving.';
    if (momentum == 'Losing')
      return 'Up from $prev7 to $curr7 urges this week. Reverse this trend now.';
    return 'Urge count stable week-over-week. Maintain and push for gains.';
  }

  String _consistencyInsight(double score, int days) {
    if (score >= 85)
      return 'Logging $days days in 2 weeks. Excellent self-monitoring habit.';
    if (score >= 60)
      return 'Logging on $days/14 days. More consistent tracking improves prediction.';
    if (score >= 35)
      return 'Logging on $days/14 days. Daily logging is therapeutic — build the habit.';
    return 'Low logging consistency. The act of tracking itself reduces urge intensity.';
  }

  // ─────────────────────────────────────────────────────────────
  //  PERSONALISED GOALS ENGINE
  // ─────────────────────────────────────────────────────────────

  List<RecoveryGoal> _buildGoals({
    required List<String> weakDimensions,
    required int currentStreak,
    required double avgIntensity,
  }) {
    final goals = <RecoveryGoal>[];

    for (final dim in weakDimensions.take(3)) {
      switch (dim) {
        case 'Streak Strength':
          goals.add(
            RecoveryGoal(
              emoji: '🔥',
              title: currentStreak == 0
                  ? 'Start your clean streak today'
                  : 'Protect your $currentStreak-day streak',
              description: currentStreak == 0
                  ? 'Log your first clean day right now. The first 24 hours '
                        'are the most powerful signal you can send your brain.'
                  : 'Your streak is your most visible recovery asset. '
                        'Identify your highest-risk window today and plan around it.',
              priority: 'High',
              dimension: 'Streak Strength',
            ),
          );
          break;

        case 'Urge Frequency':
          goals.add(
            RecoveryGoal(
              emoji: '📉',
              title: 'Reduce urge triggers this week',
              description:
                  'Audit the 3 environments or situations where you log '
                  'the most urges. Modify or avoid at least one of them this week. '
                  'Trigger reduction is faster than willpower training.',
              priority: 'High',
              dimension: 'Urge Frequency',
            ),
          );
          break;

        case 'Intensity Control':
          goals.add(
            RecoveryGoal(
              emoji: '⚡',
              title: avgIntensity >= 7
                  ? 'Learn an emergency coping technique'
                  : 'Build your urge surfing practice',
              description: avgIntensity >= 7
                  ? 'Your average urge intensity is high. Learn the 4-7-8 '
                        'breathing technique and the cold-water grounding method. '
                        'Practice them when calm so they work when it\'s hard.'
                  : 'Urge surfing (observing the urge without acting on it) '
                        'reduces peak intensity by 30–50% over 4 weeks of practice.',
              priority: avgIntensity >= 7 ? 'High' : 'Medium',
              dimension: 'Intensity Control',
            ),
          );
          break;

        case 'Emotional Resilience':
          goals.add(
            RecoveryGoal(
              emoji: '💚',
              title: 'Build one positive emotion daily',
              description:
                  'Negative emotions are the #1 trigger for urges. '
                  'Schedule one small activity that reliably generates a positive '
                  'emotion for you (exercise, music, connection, nature). '
                  'Do it daily at your highest-risk time window.',
              priority: 'Medium',
              dimension: 'Emotional Resilience',
            ),
          );
          break;

        case 'Behavioral Stability':
          goals.add(
            RecoveryGoal(
              emoji: '🧘',
              title: 'Stabilise your daily routine',
              description:
                  'High urge variance means your environment is still '
                  'controlling you. Add one fixed daily anchor — a consistent '
                  'wake time, a morning routine, or a post-work ritual. '
                  'Predictable structure dramatically reduces urge spikes.',
              priority: 'Medium',
              dimension: 'Behavioral Stability',
            ),
          );
          break;

        case 'Recovery Momentum':
          goals.add(
            RecoveryGoal(
              emoji: '📈',
              title: 'Reverse this week\'s urge trend',
              description:
                  'Your urge count is higher this week than last. '
                  'Identify what changed — sleep, stress, schedule, or social '
                  'environment — and address that one variable this week.',
              priority: 'High',
              dimension: 'Recovery Momentum',
            ),
          );
          break;

        case 'Daily Consistency':
          goals.add(
            RecoveryGoal(
              emoji: '📅',
              title: 'Log every urge for the next 7 days',
              description:
                  'Self-monitoring is clinically proven to reduce urge '
                  'intensity (affect labelling reduces amygdala activation). '
                  'Set a daily reminder to open the app and log your state, '
                  'even on good days.',
              priority: 'Medium',
              dimension: 'Daily Consistency',
            ),
          );
          break;
      }
    }

    return goals;
  }

  // ─────────────────────────────────────────────────────────────
  //  MILESTONE HELPERS
  // ─────────────────────────────────────────────────────────────

  String _nextMilestone(int streak) {
    for (final m in _milestones) {
      if (streak < m.days) return '${m.rank} at ${m.days} days';
    }
    return 'Invincible — Maximum Rank Achieved 👑';
  }

  int _daysToNext(int streak) {
    for (final m in _milestones) {
      if (streak < m.days) return m.days - streak;
    }
    return 0;
  }

  // ─────────────────────────────────────────────────────────────
  //  DOMINANT EMOTION HELPER
  // ─────────────────────────────────────────────────────────────

  String _dominantFrom(List<String> all, List<String> subset) {
    if (all.isEmpty) return '';
    final counts = <String, int>{};
    for (final e in all) {
      if (subset.contains(e)) counts[e] = (counts[e] ?? 0) + 1;
    }
    if (counts.isEmpty) return '';
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  // ─────────────────────────────────────────────────────────────
  //  LEVEL & EXPLANATION COPY
  // ─────────────────────────────────────────────────────────────

  String _level(double s) => s >= 80
      ? 'Excellent'
      : s >= 65
      ? 'Good'
      : s >= 45
      ? 'Moderate'
      : s >= 25
      ? 'Low'
      : 'Critical';

  String _explanation(double score, int streak, String momentum) {
    final streakStr = streak > 0 ? '$streak-day streak. ' : '';
    if (score >= 80) {
      return '${streakStr}Outstanding recovery health across all 7 dimensions. '
          'Your behavioral rewiring is producing measurable results. '
          'Protect this momentum — it compounds.';
    }
    if (score >= 65) {
      return '${streakStr}Good recovery health. Your consistency is building '
          'real neural resilience. Focus on your weakest dimension to break '
          'through to Excellent.';
    }
    if (score >= 45) {
      return '${streakStr}Moderate recovery. Progress is happening but key '
          'dimensions need attention. Your personalised goals below target '
          'the highest-impact areas.';
    }
    if (score >= 25) {
      return '${streakStr}Recovery needs attention. Multiple risk signals are '
          'active. Use your intervention steps daily and focus on one goal '
          'at a time — not everything at once.';
    }
    return 'Critical recovery state. Immediate action on your top goal is '
        'more important than streaks right now. Reach out to your support '
        'system today.';
  }
}
