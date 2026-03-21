// lib/features/intervention/screens/coping_tools_screen.dart
//
// 🛡️ Coping Tools Screen
//
// This screen opens when the user taps "Open Coping Tools" from the
// Pre-Relapse Warning card. It is NOT the generic Emergency Reset —
// it is a rich, personalised, science-backed toolkit that responds
// directly to the user's current warning severity, dominant emotion,
// and active risk signals.
//
// SECTIONS:
//   1. Situation header  — severity, risk score, personalised message
//   2. Breathing timer   — interactive 4-7-8 exercise with animation
//   3. Grounding tools   — cards specific to the user's emotion
//   4. Urge surfing      — guided wave visualisation
//   5. Quick wins        — immediate small actions
//   6. Log urge CTA      — routes to UrgeLogScreen

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rewirex/features/ai/models/pre_relapse_warning_model.dart';
import 'package:rewirex/features/urge/screens/urge_log_screen.dart';

class CopingToolsScreen extends StatefulWidget {
  final PreRelapseWarningModel warning;

  const CopingToolsScreen({super.key, required this.warning});

  @override
  State<CopingToolsScreen> createState() => _CopingToolsScreenState();
}

class _CopingToolsScreenState extends State<CopingToolsScreen>
    with TickerProviderStateMixin {

  // ── Animations ─────────────────────────────────────────────────
  late AnimationController _fadeController;
  late Animation<double>   _fadeAnim;

  // Breathing exercise
  late AnimationController _breathController;
  late Animation<double>   _breathAnim;
  bool   _breathingActive  = false;
  int    _breathPhase      = 0; // 0=inhale 1=hold 2=exhale
  int    _breathCycle      = 0;
  int    _breathSeconds    = 0;
  Timer? _breathTimer;

  // Urge wave
  late AnimationController _waveController;
  late Animation<double>   _waveAnim;

  // Selected tool tab
  int _selectedTool = 0;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _fadeAnim = CurvedAnimation(
        parent: _fadeController, curve: Curves.easeOut);

    _breathController = AnimationController(
        vsync: this, duration: const Duration(seconds: 4));
    _breathAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _breathController, curve: Curves.easeInOut));

    _waveController = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _waveAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _waveController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _breathController.dispose();
    _waveController.dispose();
    _breathTimer?.cancel();
    super.dispose();
  }

  // ── Severity colour ────────────────────────────────────────────
  Color get _severityColor {
    switch (widget.warning.severity) {
      case 'Critical': return const Color(0xFFEF5350);
      case 'High':     return Colors.orange;
      default:         return Colors.amber;
    }
  }

  IconData get _severityIcon {
    switch (widget.warning.severity) {
      case 'Critical': return Icons.crisis_alert_rounded;
      case 'High':     return Icons.warning_amber_rounded;
      default:         return Icons.radar_rounded;
    }
  }

  // ── Breathing exercise logic ───────────────────────────────────
  void _startBreathing() {
    setState(() {
      _breathingActive = true;
      _breathPhase     = 0;
      _breathCycle     = 0;
      _breathSeconds   = 4;
    });
    _breathController.forward(from: 0);
    _breathTimer = Timer.periodic(const Duration(seconds: 1), _breathTick);
    HapticFeedback.mediumImpact();
  }

  void _stopBreathing() {
    _breathTimer?.cancel();
    _breathController.stop();
    setState(() => _breathingActive = false);
  }

  void _breathTick(Timer t) {
    if (!mounted) { t.cancel(); return; }
    setState(() => _breathSeconds--);

    if (_breathSeconds <= 0) {
      _breathPhase = (_breathPhase + 1) % 3;
      switch (_breathPhase) {
        case 0: // inhale 4s
          _breathSeconds = 4;
          _breathController.forward(from: 0);
          break;
        case 1: // hold 7s
          _breathSeconds = 7;
          _breathController.stop();
          break;
        case 2: // exhale 8s
          _breathSeconds = 8;
          _breathController.reverse(from: 1);
          break;
      }
      if (_breathPhase == 0) {
        _breathCycle++;
        HapticFeedback.lightImpact();
        if (_breathCycle >= 3) {
          _stopBreathing();
          _showBreathingComplete();
        }
      }
    }
  }

  void _showBreathingComplete() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF161625),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: const Color(0xFF00C4A0).withOpacity(0.3), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('✅', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              const Text('3 Cycles Complete',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Text(
                'Your nervous system has been activated. '
                'The urge intensity should feel 20–40% lower now.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                    height: 1.5),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C4A0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('I Feel Better',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSituationCard(),
                      const SizedBox(height: 20),
                      _buildToolTabs(),
                      const SizedBox(height: 16),
                      _buildSelectedTool(),
                      const SizedBox(height: 20),
                      _buildInterventionSteps(),
                      const SizedBox(height: 20),
                      _buildQuickWins(),
                      const SizedBox(height: 20),
                      _buildLogUrgeButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: Colors.white.withOpacity(0.7)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Coping Tools',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                Text('Personalised for right now',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _severityColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _severityColor.withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_severityIcon, color: _severityColor, size: 13),
                const SizedBox(width: 4),
                Text(widget.warning.severity,
                    style: TextStyle(
                        color: _severityColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Situation card ─────────────────────────────────────────────
  Widget _buildSituationCard() {
    final w = widget.warning;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _severityColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: _severityColor.withOpacity(0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Risk score bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Current Risk Score',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13)),
              Text('${w.riskScore.toStringAsFixed(0)}/100',
                  style: TextStyle(
                      color: _severityColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: w.riskScore / 100),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (_, val, __) => LinearProgressIndicator(
                value: val,
                minHeight: 7,
                backgroundColor: Colors.white.withOpacity(0.07),
                valueColor:
                    AlwaysStoppedAnimation<Color>(_severityColor),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Emotion + trigger context
          if (w.dominantEmotion.isNotEmpty || w.primaryTrigger.isNotEmpty)
            Row(
              children: [
                if (w.dominantEmotion.isNotEmpty)
                  _ContextChip(
                      label: '😔 ${w.dominantEmotion}',
                      color: Colors.purple),
                if (w.dominantEmotion.isNotEmpty &&
                    w.primaryTrigger.isNotEmpty)
                  const SizedBox(width: 8),
                if (w.primaryTrigger.isNotEmpty)
                  _ContextChip(
                      label: '⚡ ${w.primaryTrigger}',
                      color: Colors.orange),
              ],
            ),
          if (w.dominantEmotion.isNotEmpty || w.primaryTrigger.isNotEmpty)
            const SizedBox(height: 12),
          Text(
            w.message,
            style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── Tool tabs ──────────────────────────────────────────────────
  Widget _buildToolTabs() {
    final tabs = ['🌬️ Breathe', '🌊 Surf', '⚡ Ground'];
    return Row(
      children: tabs.asMap().entries.map((e) {
        final isSelected = _selectedTool == e.key;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedTool = e.key);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: e.key < 2 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF6C63FF).withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF6C63FF).withOpacity(0.5)
                      : Colors.white.withOpacity(0.08),
                  width: 1.3,
                ),
              ),
              child: Text(e.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF6C63FF)
                          : Colors.white.withOpacity(0.5),
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500)),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Selected tool panel ────────────────────────────────────────
  Widget _buildSelectedTool() {
    switch (_selectedTool) {
      case 0:
        return _buildBreathingTool();
      case 1:
        return _buildUrgeSurfingTool();
      default:
        return _buildGroundingTool();
    }
  }

  // ── 4-7-8 Breathing tool ───────────────────────────────────────
  Widget _buildBreathingTool() {
    final phaseLabels  = ['Inhale', 'Hold', 'Exhale'];
    final phaseColors  = [
      const Color(0xFF6C63FF),
      const Color(0xFF00C4A0),
      Colors.blue,
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF141428),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: const Color(0xFF6C63FF).withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          const Text('4 · 7 · 8 Breathing',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            'Activates parasympathetic nervous system.\nReduces craving intensity in 90 seconds.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 13,
                height: 1.5),
          ),
          const SizedBox(height: 28),

          // Animated circle
          GestureDetector(
            onTap: _breathingActive ? _stopBreathing : _startBreathing,
            child: AnimatedBuilder(
              animation: _breathAnim,
              builder: (_, __) {
                final scale    = _breathingActive ? _breathAnim.value : 0.75;
                final color    = _breathingActive
                    ? phaseColors[_breathPhase]
                    : const Color(0xFF6C63FF);
                final label    = _breathingActive
                    ? phaseLabels[_breathPhase]
                    : 'TAP\nTO START';
                final seconds  = _breathingActive
                    ? _breathSeconds.toString()
                    : '';

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow ring
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width:  160 * scale + 20,
                      height: 160 * scale + 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withOpacity(0.08),
                      ),
                    ),
                    // Main circle
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width:  160 * scale,
                      height: 160 * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withOpacity(0.12),
                        border: Border.all(
                            color: color.withOpacity(0.5),
                            width: 2.5),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: color,
                                  fontSize: _breathingActive ? 18 : 15,
                                  fontWeight: FontWeight.w800,
                                  height: 1.3)),
                          if (seconds.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(seconds,
                                style: TextStyle(
                                    color: color.withOpacity(0.7),
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900)),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Cycle counter
          if (_breathingActive) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => Container(
                width: 10, height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _breathCycle
                      ? const Color(0xFF00C4A0)
                      : Colors.white.withOpacity(0.15),
                ),
              )),
            ),
            const SizedBox(height: 12),
            Text('Cycle ${_breathCycle + 1} of 3',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 13)),
          ] else ...[
            // Phase guide
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _PhaseChip(label: 'Inhale', seconds: 4, color: phaseColors[0]),
                _PhaseChip(label: 'Hold',   seconds: 7, color: phaseColors[1]),
                _PhaseChip(label: 'Exhale', seconds: 8, color: phaseColors[2]),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Urge surfing tool ──────────────────────────────────────────
  Widget _buildUrgeSurfingTool() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF141428),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: Colors.blue.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Urge Surfing',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            'Urges are waves — they rise, peak, and fall in 15–20 minutes. '
            'You don\'t fight the wave. You ride it.',
            style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 13,
                height: 1.5),
          ),
          const SizedBox(height: 24),

          // Wave animation
          AnimatedBuilder(
            animation: _waveAnim,
            builder: (_, __) {
              return SizedBox(
                height: 100,
                child: CustomPaint(
                  painter: _WavePainter(
                    progress: _waveAnim.value,
                    color: Colors.blue,
                  ),
                  size: const Size(double.infinity, 100),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // 4-step guide
          ..._urgeSurfingSteps.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.blue.withOpacity(0.3), width: 1),
                  ),
                  child: Center(
                    child: Text('${e.key + 1}',
                        style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.value['title']!,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(e.value['body']!,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                              height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  static const _urgeSurfingSteps = [
    {
      'title': 'Notice the urge',
      'body':  'Acknowledge it without judgement. "I notice I am having an urge." Name it.',
    },
    {
      'title': 'Observe where you feel it',
      'body':  'Where is it in your body? Chest? Throat? Stomach? Just observe — don\'t react.',
    },
    {
      'title': 'Watch it rise',
      'body':  'Like a wave, it will intensify for a few minutes. Stay with it. Don\'t run.',
    },
    {
      'title': 'Watch it pass',
      'body':  'Every urge peaks and falls within 15–20 min. You have outlasted every one so far.',
    },
  ];

  // ── Grounding tool ─────────────────────────────────────────────
  Widget _buildGroundingTool() {
    final emotion = widget.warning.dominantEmotion;

    final tool = _groundingForEmotion(emotion);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF141428),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: const Color(0xFF00C4A0).withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(tool['emoji']!,
                  style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tool['title']!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  Text('For ${emotion.isNotEmpty ? emotion.toLowerCase() : "right now"}',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(tool['science']!,
              style: TextStyle(
                  color: const Color(0xFF00C4A0).withOpacity(0.8),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  height: 1.4)),
          const SizedBox(height: 16),
          ...( tool['steps'] as List<String>).asMap().entries.map((e) =>
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C4A0).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('${e.key + 1}',
                          style: const TextStyle(
                              color: Color(0xFF00C4A0),
                              fontSize: 11,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(e.value,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            height: 1.5)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _groundingForEmotion(String emotion) {
    if (emotion == 'Anxious' || emotion == 'Stressed') {
      return {
        'emoji': '🧊',
        'title': 'Cold Grounding',
        'science': 'Cold stimulation activates the dive reflex — heart rate drops '
            'within seconds, directly countering the anxiety response.',
        'steps': [
          'Fill a bowl with cold water or grab ice cubes.',
          'Submerge your hands or splash cold water on your face for 15 seconds.',
          'Focus entirely on the physical sensation — temperature, pressure, texture.',
          'Notice your heart rate slowing. Your nervous system is resetting.',
          'Repeat once more if needed.',
        ],
      };
    }
    if (emotion == 'Lonely') {
      return {
        'emoji': '📲',
        'title': '2-Minute Connection',
        'science': 'Social connection activates oxytocin release which directly '
            'counteracts the loneliness signal that triggers urges.',
        'steps': [
          'Open your contacts right now.',
          'Text or call one person — a friend, family member, or anyone safe.',
          'You don\'t need to explain your situation. Just connect.',
          'Even a 2-minute conversation is enough to shift your neurochemistry.',
          'After the call, notice how the urge has changed.',
        ],
      };
    }
    if (emotion == 'Bored') {
      return {
        'emoji': '🚶',
        'title': 'Environment Change',
        'science': 'Boredom urges are environment-specific. Breaking your physical '
            'context interrupts the cue-routine neural pathway immediately.',
        'steps': [
          'Stand up right now — don\'t think about it, just do it.',
          'Leave the room you are in.',
          'Go outside if possible, even for 5 minutes.',
          'If outside isn\'t possible, move to a different room entirely.',
          'Do one physical movement — 10 jumping jacks, a short walk, anything.',
        ],
      };
    }
    if (emotion == 'Angry' || emotion == 'Frustrated') {
      return {
        'emoji': '💪',
        'title': 'Physical Release',
        'science': 'Anger generates cortisol. Physical exertion metabolises it and '
            'produces endorphins that counteract the urge signal.',
        'steps': [
          'Do 20 push-ups or 20 jump squats right now.',
          'If that\'s too much, do 30 seconds of intense movement — anything.',
          'Breathe hard. Let your body burn the cortisol.',
          'After movement, take 3 slow deep breaths.',
          'Notice the anger has shifted. Physical action is faster than thinking.',
        ],
      };
    }
    if (emotion == 'Sad' || emotion == 'Depressed') {
      return {
        'emoji': '✍️',
        'title': 'Gratitude Activation',
        'science': 'Writing activates the prefrontal cortex, creating neural '
            'activity that competes directly with the craving response.',
        'steps': [
          'Get something to write on — phone notes is fine.',
          'Write 3 specific things you are grateful for right now.',
          'They can be tiny. "The sun came out today." That counts.',
          'For each one, write one sentence about WHY you are grateful for it.',
          'Read what you wrote aloud. This reinforces the neural shift.',
        ],
      };
    }
    // Default
    return {
      'emoji': '🎯',
      'title': '5-4-3-2-1 Grounding',
      'science': 'Sensory grounding redirects attention from internal cravings '
          'to external reality, reducing urge intensity by up to 30%.',
      'steps': [
        'Name 5 things you can SEE right now.',
        'Name 4 things you can physically TOUCH.',
        'Name 3 things you can HEAR right now.',
        'Name 2 things you can SMELL.',
        'Name 1 thing you can TASTE. Take a slow breath. You are here.',
      ],
    };
  }

  // ── Personalised intervention steps ───────────────────────────
  Widget _buildInterventionSteps() {
    if (widget.warning.interventionSteps.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('YOUR PERSONALISED PLAN',
            style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.5)),
        const SizedBox(height: 12),
        ...widget.warning.interventionSteps.asMap().entries.map((entry) {
          final step = entry.value;
          final idx  = entry.key + 1;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF141428),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.white.withOpacity(0.07), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(children: [
                  Text(step.emoji,
                      style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 2),
                  Text('$idx',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.25),
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(step.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 5),
                      Text(step.description,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.55),
                              fontSize: 13,
                              height: 1.5)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Quick wins ─────────────────────────────────────────────────
  Widget _buildQuickWins() {
    final wins = [
      {'emoji': '💧', 'text': 'Drink a full glass of water right now'},
      {'emoji': '📱', 'text': 'Put your phone face-down for 5 minutes'},
      {'emoji': '🚪', 'text': 'Open a window or step outside'},
      {'emoji': '🎵', 'text': 'Play your strongest song at full volume'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('INSTANT WINS',
            style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.5)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.4,
          children: wins.map((w) => Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF141428),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Colors.white.withOpacity(0.08), width: 1),
            ),
            child: Row(
              children: [
                Text(w['emoji']!,
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(w['text']!,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 11,
                          height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          )).toList(),
        ),
      ],
    );
  }

  // ── Log urge CTA ───────────────────────────────────────────────
  Widget _buildLogUrgeButton() {
    return Column(
      children: [
        SizedBox(
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
                  color: const Color(0xFF6C63FF).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => const UrgeLogScreen()),
              ),
              icon: const Icon(Icons.flash_on_rounded,
                  color: Colors.white, size: 22),
              label: const Text('Log This Urge',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'I\'m feeling better, go back',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  WAVE PAINTER
// ─────────────────────────────────────────────────────────────
class _WavePainter extends CustomPainter {
  final double progress;
  final Color  color;
  _WavePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = color.withOpacity(0.25)
      ..style = PaintingStyle.fill;

    _drawWave(canvas, size, paint,  progress,       0.6);
    _drawWave(canvas, size, paint2, progress + 0.3, 0.4);
  }

  void _drawWave(Canvas canvas, Size size, Paint paint,
      double offset, double heightRatio) {
    final path = Path();
    final h    = size.height * heightRatio;
    final baseY= size.height * (1 - heightRatio * 0.5);

    path.moveTo(0, baseY);
    for (double x = 0; x <= size.width; x++) {
      final y = baseY +
          math.sin((x / size.width * 2 * math.pi) +
                  (offset * 2 * math.pi)) *
              h *
              0.5;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────
//  HELPER WIDGETS
// ─────────────────────────────────────────────────────────────

class _ContextChip extends StatelessWidget {
  final String label;
  final Color  color;
  const _ContextChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _PhaseChip extends StatelessWidget {
  final String label;
  final int    seconds;
  final Color  color;
  const _PhaseChip(
      {required this.label,
      required this.seconds,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.12),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Center(
            child: Text('${seconds}s',
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 5),
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 11)),
      ],
    );
  }
}