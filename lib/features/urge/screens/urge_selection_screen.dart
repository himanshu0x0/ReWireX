// lib/features/urge/screens/urge_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rewirex/features/urge/data/urge_needs.dart';
import 'package:rewirex/features/urge/data/urge_types.dart';
import 'package:rewirex/features/urge/engine/intervention_engine.dart';

import '../engine/urge_engine.dart';
import '../models/urge_intervention_model.dart';
import '../models/urge_session_model.dart';
import 'urge_rescue_screen.dart';

/// Intervention selection step of the Urge Rescue flow.
///
/// The screen uses InterventionEngine through UrgeEngine. The user can see
/// why the recommended predefined intervention was selected and can choose
/// another ranked option when appropriate.
class UrgeSelectionScreen extends StatefulWidget {
  final UrgeSessionModel session;

  const UrgeSelectionScreen({super.key, required this.session});

  @override
  State<UrgeSelectionScreen> createState() => _UrgeSelectionScreenState();
}

class _UrgeSelectionScreenState extends State<UrgeSelectionScreen> {
  final UrgeEngine _engine = const UrgeEngine();

  late UrgeSessionModel _session;
  late final InterventionDecision _decision;
  late final List<UrgeInterventionModel> _ranked;
  late UrgeInterventionModel _selected;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();

    _session = widget.session;

    final decision = _engine.interventionEngine.decide(_session);
    _decision = decision;
    _ranked = decision.ranked;
    _selected = decision.selected;
  }

  List<UrgeInterventionModel> get _visibleInterventions {
    if (_showAll) return _ranked;
    return _ranked.take(3).toList(growable: false);
  }

  void _select(UrgeInterventionModel intervention) {
    HapticFeedback.selectionClick();
    setState(() => _selected = intervention);
  }

  Future<void> _continue() async {
    HapticFeedback.mediumImpact();

    final updated = _session.copyWith(
      selectedNeed: _decision.selectedNeed,
      rescuePath: _selected.rescuePath,
      interventionId: _selected.id,
      interventionTitle: _selected.title,
      status: UrgeSessionStatus.interventionSelected,
      updatedAt: DateTime.now(),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => UrgeRescueScreen(
          session: updated,
          selectedIntervention: _selected,
          rankedInterventions: _ranked,
        ),
      ),
    );
  }

  Color _safetyColor(InterventionSafetyLevel level) {
    switch (level) {
      case InterventionSafetyLevel.standard:
        return const Color(0xFF00C4A0);
      case InterventionSafetyLevel.caution:
        return const Color(0xFFFFB74D);
      case InterventionSafetyLevel.safetyReviewRequired:
        return const Color(0xFFE53935);
    }
  }

  String _safetyLabel(InterventionSafetyLevel level) {
    switch (level) {
      case InterventionSafetyLevel.standard:
        return 'Standard rescue';
      case InterventionSafetyLevel.caution:
        return 'Cautious rescue';
      case InterventionSafetyLevel.safetyReviewRequired:
        return 'Safety review';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: const Text(
          'Choose your rescue',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummary(),
                    const SizedBox(height: 20),
                    _buildRecommendation(),
                    const SizedBox(height: 20),
                    Text(
                      'AVAILABLE RESCUES',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.38),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._visibleInterventions.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildInterventionTile(
                          entry.value,
                          rank: entry.key,
                        ),
                      ),
                    ),
                    if (!_showAll && _ranked.length > 3)
                      Center(
                        child: TextButton(
                          onPressed: () {
                            setState(() => _showAll = true);
                          },
                          child: Text('See all ${_ranked.length} options'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final intensity = (_session.urgeBefore ?? 5).clamp(1, 10);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚡', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _session.urgeType.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _Chip(
                label: '$intensity/10',
                color: intensity >= 8
                    ? const Color(0xFFE53935)
                    : intensity >= 5
                    ? const Color(0xFFFFB74D)
                    : const Color(0xFF00C4A0),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_session.emotion.isNotEmpty) _line('Emotion', _session.emotion),
          _line('Need', _decision.selectedNeed.title),
          if (_session.trigger.isNotEmpty) _line('Trigger', _session.trigger),
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 12,
              ),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendation() {
    final color = _safetyColor(_decision.selected.safetyLevel);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C63FF).withOpacity(0.16),
            const Color(0xFF00C4A0).withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF00C4A0),
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'RECOMMENDED FOR YOU',
                style: TextStyle(
                  color: Color(0xFF00C4A0),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _decision.selected.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _decision.selected.subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _decision.rationale,
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(
                label: _safetyLabel(_decision.selected.safetyLevel),
                color: color,
              ),
              if (_decision.requiresConnection)
                const _Chip(
                  label: 'Connection support',
                  color: Color(0xFF6C63FF),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInterventionTile(
    UrgeInterventionModel intervention, {
    required int rank,
  }) {
    final selected = intervention.id == _selected.id;
    final color = _safetyColor(intervention.safetyLevel);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _select(intervention),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF6C63FF).withOpacity(0.14)
              : Colors.white.withOpacity(0.045),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? const Color(0xFF6C63FF)
                : Colors.white.withOpacity(0.08),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF6C63FF).withOpacity(0.18)
                    : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                intervention.title.isNotEmpty
                    ? intervention.title.substring(0, 1).toUpperCase()
                    : '?',
                style: const TextStyle(fontSize: 21),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          intervention.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (rank == 0)
                        const _Chip(
                          label: 'Best match',
                          color: Color(0xFF00C4A0),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    intervention.subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    intervention.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.62),
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      _Chip(
                        label:
                            '~${(intervention.estimatedDurationSeconds / 60).ceil()} min',
                        color: Colors.white.withOpacity(0.45),
                      ),
                      _Chip(
                        label: _safetyLabel(intervention.safetyLevel),
                        color: color,
                      ),
                      if (intervention.requiresConnection)
                        const _Chip(
                          label: 'Connection',
                          color: Color(0xFF6C63FF),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected
                  ? const Color(0xFF6C63FF)
                  : Colors.white.withOpacity(0.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.07))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: FilledButton.icon(
          onPressed: _continue,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text('Start ${_selected.title}'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
