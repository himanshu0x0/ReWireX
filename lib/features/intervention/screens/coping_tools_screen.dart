// ============================================================
// PATH: lib/features/intervention/screens/coping_tools_screen.dart
// ============================================================

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rewirex/features/ai/models/pre_relapse_warning_model.dart';
import 'package:rewirex/features/connect/connect_screen.dart';
import 'package:rewirex/features/connect/games/screens/games_hub_screen.dart';
import 'package:rewirex/features/connect/wellness/screens/wellness_hub_screen.dart';

class CopingToolsScreen extends StatefulWidget {
  final PreRelapseWarningModel warning;
  const CopingToolsScreen({super.key, required this.warning});
  @override
  State<CopingToolsScreen> createState() => _State();
}

class _State extends State<CopingToolsScreen> with TickerProviderStateMixin {
  late TabController _tab;

  // Breathing state
  int _breathPhase = 0;
  int _breathSecs = 4;
  int _breathCycles = 0;
  bool _breathActive = false;
  Timer? _breathTimer;
  late AnimationController _breathCtrl;
  late Animation<double> _breathAnim;

  // Surf state
  int _surfStep = 0;

  // Steps panel
  bool _stepsExpanded = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _breathCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4));
    _breathAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _tab.dispose();
    _breathTimer?.cancel();
    _breathCtrl.dispose();
    super.dispose();
  }

  // ── Breathing helpers ──────────────────────────────────────────
  static const _bLabels = ['Inhale', 'Hold', 'Exhale'];
  static const _bDurations = [4, 7, 8];
  static const _bColors = [
    Color(0xFF6C63FF),
    Color(0xFF00C4A0),
    Color(0xFF4FC3F7),
  ];

  void _startBreathing() {
    setState(() {
      _breathActive = true;
      _breathPhase = 0;
      _breathSecs = 4;
      _breathCycles = 0;
    });
    _breathCtrl.forward(from: 0);
    _breathTimer?.cancel();
    _breathTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _breathSecs--);
      if (_breathSecs <= 0) {
        _breathPhase = (_breathPhase + 1) % 3;
        _breathSecs = _bDurations[_breathPhase];
        if (_breathPhase == 0) {
          _breathCycles++;
          if (_breathCycles >= 3) {
            _breathTimer?.cancel();
            setState(() => _breathActive = false);
            _showCompletion();
            return;
          }
          _breathCtrl.forward(from: 0);
        } else if (_breathPhase == 2) {
          _breathCtrl.reverse(from: 1);
        } else {
          _breathCtrl.stop();
        }
      }
    });
  }

  void _stopBreathing() {
    _breathTimer?.cancel();
    setState(() => _breathActive = false);
  }

  // ── Session-complete dialog ────────────────────────────────────
  // For Lonely / Sad / Depressed users, surfaces Truth & Dare and
  // Connect Hub so they are never left alone after the exercise.
  void _showCompletion() {
    final emotion = widget.warning.dominantEmotion;
    final needsConnection =
        emotion == 'Lonely' || emotion == 'Sad' || emotion == 'Depressed';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: const Color(0xFF141428),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: const Color(0xFF00C4A0).withOpacity(0.3))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // ── Trophy ────────────────────────────────────────
            const Text('🎉', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 12),
            const Text('3 Cycles Complete!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
                'Your nervous system is calmer.\nCraving intensity has reduced.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 14,
                    height: 1.5)),

            const SizedBox(height: 20),

            // ── Connection banner (lonely / sad / depressed) ──
            if (needsConnection) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFF6C63FF).withOpacity(0.25))),
                child: Row(children: [
                  const Text('💬', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Breathing helps — but connection heals. '
                      'Talk to real warriors right now.',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          height: 1.5),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 12),

              // Truth & Dare
              SizedBox(
                width: double.infinity,
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)]),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFFFF6B6B).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // close dialog
                      Navigator.pop(context); // close coping screen
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const GamesHubScreen()));
                    },
                    icon: const Text('🎮', style: TextStyle(fontSize: 18)),
                    label: const Text('Play Truth & Dare',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Connect Hub
              SizedBox(
                width: double.infinity,
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)]),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF6C63FF).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ConnectScreen()));
                    },
                    icon: const Text('👥', style: TextStyle(fontSize: 18)),
                    label: const Text('Connect with Warriors',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // ── Wellness shortcut (always shown) ──────────────
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const WellnessHubScreen()));
                },
                icon: const Text('🧘', style: TextStyle(fontSize: 16)),
                label: Text('More Wellness Tools',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: Colors.white.withOpacity(0.15)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
              ),
            ),
            const SizedBox(height: 8),

            // ── I feel better ─────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C4A0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                child: const Text('I feel better ✓',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Severity color ─────────────────────────────────────────────
  Color get _sevColor {
    switch (widget.warning.severity) {
      case 'Critical':
        return Colors.red;
      case 'High':
        return Colors.orange;
      default:
        return Colors.amber;
    }
  }

  // ── Emotion-personalised grounding ────────────────────────────
  Map<String, dynamic> get _groundData {
    final e = widget.warning.dominantEmotion;
    if (e == 'Anxious' || e == 'Stressed')
      return {
        'icon': '🧊',
        'title': 'Cold Grounding',
        'steps': [
          'Hold an ice cube or cold object in your hand.',
          'Focus entirely on the sensation for 30 seconds.',
          'Notice how the sensation overrides the craving signal.',
          'Repeat until the urge wave passes.',
        ]
      };
    if (e == 'Lonely')
      return {
        'icon': '📲',
        'title': '2-Min Connection',
        'steps': [
          'Open your messages right now.',
          'Send a "thinking of you" text to one person.',
          'You don\'t need to explain yourself.',
          'Connection is the opposite of craving.',
        ]
      };
    if (e == 'Bored')
      return {
        'icon': '🚶',
        'title': 'Environment Change',
        'steps': [
          'Stand up from wherever you are right now.',
          'Walk to a different room or go outside.',
          'Boredom urges are location-specific.',
          'Breaking the context breaks the pattern.',
        ]
      };
    if (e == 'Angry' || e == 'Frustrated')
      return {
        'icon': '💪',
        'title': 'Physical Release',
        'steps': [
          'Do 20 push-ups or jumping jacks right now.',
          'Anger creates cortisol — movement burns it.',
          'Sprint for 30 seconds if you can.',
          'Endorphins will counteract the urge signal.',
        ]
      };
    if (e == 'Sad' || e == 'Depressed')
      return {
        'icon': '🙏',
        'title': 'Gratitude Activation',
        'steps': [
          'Write down 3 things you are grateful for.',
          'They can be as small as "I woke up today".',
          'This activates the prefrontal cortex.',
          'Competing neural activity reduces the craving pull.',
        ]
      };
    return {
      'icon': '🎯',
      'title': '5-4-3-2-1 Grounding',
      'steps': [
        'Name 5 things you can see right now.',
        'Name 4 things you can touch — touch them.',
        'Name 3 things you can hear in this moment.',
        'Name 2 things you can smell. Take 1 deep breath.',
      ]
    };
  }

  // ── Surf steps ─────────────────────────────────────────────────
  static const _surfSteps = [
    {
      'icon': '🌊',
      'title': 'Notice the Wave',
      'desc': 'The urge is a wave — it will peak and fall. '
          'You don\'t have to fight it. Just notice it.',
    },
    {
      'icon': '🏄',
      'title': 'Ride, Don\'t Resist',
      'desc': 'Resistance amplifies the craving. '
          'Instead, observe it with curiosity: "Where do I feel this in my body?"',
    },
    {
      'icon': '⏱',
      'title': 'Wait 20 Minutes',
      'desc': 'Peak urge intensity lasts 15–20 minutes max. '
          'After that, neurological pressure drops significantly.',
    },
    {
      'icon': '✅',
      'title': 'Celebrate the Resist',
      'desc': 'Every time you surf a wave without acting, '
          'the neural pathway for the habit weakens. '
          'This is literally rewiring your brain.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final w = widget.warning;
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
          backgroundColor: const Color(0xFF0D0D1A),
          elevation: 0,
          leading: IconButton(
              icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 15, color: Colors.white.withOpacity(0.7))),
              onPressed: () => Navigator.pop(context)),
          title: ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)])
                  .createShader(b),
              child: const Text('Coping Tools',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)))),
      body: Column(children: [
        _situationHeader(w),
        Container(
            color: const Color(0xFF0D0D1A),
            child: TabBar(
                controller: _tab,
                indicatorColor: const Color(0xFF6C63FF),
                indicatorWeight: 2.5,
                labelColor: const Color(0xFF6C63FF),
                unselectedLabelColor: Colors.white.withOpacity(0.35),
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13),
                tabs: const [
                  Tab(
                      icon: Icon(Icons.air_rounded, size: 18),
                      text: 'Breathe'),
                  Tab(
                      icon: Icon(Icons.waves_rounded, size: 18),
                      text: 'Surf'),
                  Tab(
                      icon: Icon(Icons.bolt_rounded, size: 18),
                      text: 'Ground'),
                ])),
        Expanded(
            child: TabBarView(controller: _tab, children: [
          _buildBreathe(),
          _buildSurf(),
          _buildGround(),
        ])),
        if (w.interventionSteps.isNotEmpty) _stepsPanel(w),
        _logUrgeBtn(),
      ]),
    );
  }

  // ── Situation header ───────────────────────────────────────────
  Widget _situationHeader(PreRelapseWarningModel w) => Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: _sevColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _sevColor.withOpacity(0.2))),
        child: Row(children: [
          Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color: _sevColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9)),
              child: Icon(
                  w.severity == 'Critical'
                      ? Icons.crisis_alert_rounded
                      : Icons.warning_amber_rounded,
                  color: _sevColor,
                  size: 16)),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                    '${w.severity} Risk · ${w.dominantEmotion.isNotEmpty ? w.dominantEmotion : "Act Now"}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                        value: (w.riskScore / 100).clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: Colors.white.withOpacity(0.07),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(_sevColor))),
              ])),
          const SizedBox(width: 8),
          Text('${w.riskScore.toStringAsFixed(0)}',
              style: TextStyle(
                  color: _sevColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w800)),
        ]),
      );

  // ── Breathe Tab ────────────────────────────────────────────────
  Widget _buildBreathe() => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const Text('4 – 7 – 8 Breathing',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
              'Activates your parasympathetic nervous system in 90 seconds.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.45), fontSize: 13)),
          const SizedBox(height: 24),
          AnimatedBuilder(
              animation: _breathAnim,
              builder: (_, __) {
                final color = _breathActive
                    ? _bColors[_breathPhase]
                    : const Color(0xFF6C63FF);
                final scale = _breathActive ? _breathAnim.value : 0.75;
                return GestureDetector(
                  onTap: _breathActive ? null : _startBreathing,
                  child: Stack(alignment: Alignment.center, children: [
                    AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 170 * scale + 20,
                        height: 170 * scale + 20,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withOpacity(0.07))),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 150 * scale,
                      height: 150 * scale,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withOpacity(0.12),
                          border: Border.all(
                              color: color.withOpacity(0.5), width: 2.5)),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                                _breathActive
                                    ? _bLabels[_breathPhase]
                                    : 'TAP\nTO START',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: color,
                                    fontSize: _breathActive ? 16 : 13,
                                    fontWeight: FontWeight.w800)),
                            if (_breathActive) ...[
                              const SizedBox(height: 4),
                              Text('$_breathSecs',
                                  style: TextStyle(
                                      color: color.withOpacity(0.7),
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900)),
                            ],
                          ]),
                    ),
                  ]),
                );
              }),
          const SizedBox(height: 20),
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                  3,
                  (i) => Container(
                        width: 12,
                        height: 12,
                        margin:
                            const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < _breathCycles
                                ? const Color(0xFF00C4A0)
                                : Colors.white.withOpacity(0.15)),
                      ))),
          const SizedBox(height: 8),
          Text(
              '${3 - _breathCycles} cycle${3 - _breathCycles == 1 ? '' : 's'} remaining',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.35), fontSize: 12)),
          if (_breathActive) ...[
            const SizedBox(height: 16),
            TextButton(
                onPressed: _stopBreathing,
                child: Text('Stop',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 13))),
          ],
        ]),
      );

  // ── Surf Tab ───────────────────────────────────────────────────
  Widget _buildSurf() => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const Text('Urge Surfing',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Ride the wave without fighting. It will pass.',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.45), fontSize: 13)),
          const SizedBox(height: 20),
          _WaveWidget(color: const Color(0xFF6C63FF)),
          const SizedBox(height: 20),
          ...List.generate(_surfSteps.length, (i) {
            final s = _surfSteps[i];
            final done = i < _surfStep;
            return GestureDetector(
              onTap: () => setState(() => _surfStep = i + 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: done
                        ? const Color(0xFF00C4A0).withOpacity(0.07)
                        : _surfStep == i
                            ? const Color(0xFF6C63FF).withOpacity(0.08)
                            : Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: done
                            ? const Color(0xFF00C4A0).withOpacity(0.25)
                            : _surfStep == i
                                ? const Color(0xFF6C63FF)
                                    .withOpacity(0.25)
                                : Colors.white.withOpacity(0.06))),
                child: Row(children: [
                  Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done
                              ? const Color(0xFF00C4A0).withOpacity(0.15)
                              : Colors.white.withOpacity(0.05)),
                      child: Center(
                          child: Text(
                              done ? '✅' : s['icon'] as String,
                              style: const TextStyle(fontSize: 18)))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(s['title'] as String,
                            style: TextStyle(
                                color: done
                                    ? const Color(0xFF00C4A0)
                                    : Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(s['desc'] as String,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                                height: 1.4)),
                      ])),
                ]),
              ),
            );
          }),
          if (_surfStep >= _surfSteps.length) ...[
            const SizedBox(height: 16),
            Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFF00C4A0).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color:
                            const Color(0xFF00C4A0).withOpacity(0.25))),
                child: const Row(children: [
                  Text('🏆', style: TextStyle(fontSize: 28)),
                  SizedBox(width: 12),
                  Expanded(
                      child: Text(
                          'You surfed the urge! Your brain just got stronger.',
                          style: TextStyle(
                              color: Color(0xFF00C4A0),
                              fontSize: 14,
                              fontWeight: FontWeight.w600))),
                ])),
          ],
        ]),
      );

  // ── Ground Tab ─────────────────────────────────────────────────
  Widget _buildGround() {
    final gd = _groundData;
    final steps = gd['steps'] as List<String>;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(gd['icon'] as String,
              style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(gd['title'] as String,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
            Text(
                'Personalised for ${widget.warning.dominantEmotion.isNotEmpty ? widget.warning.dominantEmotion : "you"}',
                style: TextStyle(
                    color: const Color(0xFF6C63FF).withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ]),
        ]),
        const SizedBox(height: 20),
        ...steps.asMap().entries.map((e) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: const Color(0xFF141428),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.07))),
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF6C63FF)
                                .withOpacity(0.15),
                            border: Border.all(
                                color: const Color(0xFF6C63FF)
                                    .withOpacity(0.3))),
                        child: Center(
                            child: Text('${e.key + 1}',
                                style: const TextStyle(
                                    color: Color(0xFF6C63FF),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800)))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(e.value,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 14,
                                height: 1.5))),
                  ]),
            )),
        const SizedBox(height: 8),
        Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFF6C63FF).withOpacity(0.15))),
            child: Text('Science: $_groundNote',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    height: 1.5))),
      ]),
    );
  }

  String get _groundNote {
    final e = widget.warning.dominantEmotion;
    if (e == 'Anxious' || e == 'Stressed')
      return 'Cold stimulation activates the dive reflex, '
          'immediately lowering heart rate (clinically validated).';
    if (e == 'Lonely')
      return 'Even a 2-min conversation reduces cortisol and '
          'raises oxytocin — the opposite of addiction chemistry.';
    if (e == 'Bored')
      return 'Boredom cravings are environment-specific cues. '
          'Changing location breaks the cue-routine-reward loop.';
    if (e == 'Angry' || e == 'Frustrated')
      return 'Physical exertion metabolises cortisol and releases '
          'endorphins — directly counteracting the urge signal.';
    if (e == 'Sad' || e == 'Depressed')
      return 'Affect labelling activates the prefrontal cortex, '
          'reducing amygdala-driven craving by up to 40%.';
    return 'Sensory grounding anchors attention in the present moment, '
        'interrupting the automatic craving loop (DBT research, 2003).';
  }

  // ── Intervention steps panel ───────────────────────────────────
  Widget _stepsPanel(PreRelapseWarningModel w) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        decoration: BoxDecoration(
            color: const Color(0xFF141428),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Colors.white.withOpacity(0.07))),
        child: Column(children: [
          GestureDetector(
              onTap: () =>
                  setState(() => _stepsExpanded = !_stepsExpanded),
              child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    const Icon(Icons.tips_and_updates_outlined,
                        color: Color(0xFF6C63FF), size: 16),
                    const SizedBox(width: 8),
                    Text(
                        '${w.interventionSteps.length} personalised steps',
                        style: const TextStyle(
                            color: Color(0xFF6C63FF),
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Icon(
                        _stepsExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: Colors.white.withOpacity(0.3),
                        size: 18),
                  ]))),
          if (_stepsExpanded)
            ...w.interventionSteps.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.value.emoji,
                            style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                              Text(e.value.title,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 3),
                              Text(e.value.description,
                                  style: TextStyle(
                                      color:
                                          Colors.white.withOpacity(0.5),
                                      fontSize: 11,
                                      height: 1.4)),
                            ])),
                      ]),
                )),
        ]),
      );

  // ── Log urge button ────────────────────────────────────────────
  Widget _logUrgeBtn() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: DecoratedBox(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                    colors: [_sevColor, _sevColor.withOpacity(0.7)]),
                boxShadow: [
                  BoxShadow(
                      color: _sevColor.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 5))
                ]),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.edit_note_rounded,
                  color: Colors.white, size: 20),
              label: const Text('Log This Urge',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
            ),
          ),
        ),
      );
}

// ── Wave Widget ────────────────────────────────────────────────

class _WaveWidget extends StatefulWidget {
  final Color color;
  const _WaveWidget({required this.color});
  @override
  State<_WaveWidget> createState() => _WaveState();
}

class _WaveState extends State<_WaveWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 80,
        child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => CustomPaint(
                size: const Size(double.infinity, 80),
                painter: _WavePainter(_ctrl.value, widget.color))),
      );
}

// ── Wave Painter ───────────────────────────────────────────────

class _WavePainter extends CustomPainter {
  final double progress;
  final Color color;
  _WavePainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.35)
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height * 0.5);
    for (double x = 0; x <= size.width; x++) {
      final y = size.height * 0.5 +
          math.sin((x / size.width * 2 * math.pi) +
                  progress * 2 * math.pi) *
              18;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);

    final paint2 = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    final path2 = Path();
    path2.moveTo(0, size.height * 0.5);
    for (double x = 0; x <= size.width; x++) {
      final y = size.height * 0.5 +
          math.sin((x / size.width * 2 * math.pi) +
                  (progress + 0.3) * 2 * math.pi) *
              12;
      path2.lineTo(x, y);
    }
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(_WavePainter old) => true;
}