// lib/features/urge/screens/urge_need_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rewirex/features/urge/data/urge_types.dart';

import '../data/urge_needs.dart';
import '../engine/urge_ai_resolver.dart';
import '../models/urge_intervention_model.dart';
import '../models/urge_session_model.dart';
import 'urge_rescue_screen.dart';

/// Simple decision screen for Urge Rescue.
///
/// ReWireX makes one recommendation for the user instead of forcing them
/// through multiple routing decisions. The user can still change the need when
/// the recommendation does not feel right.
class UrgeNeedScreen extends StatefulWidget {
  const UrgeNeedScreen({super.key, required this.session});

  final UrgeSessionModel session;

  @override
  State<UrgeNeedScreen> createState() => _UrgeNeedScreenState();
}

class _UrgeNeedScreenState extends State<UrgeNeedScreen> {
  static const _background = Color(0xFF0D0D1A);
  static const _card = Color(0xFF141428);
  static const _primary = Color(0xFF6C63FF);
  static const _accent = Color(0xFF00C4A0);

  final UrgeAiResolver _resolver = const UrgeAiResolver();

  late UrgeSessionModel _session;
  late UrgeResolution _resolution;
  bool _showAlternatives = false;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _resolution = _resolver.resolve(_session);
  }

  void _chooseNeed(NeedType need) {
    HapticFeedback.selectionClick();

    final nextSession = _session.copyWith(
      selectedNeed: need,
      updatedAt: DateTime.now(),
    );

    setState(() {
      _session = nextSession;
      _resolution = _resolver.resolve(nextSession);
      _showAlternatives = false;
    });
  }

  void _continue() {
    HapticFeedback.mediumImpact();

    final updated = _session.copyWith(
      selectedNeed: _resolution.need,
      rescuePath: _resolution.intervention.rescuePath,
      interventionId: _resolution.intervention.id,
      interventionTitle: _resolution.intervention.title,
      status: UrgeSessionStatus.interventionSelected,
      updatedAt: DateTime.now(),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => UrgeRescueScreen(
          session: updated,
          selectedIntervention: _resolution.intervention,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final intervention = _resolution.intervention;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Your rescue plan',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                children: [
                  _buildSituationCard(),
                  const SizedBox(height: 18),
                  const Text(
                    'ReWireX thinks this may help most',
                    style: TextStyle(
                      color: _accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildRecommendation(intervention),
                  const SizedBox(height: 14),
                  Text(
                    _resolution.reason,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.58),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  if (_resolution.requiresSafetyReview) ...[
                    const SizedBox(height: 14),
                    _buildSafetyNote(),
                  ],
                  const SizedBox(height: 18),
                  _buildAlternativeToggle(),
                  if (_showAlternatives) ...[
                    const SizedBox(height: 12),
                    ..._resolution.alternateNeeds.map(
                      (need) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildAlternative(need),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: _continue,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text('Start ${intervention.title}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSituationCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: _primary.withValues(alpha: 0.18),
                child: Text(
                  _session.urgeType.emoji,
                  style: const TextStyle(fontSize: 23),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _session.urgeType.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (_session.urgeBefore != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_session.urgeBefore}/10',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (_session.emotion.trim().isNotEmpty)
            _infoRow('Emotion', _session.emotion),
          if (_session.trigger.trim().isNotEmpty)
            _infoRow('Trigger', _session.trigger),
          if (_session.context.trim().isNotEmpty)
            _infoRow('Context', _session.context),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 68,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.38),
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

  Widget _buildRecommendation(UrgeInterventionModel intervention) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primary.withValues(alpha: 0.20),
            _accent.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Colors.white),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  intervention.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            intervention.subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.favorite_outline_rounded,
                color: _accent,
                size: 17,
              ),
              const SizedBox(width: 7),
              Text(
                _resolution.need.title,
                style: const TextStyle(
                  color: _accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: Colors.orange, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This moment needs extra care. Stay away from the trigger and use additional support when the rescue is not enough.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativeToggle() {
    return TextButton.icon(
      onPressed: _resolution.alternateNeeds.isEmpty
          ? null
          : () => setState(() => _showAlternatives = !_showAlternatives),
      icon: Icon(
        _showAlternatives
            ? Icons.keyboard_arrow_up_rounded
            : Icons.tune_rounded,
      ),
      label: Text(
        _showAlternatives ? 'Hide alternatives' : 'This does not feel right',
      ),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white70,
        alignment: Alignment.centerLeft,
      ),
    );
  }

  Widget _buildAlternative(NeedType need) {
    return Material(
      color: _card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _chooseNeed(need),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Text(need.emoji, style: const TextStyle(fontSize: 23)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      need.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      need.subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.50),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
