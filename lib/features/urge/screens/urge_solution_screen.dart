// lib/features/urge/screens/urge_solution_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rewirex/features/connect/games/screens/games_hub_screen.dart';
import 'package:rewirex/features/connect/wellness/screens/journal_screen.dart';
import 'package:rewirex/features/connect/wellness/screens/meditation_screen.dart';
import 'package:rewirex/features/connect/wellness/screens/mood_music_screen.dart';
import 'package:rewirex/features/connect/stories/screens/stories_screen.dart';

import '../data/intervention_catalog.dart';
import '../data/urge_needs.dart';
import '../engine/urge_solution_engine.dart';
import '../models/urge_session_model.dart';
import '../models/urge_solution_model.dart';
import '../services/urge_session_service.dart';
import '../services/urge_solution_feedback_service.dart';
import 'urge_rescue_screen.dart';
import 'urge_result_screen.dart';

/// The main user-facing Urge Rescue decision screen.
///
/// The user does not select a need or a rescue path here. ReWireX analyzes the
/// information already collected and gives one clear next step plus up to two
/// alternatives.
class UrgeSolutionScreen extends StatefulWidget {
  const UrgeSolutionScreen({super.key, required this.session});

  final UrgeSessionModel session;

  @override
  State<UrgeSolutionScreen> createState() => _UrgeSolutionScreenState();
}

class _UrgeSolutionScreenState extends State<UrgeSolutionScreen> {
  static const _background = Color(0xFF0D0D1A);
  static const _surface = Color(0xFF171728);
  static const _primary = Color(0xFF6C63FF);
  static const _teal = Color(0xFF00C4A0);

  final UrgeSolutionEngine _engine = const UrgeSolutionEngine();
  final UrgeSessionService _sessionService = UrgeSessionService();
  final UrgeSolutionFeedbackService _feedbackService =
      UrgeSolutionFeedbackService();

  late UrgeSessionModel _session;
  late UrgeSolutionPlan _plan;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _plan = _engine.resolve(_session);
    _persistSelection();
  }

  Future<void> _persistSelection() async {
    final action = _plan.primary;
    final intervention = _plan.intervention;

    _session = _session.copyWith(
      selectedNeed: _plan.need,
      interventionId: intervention?.id,
      interventionTitle: action.title,
      rescuePath: intervention?.rescuePath ?? _session.rescuePath,
      status: intervention != null
          ? UrgeSessionStatus.interventionSelected
          : _session.status,
      updatedAt: DateTime.now(),
    );

    try {
      await _sessionService.saveSession(_session);
    } catch (e) {
      debugPrint('Urge solution persistence warning: $e');
    }
  }

  Future<void> _run(UrgeSolutionAction action) async {
    if (_busy) return;

    if (action.type == UrgeSolutionActionType.chat) {
      _showUnavailableConnection();
      return;
    }

    final intervention = action.interventionId == null
        ? null
        : interventionById(action.interventionId!);

    setState(() => _busy = true);
    HapticFeedback.mediumImpact();

    try {
      if (action.type == UrgeSolutionActionType.truthDare) {
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const GamesHubScreen()),
        );
        if (!mounted) return;
        await _finishWithRecheck(action);
        return;
      }

      // Real Wellness/Stories tools are opened as full screens. Each screen
      // returns to this rescue flow when the user finishes the activity.
      switch (action.type) {
        case UrgeSolutionActionType.journal:
          if (!mounted) return;
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const JournalScreen(returnAfterSave: true),
            ),
          );
          if (!mounted) return;
          await _finishWithRecheck(action);
          return;
        case UrgeSolutionActionType.meditation:
          if (!mounted) return;
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const MeditationScreen(returnWhenComplete: true),
            ),
          );
          if (!mounted) return;
          await _finishWithRecheck(action);
          return;
        case UrgeSolutionActionType.music:
          if (!mounted) return;
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const MoodMusicScreen(rescueMode: true),
            ),
          );
          if (!mounted) return;
          await _finishWithRecheck(action);
          return;
        case UrgeSolutionActionType.recoveryStories:
          if (!mounted) return;
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const StoriesScreen(rescueMode: true),
            ),
          );
          if (!mounted) return;
          await _finishWithRecheck(action);
          return;
        default:
          break;
      }

      if (intervention != null) {
        final prepared = _session.copyWith(
          selectedNeed: _plan.need,
          interventionId: intervention.id,
          interventionTitle: action.title,
          rescuePath: intervention.rescuePath,
          status: UrgeSessionStatus.interventionSelected,
          updatedAt: DateTime.now(),
        );

        try {
          await _sessionService.saveSession(prepared);
        } catch (e) {
          debugPrint('Guided rescue preparation save warning: $e');
        }

        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => UrgeRescueScreen(
              session: prepared,
              selectedIntervention: intervention,
            ),
          ),
        );
        return;
      }

      final notes = await _showQuickTool(action);
      if (!mounted || notes == null) return;
      await _finishWithRecheck(action, additionalNotes: notes);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _showQuickTool(UrgeSolutionAction action) async {
    final controller = TextEditingController();
    Timer? timer;
    int secondsLeft = action.estimatedMinutes * 60;
    bool running = false;

    final notes = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void startTimer() {
              if (running) return;
              setSheetState(() => running = true);
              timer?.cancel();
              timer = Timer.periodic(const Duration(seconds: 1), (_) {
                if (!context.mounted) return;
                if (secondsLeft <= 1) {
                  timer?.cancel();
                  setSheetState(() {
                    secondsLeft = 0;
                    running = false;
                  });
                  return;
                }
                setSheetState(() => secondsLeft--);
              });
            }

            return Container(
              decoration: const BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.fromLTRB(
                22,
                14,
                22,
                24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text(action.emoji, style: const TextStyle(fontSize: 34)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            action.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      action.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (action.type == UrgeSolutionActionType.journal) ...[
                      TextField(
                        controller: controller,
                        minLines: 4,
                        maxLines: 7,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText:
                              'Write whatever is taking up space in your head...',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.04),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ] else ...[
                      Center(
                        child: Text(
                          '${secondsLeft ~/ 60}:${(secondsLeft % 60).toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          _timerInstruction(action),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: startTimer,
                          icon: Icon(
                            running
                                ? Icons.timelapse_rounded
                                : Icons.play_arrow_rounded,
                          ),
                          label: Text(running ? 'In progress' : 'Start timer'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _primary,
                            minimumSize: const Size.fromHeight(52),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          timer?.cancel();
                          Navigator.of(sheetContext).pop(controller.text.trim());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _teal,
                          minimumSize: const Size.fromHeight(52),
                        ),
                        child: const Text(
                          'Done — Recheck my urge',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    timer?.cancel();
    controller.dispose();
    return notes;
  }

  Future<void> _finishWithRecheck(
    UrgeSolutionAction action, {
    String? additionalNotes,
  }) async {
    final before = (_session.urgeBefore ?? 5).clamp(1, 10).toInt();
    int score = before;

    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: _surface,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  20 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recheck the urge',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'How strong is the urge right now?',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        '$score / 10',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Slider(
                      value: score.toDouble(),
                      min: 0,
                      max: 10,
                      divisions: 10,
                      activeColor: _primary,
                      onChanged: (value) {
                        setSheetState(() => score = value.round());
                      },
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(score),
                        style: FilledButton.styleFrom(
                          backgroundColor: _teal,
                          minimumSize: const Size.fromHeight(52),
                        ),
                        child: const Text('Save check-in'),
                      ),
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

    final after = result.clamp(0, 10).toInt();
    final outcome = UrgeSessionModel.outcomeFromScores(before, after);
    final mergedNotes = additionalNotes == null || additionalNotes.trim().isEmpty
        ? _session.notes
        : '${_session.notes}\n${action.title}: ${additionalNotes.trim()}'.trim();

    final completed = _session.copyWith(
      selectedNeed: _plan.need,
      notes: mergedNotes,
      clearInterventionId: action.interventionId == null,
      interventionId: action.interventionId,
      interventionTitle: action.title,
      urgeAfter: after,
      outcome: outcome,
      status: UrgeSessionStatus.completed,
      interventionCompleted: true,
      interventionCompletedAt: DateTime.now(),
      recheckedAt: DateTime.now(),
      completedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setState(() => _session = completed);

    try {
      await _sessionService.saveSession(completed);
    } catch (e) {
      debugPrint('Quick urge solution save warning: $e');
    }

    try {
      await _feedbackService.record(
        session: completed,
        action: action,
        urgeAfter: after,
      );
    } catch (e) {
      debugPrint('Urge solution feedback warning: $e');
    }

    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => UrgeResultScreen(session: completed),
      ),
    );
  }

  String _timerInstruction(UrgeSolutionAction action) {
    switch (action.type) {
      case UrgeSolutionActionType.music:
        return 'Play one calming or uplifting track. Stay with it instead of checking the trigger.';
      case UrgeSolutionActionType.meditation:
        return 'Sit comfortably. Slow your breathing and notice five slow breaths.';
      case UrgeSolutionActionType.environmentReset:
        return 'Stand up and move to another room, outside, or another safe location.';
      case UrgeSolutionActionType.movement:
        return 'Walk, stretch, or move gently. The goal is a state change, not a workout.';
      default:
        return 'Stay with the action until the timer finishes.';
    }
  }

  void _showUnavailableConnection() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Chat support is planned for the Connect phase. Truth & Dare is available now.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                const Expanded(
                  child: Text(
                    'Urge Rescue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Here is the best next step for you.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ReWireX is using the urge, emotion, intensity, trigger, and context you just entered. You do not need to choose the rescue path yourself.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.58),
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            _buildSituationCard(),
            const SizedBox(height: 18),
            _buildPrimaryCard(_plan.primary),
            if (_plan.alternatives.isNotEmpty) ...[
              const SizedBox(height: 22),
              Text(
                'OTHER GOOD OPTIONS',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 10),
              ..._plan.alternatives.map(_buildAlternativeCard),
            ],
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _teal.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _teal.withValues(alpha: 0.16)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('↘️', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'After the action, ReWireX will ask you to rate the urge again. That result becomes feedback for future personalization.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.62),
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSituationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: _teal, size: 20),
              const SizedBox(width: 10),
              const Text(
                'What ReWireX noticed',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${_session.urgeBefore ?? 5}/10',
                  style: const TextStyle(
                    color: Color(0xFF9A92FF),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _infoLine('Emotion', _session.emotion),
          _infoLine('Trigger', _session.trigger),
          _infoLine('Context', _session.context),
          _infoLine('Likely need', _needTitle(_plan.need)),
          const SizedBox(height: 12),
          Text(
            _plan.reason,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.52),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoLine(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 74,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryCard(UrgeSolutionAction action) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            _primary.withValues(alpha: 0.2),
            _teal.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: _primary.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BEST NEXT STEP',
            style: TextStyle(
              color: _teal,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(action.emoji, style: const TextStyle(fontSize: 34)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  action.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            action.subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busy ? null : () => _run(action),
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward_rounded),
              label: Text('Start ${action.title}'),
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                minimumSize: const Size.fromHeight(54),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativeCard(UrgeSolutionAction action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: _busy ? null : () => _run(action),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Text(action.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        action.subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.48),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white38),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _needTitle(NeedType need) {
    switch (need) {
      case NeedType.connection:
        return 'Connection';
      case NeedType.validation:
        return 'Validation';
      case NeedType.reassurance:
        return 'Reassurance';
      case NeedType.relief:
        return 'Relief';
      case NeedType.clarity:
        return 'Clarity';
      case NeedType.stimulation:
        return 'Stimulation';
      case NeedType.escape:
        return 'A break from the pressure';
      case NeedType.space:
        return 'Space';
      case NeedType.control:
        return 'Control';
      case NeedType.release:
        return 'Release';
      case NeedType.structure:
        return 'Structure';
      case NeedType.selfCompassion:
        return 'Self-compassion';
      case NeedType.unknown:
        return 'Relief';
    }
  }
}
