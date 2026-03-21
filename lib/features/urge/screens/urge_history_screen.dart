// lib/features/urge/screens/urge_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/urge_service.dart';
import '../models/urge_model.dart';
import '../data/urge_data.dart';

class UrgeHistoryScreen extends StatefulWidget {
  const UrgeHistoryScreen({super.key});

  @override
  State<UrgeHistoryScreen> createState() => _UrgeHistoryScreenState();
}

class _UrgeHistoryScreenState extends State<UrgeHistoryScreen>
    with SingleTickerProviderStateMixin {
  final UrgeService _urgeService = UrgeService();

  // ── Filter state ─────────────────────────────────────────────
  String _filterEmotion = 'All';
  String _filterIntensity = 'All'; // 'All' | 'Low' | 'Medium' | 'High'
  int _filterDays = 30;

  // ── Stats state ──────────────────────────────────────────────
  UrgeStats? _stats;
  bool _statsLoading = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
    _loadStats();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _statsLoading = true);
    try {
      final stats = await _urgeService.getUrgeStats(days: _filterDays);
      if (mounted) {
        setState(() {
        _stats = stats;
        _statsLoading = false;
      });
      }
    } catch (_) {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  // ── Filter urges ─────────────────────────────────────────────
  List<UrgeModel> _applyFilters(List<UrgeModel> urges) {
    final cutoff = DateTime.now().subtract(Duration(days: _filterDays));
    return urges.where((u) {
      if (u.timestamp.isBefore(cutoff)) return false;
      if (_filterEmotion != 'All' && u.emotion != _filterEmotion) {
        return false;
      }
      if (_filterIntensity == 'Low' && u.intensity > 3) return false;
      if (_filterIntensity == 'Medium' &&
          (u.intensity < 4 || u.intensity > 6)) {
        return false;
      }
      if (_filterIntensity == 'High' && u.intensity < 7) return false;
      return true;
    }).toList();
  }

  // ── Group urges by date ──────────────────────────────────────
  Map<String, List<UrgeModel>> _groupByDate(List<UrgeModel> urges) {
    final map = <String, List<UrgeModel>>{};
    for (final u in urges) {
      final key = _dateLabel(u.timestamp);
      map.putIfAbsent(key, () => []).add(u);
    }
    return map;
  }

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('EEEE, MMM d').format(dt);
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildStatsRow(),
              _buildFilterBar(),
              const SizedBox(height: 4),
              Expanded(child: _buildUrgeList()),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(11),
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
                  'Urge History',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Last $_filterDays days',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Time range selector
          _TimeRangeChip(
            selected: _filterDays,
            onChanged: (v) {
              setState(() => _filterDays = v);
              _loadStats();
            },
          ),
        ],
      ),
    );
  }

  // ── Stats row ─────────────────────────────────────────────────
  Widget _buildStatsRow() {
    if (_statsLoading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: SizedBox(
          height: 90,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF6C63FF),
            ),
          ),
        ),
      );
    }

    if (_stats == null || _stats!.totalUrges == 0) {
      return const SizedBox(height: 8);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          _StatCard(
            label: 'Total Urges',
            value: '${_stats!.totalUrges}',
            icon: Icons.flash_on_rounded,
            color: const Color(0xFF6C63FF),
          ),
          const SizedBox(width: 10),
          _StatCard(
            label: 'Avg Intensity',
            value: _stats!.avgIntensity.toStringAsFixed(1),
            icon: Icons.bar_chart_rounded,
            color: _intensityColor(_stats!.avgIntensity),
          ),
          const SizedBox(width: 10),
          _StatCard(
            label: 'High Risk',
            value: '${_stats!.highIntensityCount}',
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFFE53935),
          ),
          const SizedBox(width: 10),
          _StatCard(
            label: 'Peak Hour',
            value: _formatHour(_stats!.peakHour),
            icon: Icons.access_time_rounded,
            color: const Color(0xFF00C4A0),
          ),
        ],
      ),
    );
  }

  Color _intensityColor(double v) {
    if (v <= 3) return const Color(0xFF00C853);
    if (v <= 5) return const Color(0xFFFFD600);
    if (v <= 7) return const Color(0xFFFF6D00);
    return const Color(0xFFE53935);
  }

  String _formatHour(int h) {
    if (h == 0) return '12am';
    if (h < 12) return '${h}am';
    if (h == 12) return '12pm';
    return '${h - 12}pm';
  }

  // ── Filter bar ───────────────────────────────────────────────
  Widget _buildFilterBar() {
    final uniqueEmotions = ['All', ...allEmotions.map((e) => e.name)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Text(
            'FILTER BY EMOTION',
            style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: uniqueEmotions.length,
            itemBuilder: (context, i) {
              final em = uniqueEmotions[i];
              final isSelected = _filterEmotion == em;
              final data = em == 'All'
                  ? null
                  : allEmotions
                      .firstWhere((e) => e.name == em,
                          orElse: () => const EmotionData(
                              name: '', emoji: '', colorValue: 0xFF607D8B))
                  ;
              final col = data != null
                  ? Color(data.colorValue)
                  : const Color(0xFF6C63FF);

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _filterEmotion = em);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: isSelected
                        ? col.withOpacity(0.2)
                        : Colors.white.withOpacity(0.06),
                    border: Border.all(
                      color: isSelected
                          ? col
                          : Colors.transparent,
                      width: 1.3,
                    ),
                  ),
                  child: Text(
                    em == 'All'
                        ? 'All'
                        : '${data?.emoji ?? ''}  $em',
                    style: TextStyle(
                      color: isSelected
                          ? col
                          : Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // Intensity quick filters
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: ['All', 'Low', 'Medium', 'High'].map((label) {
              final isSelected = _filterIntensity == label;
              final col = label == 'Low'
                  ? const Color(0xFF00C853)
                  : label == 'Medium'
                      ? const Color(0xFFFF6D00)
                      : label == 'High'
                          ? const Color(0xFFE53935)
                          : const Color(0xFF6C63FF);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _filterIntensity = label);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isSelected
                        ? col.withOpacity(0.18)
                        : Colors.white.withOpacity(0.05),
                    border: Border.all(
                      color: isSelected
                          ? col.withOpacity(0.6)
                          : Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? col
                          : Colors.white.withOpacity(0.45),
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Main list ────────────────────────────────────────────────
  Widget _buildUrgeList() {
    return StreamBuilder<List<UrgeModel>>(
      stream: _urgeService.getUrges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF6C63FF),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Something went wrong',
              style: TextStyle(color: Colors.white.withOpacity(0.4)),
            ),
          );
        }

        final allUrges = snapshot.data ?? [];
        final filtered = _applyFilters(allUrges);

        if (filtered.isEmpty) {
          return _buildEmpty(allUrges.isEmpty);
        }

        final grouped = _groupByDate(filtered);
        final dateKeys = grouped.keys.toList();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          itemCount: dateKeys.length,
          itemBuilder: (context, di) {
            final dateKey = dateKeys[di];
            final dayUrges = grouped[dateKey]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateHeader(dateKey, dayUrges),
                const SizedBox(height: 8),
                ...dayUrges.asMap().entries.map((entry) {
                  return _UrgeCard(
                    urge: entry.value,
                    onDelete: () => _confirmDelete(entry.value),
                  );
                }),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDateHeader(String label, List<UrgeModel> dayUrges) {
    final avgInt =
        dayUrges.map((u) => u.intensity).reduce((a, b) => a + b) /
            dayUrges.length;
    final color = _intensityColor(avgInt);
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.9,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${dayUrges.length} urge${dayUrges.length != 1 ? 's' : ''}',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(bool noData) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            noData
                ? Icons.assignment_outlined
                : Icons.filter_list_off_rounded,
            size: 48,
            color: Colors.white.withOpacity(0.12),
          ),
          const SizedBox(height: 16),
          Text(
            noData ? 'No urges logged yet' : 'No results for this filter',
            style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            noData
                ? 'Your urge history will appear here'
                : 'Try changing your filter options',
            style: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ── Delete ───────────────────────────────────────────────────
  Future<void> _confirmDelete(UrgeModel urge) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF13131F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Delete this urge log?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFFE53935).withOpacity(0.4)),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          color: Color(0xFFE53935),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      await _urgeService.deleteUrge(urge.id);
      _loadStats();
    }
  }
}

// ─────────────────────────────────────────────────────────────
//  URGE CARD
// ─────────────────────────────────────────────────────────────
class _UrgeCard extends StatelessWidget {
  final UrgeModel urge;
  final VoidCallback onDelete;

  const _UrgeCard({required this.urge, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final emotion = emotionByName(urge.emotion);
    final intensityColor = Color(urge.intensityColorValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onLongPress: onDelete,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: type + time
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        urge.type,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm').format(urge.timestamp),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Row 2: chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    // Emotion
                    _Chip(
                      label: '${emotion.emoji}  ${urge.emotion}',
                      color: Color(emotion.colorValue),
                    ),
                    // Intensity
                    _Chip(
                      label: '${urge.intensityLabel}  ${urge.intensity}/10',
                      color: intensityColor,
                    ),
                    // Trigger
                    if (urge.trigger.isNotEmpty)
                      _Chip(
                        label: urge.trigger,
                        color: Colors.white.withOpacity(0.3),
                        subtle: true,
                      ),
                    // Context
                    if (urge.context.isNotEmpty)
                      _Chip(
                        label: urge.context,
                        color: Colors.white.withOpacity(0.2),
                        subtle: true,
                      ),
                    // Body location
                    if (urge.bodyLocation.isNotEmpty)
                      _Chip(
                        label: urge.bodyLocation,
                        color: const Color(0xFF6C63FF).withOpacity(0.6),
                        subtle: true,
                      ),
                  ],
                ),
                // Notes
                if (urge.notes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.format_quote_rounded,
                            size: 14,
                            color: Colors.white.withOpacity(0.25)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            urge.notes,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12.5,
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Long-press hint
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Hold to delete',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.15),
                      fontSize: 10.5,
                    ),
                  ),
                ),
              ],
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
  final bool subtle;

  const _Chip({
    required this.label,
    required this.color,
    this.subtle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: subtle
            ? Colors.white.withOpacity(0.05)
            : color.withOpacity(0.15),
        border: Border.all(
          color: subtle
              ? Colors.white.withOpacity(0.08)
              : color.withOpacity(0.35),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: subtle ? Colors.white.withOpacity(0.45) : color,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeRangeChip extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _TimeRangeChip(
      {required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [7, 30, 90].map((days) {
        final isSelected = selected == days;
        return GestureDetector(
          onTap: () => onChanged(days),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(left: 6),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: isSelected
                  ? const Color(0xFF6C63FF).withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF6C63FF).withOpacity(0.5)
                    : Colors.transparent,
              ),
            ),
            child: Text(
              '${days}d',
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF6C63FF)
                    : Colors.white.withOpacity(0.35),
                fontSize: 11.5,
                fontWeight: isSelected
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}