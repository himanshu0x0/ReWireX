import 'package:flutter/material.dart';
import 'package:rewirex/features/urge/data/urge_needs.dart';

import '../data/urge_types.dart';
import '../models/urge_intervention_model.dart';
import '../models/urge_session_model.dart';

/// Final screen for an Urge Rescue session.
///
/// Shows the outcome after the intervention and gives the user a clear next
/// action. This screen is presentation-only; persistence can be connected to
/// UrgeSessionService when that service is introduced.
class UrgeResultScreen extends StatelessWidget {
  final UrgeSessionModel session;
  final UrgeInterventionModel? intervention;

  const UrgeResultScreen({
    super.key,
    required this.session,
    this.intervention,
  });

  bool get _wasEscalated =>
      session.wasEscalated || session.outcome == UrgeOutcome.escalated;

  bool get _improved {
    final before = session.urgeBefore;
    final after = session.urgeAfter;

    if (before == null || after == null) {
      return session.outcome == UrgeOutcome.reduced ||
          session.outcome == UrgeOutcome.resolved;
    }

    return after < before;
  }

  String get _headline {
    if (_wasEscalated) {
      return 'You paused before acting.';
    }

    switch (session.outcome) {
      case UrgeOutcome.resolved:
        return 'The urge settled.';
      case UrgeOutcome.reduced:
        return 'The urge came down.';
      case UrgeOutcome.unchanged:
        return 'The urge is still there.';
      case UrgeOutcome.stronger:
        return 'The urge got stronger.';
      case UrgeOutcome.escalated:
        return 'You reached for more support.';
      case UrgeOutcome.unknown:
        return 'You completed the rescue.';
    }
  }

  String get _message {
    if (_wasEscalated) {
      return 'The goal is not to handle everything alone. Stay away from the trigger and use a trusted person, your Connect Hub, or the appropriate safety support available to you.';
    }

    switch (session.outcome) {
      case UrgeOutcome.resolved:
        return 'You created enough space to move forward without acting on the urge.';
      case UrgeOutcome.reduced:
        return 'A smaller urge is still progress. You created space between the feeling and the action.';
      case UrgeOutcome.unchanged:
        return 'Not every rescue works immediately. Try another support path rather than acting on the urge.';
      case UrgeOutcome.stronger:
        return 'The urge increased after the rescue. Step away from the trigger and use another support option.';
      case UrgeOutcome.escalated:
        return 'You chose more support instead of pushing through alone.';
      case UrgeOutcome.unknown:
        return 'You completed a rescue step. Your response is useful information for future personalization.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Rescue complete',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            _buildStatusIcon(theme),
            const SizedBox(height: 20),
            Text(
              _headline,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.45,
                color: Colors.white.withOpacity(0.60),
              ),
            ),
            const SizedBox(height: 24),
            _buildSessionSummary(theme),
            const SizedBox(height: 20),
            if (intervention != null) _buildInterventionSummary(theme),
            if (intervention != null) const SizedBox(height: 20),
            _buildNextAction(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(ThemeData theme) {
    final icon = _wasEscalated
        ? Icons.support_agent_rounded
        : _improved
        ? Icons.check_circle_outline_rounded
        : Icons.info_outline_rounded;

    return Center(
      child: CircleAvatar(
        radius: 38,
        backgroundColor: const Color(0xFF6C63FF).withOpacity(0.18),
        child: Icon(
          icon,
          size: 42,
          color: const Color(0xFF6C63FF),
        ),
      ),
    );
  }

  Widget _buildSessionSummary(ThemeData theme) {
    final before = session.urgeBefore;
    final after = session.urgeAfter;

    return Card(
      color: const Color(0xFF141428),
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your rescue',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            _SummaryRow(
              label: 'Urge',
              value: session.urgeType.title,
            ),
            if (session.emotion.trim().isNotEmpty)
              _SummaryRow(
                label: 'Emotion',
                value: session.emotion,
              ),
            if (session.selectedNeed != null)
              _SummaryRow(
                label: 'Need',
                value: session.selectedNeed!.title,
              ),
            _SummaryRow(
              label: 'Outcome',
              value: session.outcome.label,
            ),
            if (before != null || after != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _ScoreBox(
                        label: 'Before',
                        score: before,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ScoreBox(
                        label: 'After',
                        score: after,
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

  Widget _buildInterventionSummary(ThemeData theme) {
    final item = intervention!;

    return Card(
      color: const Color(0xFF141428),
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What you used',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.60),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              item.completionMessage ??
                  'You completed the selected rescue and created space before acting.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.65),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextAction(BuildContext context, ThemeData theme) {
    if (_wasEscalated || session.outcome == UrgeOutcome.stronger) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: () => Navigator.of(context).popUntil(
              (route) => route.isFirst,
            ),
            icon: const Icon(Icons.people_alt_outlined),
            label: const Text('Go back to support'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(54),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withOpacity(0.25)),
            ),
            child: const Text('Close rescue'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
          ),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.60),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBox extends StatelessWidget {
  final String label;
  final int? score;

  const _ScoreBox({
    required this.label,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF1A1A2E),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.60),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            score == null ? '—' : '$score / 10',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
