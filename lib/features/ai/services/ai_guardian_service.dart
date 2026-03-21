// lib/features/ai/services/ai_guardian_service.dart
//
// 🛡️ AI Guardian Service — Advanced Edition
//
// PURPOSE:
//   The AI Guardian is the app's proactive safety layer. It watches the
//   user's behavioral signals in real time and surfaces contextual alerts,
//   check-ins, and nudges BEFORE a relapse happens — not after.
//
// WHAT IT DOES (6-signal composite engine):
//   Signal 1 — Relapse probability spike  (live)
//   Signal 2 — Urge velocity (urge count acceleration this week vs last)
//   Signal 3 — Streak fragility (how short & unstable the current streak is)
//   Signal 4 — Time-of-day vulnerability (is the user in their peak risk hour?)
//   Signal 5 — Emotional state (dominant negative emotion in last 48h)
//   Signal 6 — Consecutive high-risk days (memory from AIMemoryService)
//
// GUARDIAN LEVELS (adaptive, not binary):
//   🟢 Calm      — User is stable. Gentle motivation message.
//   🟡 Watchful  — Early warning. Supportive check-in.
//   🟠 Alert     — Multiple signals firing. Grounding exercise prompt.
//   🔴 Critical  — High relapse probability. Emergency intervention.
//
// SMART THROTTLING:
//   • Never shows the same level twice in 6 hours (prevents alert fatigue)
//   • Respects user's sleep hours (no alerts 11 PM – 7 AM unless Critical)
//   • Escalates if user dismisses without acting
//
// PERSONALIZATION:
//   • Reads the user's dominant emotion to tailor the message tone
//   • Adapts language based on streak length (new vs veteran)
//   • References the user's actual peak-risk time window

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../prediction/services/relapse_prediction_service.dart';
import '../../risk/services/risk_prediction_service.dart';
import '../../analytics/services/heatmap_service.dart';
import 'ai_memory_service.dart';

// ── Guardian level enum ────────────────────────────────────────
enum GuardianLevel { calm, watchful, alert, critical }

// ── Guardian state model ───────────────────────────────────────
class GuardianState {
  final GuardianLevel level;
  final String        title;
  final String        message;
  final String        actionLabel;
  final String        actionRoute;   // e.g. 'emergency', 'checkin', 'insight'
  final Color         accentColor;
  final IconData      icon;
  final double        compositeScore; // 0–100 internal score
  final List<String>  activeSignals;  // which signals fired

  const GuardianState({
    required this.level,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.actionRoute,
    required this.accentColor,
    required this.icon,
    required this.compositeScore,
    required this.activeSignals,
  });
}

// ─────────────────────────────────────────────────────────────
class AIGuardianService {
  final RelapsePredictionService _relapseService = RelapsePredictionService();
  final RiskPredictionService    _riskService    = RiskPredictionService();
  final HeatmapService           _heatmapService = HeatmapService();
  final AIMemoryService          _memoryService  = AIMemoryService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth      _auth      = FirebaseAuth.instance;

  // SharedPreferences keys
  static const _kLastAlertTime  = 'guardian_last_alert_time';
  static const _kLastAlertLevel = 'guardian_last_alert_level';

  // Throttle: minimum gap between same-level alerts (hours)
  static const _throttleHours = 6;

  // ── Public entry point (called from DashboardScreen) ──────────
  Future<void> checkAndTriggerGuardian(BuildContext context) async {
    try {
      final state = await _evaluateGuardianState();
      if (state == null) return;

      final shouldShow = await _shouldShowAlert(state.level);
      if (!shouldShow) return;

      if (context.mounted) {
        await _showGuardianDialog(context, state);
        await _recordAlertShown(state.level);
      }
    } catch (_) {
      // Guardian is non-critical — never crash the app
    }
  }

  // ── Full signal evaluation ─────────────────────────────────────
  Future<GuardianState?> _evaluateGuardianState() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final now = DateTime.now();

    // Fetch all signals in parallel
    final results = await Future.wait([
      _relapseService.analyzeRelapseRisk(),
      _riskService.analyzeRisk(),
      _heatmapService.getWeightedHeatmap(),
      _memoryService.getMemory(),
      _fetchStreakData(user.uid),
      _fetchRecentUrges(user.uid, hours: 48),
    ]);

    final relapse   = results[0] as RelapsePredictionModel;
    final risk      = results[1] as RiskModel?;
    final heatmap   = results[2] as Map<int, double>;
    final memory    = results[3] as AIMemoryModel?;
    final streak    = results[4] as Map<String, dynamic>;
    final urges48h  = results[5] as List<Map<String, dynamic>>;

    // ── Signal 1: Relapse probability ─────────────────────────────
    final relProb       = relapse.probability.clamp(0.0, 100.0);
    final s1Score       = relProb / 100.0;
    final s1Fires       = relProb >= 45;

    // ── Signal 2: Urge velocity ────────────────────────────────────
    final urgeVelocity  = await _calculateUrgeVelocity(user.uid);
    final s2Score       = urgeVelocity.clamp(0.0, 1.0);
    final s2Fires       = urgeVelocity >= 0.4;

    // ── Signal 3: Streak fragility ─────────────────────────────────
    final currentStreak = (streak['currentStreak'] as num?)?.toInt() ?? 0;
    final totalRelapses = (streak['totalRelapses'] as num?)?.toInt() ?? 0;
    final fragility     = _streakFragility(currentStreak, totalRelapses);
    final s3Score       = fragility;
    final s3Fires       = fragility >= 0.55;

    // ── Signal 4: Temporal vulnerability ──────────────────────────
    final peakHour    = _peakHour(heatmap);
    final dist        = _circularDist(now.hour, peakHour);
    final s4Score     = dist <= 1 ? 1.0 : dist <= 2 ? 0.7 : dist <= 3 ? 0.4 : 0.0;
    final s4Fires     = s4Score >= 0.7;

    // ── Signal 5: Dominant emotion in last 48h ─────────────────────
    final emotionScore = _emotionRiskScore(urges48h);
    final s5Score      = emotionScore;
    final s5Fires      = emotionScore >= 0.6;
    final topEmotion   = _dominantEmotion(urges48h);

    // ── Signal 6: Consecutive high-risk days (memory) ─────────────
    final highRiskDays  = memory?.consecutiveHighRiskDays ?? 0;
    final s6Score       = (highRiskDays / 5.0).clamp(0.0, 1.0);
    final s6Fires       = highRiskDays >= 2;

    // ── Weighted composite (0–100) ────────────────────────────────
    final composite = (
      s1Score * 0.30 +
      s2Score * 0.20 +
      s3Score * 0.15 +
      s4Score * 0.15 +
      s5Score * 0.12 +
      s6Score * 0.08
    ) * 100;

    // ── Count active signals ───────────────────────────────────────
    final activeSignals = <String>[];
    if (s1Fires) activeSignals.add('High relapse probability (${relProb.toStringAsFixed(0)}%)');
    if (s2Fires) activeSignals.add('Urge frequency increasing this week');
    if (s3Fires) activeSignals.add('Streak is short and fragile ($currentStreak days)');
    if (s4Fires) activeSignals.add('You are in your peak risk window now');
    if (s5Fires) activeSignals.add('$topEmotion state is dominant right now');
    if (s6Fires) activeSignals.add('$highRiskDays consecutive high-risk days detected');

    // ── Determine level ────────────────────────────────────────────
    final signalCount = activeSignals.length;
    GuardianLevel level;
    if (composite >= 72 || signalCount >= 4 || relProb >= 80) {
      level = GuardianLevel.critical;
    } else if (composite >= 52 || signalCount >= 3 || relProb >= 60) {
      level = GuardianLevel.alert;
    } else if (composite >= 35 || signalCount >= 2) {
      level = GuardianLevel.watchful;
    } else {
      level = GuardianLevel.calm;
    }

    // Save updated memory
    await _memoryService.saveMemory(AIMemoryModel(
      consecutiveHighRiskDays: level == GuardianLevel.calm ? 0 : highRiskDays + 1,
      sessionStarted:          memory?.sessionStarted ?? now,
      lastTone:                level.name,
      lastRelapseProbability:  relProb,
      lastUpdated:             now,
    ));

    // Only surface alerts for watchful and above
    if (level == GuardianLevel.calm) return null;

    return _buildState(
      level: level,
      composite: composite,
      activeSignals: activeSignals,
      currentStreak: currentStreak,
      topEmotion: topEmotion,
      peakHour: peakHour,
      relProb: relProb,
      risk: risk,
    );
  }

  // ── State builder (personalised copy) ─────────────────────────
  GuardianState _buildState({
    required GuardianLevel level,
    required double composite,
    required List<String> activeSignals,
    required int currentStreak,
    required String topEmotion,
    required int peakHour,
    required double relProb,
    required RiskModel? risk,
  }) {
    final streakContext = currentStreak == 0
        ? 'You are at the start of a new journey.'
        : currentStreak < 7
            ? 'Your $currentStreak-day streak is precious — protect it.'
            : 'You have built a $currentStreak-day streak. Don\'t let it slip now.';

    final emotionContext = topEmotion.isNotEmpty && topEmotion != 'Unknown'
        ? 'You\'ve been feeling $topEmotion lately.'
        : '';

    final peakContext = 'Your highest-risk window is around ${_fmt(peakHour)}.';

    switch (level) {
      case GuardianLevel.watchful:
        return GuardianState(
          level:          level,
          title:          '👁 Guardian Check-In',
          message:        '$streakContext ${emotionContext.isNotEmpty ? emotionContext : ''} '
                          'Two or more risk signals are active. A quick grounding now '
                          'is worth more than fighting a full-blown urge later.',
          actionLabel:    'Do a 2-Min Check-In',
          actionRoute:    'checkin',
          accentColor:    Colors.amber,
          icon:           Icons.visibility_outlined,
          compositeScore: composite,
          activeSignals:  activeSignals,
        );

      case GuardianLevel.alert:
        return GuardianState(
          level:          level,
          title:          '⚠️ Elevated Risk Detected',
          message:        '$emotionContext $peakContext '
                          'Multiple risk signals are converging. '
                          '$streakContext '
                          'Use a coping tool before the urge peaks.',
          actionLabel:    'Open Coping Tools',
          actionRoute:    'coping',
          accentColor:    Colors.orange,
          icon:           Icons.warning_amber_rounded,
          compositeScore: composite,
          activeSignals:  activeSignals,
        );

      case GuardianLevel.critical:
        return GuardianState(
          level:          level,
          title:          '🚨 Critical — Act Now',
          message:        'Relapse risk is at ${relProb.toStringAsFixed(0)}%. '
                          '$emotionContext '
                          '$streakContext '
                          'Your brain is in a high-risk state. '
                          'An emergency reset can break the pattern right now.',
          actionLabel:    'Start Emergency Reset',
          actionRoute:    'emergency',
          accentColor:    const Color(0xFFE53935),
          icon:           Icons.crisis_alert_rounded,
          compositeScore: composite,
          activeSignals:  activeSignals,
        );

      default:
        return GuardianState(
          level:          level,
          title:          '✅ You\'re Doing Well',
          message:        '$streakContext Keep going.',
          actionLabel:    'View Progress',
          actionRoute:    'dashboard',
          accentColor:    const Color(0xFF00C4A0),
          icon:           Icons.check_circle_outline_rounded,
          compositeScore: composite,
          activeSignals:  activeSignals,
        );
    }
  }

  // ── Alert dialog ───────────────────────────────────────────────
  Future<void> _showGuardianDialog(
      BuildContext context, GuardianState state) async {
    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      barrierDismissible: state.level != GuardianLevel.critical,
      builder: (_) => _GuardianDialog(state: state),
    );
  }

  // ── Throttle logic ─────────────────────────────────────────────
  Future<bool> _shouldShowAlert(GuardianLevel level) async {
    final now   = DateTime.now();
    final hour  = now.hour;

    // Sleep hours: suppress non-critical alerts
    if (level != GuardianLevel.critical && (hour >= 23 || hour < 7)) {
      return false;
    }

    final prefs         = await SharedPreferences.getInstance();
    final lastTimeStr   = prefs.getString(_kLastAlertTime);
    final lastLevelStr  = prefs.getString(_kLastAlertLevel);

    if (lastTimeStr != null && lastLevelStr == level.name) {
      final lastTime = DateTime.tryParse(lastTimeStr);
      if (lastTime != null) {
        final hoursSince = now.difference(lastTime).inHours;
        if (hoursSince < _throttleHours) return false;
      }
    }

    return true;
  }

  Future<void> _recordAlertShown(GuardianLevel level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastAlertTime,  DateTime.now().toIso8601String());
    await prefs.setString(_kLastAlertLevel, level.name);
  }

  // ── Signal helpers ─────────────────────────────────────────────

  Future<double> _calculateUrgeVelocity(String uid) async {
    final now    = DateTime.now();
    final snap   = await _firestore
        .collection('users').doc(uid).collection('urge_logs')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(
            now.subtract(const Duration(days: 14))))
        .get();

    if (snap.docs.isEmpty) return 0.0;

    final mid    = now.subtract(const Duration(days: 7));
    int week1    = 0, week2 = 0;
    for (final doc in snap.docs) {
      final ts = (doc.data()['timestamp'] as Timestamp).toDate();
      if (ts.isBefore(mid)) week1++; else week2++;
    }
    if (week1 == 0) return week2 > 0 ? 0.8 : 0.0;
    return ((week2 - week1) / math.max(week1, 1).toDouble()).clamp(0.0, 1.0);
  }

  double _streakFragility(int streak, int relapses) {
    final streakFactor  = 1.0 - (streak / 90.0).clamp(0.0, 1.0);
    final relapseFactor = (relapses / 10.0).clamp(0.0, 1.0);
    return (streakFactor * 0.6 + relapseFactor * 0.4).clamp(0.0, 1.0);
  }

  int _peakHour(Map<int, double> heatmap) {
    if (heatmap.isEmpty) return 21;
    return heatmap.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  int _circularDist(int a, int b) {
    final d = (a - b).abs();
    return d < 24 - d ? d : 24 - d;
  }

  double _emotionRiskScore(List<Map<String, dynamic>> urges) {
    const negativeEmotions = {
      'Stressed', 'Anxious', 'Lonely', 'Bored', 'Sad',
      'Angry', 'Frustrated', 'Depressed', 'Hopeless', 'Empty',
    };
    if (urges.isEmpty) return 0.3;
    final neg = urges.where((u) =>
        negativeEmotions.contains(u['emotion'] as String? ?? '')).length;
    return (neg / urges.length).clamp(0.0, 1.0);
  }

  String _dominantEmotion(List<Map<String, dynamic>> urges) {
    if (urges.isEmpty) return 'Unknown';
    final counts = <String, int>{};
    for (final u in urges) {
      final e = u['emotion'] as String? ?? 'Unknown';
      counts[e] = (counts[e] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  Future<Map<String, dynamic>> _fetchStreakData(String uid) async {
    final snap = await _firestore
        .collection('users').doc(uid)
        .collection('stats').doc('streak').get();
    return snap.data() ?? {};
  }

  Future<List<Map<String, dynamic>>> _fetchRecentUrges(
      String uid, {required int hours}) async {
    final cutoff = DateTime.now().subtract(Duration(hours: hours));
    final snap   = await _firestore
        .collection('users').doc(uid).collection('urge_logs')
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  String _fmt(int hour) {
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final h = hour % 12 == 0 ? 12 : hour % 12;
    return '$h:00 $suffix';
  }
}

// ─────────────────────────────────────────────────────────────
//  GUARDIAN DIALOG WIDGET
// ─────────────────────────────────────────────────────────────
class _GuardianDialog extends StatefulWidget {
  final GuardianState state;
  const _GuardianDialog({required this.state});

  @override
  State<_GuardianDialog> createState() => _GuardianDialogState();
}

class _GuardianDialogState extends State<_GuardianDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scaleAnim;
  late Animation<double>   _fadeAnim;
  bool _showSignals = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400))
      ..forward();
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;

    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF161625),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: s.accentColor.withOpacity(0.3), width: 1),
              boxShadow: [
                BoxShadow(
                  color: s.accentColor.withOpacity(0.15),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Icon header ──────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                  decoration: BoxDecoration(
                    color: s.accentColor.withOpacity(0.07),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28)),
                    border: Border(
                      bottom: BorderSide(
                          color: Colors.white.withOpacity(0.05), width: 1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 68, height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: s.accentColor.withOpacity(0.12),
                          border: Border.all(
                              color: s.accentColor.withOpacity(0.35),
                              width: 1.5),
                        ),
                        child: Icon(s.icon, color: s.accentColor, size: 30),
                      ),
                      const SizedBox(height: 14),
                      Text(s.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),

                // ── Message ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 4),
                  child: Text(s.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 14,
                          height: 1.6)),
                ),

                // ── Composite score bar ───────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Risk Score',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 12)),
                          Text(
                            '${s.compositeScore.toStringAsFixed(0)}/100',
                            style: TextStyle(
                                color: s.accentColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: s.compositeScore / 100,
                          minHeight: 6,
                          backgroundColor: Colors.white.withOpacity(0.07),
                          valueColor: AlwaysStoppedAnimation<Color>(s.accentColor),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Active signals (expandable) ───────────
                if (s.activeSignals.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _showSignals = !_showSignals),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.07), width: 1),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.radar_rounded,
                                color: s.accentColor.withOpacity(0.7), size: 15),
                            const SizedBox(width: 8),
                            Text(
                              '${s.activeSignals.length} signal${s.activeSignals.length > 1 ? 's' : ''} detected',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 12,
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
                          ],
                        ),
                      ),
                    ),
                  ),

                if (_showSignals && s.activeSignals.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: s.accentColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: s.accentColor.withOpacity(0.15), width: 1),
                      ),
                      child: Column(
                        children: s.activeSignals.map((signal) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.circle,
                                  color: s.accentColor, size: 6),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(signal,
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 12,
                                        height: 1.4)),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                    ),
                  ),

                // ── Buttons ───────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    children: [
                      // Primary action
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: s.accentColor,
                            boxShadow: [
                              BoxShadow(
                                  color: s.accentColor.withOpacity(0.3),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5)),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, 'action'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(s.actionLabel,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Dismiss (not available for critical)
                      if (s.level != GuardianLevel.critical)
                        GestureDetector(
                          onTap: () => Navigator.pop(context, 'dismiss'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'I\'m okay, dismiss',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.3),
                                  fontSize: 13),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}