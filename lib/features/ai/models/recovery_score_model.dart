// lib/features/ai/models/recovery_score_model.dart
//
// ═══════════════════════════════════════════════════════════════════
// 📊  RECOVERY SCORE MODEL  —  ReWireX Behavioral Intelligence
// ═══════════════════════════════════════════════════════════════════
//
// This model is the single most important data structure in the app.
// It answers the question every user is silently asking every day:
//
//   "Am I actually getting better — or just not relapsing yet?"
//
// Those are two very different things. Someone can have a 30-day streak
// while their emotional resilience is collapsing, their urge intensity
// is climbing, and their sleep-hour vulnerability is worsening. The
// streak number alone would never show this.
//
// This model surfaces SEVEN dimensions of recovery health so the user
// can see exactly where they are strong, where they need work, and
// what to focus on next — backed by the same multi-factor thinking
// used in clinical GORSKI/CENAPS recovery assessment frameworks.

/// One dimension of the 7-component recovery score.
class RecoveryDimension {
  /// Short name shown in the UI (e.g. 'Streak Strength').
  final String name;

  /// Score 0–100 for this dimension.
  final double score;

  /// Weight this dimension carries in the composite (0–1, sums to 1.0).
  final double weight;

  /// One-line explanation of what this score means for the user.
  final String insight;

  /// Emoji icon for visual quick-scan.
  final String emoji;

  /// Trend vs previous period: 'Improving' | 'Stable' | 'Declining'
  final String trend;

  const RecoveryDimension({
    required this.name,
    required this.score,
    required this.weight,
    required this.insight,
    required this.emoji,
    this.trend = 'Stable',
  });

  /// Weighted contribution to the composite score.
  double get weightedScore => score * weight;
}

/// A concrete, personalised next step shown to the user.
class RecoveryGoal {
  final String emoji;
  final String title;
  final String description;
  final String priority; // 'High' | 'Medium' | 'Low'
  final String dimension; // which dimension this goal improves

  const RecoveryGoal({
    required this.emoji,
    required this.title,
    required this.description,
    required this.priority,
    required this.dimension,
  });
}

/// 📊 Recovery Score Model
class RecoveryScoreModel {
  // ── Core score ──────────────────────────────────────────────────

  /// Composite score 0–100.
  final double score;

  /// Level label: 'Critical' | 'Low' | 'Moderate' | 'Good' | 'Excellent'
  final String level;

  /// Primary explanation shown below the score number.
  final String explanation;

  // ── 7-Dimension breakdown ────────────────────────────────────────

  /// All seven scored dimensions — drives the breakdown chart in UI.
  final List<RecoveryDimension> dimensions;

  // ── Legacy compatibility (existing UI uses these) ────────────────

  /// Flat map of dimension name → score (kept for backward compat).
  final Map<String, double> componentScores;

  /// Week-over-week momentum change (-100 to +100).
  final double weekOverWeekChange;

  /// Momentum label: 'Gaining' | 'Stable' | 'Losing'
  final String momentum;

  // ── Trend intelligence ───────────────────────────────────────────

  /// Score delta vs 7 days ago (positive = improving).
  final double scoreDelta7d;

  /// Strongest dimension (highest score) — shown as user's superpower.
  final String strongestDimension;

  /// Weakest dimension (lowest score) — shown as priority focus area.
  final String weakestDimension;

  // ── Personalised goals ────────────────────────────────────────────

  /// 2–3 concrete next steps tailored to the user's weakest signals.
  final List<RecoveryGoal> nextGoals;

  // ── Streak context ────────────────────────────────────────────────

  /// Current streak in days — used to personalise copy.
  final int currentStreak;

  /// Milestone the user is approaching next (e.g. 'Ironclad at 30 days').
  final String nextMilestone;

  /// Days remaining to reach nextMilestone.
  final int daysToNextMilestone;

  // ── Behavioral fingerprint ────────────────────────────────────────

  /// Dominant positive emotion in the scoring window.
  final String dominantPositiveEmotion;

  /// Dominant negative emotion in the scoring window.
  final String dominantNegativeEmotion;

  /// Average urge intensity over the scoring window.
  final double avgUrgeIntensity;

  /// Total urges logged in the scoring window.
  final int totalUrgesLogged;

  const RecoveryScoreModel({
    required this.score,
    required this.level,
    this.explanation             = '',
    this.dimensions              = const [],
    this.componentScores         = const {},
    this.weekOverWeekChange      = 0,
    this.momentum                = 'Stable',
    this.scoreDelta7d            = 0,
    this.strongestDimension      = '',
    this.weakestDimension        = '',
    this.nextGoals               = const [],
    this.currentStreak           = 0,
    this.nextMilestone           = '',
    this.daysToNextMilestone     = 0,
    this.dominantPositiveEmotion = '',
    this.dominantNegativeEmotion = '',
    this.avgUrgeIntensity        = 0,
    this.totalUrgesLogged        = 0,
  });
}