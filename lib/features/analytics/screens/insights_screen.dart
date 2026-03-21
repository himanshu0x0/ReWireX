// lib/features/insights/screens/insights_screen.dart

import 'package:flutter/material.dart';
import 'package:rewirex/features/ai/services/behavior_pattern_service.dart';
import 'package:rewirex/features/stability/services/stability_service.dart';
import 'package:rewirex/features/analytics/services/habit_pattern_service.dart';
import 'package:rewirex/features/prediction/services/relapse_prediction_service.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen>
    with SingleTickerProviderStateMixin {

  final StabilityService         _stabilityService       = StabilityService();
  final HabitPatternService      _patternService         = HabitPatternService();
  final RelapsePredictionService _relapseService         = RelapsePredictionService();
  final BehaviorPatternService   _behaviorPatternService = BehaviorPatternService();

  late AnimationController _fadeController;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader('AI BEHAVIORAL ANALYSIS'),
              const SizedBox(height: 12),
              _buildBehaviorPatternCard(),
              const SizedBox(height: 20),
              _sectionHeader('STABILITY & PATTERNS'),
              const SizedBox(height: 12),
              _buildStabilityCard(),
              const SizedBox(height: 16),
              _buildPatternCard(),
              const SizedBox(height: 20),
              _sectionHeader('RELAPSE INTELLIGENCE'),
              const SizedBox(height: 12),
              _buildRelapseCard(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0D0D1A),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded,
            color: Colors.white, size: 20),        // was 18
        onPressed: () => Navigator.pop(context),
      ),
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)],
        ).createShader(bounds),
        child: const Text('AI Insights',
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,                       // was 20
                fontWeight: FontWeight.w800)),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFF6C63FF).withOpacity(0.3), width: 1),
          ),
          child: const Row(children: [
            Icon(Icons.auto_awesome_rounded,
                color: Color(0xFF6C63FF), size: 14),  // was 13
            SizedBox(width: 5),
            Text('AI Powered',
                style: TextStyle(
                    color: Color(0xFF6C63FF),
                    fontSize: 12,                    // was 11
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      ],
    );
  }

  Widget _sectionHeader(String label) => Text(label,
      style: TextStyle(
          color: Colors.white.withOpacity(0.35),
          fontSize: 12,                              // was 10
          fontWeight: FontWeight.w700,
          letterSpacing: 2.5));

  // ── AI Behavioral Pattern ──────────────────────────────────────
  Widget _buildBehaviorPatternCard() {
    return FutureBuilder<BehaviorPatternModel?>(
      future: _behaviorPatternService.analyzeBehavior(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _loadingCard(accent: const Color(0xFF00C4A0));
        }
        if (!snap.hasData || snap.data == null) {
          return _emptyCard(
            icon: Icons.psychology_outlined,
            accent: const Color(0xFF00C4A0),
            title: 'AI Behavioral Pattern',
            message: 'Log more urges for AI to detect deeper behavioral patterns.',
          );
        }
        final p = snap.data!;
        final trendColor = p.intensityTrend == 'Improving'
            ? const Color(0xFF00C853)
            : p.intensityTrend == 'Worsening'
                ? const Color(0xFFE53935)
                : Colors.amber;

        return _InsightCard(
          accent: const Color(0xFF00C4A0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _iconBox(Icons.psychology_outlined, const Color(0xFF00C4A0)),
              const SizedBox(width: 10),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('AI Behavioral Pattern',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),             // was 14
                Text('Confidence: ${p.confidence}%',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 13)),             // was 12
              ])),
              _confidenceBadge(p.confidence),
            ]),
            const SizedBox(height: 18),
            _labeledRow('Detected Pattern', p.pattern,
                valueColor: const Color(0xFF6C63FF)),
            const SizedBox(height: 12),
            _labeledRow('Primary Trigger', p.trigger),
            const SizedBox(height: 12),
            _labeledRow('Risk Window', p.riskWindow),
            const SizedBox(height: 12),
            Row(children: [
              Text('Intensity Trend  ',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 13)),               // was 12
              _chip(p.intensityTrend, trendColor),
            ]),
            if (p.topCoPattern.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C4A0).withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF00C4A0).withOpacity(0.15), width: 1),
                ),
                child: Row(children: [
                  const Icon(Icons.link_rounded,
                      color: Color(0xFF00C4A0), size: 16), // was 14
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                      'Co-pattern: ${p.topCoPattern}',
                      style: const TextStyle(
                          color: Color(0xFF00C4A0),
                          fontSize: 13,              // was 12
                          fontWeight: FontWeight.w600))),
                ]),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(color: Colors.white12),
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.tips_and_updates_outlined,
                  color: Color(0xFF6C63FF), size: 17), // was 15
              const SizedBox(width: 8),
              Expanded(child: Text(p.recommendation,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 14,                  // was 13
                      height: 1.5))),
            ]),
          ]),
        );
      },
    );
  }

  // ── Behavioral Stability ───────────────────────────────────────
  Widget _buildStabilityCard() {
    return FutureBuilder<StabilityModel>(
      future: _stabilityService.calculateStability(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _loadingCard(accent: const Color(0xFF6C63FF));
        }
        if (!snap.hasData) return const SizedBox.shrink();
        final s     = snap.data!;
        final color = s.level == 'High'
            ? const Color(0xFF00C853)
            : s.level == 'Moderate'
                ? const Color(0xFF6C63FF)
                : const Color(0xFFE53935);

        return _InsightCard(
          accent: color,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _iconBox(Icons.balance_rounded, color),
              const SizedBox(width: 10),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Behavioral Stability',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),             // was 14
                Text('${s.trend} pattern',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 13)),             // was 12
              ])),
              _chip(s.level, color),
            ]),
            const SizedBox(height: 20),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(s.score.toStringAsFixed(0),
                  style: TextStyle(
                      color: color,
                      fontSize: 56,                 // was 52
                      fontWeight: FontWeight.w800,
                      height: 1.0)),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4),
                child: Text('/100',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 17)),             // was 16
              ),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: s.score / 100,
                minHeight: 7,                       // was 6
                backgroundColor: Colors.white.withOpacity(0.07),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 14),
            Text(s.explanation,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,                   // was 13
                    height: 1.5)),
          ]),
        );
      },
    );
  }

  // ── Habit Pattern ──────────────────────────────────────────────
  Widget _buildPatternCard() {
    return FutureBuilder(
      future: _patternService.analyzePatterns(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _loadingCard(accent: Colors.indigo);
        }
        if (!snap.hasData || snap.data == null) return const SizedBox.shrink();
        final p = snap.data!;

        return _InsightCard(
          accent: Colors.indigo,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _iconBox(Icons.hub_outlined, Colors.indigo),
              const SizedBox(width: 10),
              const Text('Behavioral Pattern Insight',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),               // was 14
            ]),
            const SizedBox(height: 16),
            Text(p.insight,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 14,                   // was 13
                    height: 1.6)),
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _metaChip('🎭 ${p.dominantEmotion}'),
              _metaChip('⏰ ${p.dominantTimeBlock}'),
              _metaChip('📊 ${p.intensityTrend}'),
            ]),
          ]),
        );
      },
    );
  }

  // ── Relapse Risk ───────────────────────────────────────────────
  Widget _buildRelapseCard() {
    return FutureBuilder<RelapsePredictionModel>(
      future: _relapseService.analyzeRelapseRisk(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _loadingCard(accent: Colors.red);
        }
        if (!snap.hasData) return const SizedBox.shrink();
        final pred  = snap.data!;
        final color = pred.level == 'Critical' ? const Color(0xFFE53935)
            : pred.level == 'High'             ? Colors.orange
            : pred.level == 'Moderate'         ? Colors.amber
            :                                    const Color(0xFF00C853);

        return _InsightCard(
          accent: color,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _iconBox(Icons.warning_amber_rounded, color),
              const SizedBox(width: 10),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Relapse Risk Analysis',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),             // was 14
                Text('Confidence: ${(pred.confidenceScore * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 13)),             // was 12
              ])),
              _chip(pred.level, color),
            ]),
            const SizedBox(height: 20),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${pred.probability.toStringAsFixed(0)}%',
                  style: TextStyle(
                      color: color,
                      fontSize: 56,                 // was 52
                      fontWeight: FontWeight.w800,
                      height: 1.0)),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 8),
                child: Text('probability',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 15)),             // was 14
              ),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pred.probability / 100,
                minHeight: 7,                       // was 6
                backgroundColor: Colors.white.withOpacity(0.07),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 14),
            Text(pred.reason,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,                   // was 13
                    height: 1.5)),
            if (pred.warningSignals.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Divider(color: Colors.white12),
              const SizedBox(height: 10),
              Text('WARNING SIGNALS',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 11,                // was 10
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0)),
              const SizedBox(height: 8),
              ...pred.warningSignals.take(3).map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  Icon(Icons.circle, color: color, size: 7),  // was 6
                  const SizedBox(width: 10),
                  Expanded(child: Text(s,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 13,            // was 12
                          height: 1.4))),
                ]),
              )),
            ],
          ]),
        );
      },
    );
  }

  // ── Reusable helpers ───────────────────────────────────────────
  Widget _loadingCard({required Color accent}) => _InsightCard(
    accent: accent,
    child: const SizedBox(height: 60,
        child: Center(child: SizedBox(width: 22, height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white38)))),
  );

  Widget _emptyCard({required IconData icon, required Color accent,
      required String title, required String message}) =>
    _InsightCard(
      accent: accent,
      child: Row(children: [
        Icon(icon, color: accent.withOpacity(0.5), size: 34),  // was 32
        const SizedBox(width: 14),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15)),                        // was 13
          const SizedBox(height: 4),
          Text(message, style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 13,                          // was 12
              height: 1.4)),
        ])),
      ]),
    );

  Widget _iconBox(IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(9),               // was 8
    decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10)),
    child: Icon(icon, color: color, size: 18),       // was 16
  );

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.25), width: 1),
    ),
    child: Text(label, style: TextStyle(
        color: color,
        fontSize: 12,                                // was 11
        fontWeight: FontWeight.w700)),
  );

  Widget _metaChip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),  // was 10,5
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
    ),
    child: Text(label, style: TextStyle(
        color: Colors.white.withOpacity(0.55),
        fontSize: 12,                                // was 11
        fontWeight: FontWeight.w600)),
  );

  Widget _confidenceBadge(int confidence) {
    final color = confidence >= 70 ? const Color(0xFF00C853)
        : confidence >= 40           ? Colors.amber
        :                              Colors.red;
    return SizedBox(width: 48, height: 48,           // was 44
      child: Stack(alignment: Alignment.center, children: [
        CircularProgressIndicator(
          value: confidence / 100,
          strokeWidth: 3,
          backgroundColor: Colors.white.withOpacity(0.07),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
        Text('$confidence', style: TextStyle(
            color: color,
            fontSize: 12,                            // was 11
            fontWeight: FontWeight.w800)),
      ]),
    );
  }

  Widget _labeledRow(String label, String value, {Color? valueColor}) =>
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 115,                           // was 110
        child: Text(label, style: TextStyle(
            color: Colors.white.withOpacity(0.45),
            fontSize: 13))),                         // was 12
      Expanded(child: Text(value, style: TextStyle(
          color: valueColor ?? Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14))),                           // was 13
    ]);
}

class _InsightCard extends StatelessWidget {
  final Color  accent;
  final Widget child;
  const _InsightCard({required this.accent, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141428),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.18), width: 1),
        boxShadow: [BoxShadow(
            color: accent.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }
}