import 'package:flutter/material.dart';
import 'package:rewirex/features/urge/data/urge_needs.dart';

import '../models/urge_session_model.dart';
import '../services/urge_session_service.dart';

/// History of complete Urge Rescue sessions.
///
/// This screen intentionally reads `urge_sessions` rather than the older
/// `urge_logs` collection so the user can review the complete journey:
/// urge -> need -> intervention -> recheck -> outcome.
class UrgeHistoryScreen extends StatefulWidget {
  const UrgeHistoryScreen({super.key});

  @override
  State<UrgeHistoryScreen> createState() => _UrgeHistoryScreenState();
}

class _UrgeHistoryScreenState extends State<UrgeHistoryScreen> {
  final UrgeSessionService _sessionService = UrgeSessionService();

  String _filter = 'All';

  List<UrgeSessionModel> _filterSessions(
    List<UrgeSessionModel> sessions,
  ) {
    final now = DateTime.now();

    switch (_filter) {
      case 'Helpful':
        return sessions.where((session) {
          return session.outcome == UrgeOutcome.resolved ||
              session.outcome == UrgeOutcome.reduced;
        }).toList();
      case 'High':
        return sessions.where((session) {
          return (session.urgeBefore ?? 0) >= 7;
        }).toList();
      case 'Today':
        return sessions.where((session) {
          final date = session.startedAt;
          return date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
        }).toList();
      case '7 days':
        final cutoff = now.subtract(const Duration(days: 7));
        return sessions
            .where((session) => session.startedAt.isAfter(cutoff))
            .toList();
      default:
        return sessions;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rescue History'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<UrgeSessionModel>>(
        stream: _sessionService.watchRecentSessions(limit: 100),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: 'Could not load rescue history.',
              onRetry: () => setState(() {}),
            );
          }

          final allSessions = snapshot.data ?? const <UrgeSessionModel>[];
          final sessions = _filterSessions(allSessions);

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
              await Future<void>.delayed(const Duration(milliseconds: 250));
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Text(
                  'Learn what helps when an urge arrives.',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your rescue history shows the urge level before and after an intervention, so patterns can guide future choices.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                if (allSessions.isNotEmpty) ...[
                  _StatsCard(sessions: allSessions),
                  const SizedBox(height: 18),
                ],
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: const [
                      'All',
                      'Helpful',
                      'High',
                      'Today',
                      '7 days',
                    ].map(_HistoryFilterChip.new).toList(),
                  ),
                ),
                const SizedBox(height: 18),
                if (sessions.isEmpty)
                  _EmptyState(filter: _filter)
                else
                  ...sessions.map(
                    (session) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SessionTile(
                        session: session,
                        onDelete: () => _delete(context, session),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    UrgeSessionModel session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete rescue session?'),
        content: const Text(
          'This removes this rescue session from history. It does not change your urge log, streak, or relapse history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _sessionService.deleteSession(session.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rescue session deleted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete rescue session: $e')),
      );
    }
  }
}

class _HistoryFilterChip extends StatelessWidget {
  final String value;

  const _HistoryFilterChip(this.value);

  @override
  Widget build(BuildContext context) {
    final state = context
        .findAncestorStateOfType<_UrgeHistoryScreenState>();

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(value),
        selected: state?._filter == value,
        onSelected: (_) {
          if (state == null) return;
          // ignore: invalid_use_of_protected_member
          state.setState(() => state._filter = value);
        },
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final List<UrgeSessionModel> sessions;

  const _StatsCard({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final completed = sessions.where((session) {
      return session.status == UrgeSessionStatus.completed ||
          session.status == UrgeSessionStatus.escalated;
    }).length;

    final helpful = sessions.where((session) {
      return session.outcome == UrgeOutcome.resolved ||
          session.outcome == UrgeOutcome.reduced;
    }).length;

    final resolved = sessions.where(
      (session) => session.outcome == UrgeOutcome.resolved,
    ).length;

    final rate = completed == 0 ? 0 : (helpful / completed * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'YOUR RESCUE PATTERN',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    value: '${sessions.length}',
                    label: 'Sessions',
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    value: '$completed',
                    label: 'Completed',
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    value: '$rate%',
                    label: 'Helpful',
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    value: '$resolved',
                    label: 'Resolved',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  final UrgeSessionModel session;
  final VoidCallback onDelete;

  const _SessionTile({
    required this.session,
    required this.onDelete,
  });

  Color get intensityColor {
    final intensity = session.urgeBefore ?? 0;

    if (intensity <= 3) return const Color(0xFF00C853);
    if (intensity <= 5) return const Color(0xFFFFD600);
    if (intensity <= 7) return const Color(0xFFFF6D00);
    return const Color(0xFFE53935);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _urgeLabel(String value) {
    final text = value
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ');

    if (text.isEmpty) return 'Unknown urge';
    return text[0].toUpperCase() + text.substring(1);
  }

  Color _outcomeColor(BuildContext context) {
    switch (session.outcome) {
      case UrgeOutcome.resolved:
        return const Color(0xFF00C853);
      case UrgeOutcome.reduced:
        return const Color(0xFF64DD17);
      case UrgeOutcome.unchanged:
        return const Color(0xFFFFD600);
      case UrgeOutcome.stronger:
        return const Color(0xFFFF6D00);
      case UrgeOutcome.escalated:
        return const Color(0xFFE53935);
      case UrgeOutcome.unknown:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final before = session.urgeBefore;
    final after = session.urgeAfter;
    final color = intensityColor;
    final outcomeColor = _outcomeColor(context);

    return Card(
      child: InkWell(
        onLongPress: onDelete,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: color.withOpacity(0.12),
                    child: Icon(Icons.shield_outlined, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _urgeLabel(session.urgeType.name),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(session.startedAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _ScorePill(
                    label: 'Before',
                    value: before == null ? '—' : '$before/10',
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  _ScorePill(
                    label: 'After',
                    value: after == null ? '—' : '$after/10',
                    color: outcomeColor,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (session.emotion.trim().isNotEmpty)
                    _Tag(
                      icon: Icons.mood_outlined,
                      text: session.emotion,
                    ),
                  if (session.selectedNeed != null)
                    _Tag(
                      icon: Icons.favorite_outline_rounded,
                      text: session.selectedNeed!.title,
                    ),
                  if (session.interventionTitle != null &&
                      session.interventionTitle!.trim().isNotEmpty)
                    _Tag(
                      icon: Icons.auto_awesome_outlined,
                      text: session.interventionTitle!,
                    ),
                ],
              ),
              if (session.trigger.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Trigger: ${session.trigger}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: outcomeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      session.outcome.label,
                      style: TextStyle(
                        color: outcomeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (session.duration != null)
                    Text(
                      _durationLabel(session.duration!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _durationLabel(Duration duration) {
    if (duration.inSeconds < 60) return '${duration.inSeconds}s';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return seconds == 0 ? '${minutes}m' : '${minutes}m ${seconds}s';
  }
}

class _ScorePill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ScorePill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Tag({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String filter;

  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Icon(Icons.history_toggle_off_rounded, size: 52),
            const SizedBox(height: 12),
            Text(
              'No rescue sessions in this view',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              filter == 'All'
                  ? 'Completed rescue journeys will appear here.'
                  : 'Try another filter.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
