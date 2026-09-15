// lib/features/urge/screens/urge_trigger_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/urge_data.dart';
import '../models/urge_session_model.dart';
import 'urge_need_screen.dart';

/// Captures trigger/context/body signals for an existing urge session.
///
/// This screen only enriches the current rescue session. It never records a
/// relapse and never changes streak state.
class UrgeTriggerScreen extends StatefulWidget {
  final UrgeSessionModel session;

  const UrgeTriggerScreen({super.key, required this.session});

  @override
  State<UrgeTriggerScreen> createState() => _UrgeTriggerScreenState();
}

class _UrgeTriggerScreenState extends State<UrgeTriggerScreen> {
  late String _trigger;
  late String _context;
  late String _bodyLocation;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _trigger = widget.session.trigger;
    _context = widget.session.context;
    _bodyLocation = widget.session.bodyLocation;
    _notesController = TextEditingController(text: widget.session.notes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _toggle(String current, String value, void Function(String) setValue) {
    HapticFeedback.selectionClick();
    setState(() => setValue(current == value ? '' : value));
  }

  void _continue() {
    HapticFeedback.mediumImpact();
    final now = DateTime.now();
    final updated = widget.session.copyWith(
      trigger: _trigger.trim(),
      context: _context.trim(),
      bodyLocation: _bodyLocation.trim(),
      notes: _notesController.text.trim(),
      updatedAt: now,
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => UrgeNeedScreen(session: updated)),
    );
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
          'Understand the trigger',
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
                    _buildIntro(),
                    const SizedBox(height: 24),
                    _section('WHAT SET THIS OFF?', 'Choose the closest trigger.'),
                    const SizedBox(height: 12),
                    _buildTriggerChoices(),
                    const SizedBox(height: 28),
                    _section(
                      'WHERE / WHAT SITUATION?',
                      'Context helps identify repeat patterns.',
                    ),
                    const SizedBox(height: 12),
                    _buildContextChoices(),
                    const SizedBox(height: 28),
                    _section(
                      'WHERE DO YOU FEEL IT?',
                      'Notice the body signal without judging it.',
                    ),
                    const SizedBox(height: 12),
                    _buildBodyChoices(),
                    const SizedBox(height: 28),
                    _buildNotes(),
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

  Widget _buildIntro() {
    final intensity = (widget.session.urgeBefore ?? 0).clamp(0, 10).toInt();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.psychology_alt_rounded, color: Color(0xFF9B94FF)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Current urge: $intensity/10  •  '
              '${widget.session.emotion.isEmpty ? 'Emotion not specified' : widget.session.emotion}\n'
              'Noticing the trigger gives the rescue engine more useful context.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.62),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, String subtitle) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.38),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12),
          ),
        ],
      );

  Widget _buildTriggerChoices() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: allTriggers
            .map(
              (item) => _ChoiceChip(
                label: item.name,
                emoji: item.emoji,
                selected: _trigger == item.name,
                color: const Color(0xFF00C4A0),
                onTap: () => _toggle(_trigger, item.name, (v) => _trigger = v),
              ),
            )
            .toList(),
      );

  Widget _buildContextChoices() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: allContexts
            .map(
              (item) => _ChoiceChip(
                label: item.name,
                emoji: item.emoji,
                selected: _context == item.name,
                color: const Color(0xFF6C63FF),
                onTap: () => _toggle(_context, item.name, (v) => _context = v),
              ),
            )
            .toList(),
      );

  Widget _buildBodyChoices() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: bodyLocations
            .map(
              (location) => _ChoiceChip(
                label: location,
                selected: _bodyLocation == location,
                color: const Color(0xFFFFB74D),
                onTap: () => _toggle(
                  _bodyLocation,
                  location,
                  (v) => _bodyLocation = v,
                ),
              ),
            )
            .toList(),
      );

  Widget _buildNotes() => Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.045),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: TextField(
          controller: _notesController,
          minLines: 4,
          maxLines: 7,
          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
          decoration: InputDecoration(
            hintText: 'Anything else worth remembering about this moment?',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.28), fontSize: 13),
            prefixIcon: const Icon(Icons.notes_rounded, color: Color(0xFF6C63FF)),
            prefixIconConstraints: const BoxConstraints(minWidth: 50, minHeight: 50),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
          ),
        ),
      );

  Widget _buildBottomBar() => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D1A),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: _continue,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continue to rescue planning',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 19),
              ],
            ),
          ),
        ),
      );
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final String? emoji;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ChoiceChip({
    required this.label,
    this.emoji,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              color: selected ? color.withOpacity(0.16) : Colors.white.withOpacity(0.05),
              border: Border.all(
                color: selected ? color.withOpacity(0.85) : Colors.white.withOpacity(0.09),
                width: selected ? 1.3 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (emoji != null) ...[
                  Text(emoji!, style: const TextStyle(fontSize: 15)),
                  const SizedBox(width: 7),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? color : Colors.white.withOpacity(0.68),
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.check_rounded, size: 14, color: color),
                ],
              ],
            ),
          ),
        ),
      );
}
