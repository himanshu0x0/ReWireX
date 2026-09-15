// lib/features/urge/screens/urge_rescue_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/intervention_catalog.dart';
import '../data/urge_needs.dart';
import '../models/urge_intervention_model.dart';
import '../models/urge_session_model.dart';
import '../services/urge_session_service.dart';
import 'urge_result_screen.dart';

/// Executes exactly one AI-selected, predefined rescue intervention.
///
/// No runtime-generated intervention content is allowed here. The resolver
/// chooses from the static catalog and this screen only executes its steps.
class UrgeRescueScreen extends StatefulWidget {
  const UrgeRescueScreen({
    super.key,
    required this.session,
    this.selectedIntervention,
    this.rankedInterventions,
  });

  final UrgeSessionModel session;
  final UrgeInterventionModel? selectedIntervention;
  final List<UrgeInterventionModel>? rankedInterventions;

  @override
  State<UrgeRescueScreen> createState() => _UrgeRescueScreenState();
}

class _UrgeRescueScreenState extends State<UrgeRescueScreen> {
  static const _background = Color(0xFF0D0D1A);
  static const _card = Color(0xFF141428);
  static const _primary = Color(0xFF6C63FF);
  static const _accent = Color(0xFF00C4A0);

  final UrgeSessionService _sessionService = UrgeSessionService();

  late UrgeSessionModel _session;
  late UrgeInterventionModel _intervention;
  int _stepIndex = 0;
  int _remainingSeconds = 0;
  bool _starting = true;
  bool _showRecheck = false;
  bool _saving = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _session = widget.session;

    final fallbackNeed =
        _session.selectedNeed ??
        (_session.suggestedNeeds.isNotEmpty
            ? _session.suggestedNeeds.first
            : needsForUrge(_session.urgeType).first);
    _intervention =
        widget.selectedIntervention ??
        bestInterventionFor(urge: _session.urgeType, need: fallbackNeed);

    _session = _session.copyWith(
      selectedNeed: _session.selectedNeed ?? fallbackNeed,
      rescuePath: _intervention.rescuePath,
      interventionId: _intervention.id,
      interventionTitle: _intervention.title,
      status: UrgeSessionStatus.interventionSelected,
      updatedAt: DateTime.now(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _persistAndStart());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _hasSteps => _intervention.steps.isNotEmpty;

  InterventionStep get _currentStep {
    if (!_hasSteps) {
      return const InterventionStep(
        id: 'fallback',
        title: 'Pause',
        instruction:
            'Give yourself a few quiet minutes before making any decision.',
        helperText:
            'The goal is to create space between the urge and the action.',
        estimatedSeconds: 30,
      );
    }

    final safeIndex = _stepIndex.clamp(0, _intervention.steps.length - 1);
    return _intervention.steps[safeIndex];
  }

  Future<void> _persistAndStart() async {
    try {
      await _sessionService.saveSession(_session);
    } catch (e) {
      debugPrint('Urge session save error: $e');
    }

    if (!mounted) return;

    setState(() => _starting = false);

    if (!_hasSteps) {
      setState(() => _showRecheck = true);
      return;
    }

    await _startCurrentStep();
  }

  Future<void> _startCurrentStep() async {
    _timer?.cancel();

    final seconds = _currentStep.estimatedSeconds.clamp(0, 600);
    if (!mounted) return;

    setState(() => _remainingSeconds = seconds);

    if (seconds <= 0) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  Future<void> _nextStep() async {
    if (_starting || _saving || _showRecheck) return;

    HapticFeedback.lightImpact();
    _timer?.cancel();

    if (!_hasSteps || _stepIndex >= _intervention.steps.length - 1) {
      setState(() {
        _session = _session.copyWith(
          status: UrgeSessionStatus.rechecked,
          interventionCompleted: true,
          interventionCompletedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _showRecheck = true;
      });
      await _persist();
      return;
    }

    setState(() {
      _stepIndex++;
      _session = _session.copyWith(
        status: UrgeSessionStatus.inProgress,
        interventionStartedAt: _session.interventionStartedAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    await _persist();
    await _startCurrentStep();
  }

  Future<void> _previousStep() async {
    if (_stepIndex <= 0 || _showRecheck || _saving) return;

    _timer?.cancel();
    setState(() => _stepIndex--);
    await _startCurrentStep();
  }

  Future<void> _persist() async {
    try {
      await _sessionService.saveSession(_session);
    } catch (e) {
      debugPrint('Urge session update error: $e');
    }
  }

  Future<void> _submitRecheck({
    required int score,
    required bool escalated,
  }) async {
    if (_saving) return;

    setState(() => _saving = true);

    final before = (_session.urgeBefore ?? 5).clamp(1, 10).toInt();
    final after = score.clamp(0, 10).toInt();
    final outcome = escalated
        ? UrgeOutcome.escalated
        : UrgeSessionModel.outcomeFromScores(before, after);

    _session = _session.copyWith(
      urgeAfter: after,
      outcome: outcome,
      status: escalated
          ? UrgeSessionStatus.escalated
          : UrgeSessionStatus.completed,
      wasEscalated: escalated,
      recheckedAt: DateTime.now(),
      completedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _persist();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            UrgeResultScreen(session: _session, intervention: _intervention),
      ),
    );
  }

  Future<void> _openRecheck() async {
    final before = (_session.urgeBefore ?? 5).clamp(0, 10).toInt();
    var score = before;

    final result = await showModalBottomSheet<_RecheckResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  20 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How strong is the urge now?',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lower is progress. You do not need to feel perfect.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: Text(
                        '$score / 10',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    Slider(
                      value: score.toDouble(),
                      min: 0,
                      max: 10,
                      divisions: 10,
                      label: '$score',
                      onChanged: (value) {
                        setSheetState(() => score = value.round());
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(
                              context,
                              _RecheckResult(score: score, escalated: false),
                            ),
                            child: const Text('Save'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.pop(
                              context,
                              _RecheckResult(score: score, escalated: true),
                            ),
                            child: const Text('Need more help'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;

    await _submitRecheck(score: result.score, escalated: result.escalated);
  }

  @override
  Widget build(BuildContext context) {
    if (_starting) {
      return const Scaffold(
        backgroundColor: _background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_showRecheck) return _buildRecheckIntro();

    final total = _intervention.steps.isEmpty ? 1 : _intervention.steps.length;
    final progress = ((_stepIndex + 1) / total).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: _stepIndex == 0
              ? () => Navigator.pop(context)
              : _previousStep,
          icon: Icon(
            _stepIndex == 0
                ? Icons.close_rounded
                : Icons.arrow_back_ios_new_rounded,
          ),
        ),
        title: Text(
          _intervention.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                borderRadius: BorderRadius.circular(8),
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                color: _primary,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: _buildStepCard(),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _currentStep.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _currentStep.instruction,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              height: 1.55,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_currentStep.helperText != null) ...[
            const SizedBox(height: 14),
            Text(
              _currentStep.helperText!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.52),
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
          if (_remainingSeconds > 0) ...[
            const SizedBox(height: 26),
            Center(
              child: Text(
                '$_remainingSeconds',
                style: const TextStyle(
                  color: _accent,
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Center(
              child: Text(
                'seconds',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final isLast =
        _intervention.steps.isEmpty ||
        _stepIndex >= _intervention.steps.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: _background,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: FilledButton.icon(
          onPressed: _saving ? null : (isLast ? _openRecheck : _nextStep),
          icon: Icon(
            isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
          ),
          label: Text(isLast ? 'Recheck my urge' : 'Done — next step'),
        ),
      ),
    );
  }

  Widget _buildRecheckIntro() {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.favorite_outline_rounded,
                  color: _accent,
                  size: 56,
                ),
                const SizedBox(height: 18),
                const Text(
                  'You created some space.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Now let’s check whether the urge changed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _openRecheck,
                    icon: const Icon(Icons.speed_rounded),
                    label: const Text('Check the urge'),
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

class _RecheckResult {
  const _RecheckResult({required this.score, required this.escalated});

  final int score;
  final bool escalated;
}
