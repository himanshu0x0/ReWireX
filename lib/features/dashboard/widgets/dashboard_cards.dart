import 'package:flutter/material.dart';
import 'package:rewirex/features/ai/models/pre_relapse_warning_model.dart';
import 'package:rewirex/features/ai/models/recovery_score_model.dart';
import 'package:rewirex/features/ai/models/ai_guidance_model.dart';
import 'package:rewirex/features/prediction/models/urge_prediction_model.dart';
import 'package:rewirex/features/risk/models/risk_model.dart';

// ─────────────────────────────────────────────────────────────
// Shared base card for all dashboard info cards
// ─────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final Color accentColor;
  final Widget child;

  const _InfoCard({required this.accentColor, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141428),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withOpacity(0.18), width: 1),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

Widget _cardTitle(String title) => Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
    );

Widget _subText(String text) => Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(0.6),
        fontSize: 13,
        height: 1.4,
      ),
    );

// ─────────────────────────────────────────────────────────────
// ⚠️ Pre-Relapse Warning Card
// ─────────────────────────────────────────────────────────────

class PreRelapseWarningCard extends StatelessWidget {
  final PreRelapseWarningModel warning;
  final VoidCallback onStartPrevention;

  const PreRelapseWarningCard({
    super.key,
    required this.warning,
    required this.onStartPrevention,
  });

  Color get _color {
    switch (warning.severity) {
      case 'Critical':
        return Colors.red;
      case 'High':
        return Colors.orange;
      default:
        return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      accentColor: _color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: _color, size: 18),
              const SizedBox(width: 8),
              _cardTitle('Pre-Relapse Warning'),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  warning.severity,
                  style: TextStyle(
                    color: _color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _subText(warning.message),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: onStartPrevention,
              style: ElevatedButton.styleFrom(
                backgroundColor: _color.withOpacity(0.85),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Start Prevention',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 🧠 Recovery Score Card  ← FIXED
// ─────────────────────────────────────────────────────────────

class RecoveryScoreCard extends StatelessWidget {
  final RecoveryScoreModel score;

  const RecoveryScoreCard({super.key, required this.score});

  Color get _color {
    switch (score.level) {
      case 'Excellent':
        return const Color(0xFF00C853);
      case 'Good':
        return const Color(0xFF00C853);
      case 'Moderate':
        return const Color(0xFF2979FF);
      case 'Low':
        return Colors.orange;
      default: // Critical
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Round to nearest integer and clamp to valid range
    final displayScore = score.score.clamp(0.0, 100.0).round();

    return _InfoCard(
      accentColor: _color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────
          Row(
            children: [
              const Text('🧠', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              _cardTitle('Recovery Score'),
            ],
          ),
          const SizedBox(height: 14),

          // ── Score row ────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Score number — fixed width so it never overflows
              SizedBox(
                width: 90,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$displayScore',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '/ 100',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              // Level badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  score.level,
                  style: TextStyle(
                    color: _color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Progress bar ─────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: displayScore / 100,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.07),
              valueColor: AlwaysStoppedAnimation<Color>(_color),
            ),
          ),
          const SizedBox(height: 10),

          // ── Explanation ──────────────────────────────────
          _subText(score.explanation),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 🔮 Urge Prediction Card
// ─────────────────────────────────────────────────────────────

class UrgePredictionCard extends StatelessWidget {
  final UrgePredictionModel prediction;

  const UrgePredictionCard({super.key, required this.prediction});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      accentColor: Colors.indigo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔮', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              _cardTitle('Urge Prediction'),
            ],
          ),
          const SizedBox(height: 12),
          _subText(prediction.prediction),
          const SizedBox(height: 12),
          Row(
            children: [
              _PredictionChip(
                label: '⏱ ${prediction.window}',
                color: Colors.indigoAccent,
              ),
              const SizedBox(width: 8),
              _PredictionChip(
                label: '📊 ${prediction.probability}%',
                color: prediction.probability >= 70
                    ? Colors.red
                    : prediction.probability >= 40
                        ? Colors.orange
                        : const Color(0xFF00C853),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PredictionChip extends StatelessWidget {
  final String label;
  final Color color;

  const _PredictionChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 🤖 AI Guidance Card
// ─────────────────────────────────────────────────────────────

class AIGuidanceCard extends StatelessWidget {
  final AIGuidanceModel guidance;
  final ValueChanged<String> onAction;

  const AIGuidanceCard({
    super.key,
    required this.guidance,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      accentColor: Colors.teal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.smart_toy_outlined,
                    color: Colors.white, size: 15),
              ),
              const SizedBox(width: 10),
              _cardTitle('AI Daily Guidance'),
              const Spacer(),
              Text(
                guidance.tone,
                style: TextStyle(
                  color: Colors.teal.withOpacity(0.7),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _subText(guidance.message),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: () => onAction(guidance.action),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF00C4A0), width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                guidance.action,
                style: const TextStyle(
                    color: Color(0xFF00C4A0), fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 🧠 Risk Card
// ─────────────────────────────────────────────────────────────

class RiskCard extends StatelessWidget {
  final RiskModel risk;

  const RiskCard({super.key, required this.risk});

  Color get _levelColor {
    switch (risk.level) {
      case 'Critical':
        return Colors.red;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return Colors.amber;
      default:
        return const Color(0xFF00C853);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      accentColor: _levelColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🧠', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            _cardTitle('Current Risk Level'),
          ]),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                risk.level,
                style: TextStyle(
                  color: _levelColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${risk.probability.toStringAsFixed(1)}%',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'probability',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          _subText('Peak window: ${risk.timeWindow}'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 🔮 Relapse Prediction Card
// ─────────────────────────────────────────────────────────────

class RelapsePredictionCard extends StatelessWidget {
  final double probability;
  final String level;

  const RelapsePredictionCard({
    super.key,
    required this.probability,
    required this.level,
  });

  Color get _levelColor {
    switch (level) {
      case 'Critical':
        return Colors.red;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return Colors.amber;
      default:
        return const Color(0xFF00C853);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      accentColor: Colors.red,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🔮', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            _cardTitle('Relapse Probability'),
          ]),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${probability.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _levelColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  level,
                  style: TextStyle(
                    color: _levelColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: probability / 100,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.07),
              valueColor: AlwaysStoppedAnimation<Color>(_levelColor),
            ),
          ),
        ],
      ),
    );
  }
}