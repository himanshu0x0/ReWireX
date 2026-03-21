import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:rewirex/features/analytics/services/trend_analytics_service.dart';
import 'package:rewirex/features/analytics/services/heatmap_service.dart';
import 'package:rewirex/features/analytics/services/habit_loop_service.dart';
import 'package:rewirex/features/analytics/services/trigger_mapping_service.dart';
import 'package:rewirex/features/analytics/services/habit_pattern_service.dart';

import 'package:rewirex/features/analytics/models/weekly_trend_model.dart';
import 'package:rewirex/features/analytics/models/habit_loop_model.dart';
import 'package:rewirex/features/analytics/models/trigger_pattern_model.dart';
import 'package:rewirex/features/analytics/models/habit_pattern_model.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  final TrendAnalyticsService _trendService     = TrendAnalyticsService();
  final HeatmapService        _heatmapService   = HeatmapService();
  final HabitLoopService      _habitLoopService = HabitLoopService();
  final TriggerMappingService _triggerService   = TriggerMappingService();
  final HabitPatternService   _patternService   = HabitPatternService();

  late AnimationController _fadeController;
  late Animation<double>   _fadeAnim;

  static const List<String> _dayLabels = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  static const Map<String, Color> _emotionColors = {
    'Anxious':  Color(0xFF6C63FF),
    'Lonely':   Color(0xFF00C4A0),
    'Sad':      Color(0xFF4FC3F7),
    'Angry':    Color(0xFFEF5350),
    'Bored':    Color(0xFFFFB74D),
    'Stressed': Color(0xFFAB47BC),
    'Unknown':  Color(0xFF607D8B),
  };

  Color _emotionColor(String emotion) =>
      _emotionColors[emotion] ?? const Color(0xFF607D8B);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600),
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionLabel('WEEKLY OVERVIEW'),
              const SizedBox(height: 12),
              _buildWeeklyTrend(),
              const SizedBox(height: 20),
              _buildEmotionDistribution(),
              const SizedBox(height: 20),
              _buildSectionLabel('HOURLY RISK MAP'),
              const SizedBox(height: 12),
              _buildHeatmap(),
              const SizedBox(height: 20),
              _buildSectionLabel('BEHAVIORAL INSIGHTS'),
              const SizedBox(height: 12),
              _buildHabitPattern(),
              const SizedBox(height: 20),
              _buildHabitLoopInsight(),
              const SizedBox(height: 20),
              _buildTriggerMappingCard(),
              const SizedBox(height: 8),
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
      titleSpacing: 20,
      leading: const SizedBox.shrink(),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8), // was 7
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bar_chart_rounded,
                color: Colors.white, size: 19), // was 17
          ),
          const SizedBox(width: 10),
          const Text(
            'Analytics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,            // was 20
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.white.withOpacity(0.35),
        fontSize: 12,                  // was 11
        fontWeight: FontWeight.w700,
        letterSpacing: 2.5,
      ),
    );
  }

  Widget _analyticsCard({
    required Widget child,
    Color? accentColor,
    EdgeInsets? padding,
  }) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141428),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: (accentColor ?? Colors.white).withOpacity(0.09),
          width: 1,
        ),
        boxShadow: accentColor != null
            ? [BoxShadow(
                color: accentColor.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 6),
              )]
            : [],
      ),
      child: child,
    );
  }

  Widget _cardTitle(String title, {Color? color}) {
    return Text(
      title,
      style: TextStyle(
        color: color ?? Colors.white,
        fontSize: 17,                  // was 15
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // ── Weekly Trend ──────────────────────────────────────────────
  Widget _buildWeeklyTrend() {
    return FutureBuilder<WeeklyTrendModel?>(
      future: _trendService.getWeeklyTrend(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data == null) {
          return _buildLoadingCard('📈 7-Day Urge Trend');
        }
        final trend  = snap.data!;
        final maxVal = trend.dailyCounts.reduce((a, b) => a > b ? a : b).toDouble();
        final safeMax= maxVal == 0 ? 5.0 : maxVal + 1;

        return _analyticsCard(
          accentColor: const Color(0xFF6C63FF),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _cardTitle('7-Day Urge Trend'),
                  const Spacer(),
                  _TrendBadge(direction: trend.trendDirection),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${trend.totalUrges} total urges  •  avg intensity ${trend.averageIntensity.toStringAsFixed(1)}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.38),
                    fontSize: 13),    // was 12
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: safeMax,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: safeMax / 4,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: Colors.white.withOpacity(0.05),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: safeMax / 4,
                          getTitlesWidget: (val, _) => Text(
                            val.toInt().toString(),
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 11),  // was 10
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (val, _) {
                            final i = val.toInt();
                            if (i < 0 || i >= _dayLabels.length) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                _dayLabels[i],
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.35),
                                    fontSize: 11),  // was 10
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(7, (i) => FlSpot(
                            i.toDouble(), trend.dailyCounts[i].toDouble())),
                        isCurved: true,
                        curveSmoothness: 0.35,
                        barWidth: 2.5,
                        color: const Color(0xFF6C63FF),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF6C63FF).withOpacity(0.25),
                              const Color(0xFF6C63FF).withOpacity(0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                            radius: 4,
                            color: const Color(0xFF6C63FF),
                            strokeWidth: 2,
                            strokeColor: const Color(0xFF141428),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Emotion Distribution ──────────────────────────────────────
  Widget _buildEmotionDistribution() {
    return FutureBuilder<WeeklyTrendModel?>(
      future: _trendService.getWeeklyTrend(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data == null ||
            snap.data!.emotionDistribution.isEmpty) {
          return const SizedBox.shrink();
        }
        final dist   = snap.data!.emotionDistribution;
        final total  = dist.values.fold(0, (a, b) => a + b);
        final sorted = dist.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return _analyticsCard(
          accentColor: const Color(0xFF00C4A0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _cardTitle('Emotion Distribution'),
                  const Spacer(),
                  Text(
                    snap.data!.dominantEmotion,
                    style: TextStyle(
                        color: _emotionColor(snap.data!.dominantEmotion),
                        fontSize: 13,          // was 12
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  Text('dominant',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.35),
                          fontSize: 13)),       // was 12
                ],
              ),
              const SizedBox(height: 18),
              ...sorted.map((entry) {
                final pct = entry.value / total;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(entry.key,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,        // was 13
                                  fontWeight: FontWeight.w500)),
                          const Spacer(),
                          Text(
                            '${(pct * 100).toStringAsFixed(0)}%  (${entry.value})',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 12)),        // was 11
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: pct),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          builder: (_, val, __) => LinearProgressIndicator(
                            value: val,
                            minHeight: 7,
                            backgroundColor: Colors.white.withOpacity(0.07),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                _emotionColor(entry.key)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ── Heatmap ───────────────────────────────────────────────────
  Widget _buildHeatmap() {
    return FutureBuilder<Map<int, int>>(
      future: _heatmapService.getHourlyHeatmap(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.isEmpty) {
          return _buildEmptyCard('🔥 Hourly Risk Map',
              'Log more urges to generate your heatmap.');
        }
        final heatmap  = snap.data!;
        final maxCount = heatmap.values.fold(0, (a, b) => a > b ? a : b);

        return _analyticsCard(
          accentColor: const Color(0xFFEF5350),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _cardTitle('Hourly Risk Map'),
                  const Spacer(),
                  _buildHeatmapLegend(),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Darker = more urges logged at that hour',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 12)),             // was 11
              const SizedBox(height: 16),
              _buildHeatmapGrid(heatmap, maxCount),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeatmapGrid(Map<int, int> heatmap, int maxCount) {
    return Column(
      children: [
        _buildHeatmapRow(heatmap, maxCount, 0,  12, 'AM'),
        const SizedBox(height: 10),
        _buildHeatmapRow(heatmap, maxCount, 12, 24, 'PM'),
      ],
    );
  }

  Widget _buildHeatmapRow(Map<int, int> heatmap, int maxCount,
      int start, int end, String label) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 11,                // was 10
                  fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(end - start, (i) {
              final hour      = start + i;
              final count     = heatmap[hour] ?? 0;
              final intensity = maxCount > 0 ? count / maxCount : 0.0;
              Color cellColor;
              if (intensity == 0)        cellColor = Colors.white.withOpacity(0.05);
              else if (intensity <= 0.33) cellColor = const Color(0xFF00C4A0).withOpacity(0.5);
              else if (intensity <= 0.66) cellColor = const Color(0xFFFFB74D).withOpacity(0.7);
              else                        cellColor = const Color(0xFFEF5350).withOpacity(0.85);

              return Tooltip(
                message: '${_formatHour(hour)}: $count urges',
                child: Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                      color: cellColor, borderRadius: BorderRadius.circular(5)),
                  child: Center(
                    child: Text(
                      '${hour % 12 == 0 ? 12 : hour % 12}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildHeatmapLegend() {
    return Row(
      children: [
        _LegendDot(color: Colors.white.withOpacity(0.08), label: 'None'),
        const SizedBox(width: 8),
        _LegendDot(color: const Color(0xFF00C4A0).withOpacity(0.5), label: 'Low'),
        const SizedBox(width: 8),
        _LegendDot(color: const Color(0xFFFFB74D).withOpacity(0.7), label: 'Mid'),
        const SizedBox(width: 8),
        _LegendDot(color: const Color(0xFFEF5350).withOpacity(0.85), label: 'High'),
      ],
    );
  }

  // ── Habit Pattern ─────────────────────────────────────────────
  Widget _buildHabitPattern() {
    return FutureBuilder<HabitPatternModel?>(
      future: _patternService.analyzePatterns(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard('🔄 Habit Pattern Analysis');
        }
        if (!snap.hasData || snap.data == null) {
          return _buildEmptyCard('🔄 Habit Pattern Analysis',
              'Log more urges to detect deep behavioral patterns.');
        }
        final p = snap.data!;
        final trendColor = p.intensityTrend == 'Rising'
            ? const Color(0xFFEF5350)
            : p.intensityTrend == 'Decreasing'
                ? const Color(0xFF00C4A0)
                : const Color(0xFFFFB74D);

        return _analyticsCard(
          accentColor: const Color(0xFF6C63FF),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _cardTitle('Habit Pattern Analysis'),
                  const Spacer(),
                  _RiskScoreChip(score: p.riskScore),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _StatTile(
                    label: 'Peak Time', value: p.dominantTimeBlock,
                    icon: Icons.access_time_rounded,
                    color: const Color(0xFF6C63FF),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _StatTile(
                    label: 'Top Emotion', value: p.dominantEmotion,
                    icon: Icons.mood_rounded,
                    color: _emotionColor(p.dominantEmotion),
                  )),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _StatTile(
                    label: 'Avg Intensity',
                    value: '${p.averageIntensity.toStringAsFixed(1)}/10',
                    icon: Icons.bolt_rounded,
                    color: const Color(0xFFFFB74D),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _StatTile(
                    label: 'Trend', value: p.intensityTrend,
                    icon: p.intensityTrend == 'Rising'
                        ? Icons.trending_up_rounded
                        : p.intensityTrend == 'Decreasing'
                            ? Icons.trending_down_rounded
                            : Icons.trending_flat_rounded,
                    color: trendColor,
                  )),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded,
                        color: Color(0xFF6C63FF), size: 18), // was 16
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(p.insight,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.55),
                              fontSize: 14,    // was 12
                              height: 1.6)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Habit Loop ────────────────────────────────────────────────
  Widget _buildHabitLoopInsight() {
    return FutureBuilder<HabitLoopModel?>(
      future: _habitLoopService.detectHabitLoop(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard('🧠 Habit Loop Detection');
        }
        if (!snap.hasData || snap.data == null) {
          return _buildEmptyCard('🧠 Habit Loop Detection',
              'Not enough data yet. Log more urges to detect habit loops.');
        }
        final habit = snap.data!;
        final severityColor = habit.severity == 'High'
            ? const Color(0xFFEF5350)
            : habit.severity == 'Moderate'
                ? const Color(0xFFFFB74D)
                : const Color(0xFF00C4A0);

        return _analyticsCard(
          accentColor: severityColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _cardTitle('Habit Loop Detection'),
                  const Spacer(),
                  _SeverityBadge(severity: habit.severity, color: severityColor),
                ],
              ),
              const SizedBox(height: 14),
              _buildLoopChain(habit),
              const SizedBox(height: 16),
              _InsightBox(text: habit.insight),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: severityColor.withOpacity(0.18), width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.tips_and_updates_outlined,
                        color: severityColor, size: 18), // was 16
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(habit.recommendation,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 14,    // was 12
                              height: 1.5)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoopChain(HabitLoopModel habit) {
    return Row(
      children: [
        _LoopNode(label: habit.trigger,   color: const Color(0xFF6C63FF)),
        _LoopArrow(),
        _LoopNode(label: habit.behavior,  color: const Color(0xFFFFB74D)),
        _LoopArrow(),
        _LoopNode(label: '${habit.frequency}×', color: const Color(0xFF00C4A0)),
      ],
    );
  }

  // ── Trigger Mapping ───────────────────────────────────────────
  Widget _buildTriggerMappingCard() {
    return FutureBuilder<TriggerPatternModel?>(
      future: _triggerService.detectTriggerPattern(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard('⚡ Trigger Mapping Engine');
        }
        if (!snap.hasData || snap.data == null) {
          return _buildEmptyCard('⚡ Trigger Mapping Engine',
              'Not enough data yet. Log more urges to map your triggers.');
        }
        final t          = snap.data!;
        final riskColor  = _riskColor(t.riskLevel);

        return _analyticsCard(
          accentColor: riskColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _cardTitle('Trigger Mapping Engine'),
                  const Spacer(),
                  _RiskLevelBadge(level: t.riskLevel, color: riskColor),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.flash_on_rounded, color: riskColor, size: 20), // was 18
                  const SizedBox(width: 8),
                  Text(t.trigger,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,        // was 17
                          fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 10),
              _InsightBox(text: t.description),
              const SizedBox(height: 14),
              Row(
                children: [
                  _MiniStat(label: 'Peak Hour', value: _formatHour(t.peakHour), color: riskColor),
                  const SizedBox(width: 10),
                  _MiniStat(label: 'Frequency', value: '${t.frequency}×', color: const Color(0xFF6C63FF)),
                  const SizedBox(width: 10),
                  _MiniStat(label: 'Active Hours', value: '${t.activeHours.length}h', color: const Color(0xFF00C4A0)),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: riskColor.withOpacity(0.2), width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.psychology_outlined, color: riskColor, size: 18), // was 16
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(t.actionAdvice,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 14,    // was 12
                              height: 1.5)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingCard(String title) {
    return _analyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(title),
          const SizedBox(height: 20),
          const Center(child: SizedBox(width: 24, height: 24,
              child: CircularProgressIndicator(
                  color: Color(0xFF6C63FF), strokeWidth: 2.5))),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String title, String message) {
    return _analyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(title),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: Colors.white.withOpacity(0.25), size: 18), // was 16
              const SizedBox(width: 8),
              Expanded(
                child: Text(message,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 13,          // was 12
                        height: 1.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _riskColor(String level) {
    switch (level) {
      case 'Critical': return const Color(0xFFEF5350);
      case 'High':     return const Color(0xFFFFB74D);
      case 'Medium':   return const Color(0xFF6C63FF);
      default:         return const Color(0xFF00C4A0);
    }
  }

  String _formatHour(int hour) {
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final h = hour % 12 == 0 ? 12 : hour % 12;
    return '$h:00 $suffix';
  }
}

// ── Sub-widgets ───────────────────────────────────────────────

class _TrendBadge extends StatelessWidget {
  final String direction;
  const _TrendBadge({required this.direction});

  @override
  Widget build(BuildContext context) {
    final color = direction == 'Rising'
        ? const Color(0xFFEF5350)
        : direction == 'Decreasing'
            ? const Color(0xFF00C4A0)
            : const Color(0xFFFFB74D);
    final icon = direction == 'Rising'
        ? Icons.trending_up_rounded
        : direction == 'Decreasing'
            ? Icons.trending_down_rounded
            : Icons.trending_flat_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),    // was 13
          const SizedBox(width: 4),
          Text(direction,
              style: TextStyle(
                  color: color,
                  fontSize: 12,                  // was 11
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final String severity;
  final Color  color;
  const _SeverityBadge({required this.severity, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(severity,
          style: TextStyle(
              color: color,
              fontSize: 12,                      // was 11
              fontWeight: FontWeight.w700)),
    );
  }
}

class _RiskLevelBadge extends StatelessWidget {
  final String level;
  final Color  color;
  const _RiskLevelBadge({required this.level, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text('$level Risk',
          style: TextStyle(
              color: color,
              fontSize: 12,                      // was 11
              fontWeight: FontWeight.w700)),
    );
  }
}

class _RiskScoreChip extends StatelessWidget {
  final double score;
  const _RiskScoreChip({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 70
        ? const Color(0xFFEF5350)
        : score >= 45
            ? const Color(0xFFFFB74D)
            : const Color(0xFF00C4A0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text('Risk ${score.toStringAsFixed(0)}',
          style: TextStyle(
              color: color,
              fontSize: 12,                      // was 11
              fontWeight: FontWeight.w700)),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;
  const _StatTile({required this.label, required this.value,
      required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 17),    // was 16
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.38),
                        fontSize: 11)),           // was 10
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,              // was 13
                        fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 11)),               // was 10
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 15,                // was 14
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _InsightBox extends StatelessWidget {
  final String text;
  const _InsightBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
      ),
      child: Text(text,
          style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,                      // was 12
              height: 1.6)),
    );
  }
}

class _LoopNode extends StatelessWidget {
  final String label;
  final Color  color;
  const _LoopNode({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: color,
                fontSize: 12,                    // was 11
                fontWeight: FontWeight.w700),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _LoopArrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Icon(Icons.arrow_forward_rounded,
          color: Colors.white.withOpacity(0.2), size: 17), // was 16
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color  color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 10,                    // was 9
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}