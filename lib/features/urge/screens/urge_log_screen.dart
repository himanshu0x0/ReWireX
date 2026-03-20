// lib/features/urge/screens/urge_log_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rewirex/features/intervention/screens/intevention_screen.dart';
import 'package:rewirex/features/urge/services/urge_service.dart';
import 'package:rewirex/features/streak/services/streak_service.dart';
import 'package:rewirex/features/risk/services/risk_prediction_service.dart';
import 'package:rewirex/features/urge/data/urge_data.dart';

class UrgeLogScreen extends StatefulWidget {
  const UrgeLogScreen({super.key});

  @override
  State<UrgeLogScreen> createState() => _UrgeLogScreenState();
}

class _UrgeLogScreenState extends State<UrgeLogScreen>
    with TickerProviderStateMixin {
  // ── Services ─────────────────────────────────────────────────
  final UrgeService _urgeService = UrgeService();
  final StreakService _streakService = StreakService();

  // ── Step state ───────────────────────────────────────────────
  int _currentStep = 0;
  final int _totalSteps = 5;
  final PageController _pageController = PageController();

  // ── Selected values ──────────────────────────────────────────
  UrgeTypeCategory? _selectedCategory;
  String _selectedType = '';
  String _selectedEmotion = '';
  double _intensity = 5;
  String _selectedTrigger = '';
  String _selectedContext = '';
  String _selectedBodyLocation = '';
  final TextEditingController _notesController = TextEditingController();

  // ── UI state ─────────────────────────────────────────────────
  bool _isSaving = false;

  // ── Animations ───────────────────────────────────────────────
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _pageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ── Navigation ───────────────────────────────────────────────
  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      HapticFeedback.lightImpact();
      _fadeController.reset();
      _fadeController.forward();
      setState(() => _currentStep++);
      _pageController.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();
      _fadeController.reset();
      _fadeController.forward();
      setState(() => _currentStep--);
      _pageController.previousPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    }
  }

  bool get _canAdvance {
    switch (_currentStep) {
      case 0:
        return _selectedType.isNotEmpty;
      case 1:
        return _selectedEmotion.isNotEmpty;
      case 2:
        return true; // intensity always valid
      case 3:
        return true; // trigger optional
      case 4:
        return true; // notes/context optional
      default:
        return false;
    }
  }

  // ── Save logic (preserved from original) ────────────────────
  Future<void> _saveUrge() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      await _urgeService.saveUrge(
        type: _selectedType,
        intensity: _intensity.toInt(),
        emotion: _selectedEmotion,
        trigger: _selectedTrigger,
        notes: _notesController.text.trim(),
        context: _selectedContext,
        bodyLocation: _selectedBodyLocation,
      );

      // ── Auto-relapse logic (preserved exactly) ───────────────
      final riskService = RiskPredictionService();
      final risk = await riskService.analyzeRisk();
      bool shouldRelapse = false;
      final int intensityInt = _intensity.toInt();

      if (intensityInt >= 9) {
        shouldRelapse = true;
      } else if (risk != null && risk.level == 'High' && intensityInt >= 7) {
        shouldRelapse = true;
      } else if (_selectedEmotion == 'Lonely' && intensityInt >= 7) {
        shouldRelapse = true;
      }

      if (shouldRelapse) {
        await _streakService.recordRelapse();
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => InterventionScreen(
            emotion: _selectedEmotion,
            intensity: intensityInt,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Urge Save Error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Something went wrong. Please try again.'),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Intensity UI helpers ─────────────────────────────────────
  Color get _intensityColor {
    final v = _intensity.toInt();
    if (v <= 3) return const Color(0xFF00C853);
    if (v <= 5) return const Color(0xFFFFD600);
    if (v <= 7) return const Color(0xFFFF6D00);
    return const Color(0xFFE53935);
  }

  String get _intensityLabel {
    final v = _intensity.toInt();
    if (v <= 2) return 'Minimal';
    if (v <= 4) return 'Low';
    if (v <= 6) return 'Moderate';
    if (v <= 8) return 'High';
    return 'Extreme';
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep0_UrgeType(),
                  _buildStep1_Emotion(),
                  _buildStep2_Intensity(),
                  _buildStep3_Trigger(),
                  _buildStep4_ContextNotes(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────
  Widget _buildHeader() {
    final stepTitles = [
      'What are you feeling?',
      'Name the emotion',
      'How intense is it?',
      'What triggered this?',
      'Any more details?',
    ];
    final stepSubs = [
      'Select the urge you\'re experiencing right now',
      'Pinpoint exactly what\'s driving this',
      'Rate the pull you\'re feeling from 1 to 10',
      'Understanding the trigger helps break the pattern',
      'Context helps AI predict and prevent future urges',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_currentStep > 0)
                GestureDetector(
                  onTap: _prevStep,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 15, color: Colors.white.withOpacity(0.7)),
                  ),
                )
              else
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.close_rounded,
                        size: 18, color: Colors.white.withOpacity(0.7)),
                  ),
                ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFF6C63FF).withOpacity(0.3)),
                ),
                child: Text(
                  'Step ${_currentStep + 1} of $_totalSteps',
                  style: const TextStyle(
                    color: Color(0xFF6C63FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stepTitles[_currentStep],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  stepSubs[_currentStep],
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Progress bar ─────────────────────────────────────────────
  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: List.generate(_totalSteps, (i) {
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: isDone
                    ? const Color(0xFF00C4A0)
                    : isActive
                        ? const Color(0xFF6C63FF)
                        : Colors.white.withOpacity(0.1),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  STEP 0 — Urge Type
  // ─────────────────────────────────────────────────────────────
  Widget _buildStep0_UrgeType() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: urgeTypeCategories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedCategory = cat;
                      _selectedType = '';
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: isSelected
                          ? const Color(0xFF6C63FF).withOpacity(0.2)
                          : Colors.white.withOpacity(0.06),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF6C63FF)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cat.emoji,
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          cat.name,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF6C63FF)
                                : Colors.white.withOpacity(0.6),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            if (_selectedCategory != null) ...[
              const SizedBox(height: 20),
              Text(
                '${_selectedCategory!.emoji}  ${_selectedCategory!.name}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedCategory!.types.map((type) {
                  final isSelected = _selectedType == type;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedType = type);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [
                                  Color(0xFF6C63FF),
                                  Color(0xFF00C4A0)
                                ],
                              )
                            : null,
                        color: isSelected
                            ? null
                            : Colors.white.withOpacity(0.07),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.75),
                          fontSize: 13.5,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ] else ...[
              const SizedBox(height: 32),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.touch_app_rounded,
                        size: 40,
                        color: Colors.white.withOpacity(0.15)),
                    const SizedBox(height: 12),
                    Text(
                      'Pick a category above\nto see urge types',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.25),
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  STEP 1 — Emotion
  // ─────────────────────────────────────────────────────────────
  Widget _buildStep1_Emotion() {
    // Group into negative / positive
    final negative = allEmotions.where((e) => e.isNegative).toList();
    final positive = allEmotions.where((e) => !e.isNegative).toList();

    Widget emotionChip(EmotionData e) {
      final isSelected = _selectedEmotion == e.name;
      final col = Color(e.colorValue);
      return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedEmotion = e.name);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: isSelected
                ? col.withOpacity(0.22)
                : Colors.white.withOpacity(0.06),
            border: Border.all(
              color: isSelected ? col : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e.emoji,
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 7),
              Text(
                e.name,
                style: TextStyle(
                  color: isSelected
                      ? col
                      : Colors.white.withOpacity(0.7),
                  fontSize: 13,
                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Difficult emotions',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: negative.map(emotionChip).toList(),
            ),
            const SizedBox(height: 20),
            Text(
              'Positive states',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: positive.map(emotionChip).toList(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  STEP 2 — Intensity
  // ─────────────────────────────────────────────────────────────
  Widget _buildStep2_Intensity() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          children: [
            // Big intensity dial
            ScaleTransition(
              scale: _pulseAnim,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _intensityColor.withOpacity(0.12),
                  border: Border.all(
                      color: _intensityColor.withOpacity(0.4), width: 2.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _intensity.toInt().toString(),
                      style: TextStyle(
                        color: _intensityColor,
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _intensityLabel,
                      style: TextStyle(
                        color: _intensityColor.withOpacity(0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 36),

            // Custom slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 6,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 14),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 26),
                activeTrackColor: _intensityColor,
                inactiveTrackColor: Colors.white.withOpacity(0.1),
                thumbColor: _intensityColor,
                overlayColor: _intensityColor.withOpacity(0.15),
              ),
              child: Slider(
                value: _intensity,
                min: 1,
                max: 10,
                divisions: 9,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => _intensity = v);
                },
              ),
            ),

            // Scale labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(10, (i) {
                  final val = i + 1;
                  final isSelected = _intensity.toInt() == val;
                  return Text(
                    '$val',
                    style: TextStyle(
                      color: isSelected
                          ? _intensityColor
                          : Colors.white.withOpacity(0.25),
                      fontSize: isSelected ? 13 : 11,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.normal,
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 32),

            // Descriptive text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _intensityColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _intensity <= 3
                          ? Icons.sentiment_satisfied_rounded
                          : _intensity <= 6
                              ? Icons.sentiment_neutral_rounded
                              : Icons.sentiment_very_dissatisfied_rounded,
                      color: _intensityColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _intensityDescription,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 13,
                        height: 1.5,
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

  String get _intensityDescription {
    final v = _intensity.toInt();
    if (v <= 2)
      return 'A faint pull — you\'re in control and aware. Noticing it is a win.';
    if (v <= 4)
      return 'Mild urge. Manageable with simple grounding or a distraction.';
    if (v <= 6)
      return 'Noticeable tension. Your brain is signaling — let\'s redirect it.';
    if (v <= 8)
      return 'Strong pull. Breathing and movement can help break the wave.';
    return 'Overwhelming. An emergency technique can help you get through this.';
  }

  // ─────────────────────────────────────────────────────────────
  //  STEP 3 — Trigger
  // ─────────────────────────────────────────────────────────────
  Widget _buildStep3_Trigger() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allTriggers.map((t) {
                final isSelected = _selectedTrigger == t.name;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedTrigger =
                        isSelected ? '' : t.name);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: isSelected
                          ? const Color(0xFF00C4A0).withOpacity(0.18)
                          : Colors.white.withOpacity(0.06),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00C4A0)
                            : Colors.white.withOpacity(0.1),
                        width: 1.3,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(t.emoji,
                            style: const TextStyle(fontSize: 15)),
                        const SizedBox(width: 7),
                        Text(
                          t.name,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF00C4A0)
                                : Colors.white.withOpacity(0.7),
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Body location section
            Text(
              'WHERE DO YOU FEEL IT IN YOUR BODY?',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: bodyLocations.map((loc) {
                final isSelected = _selectedBodyLocation == loc;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedBodyLocation =
                        isSelected ? '' : loc);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: isSelected
                          ? const Color(0xFF6C63FF).withOpacity(0.18)
                          : Colors.white.withOpacity(0.05),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF6C63FF).withOpacity(0.6)
                            : Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: Text(
                      loc,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF6C63FF)
                            : Colors.white.withOpacity(0.55),
                        fontSize: 12.5,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  STEP 4 — Context + Notes
  // ─────────────────────────────────────────────────────────────
  Widget _buildStep4_ContextNotes() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WHERE ARE YOU RIGHT NOW?',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allContexts.map((ctx) {
                final isSelected = _selectedContext == ctx.name;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedContext =
                        isSelected ? '' : ctx.name);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: isSelected
                          ? const Color(0xFF6C63FF).withOpacity(0.2)
                          : Colors.white.withOpacity(0.06),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF6C63FF)
                            : Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(ctx.emoji,
                            style: const TextStyle(fontSize: 15)),
                        const SizedBox(width: 7),
                        Text(
                          ctx.name,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF6C63FF)
                                : Colors.white.withOpacity(0.7),
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            Text(
              'NOTES (OPTIONAL)',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.white.withOpacity(0.1)),
              ),
              child: TextField(
                controller: _notesController,
                maxLines: 4,
                style: const TextStyle(
                    color: Colors.white, fontSize: 14, height: 1.5),
                decoration: InputDecoration(
                  hintText:
                      'What\'s going through your mind right now? Be honest with yourself...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.25),
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Summary card
            _buildSummaryCard(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final emotion =
        allEmotions.firstWhere((e) => e.name == _selectedEmotion,
            orElse: () => const EmotionData(
                name: '', emoji: '❓', colorValue: 0xFF607D8B));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR URGE SUMMARY',
            style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _summaryRow('Urge', _selectedType, Icons.flash_on_rounded),
          _summaryRow('Emotion',
              '${emotion.emoji}  $_selectedEmotion', Icons.favorite_rounded),
          _summaryRow('Intensity',
              '$_intensityLabel  (${_intensity.toInt()}/10)',
              Icons.bar_chart_rounded),
          if (_selectedTrigger.isNotEmpty)
            _summaryRow(
                'Trigger', _selectedTrigger, Icons.bolt_rounded),
          if (_selectedContext.isNotEmpty)
            _summaryRow(
                'Context', _selectedContext, Icons.place_rounded),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon,
              size: 14, color: const Color(0xFF6C63FF).withOpacity(0.7)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 12.5,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom bar ───────────────────────────────────────────────
  Widget _buildBottomBar() {
    final isLastStep = _currentStep == _totalSteps - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.07))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: ElevatedButton(
            onPressed: _canAdvance
                ? (isLastStep ? _saveUrge : _nextStep)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: _canAdvance
                    ? const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)],
                      )
                    : null,
                color: _canAdvance
                    ? null
                    : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                alignment: Alignment.center,
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLastStep
                                ? 'Save & Get Help'
                                : 'Continue',
                            style: TextStyle(
                              color: _canAdvance
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.25),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          if (!isLastStep) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: _canAdvance
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.25),
                            ),
                          ] else ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.flash_on_rounded,
                              size: 18,
                              color: _canAdvance
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.25),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}