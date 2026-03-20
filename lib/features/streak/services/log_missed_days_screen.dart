import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 📅 Log Missed Days Screen
/// Shows the last 7 days (excluding today). For each day the user
/// marks SUCCESS (clean) or RELAPSE. On Done, processes entries.
class LogMissedDaysScreen extends StatefulWidget {
  const LogMissedDaysScreen({super.key});

  @override
  State<LogMissedDaysScreen> createState() => _LogMissedDaysScreenState();
}

// Possible states for each day entry
enum _DayStatus { pending, success, relapse }

class _DayEntry {
  final DateTime date;
  _DayStatus status;

  _DayEntry({required this.date}) : status = _DayStatus.pending;

  String get dayName {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    return days[date.weekday - 1];
  }

  String get formattedDate {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _LogMissedDaysScreenState extends State<LogMissedDaysScreen>
    with SingleTickerProviderStateMixin {
  late List<_DayEntry> _entries;
  bool _isSaving = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    // Build last 7 days (excluding today), ordered oldest → most recent.
    // e.g. if today is Friday: Saturday(last week) → Sunday → Mon → Tue → Wed → Thu
    // so the user reads chronologically top-to-bottom, ending at yesterday.
    final today = DateTime.now();
    _entries = List.generate(7, (i) {
      // i=0 → 7 days ago, i=6 → yesterday
      final date = today.subtract(Duration(days: 7 - i));
      return _DayEntry(
        date: DateTime(date.year, date.month, date.day),
      );
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  int get _pendingCount =>
      _entries.where((e) => e.status == _DayStatus.pending).length;
  int get _successCount =>
      _entries.where((e) => e.status == _DayStatus.success).length;
  int get _relapseCount =>
      _entries.where((e) => e.status == _DayStatus.relapse).length;

  Future<void> _saveAndDone() async {
    if (_pendingCount > 0) {
      final confirmed = await _showPendingWarning();
      if (!confirmed) return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final batch = FirebaseFirestore.instance.batch();
        final logsRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('missed_day_logs');

        for (final entry in _entries) {
          if (entry.status != _DayStatus.pending) {
            final docId =
                '${entry.date.year}-${entry.date.month}-${entry.date.day}';
            batch.set(logsRef.doc(docId), {
              'date': Timestamp.fromDate(entry.date),
              'status': entry.status == _DayStatus.success
                  ? 'success'
                  : 'relapse',
              'loggedAt': Timestamp.now(),
            });
          }
        }
        await batch.commit();
      }
    } catch (_) {
      // Silent fail — non-critical log
    }

    setState(() => _isSaving = false);

    if (mounted) {
      Navigator.pop(context, {
        'successDays': _successCount,
        'relapseDays': _relapseCount,
      });
    }
  }

  Future<bool> _showPendingWarning() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF161625),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Skip unlogged days?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          '$_pendingCount day${_pendingCount == 1 ? '' : 's'} left unmarked. They will be skipped.',
          style: TextStyle(color: Colors.white.withOpacity(0.6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Go Back',
                style: TextStyle(color: Color(0xFF6C63FF))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child:
                const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────
              _buildHeader(context),

              // ── Summary chips ────────────────────────────
              _buildSummaryRow(),

              // ── Instruction ─────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.06), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: Color(0xFF6C63FF), size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'For each missed day, log if you stayed clean or relapsed. Be honest — it\'s your journey.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Day cards list ───────────────────────────
              Expanded(
                child: ListView.separated(
                  padding:
                      const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  itemCount: _entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _DayCard(
                    entry: _entries[i],
                    index: i,
                    onStatusChanged: (status) {
                      setState(() => _entries[i].status = status);
                    },
                  ),
                ),
              ),

              // ── Done button ──────────────────────────────
              _buildDoneButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          // Back button
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
                  'Log Missed Days',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Address your missed check-ins honestly.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.38),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          _SummaryChip(
              label: '$_successCount Clean',
              color: const Color(0xFF00C4A0),
              icon: Icons.check_circle_outline_rounded),
          const SizedBox(width: 8),
          _SummaryChip(
              label: '$_relapseCount Relapse',
              color: const Color(0xFFE53935),
              icon: Icons.warning_amber_rounded),
          const SizedBox(width: 8),
          _SummaryChip(
              label: '$_pendingCount Pending',
              color: Colors.white.withOpacity(0.35),
              icon: Icons.radio_button_unchecked_rounded),
        ],
      ),
    );
  }

  Widget _buildDoneButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveAndDone,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Day card ──────────────────────────────────────────────────

class _DayCard extends StatelessWidget {
  final _DayEntry entry;
  final int index;
  final ValueChanged<_DayStatus> onStatusChanged;

  const _DayCard({
    required this.entry,
    required this.index,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSuccess = entry.status == _DayStatus.success;
    final isRelapse = entry.status == _DayStatus.relapse;

    Color borderColor = Colors.white.withOpacity(0.07);
    if (isSuccess) borderColor = const Color(0xFF00C4A0).withOpacity(0.4);
    if (isRelapse) borderColor = const Color(0xFFE53935).withOpacity(0.35);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isSuccess
            ? const Color(0xFF00C4A0).withOpacity(0.05)
            : isRelapse
                ? const Color(0xFFE53935).withOpacity(0.05)
                : const Color(0xFF141428),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day info row
          Row(
            children: [
              // Day number badge
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${entry.date.day}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.dayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    entry.formattedDate,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.38),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Status indicator
              if (isSuccess)
                _StatusBadge(
                    label: 'Clean', color: const Color(0xFF00C4A0))
              else if (isRelapse)
                _StatusBadge(
                    label: 'Relapse',
                    color: const Color(0xFFE53935))
              else
                Text(
                  'Not logged',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.22),
                    fontSize: 11,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'SUCCESS',
                  icon: Icons.check_rounded,
                  color: const Color(0xFF00C4A0),
                  isSelected: isSuccess,
                  onTap: () => onStatusChanged(
                    isSuccess ? _DayStatus.pending : _DayStatus.success,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  label: 'RELAPSE',
                  icon: Icons.close_rounded,
                  color: const Color(0xFFE53935),
                  isSelected: isRelapse,
                  onTap: () => onStatusChanged(
                    isRelapse ? _DayStatus.pending : _DayStatus.relapse,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.25),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 15,
                color: isSelected ? Colors.white : color.withOpacity(0.7)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _SummaryChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
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