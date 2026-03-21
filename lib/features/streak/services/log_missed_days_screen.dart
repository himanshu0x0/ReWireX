import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LogMissedDaysScreen extends StatefulWidget {
  const LogMissedDaysScreen({super.key});

  @override
  State<LogMissedDaysScreen> createState() => _LogMissedDaysScreenState();
}

enum DayStatus { pending, success, relapse }

class _DayEntry {
  final DateTime date;
  final bool isToday;
  final bool isYesterday;
  DayStatus status;

  _DayEntry({
    required this.date,
    required this.isToday,
    required this.isYesterday,
    DayStatus initialStatus = DayStatus.pending,
  }) : status = initialStatus;

  String get dayLabel {
    if (isToday)     return 'Today';
    if (isYesterday) return 'Yesterday';
    const days = ['Monday','Tuesday','Wednesday',
                  'Thursday','Friday','Saturday','Sunday'];
    return days[date.weekday - 1];
  }

  String get formattedDate =>
      '${date.day.toString().padLeft(2,'0')}/'
      '${date.month.toString().padLeft(2,'0')}/'
      '${date.year}';

  String get docId =>
      '${date.year}-'
      '${date.month.toString().padLeft(2,'0')}-'
      '${date.day.toString().padLeft(2,'0')}';
}

class _LogMissedDaysScreenState extends State<LogMissedDaysScreen>
    with SingleTickerProviderStateMixin {

  List<_DayEntry> _entries = [];
  bool _isSaving  = false;
  bool _isLoading = true;

  late AnimationController _fadeController;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450))
      ..forward();
    _fadeAnim = CurvedAnimation(
        parent: _fadeController, curve: Curves.easeOut);
    _buildEntries();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _buildEntries() async {
    final now       = DateTime.now();
    final today     = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final entries = List.generate(14, (i) {
      final date = today.subtract(Duration(days: i));
      return _DayEntry(
        date:        date,
        isToday:     i == 0,
        isYesterday: date == yesterday,
      );
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final cutoff = today.subtract(const Duration(days: 13));
        final snap   = await FirebaseFirestore.instance
            .collection('users').doc(user.uid)
            .collection('missed_day_logs')
            .where('date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
            .get();

        final logged = <String, String>{};
        for (final doc in snap.docs) {
          logged[doc.id] = doc.data()['status'] as String? ?? '';
        }
        for (final e in entries) {
          if (logged.containsKey(e.docId)) {
            e.status = logged[e.docId] == 'success'
                ? DayStatus.success : DayStatus.relapse;
          }
        }
      } catch (_) {}
    }

    if (mounted) setState(() { _entries = entries; _isLoading = false; });
  }

  int get _pendingCount =>
      _entries.where((e) => e.status == DayStatus.pending).length;
  int get _successCount =>
      _entries.where((e) => e.status == DayStatus.success).length;
  int get _relapseCount =>
      _entries.where((e) => e.status == DayStatus.relapse).length;

  int get _consecutiveClean {
    int c = 0;
    for (final e in _entries) {
      if (e.status == DayStatus.success) { c++; } else { break; }
    }
    return c;
  }

  void _onStatus(int i, DayStatus s) =>
      setState(() => _entries[i].status = s);

  void _selectAllClean() =>
      setState(() { for (final e in _entries) { e.status = DayStatus.success; } });

  void _clearAll() =>
      setState(() { for (final e in _entries) { e.status = DayStatus.pending; } });

  Future<void> _saveAndDone() async {
    final toLog = _entries.where((e) => e.status != DayStatus.pending).toList();
    if (toLog.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text(
          'Please mark at least one day first.',
          style: TextStyle(fontSize: 15), // was implicit ~14
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final batch = FirebaseFirestore.instance.batch();
        final ref   = FirebaseFirestore.instance
            .collection('users').doc(user.uid)
            .collection('missed_day_logs');
        for (final e in toLog) {
          batch.set(ref.doc(e.docId), {
            'date':     Timestamp.fromDate(e.date),
            'status':   e.status == DayStatus.success ? 'success' : 'relapse',
            'loggedAt': Timestamp.now(),
          });
        }
        await batch.commit();
      }
    } catch (_) {}
    setState(() => _isSaving = false);
    if (mounted) {
      Navigator.pop(context,
        {'successDays': _successCount, 'relapseDays': _relapseCount});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D1A),
        body: Center(child: CircularProgressIndicator(
            color: Color(0xFF6C63FF), strokeWidth: 2.5)),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            children: [
              _header(),
              _streakPreview(),
              _toolbar(),
              _summaryRow(),
              Expanded(child: _dayList()),
              _doneButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
    child: Row(children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.arrow_back_ios_new_rounded,
              size: 16, color: Colors.white.withOpacity(0.7)), // was 15
        ),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Log Your Days',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,        // was 18
                fontWeight: FontWeight.w800,
              )),
          Text('Last 14 days including today',
              style: TextStyle(
                color: Colors.white.withOpacity(0.38),
                fontSize: 13,        // was 12
              )),
        ],
      )),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF6C63FF).withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFF6C63FF).withOpacity(0.25), width: 1),
        ),
        child: const Text('14 days',
            style: TextStyle(
              color: Color(0xFF6C63FF),
              fontSize: 12,        // was 11
              fontWeight: FontWeight.w700,
            )),
      ),
    ]),
  );

  Widget _streakPreview() {
    final c     = _consecutiveClean;
    final color = c >= 7 ? const Color(0xFF00C4A0)
        : c >= 3          ? const Color(0xFF6C63FF)
        :                   Colors.white.withOpacity(0.3);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Row(children: [
          Icon(Icons.local_fire_department_rounded, color: color, size: 18), // was 16
          const SizedBox(width: 8),
          Expanded(child: Text(
            c > 0
                ? '$c consecutive clean day${c == 1 ? '' : 's'} from today'
                : 'Mark your days to preview your clean streak',
            style: TextStyle(
              color: color,
              fontSize: 13,        // was 12
              fontWeight: FontWeight.w600,
            ),
          )),
          if (c > 0) Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20)),
            child: Text('$c day${c == 1 ? '' : 's'}',
                style: TextStyle(
                  color: color,
                  fontSize: 12,  // was 11
                  fontWeight: FontWeight.w800,
                )),
          ),
        ]),
      ),
    );
  }

  Widget _toolbar() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
    child: Row(children: [
      _ToolbarBtn(icon: Icons.done_all_rounded, label: 'All Clean',
          color: const Color(0xFF00C4A0), onTap: _selectAllClean),
      const SizedBox(width: 8),
      _ToolbarBtn(icon: Icons.clear_all_rounded, label: 'Clear',
          color: Colors.white.withOpacity(0.35), onTap: _clearAll),
      const Spacer(),
      Text('${_successCount + _relapseCount}/14 logged',
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 12,        // was 11
          )),
    ]),
  );

  Widget _summaryRow() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
    child: Row(children: [
      _Chip(label: '$_successCount Clean',
          color: const Color(0xFF00C4A0),
          icon: Icons.check_circle_outline_rounded),
      const SizedBox(width: 8),
      _Chip(label: '$_relapseCount Relapse',
          color: const Color(0xFFE53935),
          icon: Icons.warning_amber_rounded),
      const SizedBox(width: 8),
      _Chip(label: '$_pendingCount Pending',
          color: Colors.white.withOpacity(0.3),
          icon: Icons.radio_button_unchecked_rounded),
    ]),
  );

  Widget _dayList() => ListView.separated(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
    itemCount: _entries.length,
    separatorBuilder: (_, __) => const SizedBox(height: 8),
    itemBuilder: (_, i) => _DayCard(
      entry: _entries[i],
      onSuccessTapped: () => _onStatus(i,
          _entries[i].status == DayStatus.success
              ? DayStatus.pending : DayStatus.success),
      onRelapseTapped: () => _onStatus(i,
          _entries[i].status == DayStatus.relapse
              ? DayStatus.pending : DayStatus.relapse),
    ),
  );

  Widget _doneButton() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
    child: SizedBox(
      width: double.infinity, height: 56, // was 54
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)],
              begin: Alignment.centerLeft, end: Alignment.centerRight),
          boxShadow: [BoxShadow(
              color: const Color(0xFF6C63FF).withOpacity(0.3),
              blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveAndDone,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          child: _isSaving
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.save_rounded, color: Colors.white, size: 20), // was 18
                  const SizedBox(width: 8),
                  Text(
                    'Save ${_successCount + _relapseCount} Day${(_successCount + _relapseCount) == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,        // was 16
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ]),
        ),
      ),
    ),
  );
}

// ── Day Card ───────────────────────────────────────────────────

class _DayCard extends StatelessWidget {
  final _DayEntry    entry;
  final VoidCallback onSuccessTapped;
  final VoidCallback onRelapseTapped;

  const _DayCard({
    required this.entry,
    required this.onSuccessTapped,
    required this.onRelapseTapped,
  });

  @override
  Widget build(BuildContext context) {
    final isSuccess = entry.status == DayStatus.success;
    final isRelapse = entry.status == DayStatus.relapse;
    final isToday   = entry.isToday;
    final isYest    = entry.isYesterday;

    Color border = Colors.white.withOpacity(0.07);
    if (isSuccess) border = const Color(0xFF00C4A0).withOpacity(0.4);
    if (isRelapse) border = const Color(0xFFE53935).withOpacity(0.35);
    if (isToday && !isSuccess && !isRelapse) {
      border = const Color(0xFF6C63FF).withOpacity(0.35);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13), // was 12
      decoration: BoxDecoration(
        color: isSuccess
            ? const Color(0xFF00C4A0).withOpacity(0.05)
            : isRelapse
                ? const Color(0xFFE53935).withOpacity(0.05)
                : isToday
                    ? const Color(0xFF6C63FF).withOpacity(0.04)
                    : const Color(0xFF141428),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: isToday ? 1.5 : 1),
      ),
      child: Row(children: [
        // Date badge
        Container(
          width: 44, height: 44, // was 40x40
          decoration: BoxDecoration(
            color: isToday
                ? const Color(0xFF6C63FF).withOpacity(0.15)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: isToday
                ? Border.all(
                    color: const Color(0xFF6C63FF).withOpacity(0.3), width: 1)
                : null,
          ),
          child: Center(child: Text('${entry.date.day}',
              style: TextStyle(
                  color: isToday ? const Color(0xFF6C63FF) : Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15))), // was 14
        ),
        const SizedBox(width: 10),

        // Day name + date
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(entry.dayLabel,
                  style: TextStyle(
                      color: isToday ? const Color(0xFF6C63FF) : Colors.white,
                      fontSize: 15,        // was 13
                      fontWeight: FontWeight.w700)),
              if (isToday) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Text('NOW',
                      style: TextStyle(color: Color(0xFF6C63FF),
                          fontSize: 9, fontWeight: FontWeight.w800,
                          letterSpacing: 0.8)),
                ),
              ],
              if (isYest) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text('YEST',
                      style: TextStyle(color: Colors.white.withOpacity(0.35),
                          fontSize: 9, fontWeight: FontWeight.w700)),
                ),
              ],
            ]),
            Text(entry.formattedDate,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 11)),        // was 10
          ],
        )),

        // Buttons
        Row(children: [
          _InlineBtn(
              icon: Icons.check_rounded, label: 'Clean',
              color: const Color(0xFF00C4A0),
              selected: isSuccess, onTap: onSuccessTapped),
          const SizedBox(width: 6),
          _InlineBtn(
              icon: Icons.close_rounded, label: 'Relapse',
              color: const Color(0xFFE53935),
              selected: isRelapse, onTap: onRelapseTapped),
        ]),
      ]),
    );
  }
}

class _InlineBtn extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final bool     selected;
  final VoidCallback onTap;

  const _InlineBtn({required this.icon, required this.label,
      required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), // was 9,6
      decoration: BoxDecoration(
        color: selected ? color : color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
            color: selected ? color : color.withOpacity(0.2), width: 1.2),
        boxShadow: selected
            ? [BoxShadow(color: color.withOpacity(0.3),
                blurRadius: 6, offset: const Offset(0, 2))]
            : [],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13,         // was 12
            color: selected ? Colors.white : color.withOpacity(0.7)),
        const SizedBox(width: 4),    // was 3
        Text(label, style: TextStyle(
            color: selected ? Colors.white : color.withOpacity(0.7),
            fontSize: 11,            // was 10
            fontWeight: FontWeight.w700)),
      ]),
    ),
  );
}

class _ToolbarBtn extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final VoidCallback onTap;

  const _ToolbarBtn({required this.icon, required this.label,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), // was 12,7
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: color),  // was 14
        const SizedBox(width: 5),
        Text(label, style: TextStyle(
          color: color,
          fontSize: 13,        // was 12
          fontWeight: FontWeight.w600,
        )),
      ]),
    ),
  );
}

class _Chip extends StatelessWidget {
  final String label;
  final Color  color;
  final IconData icon;

  const _Chip({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6), // was 10,5
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.2), width: 1),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),  // was 12
      const SizedBox(width: 4),
      Text(label, style: TextStyle(
        color: color,
        fontSize: 12,        // was 11
        fontWeight: FontWeight.w600,
      )),
    ]),
  );
}