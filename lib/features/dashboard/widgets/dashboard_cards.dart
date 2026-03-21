// lib/features/dashboard/widgets/dashboard_cards.dart

import 'package:flutter/material.dart';
import 'package:rewirex/features/ai/models/pre_relapse_warning_model.dart';
import 'package:rewirex/features/ai/models/recovery_score_model.dart';
import 'package:rewirex/features/ai/models/ai_guidance_model.dart';
import 'package:rewirex/features/prediction/models/urge_prediction_model.dart';
import 'package:rewirex/features/risk/models/risk_model.dart';

// ─────────────────────────────────────────────────────────────
// Shared base card
// ─────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final Color  accentColor;
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
        fontSize: 17,
      ),
    );

Widget _subText(String text) => Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(0.6),
        fontSize: 15,
        height: 1.5,
      ),
    );

// ─────────────────────────────────────────────────────────────
// ⚠️ Pre-Relapse Warning Card  — RICH VERSION
// Uses the full PreRelapseWarningModel: risk score, peak window,
// personalised intervention steps, expandable signal list.
// ─────────────────────────────────────────────────────────────

class PreRelapseWarningCard extends StatefulWidget {
  final PreRelapseWarningModel warning;
  final VoidCallback           onStartPrevention;

  const PreRelapseWarningCard({
    super.key,
    required this.warning,
    required this.onStartPrevention,
  });

  @override
  State<PreRelapseWarningCard> createState() => _PreRelapseWarningCardState();
}

class _PreRelapseWarningCardState extends State<PreRelapseWarningCard> {
  bool _showSteps   = false;
  bool _showSignals = false;

  Color get _color {
    switch (widget.warning.severity) {
      case 'Critical': return Colors.red;
      case 'High':     return Colors.orange;
      default:         return Colors.amber;
    }
  }

  IconData get _icon {
    switch (widget.warning.severity) {
      case 'Critical': return Icons.crisis_alert_rounded;
      case 'High':     return Icons.warning_amber_rounded;
      default:         return Icons.radar_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.warning;

    return _InfoCard(
      accentColor: _color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header ────────────────────────────────────────────
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon, color: _color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(child: _cardTitle('Pre-Relapse Warning')),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(w.severity,
                  style: TextStyle(
                      color: _color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
            ),
          ]),

          const SizedBox(height: 14),

          // ── Risk score bar ─────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Risk Score',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 13)),
              Text('${w.riskScore.toStringAsFixed(0)}/100',
                  style: TextStyle(
                      color: _color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: w.riskScore / 100),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, val, __) => LinearProgressIndicator(
                value: val,
                minHeight: 7,
                backgroundColor: Colors.white.withOpacity(0.07),
                valueColor: AlwaysStoppedAnimation<Color>(_color),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── Main message ───────────────────────────────────────
          _subText(w.message),

          if (w.subMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(w.subMessage,
                style: TextStyle(
                    color: _color.withOpacity(0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4)),
          ],

          // ── Peak window badge ──────────────────────────────────
          if (w.isInPeakWindow) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: _color.withOpacity(0.25), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time_rounded,
                      color: _color, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    'You are in your peak risk window right now',
                    style: TextStyle(
                        color: _color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],

          // ── Active signals (expandable) ────────────────────────
          if (w.warningSignals.isNotEmpty) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () =>
                  setState(() => _showSignals = !_showSignals),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.08), width: 1),
                ),
                child: Row(children: [
                  Icon(Icons.sensors_rounded,
                      color: _color.withOpacity(0.7), size: 15),
                  const SizedBox(width: 8),
                  Text(
                    '${w.warningSignals.length} signal${w.warningSignals.length > 1 ? 's' : ''} detected',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Icon(
                    _showSignals
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white.withOpacity(0.3),
                    size: 18,
                  ),
                ]),
              ),
            ),
            if (_showSignals) ...[
              const SizedBox(height: 8),
              ...w.warningSignals.map((signal) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.circle, color: _color, size: 7),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(signal,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 13,
                              height: 1.4)),
                    ),
                  ],
                ),
              )),
            ],
          ],

          // ── Intervention steps (expandable) ───────────────────
          if (w.interventionSteps.isNotEmpty) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () =>
                  setState(() => _showSteps = !_showSteps),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: _color.withOpacity(0.2), width: 1),
                ),
                child: Row(children: [
                  Icon(Icons.tips_and_updates_outlined,
                      color: _color, size: 15),
                  const SizedBox(width: 8),
                  Text(
                    '${w.interventionSteps.length} personalised steps',
                    style: TextStyle(
                        color: _color,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Icon(
                    _showSteps
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: _color.withOpacity(0.6),
                    size: 18,
                  ),
                ]),
              ),
            ),
            if (_showSteps) ...[
              const SizedBox(height: 10),
              ...w.interventionSteps.asMap().entries.map((entry) {
                final step = entry.value;
                final idx  = entry.key + 1;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.07), width: 1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(children: [
                        Text(step.emoji,
                            style: const TextStyle(fontSize: 20)),
                        const SizedBox(height: 2),
                        Text('$idx',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.25),
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(step.title,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(step.description,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.55),
                                    fontSize: 12,
                                    height: 1.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],

          const SizedBox(height: 16),

          // ── CTA button ─────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: widget.onStartPrevention,
              style: ElevatedButton.styleFrom(
                backgroundColor: _color.withOpacity(0.85),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(w.actionLabel,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 🧠 Recovery Score Card
// ─────────────────────────────────────────────────────────────

class RecoveryScoreCard extends StatelessWidget {
  final RecoveryScoreModel score;
  const RecoveryScoreCard({super.key, required this.score});

  Color get _color {
    switch (score.level) {
      case 'Excellent': return const Color(0xFF00C853);
      case 'Good':      return const Color(0xFF00C853);
      case 'Moderate':  return const Color(0xFF2979FF);
      case 'Low':       return Colors.orange;
      default:          return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayScore = score.score.clamp(0.0, 100.0).round();
    return _InfoCard(
      accentColor: _color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🧠', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            _cardTitle('Recovery Score'),
          ]),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 100,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('$displayScore',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.w800,
                          height: 1.0)),
                ),
              ),
              const SizedBox(width: 4),
              Text('/ 100',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 18,
                      fontWeight: FontWeight.w500)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(score.level,
                    style: TextStyle(
                        color: _color,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: displayScore / 100,
              minHeight: 7,
              backgroundColor: Colors.white.withOpacity(0.07),
              valueColor: AlwaysStoppedAnimation<Color>(_color),
            ),
          ),
          const SizedBox(height: 10),
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
          Row(children: [
            const Text('🔮', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            _cardTitle('Urge Prediction'),
          ]),
          const SizedBox(height: 12),
          _subText(prediction.prediction),
          const SizedBox(height: 12),
          Row(children: [
            _PredictionChip(
                label: '⏱ ${prediction.window}',
                color: Colors.indigoAccent),
            const SizedBox(width: 8),
            _PredictionChip(
                label: '📊 ${prediction.probability}%',
                color: prediction.probability >= 70
                    ? Colors.red
                    : prediction.probability >= 40
                        ? Colors.orange
                        : const Color(0xFF00C853)),
          ]),
        ],
      ),
    );
  }
}

class _PredictionChip extends StatelessWidget {
  final String label;
  final Color  color;
  const _PredictionChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 🤖 AI Guidance Card
// ─────────────────────────────────────────────────────────────

class AIGuidanceCard extends StatelessWidget {
  final AIGuidanceModel      guidance;
  final ValueChanged<String> onAction;
  const AIGuidanceCard(
      {super.key, required this.guidance, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      accentColor: Colors.teal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy_outlined,
                  color: Colors.white, size: 17),
            ),
            const SizedBox(width: 10),
            _cardTitle('AI Daily Guidance'),
            const Spacer(),
            Text(guidance.tone,
                style: TextStyle(
                    color: Colors.teal.withOpacity(0.7),
                    fontSize: 13,
                    fontStyle: FontStyle.italic)),
          ]),
          const SizedBox(height: 12),
          _subText(guidance.message),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () => onAction(guidance.action),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                    color: Color(0xFF00C4A0), width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(guidance.action,
                  style: const TextStyle(
                      color: Color(0xFF00C4A0),
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
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
      case 'Critical': return Colors.red;
      case 'High':     return Colors.orange;
      case 'Medium':   return Colors.amber;
      default:         return const Color(0xFF00C853);
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
            const Text('🧠', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            _cardTitle('Current Risk Level'),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Text(risk.level,
                style: TextStyle(
                    color: _levelColor,
                    fontSize: 32,
                    fontWeight: FontWeight.w800)),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${risk.probability.toStringAsFixed(1)}%',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
                Text('probability',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 13)),
              ],
            ),
          ]),
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
  const RelapsePredictionCard(
      {super.key, required this.probability, required this.level});

  Color get _levelColor {
    switch (level) {
      case 'Critical': return Colors.red;
      case 'High':     return Colors.orange;
      case 'Medium':   return Colors.amber;
      default:         return const Color(0xFF00C853);
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
            const Text('🔮', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            _cardTitle('Relapse Probability'),
          ]),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${probability.toStringAsFixed(0)}%',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      height: 1.0)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _levelColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(level,
                    style: TextStyle(
                        color: _levelColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: probability / 100,
              minHeight: 7,
              backgroundColor: Colors.white.withOpacity(0.07),
              valueColor: AlwaysStoppedAnimation<Color>(_levelColor),
            ),
          ),
        ],
      ),
    );
  }
}