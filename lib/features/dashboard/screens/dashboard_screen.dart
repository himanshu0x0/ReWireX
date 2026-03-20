import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Streak
import 'package:rewirex/features/streak/services/streak_service.dart';
import 'package:rewirex/features/streak/models/streak_model.dart';
import 'package:rewirex/features/streak/widgets/streak_timer_card.dart';
import 'package:rewirex/features/streak/widgets/milestone_progress_card.dart';
import 'package:rewirex/features/streak/widgets/daily_checkin_card.dart';

// AI
import 'package:rewirex/features/ai/services/ai_guidance_service.dart';
import 'package:rewirex/features/ai/services/ai_guardian_service.dart';
import 'package:rewirex/features/ai/services/pre_relapse_warning_service.dart';
import 'package:rewirex/features/ai/services/recovery_score_service.dart';
import 'package:rewirex/features/ai/models/pre_relapse_warning_model.dart';
import 'package:rewirex/features/ai/models/recovery_score_model.dart';
import 'package:rewirex/features/ai/models/ai_guidance_model.dart';

// Prediction
import 'package:rewirex/features/prediction/services/relapse_prediction_service.dart';
import 'package:rewirex/features/prediction/services/urge_prediction_service.dart';
import 'package:rewirex/features/prediction/models/urge_prediction_model.dart';

// Risk
import 'package:rewirex/features/risk/services/risk_prediction_service.dart';
import 'package:rewirex/features/risk/models/risk_model.dart';

// Dashboard widgets
import 'package:rewirex/features/dashboard/widgets/dashboard_cards.dart';

// Other screens
import 'package:rewirex/features/urge/screens/urge_log_screen.dart';
import 'package:rewirex/features/profile/screens/profile_screen.dart';
import 'package:rewirex/navigation/app_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  // ── Services ───────────────────────────────────────────────
  final StreakService _streakService = StreakService();
  final RiskPredictionService _riskService = RiskPredictionService();
  final RelapsePredictionService _relapseService = RelapsePredictionService();
  final UrgePredictionService _urgePredictionService = UrgePredictionService();
  final AIGuidanceService _aiService = AIGuidanceService();
  final AIGuardianService _guardianService = AIGuardianService();
  final RecoveryScoreService _recoveryService = RecoveryScoreService();
  final PreRelapseWarningService _warningService = PreRelapseWarningService();

  // ── Animation ──────────────────────────────────────────────
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  // Track when relapse is recorded to reset timer in child widget
  int _relapseResetKey = 0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _runGuardianCheck();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _runGuardianCheck() async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) await _guardianService.checkAndTriggerGuardian(context);
  }

  void _handleAIAction(String action) {
    if (action == 'Start Emergency Reset') {
      _showEmergencyReset();
    } else if (action == 'Open Coping Tools') {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const UrgeLogScreen()));
    }
  }

  void _showEmergencyReset() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🚨 Emergency Reset',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pause for a moment.',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.75), height: 1.5)),
            const SizedBox(height: 12),
            ...[
              '• Take 5 deep breaths',
              '• Drink water',
              '• Change your environment',
              '• Log your urge',
            ].map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(s,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 13)),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("I'm Okay",
                style: TextStyle(color: Color(0xFF6C63FF))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const UrgeLogScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child:
                const Text('Log Urge', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: _buildAppBar(),
      drawer: const AppDrawer(),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: StreamBuilder<StreakModel?>(
          stream: _streakService.getStreak(),
          builder: (context, streakSnap) {
            final streak = streakSnap.data;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Greeting ──────────────────────────────
                  _buildGreeting(user?.email),
                  const SizedBox(height: 24),

                  // ── Live Streak Timer ─────────────────────
                  StreakTimerCard(
                    key: ValueKey('streak_timer_$_relapseResetKey'),
                    streak: streak,
                  ),
                  const SizedBox(height: 16),

                  // ── Milestone Progress ────────────────────
                  if (streak != null) ...[
                    MilestoneProgressCard(streak: streak),
                    const SizedBox(height: 16),
                  ],

                  // ── Daily Check-In ────────────────────────
                  DailyCheckInCard(
                    streak: streak,
                    streakService: _streakService,
                    onRelapseRecorded: () {
                      setState(() => _relapseResetKey++);
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Pre-Relapse Warning ───────────────────
                  FutureBuilder<PreRelapseWarningModel?>(
                    future: _warningService.checkWarning(),
                    builder: (_, snap) {
                      if (!snap.hasData || snap.data == null) {
                        return const SizedBox.shrink();
                      }
                      return PreRelapseWarningCard(
                        warning: snap.data!,
                        onStartPrevention: _showEmergencyReset,
                      );
                    },
                  ),

                  // ── Recovery Score ────────────────────────
                  FutureBuilder<RecoveryScoreModel>(
                    future: _recoveryService.calculateRecoveryScore(),
                    builder: (_, snap) {
                      if (!snap.hasData) return const SizedBox.shrink();
                      return RecoveryScoreCard(score: snap.data!);
                    },
                  ),

                  // ── Urge Prediction ───────────────────────
                  FutureBuilder<UrgePredictionModel>(
                    future: _urgePredictionService.predictUrge(),
                    builder: (_, snap) {
                      if (!snap.hasData) return const SizedBox.shrink();
                      return UrgePredictionCard(prediction: snap.data!);
                    },
                  ),

                  // ── AI Guidance ───────────────────────────
                  FutureBuilder<AIGuidanceModel>(
                    future: _aiService.generateGuidance(),
                    builder: (_, snap) {
                      if (!snap.hasData) return const SizedBox.shrink();
                      return AIGuidanceCard(
                        guidance: snap.data!,
                        onAction: _handleAIAction,
                      );
                    },
                  ),

                  // ── Risk ──────────────────────────────────
                  FutureBuilder<RiskModel?>(
                    future: _riskService.analyzeRisk(),
                    builder: (_, snap) {
                      if (!snap.hasData || snap.data == null) {
                        return const SizedBox.shrink();
                      }
                      return RiskCard(risk: snap.data!);
                    },
                  ),

                  // ── Relapse Probability ───────────────────
                  FutureBuilder(
                    future: _relapseService.analyzeRelapseRisk(),
                    builder: (_, snap) {
                      if (!snap.hasData) return const SizedBox.shrink();
                      final pred = snap.data!;
                      return RelapsePredictionCard(
                        probability: pred.probability,
                        level: pred.level,
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: _buildUrgeButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ── AppBar ─────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0D0D1A),
      elevation: 0,
      titleSpacing: 16,
      // ── Hamburger (opens left drawer) ──────────────────
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.menu_rounded,
                color: Colors.white.withOpacity(0.8), size: 18),
          ),
          tooltip: 'Menu',
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)],
        ).createShader(bounds),
        child: const Text(
          'ReWireX',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.8,
          ),
        ),
      ),
      // ── Profile icon (replaces AI Coach) ───────────────
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(Icons.person_outline_rounded,
                color: Colors.white.withOpacity(0.8), size: 18),
          ),
          tooltip: 'Profile',
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ProfileScreen())),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── Greeting ───────────────────────────────────────────────
  Widget _buildGreeting(String? email) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final emoji = hour < 12 ? '☀️' : hour < 17 ? '👋' : '🌙';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting $emoji',
          style: TextStyle(
            color: Colors.white.withOpacity(0.45),
            fontSize: 14,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email ?? 'Welcome back',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ── Floating Urge Button ───────────────────────────────────
  Widget _buildUrgeButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withOpacity(0.45),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const UrgeLogScreen())),
            icon: const Icon(Icons.flash_on_rounded,
                color: Colors.white, size: 22),
            label: const Text(
              'I Feel an Urge',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
          ),
        ),
      ),
    );
  }
}