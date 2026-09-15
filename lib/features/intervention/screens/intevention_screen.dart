// lib/features/intervention/screens/intevention_screen.dart
// NOTE: filename kept as "intevention_screen.dart" (original typo) to avoid
// import-path changes across the codebase.

import 'dart:async';
import 'package:flutter/material.dart';

import '../models/intervention_model.dart';
import '../data/intervention_techniques.dart';
import '../services/adaptive_intervention_service.dart';
import '../services/intervention_feedback_service.dart';
import '../models/intervention_feedback_model.dart';
import '../../risk/services/risk_prediction_service.dart';
import '../../urge/models/urge_session_model.dart';
import '../../urge/services/urge_session_service.dart';

class InterventionScreen extends StatefulWidget {
  final String emotion;
  final int intensity;

  /// Optional intervention selected by the newer Urge Rescue Engine.
  /// When provided, this screen executes that exact predefined intervention
  /// instead of asking AdaptiveInterventionService to choose a new one.
  final InterventionModel? interventionOverride;

  /// Optional urge session to keep the new urge-session record synchronized
  /// with the existing guided intervention experience.
  final UrgeSessionModel? urgeSession;

  const InterventionScreen({
    super.key,
    required this.emotion,
    required this.intensity,
    this.interventionOverride,
    this.urgeSession,
  });

  @override
  State<InterventionScreen> createState() => _InterventionScreenState();
}

class _InterventionScreenState extends State<InterventionScreen>
    with TickerProviderStateMixin {
  // ── Services ───────────────────────────────────────────────
  final AdaptiveInterventionService _service = AdaptiveInterventionService();
  final InterventionFeedbackService _feedbackService =
      InterventionFeedbackService();
  final UrgeSessionService _urgeSessionService = UrgeSessionService();

  // ── State ──────────────────────────────────────────────────
  InterventionModel? _model;
  bool _sessionStarted = false;
  bool _sessionComplete = false;
  bool _isSubmitting = false;
  int _currentStep = 0;
  int? _intensityAfter;
  String _riskLevel = 'Low';

  // Session timer
  final DateTime _sessionStart = DateTime.now();
  Timer? _stepTimer;
  int _stepSecondsRemaining = 0;

  // ── Animations ─────────────────────────────────────────────
  late AnimationController _breathController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _progressController;

  late Animation<double> _breathAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadIntervention();
  }

  void _initAnimations() {
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _breathAnim = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _progressAnim =
        CurvedAnimation(parent: _progressController, curve: Curves.easeOut);
  }

  // ── FIX: wrapped in try/catch with a guaranteed fallback model ──
  // Previously, any error thrown inside RiskPredictionService.analyzeRisk()
  // or AdaptiveInterventionService.generateIntervention() (e.g. a Firestore
  // permission-denied error) was never caught. That left `_model` as null
  // forever, so build() kept returning the loading spinner indefinitely
  // ("Selecting your technique…" never resolving). Now, any failure falls
  // back to a safe default technique instead of hanging the screen.
  Future<void> _loadIntervention() async {
    // New urge flow: respect the intervention already selected by the
    // UrgeEngine. This prevents the old emotion/intensity selector from
    // silently replacing the user's rescue choice.
    if (widget.interventionOverride != null) {
      if (mounted) {
        setState(() {
          _model = widget.interventionOverride;
        });
      }
      return;
    }

    InterventionModel? model;

    try {
      final risk = await RiskPredictionService().analyzeRisk();
      _riskLevel = risk?.level ?? 'Low';
    } catch (e) {
      debugPrint('Risk Analysis Error: $e');
      _riskLevel = 'Low';
    }

    try {
      model = await _service.generateIntervention(
        emotion: widget.emotion,
        intensity: widget.intensity,
      );
    } catch (e) {
      debugPrint('Generate Intervention Error: $e');
    }

    // Guaranteed fallback so the screen can never get stuck loading.
    model ??= widget.intensity >= 9
        ? InterventionTechniques.emergencyReset
        : InterventionTechniques.microReset;

    if (mounted) setState(() => _model = model);
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _breathController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  // ── Step Navigation ─────────────────────────────────────────

  void _startSession() {
    setState(() {
      _sessionStarted = true;
      _currentStep = 0;
    });
    _fadeController
      ..reset()
      ..forward();
    _startStep(_model!.steps[0]);
    _updateProgress();
  }

  void _startStep(InterventionStep step) {
    _stepTimer?.cancel();
    _fadeController
      ..reset()
      ..forward();

    // Start breath animation based on step type
    if (step.isBreathIn) {
      _breathController.forward(from: 0);
    } else if (step.isBreathOut) {
      _breathController.reverse(from: 1);
    } else if (step.isHold) {
      // Gentle pulse during hold
    }

    if (step.durationSeconds > 0) {
      setState(() => _stepSecondsRemaining = step.durationSeconds);
      _stepTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() => _stepSecondsRemaining--);
        if (_stepSecondsRemaining <= 0) {
          t.cancel();
          _advanceStep();
        }
      });
    } else {
      setState(() => _stepSecondsRemaining = 0);
    }
  }

  void _advanceStep() {
    if (_model == null) return;
    _stepTimer?.cancel();

    final nextIndex = _currentStep + 1;
    if (nextIndex >= _model!.steps.length) {
      _completeSession();
      return;
    }
    setState(() => _currentStep = nextIndex);
    _updateProgress();
    _startStep(_model!.steps[nextIndex]);
  }

  void _updateProgress() {
    if (_model == null) return;
    final target = (_currentStep + 1) / _model!.steps.length;
    _progressController.animateTo(target,
        duration: const Duration(milliseconds: 600), curve: Curves.easeOut);
  }

  void _completeSession() {
    _stepTimer?.cancel();
    _breathController.stop();
    setState(() => _sessionComplete = true);
    _fadeController
      ..reset()
      ..forward();
  }

  // ── Feedback ────────────────────────────────────────────────

  Future<void> _submitFeedback(bool wasEffective) async {
    if (_model == null || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final duration =
          DateTime.now().difference(_sessionStart).inSeconds;

      await _feedbackService.saveFeedback(
        InterventionFeedbackModel(
          emotion: widget.emotion,
          intensity: widget.intensity,
          technique: _model!.technique,
          wasEffective: wasEffective,
          timestamp: DateTime.now(),
          sessionDurationSeconds: duration,
          stepsCompleted: _currentStep + 1,
          totalSteps: _model!.steps.length,
          riskLevel: _riskLevel,
          intensityAfter: _intensityAfter,
        ),
      );

      await _syncUrgeSessionAfterCompletion();

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Feedback Save Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not save feedback.'),
            backgroundColor: const Color(0xFF6C63FF),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _syncUrgeSessionAfterCompletion() async {
  final urgeSession = widget.urgeSession;
  if (urgeSession == null) return;

  final int before =
      (urgeSession.urgeBefore ?? widget.intensity).clamp(1, 10).toInt();

  final int after =
      (_intensityAfter ?? widget.intensity).clamp(0, 10).toInt();

  final now = DateTime.now();

  final updated = urgeSession.copyWith(
    urgeBefore: before,
    urgeAfter: after,
    outcome: UrgeSessionModel.outcomeFromScores(
      before,
      after,
    ),
    status: UrgeSessionStatus.completed,
    interventionCompleted: true,
    interventionCompletedAt: now,
    recheckedAt: now,
    completedAt: now,
    updatedAt: now,
  );

  try {
    await _urgeSessionService.updateSession(updated);
  } catch (e, stackTrace) {
    debugPrint('Urge session sync error: $e');
    debugPrintStack(stackTrace: stackTrace);
  }
}
  // ══════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_model == null) return _buildLoading();
    if (_sessionComplete) return _buildCompletion();
    if (!_sessionStarted) return _buildPreview();
    return _buildSession();
  }

  // ── Loading ────────────────────────────────────────────────

  Widget _buildLoading() {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                color: Color(0xFF6C63FF),
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Selecting your technique…',
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Preview screen (before starting) ──────────────────────

  Widget _buildPreview() {
    final model = _model!;
    final categoryColor = _categoryColor(model.category);
    final isEmergency = model.isEmergency;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────
              _buildHeader(model),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // ── Hero icon ───────────────────────
                      Center(
                        child: ScaleTransition(
                          scale: _pulseAnim,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: categoryColor.withOpacity(0.12),
                              border: Border.all(
                                color: categoryColor.withOpacity(0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: categoryColor.withOpacity(0.2),
                                  blurRadius: 30,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                model.emoji,
                                style: const TextStyle(fontSize: 44),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Title ────────────────────────────
                      Center(
                        child: Column(
                          children: [
                            Text(
                              model.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              model.subtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.45),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Info chips ────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _InfoChip(
                            icon: Icons.timer_outlined,
                            label: '~${model.estimatedMinutes} min',
                            color: categoryColor,
                          ),
                          const SizedBox(width: 10),
                          _InfoChip(
                            icon: Icons.format_list_numbered_rounded,
                            label: '${model.steps.length} steps',
                            color: categoryColor,
                          ),
                          if (isEmergency) ...[
                            const SizedBox(width: 10),
                            _InfoChip(
                              icon: Icons.priority_high_rounded,
                              label: 'Emergency',
                              color: Colors.red,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Description ──────────────────────
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.07),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lightbulb_outline_rounded,
                              color: categoryColor,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                model.message,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.65),
                                  fontSize: 14,
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Step preview ─────────────────────
                      _StepPreviewList(model: model),
                    ],
                  ),
                ),
              ),

              // ── Start button ────────────────────────────
              _buildStartButton(model),
            ],
          ),
        ),
      ),
    );
  }

  // ── Active session screen ──────────────────────────────────

  Widget _buildSession() {
    final model = _model!;
    final step = model.steps[_currentStep];
    final categoryColor = _categoryColor(model.category);
    final isBreathStep = step.isBreathIn || step.isBreathOut || step.isHold;
    final isTimed = step.durationSeconds > 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress header ─────────────────────────
            _buildSessionHeader(model),

            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── Breath visualizer or step icon ──
                      if (isBreathStep)
                        _BreathVisualizer(
                          anim: _breathAnim,
                          pulse: _pulseAnim,
                          color: categoryColor,
                          isBreathIn: step.isBreathIn,
                          isBreathOut: step.isBreathOut,
                          isHold: step.isHold,
                          secondsRemaining: _stepSecondsRemaining,
                        )
                      else
                        _StepIcon(
                          emoji: model.emoji,
                          color: categoryColor,
                          pulse: _pulseAnim,
                        ),

                      const SizedBox(height: 36),

                      // ── Step instruction ─────────────────
                      Text(
                        step.instruction,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                          letterSpacing: 0.2,
                        ),
                      ),

                      if (step.subtext != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          step.subtext!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // ── Timer or tap-to-continue ─────────
                      if (isTimed)
                        _TimerIndicator(
                          seconds: _stepSecondsRemaining,
                          total: step.durationSeconds,
                          color: categoryColor,
                        )
                      else
                        _TapToContinueButton(
                          color: categoryColor,
                          onTap: _advanceStep,
                          isLast: _currentStep == model.steps.length - 1,
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Step counter ────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Text(
                'Step ${_currentStep + 1} of ${model.steps.length}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.28),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Completion screen ──────────────────────────────────────

  Widget _buildCompletion() {
    final model = _model!;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Back ────────────────────────────────
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.close_rounded,
                        color: Colors.white.withOpacity(0.6), size: 18),
                  ),
                ),

                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── Completion icon ──────────────────
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6C63FF).withOpacity(0.4),
                              blurRadius: 28,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 42),
                      ),
                      const SizedBox(height: 28),

                      const Text(
                        'Session Complete',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'You completed the full ${model.technique} protocol.\nThe urge is weaker now than when you started.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Intensity after slider ───────────
                      _IntensityAfterCard(
                        initialValue: _intensityAfter ?? widget.intensity,
                        originalIntensity: widget.intensity,
                        onChanged: (v) =>
                            setState(() => _intensityAfter = v),
                      ),

                      const SizedBox(height: 32),

                      // ── Feedback ─────────────────────────
                      Text(
                        'DID THIS HELP?',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.35),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _FeedbackButton(
                              label: 'Yes, it helped',
                              icon: Icons.thumb_up_rounded,
                              color: const Color(0xFF00C4A0),
                              isLoading: _isSubmitting,
                              onTap: () => _submitFeedback(true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _FeedbackButton(
                              label: 'Not really',
                              icon: Icons.thumb_down_rounded,
                              color: Colors.red.shade400,
                              isLoading: _isSubmitting,
                              onTap: () => _submitFeedback(false),
                              outlined: true,
                            ),
                          ),
                        ],
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

  // ── Shared sub-widgets ─────────────────────────────────────

  Widget _buildHeader(InterventionModel model) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 15, color: Colors.white.withOpacity(0.7)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reset Moment',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  widget.urgeSession != null
                      ? '${widget.urgeSession!.urgeType.name}  •  Intensity ${widget.intensity}/10'
                      : '${widget.emotion}  •  Intensity ${widget.intensity}/10',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.38),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Emergency badge
          if (model.isEmergency)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: Colors.red.withOpacity(0.3), width: 1),
              ),
              child: const Text(
                'EMERGENCY',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSessionHeader(InterventionModel model) {
    final categoryColor = _categoryColor(model.category);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.close_rounded,
                      color: Colors.white.withOpacity(0.4), size: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  model.technique,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar
          AnimatedBuilder(
            animation: _progressAnim,
            builder: (_, __) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _progressAnim.value,
                minHeight: 4,
                backgroundColor: Colors.white.withOpacity(0.08),
                valueColor:
                    AlwaysStoppedAnimation<Color>(categoryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(InterventionModel model) {
    final categoryColor = _categoryColor(model.category);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: model.isEmergency
                ? const LinearGradient(
                    colors: [Color(0xFFE53935), Color(0xFFFF7043)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : LinearGradient(
                    colors: [const Color(0xFF6C63FF), categoryColor],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            boxShadow: [
              BoxShadow(
                color: (model.isEmergency
                        ? Colors.red
                        : const Color(0xFF6C63FF))
                    .withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _startSession,
            icon: Icon(
              model.isEmergency
                  ? Icons.flash_on_rounded
                  : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 22,
            ),
            label: Text(
              model.actionText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
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

  // ── Helpers ────────────────────────────────────────────────

  Color _categoryColor(InterventionCategory cat) {
    switch (cat) {
      case InterventionCategory.breathing:
        return const Color(0xFF6C63FF);
      case InterventionCategory.grounding:
        return const Color(0xFF00C4A0);
      case InterventionCategory.cognitive:
        return const Color(0xFF4FC3F7);
      case InterventionCategory.physical:
        return const Color(0xFFFFB74D);
      case InterventionCategory.social:
        return const Color(0xFFAB47BC);
      case InterventionCategory.emergency:
        return const Color(0xFFE53935);
    }
  }
}

// ══════════════════════════════════════════════════════════
//  PRIVATE SUB-WIDGETS
// ══════════════════════════════════════════════════════════

/// Step-by-step preview list shown before starting
class _StepPreviewList extends StatelessWidget {
  final InterventionModel model;
  const _StepPreviewList({required this.model});

  @override
  Widget build(BuildContext context) {
    final color = _catColor(model.category);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WHAT YOU\'LL DO',
          style: TextStyle(
            color: Colors.white.withOpacity(0.35),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Colors.white.withOpacity(0.06), width: 1),
          ),
          child: Column(
            children: model.steps
                .asMap()
                .entries
                .map((e) => Padding(
                      padding: EdgeInsets.only(
                          bottom:
                              e.key < model.steps.length - 1 ? 12 : 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color.withOpacity(0.12),
                              border: Border.all(
                                  color: color.withOpacity(0.25),
                                  width: 1),
                            ),
                            child: Center(
                              child: Text(
                                '${e.key + 1}',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.value.instruction,
                                  style: TextStyle(
                                    color:
                                        Colors.white.withOpacity(0.7),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (e.value.durationSeconds > 0)
                                  Text(
                                    '${e.value.durationSeconds}s',
                                    style: TextStyle(
                                      color:
                                          color.withOpacity(0.6),
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Color _catColor(InterventionCategory cat) {
    switch (cat) {
      case InterventionCategory.breathing:
        return const Color(0xFF6C63FF);
      case InterventionCategory.grounding:
        return const Color(0xFF00C4A0);
      case InterventionCategory.cognitive:
        return const Color(0xFF4FC3F7);
      case InterventionCategory.physical:
        return const Color(0xFFFFB74D);
      case InterventionCategory.social:
        return const Color(0xFFAB47BC);
      case InterventionCategory.emergency:
        return const Color(0xFFE53935);
    }
  }
}

/// Animated breathing circle with phase label
class _BreathVisualizer extends StatelessWidget {
  final Animation<double> anim;
  final Animation<double> pulse;
  final Color color;
  final bool isBreathIn;
  final bool isBreathOut;
  final bool isHold;
  final int secondsRemaining;

  const _BreathVisualizer({
    required this.anim,
    required this.pulse,
    required this.color,
    required this.isBreathIn,
    required this.isBreathOut,
    required this.isHold,
    required this.secondsRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final label = isBreathIn
        ? 'BREATHE IN'
        : isBreathOut
            ? 'BREATHE OUT'
            : 'HOLD';

    return AnimatedBuilder(
      animation: Listenable.merge([anim, pulse]),
      builder: (_, __) {
        final scale = isHold ? pulse.value : anim.value;
        return Column(
          children: [
            SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow
                  Transform.scale(
                    scale: scale * 1.15,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withOpacity(0.06),
                      ),
                    ),
                  ),
                  // Mid ring
                  Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withOpacity(0.10),
                        border: Border.all(
                            color: color.withOpacity(0.2), width: 1.5),
                      ),
                    ),
                  ),
                  // Inner core
                  Transform.scale(
                    scale: scale * 0.72,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withOpacity(0.18),
                        border: Border.all(
                            color: color.withOpacity(0.5), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.35),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          secondsRemaining > 0
                              ? '$secondsRemaining'
                              : '',
                          style: TextStyle(
                            color: color,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.5,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Non-breath step icon
class _StepIcon extends StatelessWidget {
  final String emoji;
  final Color color;
  final Animation<double> pulse;

  const _StepIcon(
      {required this.emoji, required this.color, required this.pulse});

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: pulse,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.10),
          border: Border.all(color: color.withOpacity(0.25), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 28,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 48)),
        ),
      ),
    );
  }
}

/// Circular countdown indicator for timed steps
class _TimerIndicator extends StatelessWidget {
  final int seconds;
  final int total;
  final Color color;

  const _TimerIndicator(
      {required this.seconds, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? seconds / total : 0.0;
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 4,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Text(
            '$seconds',
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tap-to-continue button for manual steps
class _TapToContinueButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;
  final bool isLast;

  const _TapToContinueButton(
      {required this.color,
      required this.onTap,
      required this.isLast});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5), width: 1.5),
          color: color.withOpacity(0.08),
        ),
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(
            isLast
                ? Icons.check_circle_outline_rounded
                : Icons.arrow_forward_rounded,
            color: color,
            size: 20,
          ),
          label: Text(
            isLast ? 'Complete Session' : 'Continue',
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }
}

/// Info chip for preview screen
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Self-reported intensity slider after completion
class _IntensityAfterCard extends StatefulWidget {
  final int initialValue;
  final int originalIntensity;
  final ValueChanged<int> onChanged;

  const _IntensityAfterCard({
    required this.initialValue,
    required this.originalIntensity,
    required this.onChanged,
  });

  @override
  State<_IntensityAfterCard> createState() => _IntensityAfterCardState();
}

class _IntensityAfterCardState extends State<_IntensityAfterCard> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue.clamp(1, 10).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final delta = widget.originalIntensity - _value.round();
    final improved = delta > 0;
    final color = improved
        ? const Color(0xFF00C4A0)
        : _value.round() == widget.originalIntensity
            ? Colors.amber
            : Colors.red.shade400;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: Colors.white.withOpacity(0.07), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HOW IS YOUR URGE INTENSITY NOW?',
            style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                '${_value.round()}',
                style: TextStyle(
                  color: color,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              const Text(
                ' / 10',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (delta != 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    improved ? '▼ $delta lower' : '▲ ${-delta} higher',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 18),
              activeTrackColor: color,
              inactiveTrackColor: Colors.white.withOpacity(0.08),
              thumbColor: color,
              overlayColor: color.withOpacity(0.15),
            ),
            child: Slider(
              value: _value,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (v) {
                setState(() => _value = v);
                widget.onChanged(v.round());
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Feedback button (filled or outlined)
class _FeedbackButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;
  final bool outlined;

  const _FeedbackButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: isLoading ? null : onTap,
              icon: Icon(icon, color: color, size: 18),
              label: Text(label,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color.withOpacity(0.5), width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            )
          : DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : onTap,
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Icon(icon, color: Colors.white, size: 18),
                label: Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
    );
  }
}