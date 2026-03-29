// ============================================================
// PATH: lib/features/connect/stories/screens/write_story_screen.dart
// ============================================================
 
import 'package:flutter/material.dart';
import 'package:rewirex/features/connect/stories/services/story_service.dart';

class WriteStoryScreen extends StatefulWidget {
  const WriteStoryScreen({super.key});
  @override State<WriteStoryScreen> createState() => _WriteStoryState();
}
 
class _WriteStoryState extends State<WriteStoryScreen> {
  final StoryService          _svc    = StoryService();
  final TextEditingController _title  = TextEditingController();
  final TextEditingController _body   = TextEditingController();
  final TextEditingController _tags   = TextEditingController();
  String _category   = 'Recovery';
  String _emoji      = '📖';
  bool   _anonymous  = false;
  bool   _publishing = false;
 
  static const _cats  = [
    'Recovery', 'Motivation', 'Relapse', 'Milestone', 'Life'];
  static const _emojis = [
    '📖','🔥','💪','🌱','⚔️','🌟','💎','🙏','🚀','❤️'];
 
  @override void dispose() {
    _title.dispose(); _body.dispose(); _tags.dispose(); super.dispose();
  }
 
  Future<void> _publish() async {
    if (_title.text.trim().isEmpty ||
        _body.text.trim().length < 50 || _publishing) return;
    setState(() => _publishing = true);
    try {
      final tags = _tags.text.trim().isEmpty
          ? <String>[]
          : _tags.text.split(',')
              .map((t) => t.trim())
              .where((t) => t.isNotEmpty)
              .toList();
      await _svc.publishStory(
        title:       _title.text.trim(),
        content:     _body.text.trim(),
        category:    _category,
        coverEmoji:  _emoji,
        isAnonymous: _anonymous,
        tags:        tags,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Story published! 🎉'),
          backgroundColor: Color(0xFF00C4A0),
          behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }
 
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0D0D1A),
    appBar: AppBar(
      backgroundColor: const Color(0xFF0D0D1A), elevation: 0,
      leading: IconButton(
        icon: Container(width: 36, height: 36,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.arrow_back_ios_new_rounded, size: 15,
              color: Colors.white.withOpacity(0.7))),
        onPressed: () => Navigator.pop(context)),
      title: const Text('Write Your Story', style: TextStyle(
          color: Colors.white, fontSize: 20,
          fontWeight: FontWeight.w800))),
    body: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        _sect('COVER EMOJI'),
        SizedBox(height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _emojis.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => setState(() => _emoji = _emojis[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48, height: 48,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: _emoji == _emojis[i]
                      ? const Color(0xFF6C63FF).withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
                  border: Border.all(
                      color: _emoji == _emojis[i]
                          ? const Color(0xFF6C63FF)
                          : Colors.transparent,
                      width: 2)),
                child: Center(child: Text(_emojis[i],
                    style: const TextStyle(fontSize: 24))))))),
        const SizedBox(height: 20),
        _sect('TITLE'),
        _field(_title, 'Your story title…'),
        const SizedBox(height: 20),
        _sect('YOUR STORY'),
        TextField(
          controller: _body, maxLines: 10,
          style: TextStyle(
              color: Colors.white.withOpacity(0.85), fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Share your journey, struggles, wins…\n\n(minimum 50 characters)',
            hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.2), height: 1.7),
            filled: true, fillColor: const Color(0xFF141428),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.1))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.1))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                    color: Color(0xFF6C63FF), width: 1.5)),
            contentPadding: const EdgeInsets.all(16))),
        const SizedBox(height: 20),
        _sect('CATEGORY'),
        Wrap(spacing: 8, runSpacing: 8,
          children: _cats.map((c) => GestureDetector(
            onTap: () => setState(() => _category = c),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                  color: _category == c
                      ? const Color(0xFF6C63FF).withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _category == c
                          ? const Color(0xFF6C63FF)
                          : Colors.white.withOpacity(0.1))),
              child: Text(c, style: TextStyle(
                  color: _category == c
                      ? const Color(0xFF6C63FF)
                      : Colors.white.withOpacity(0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.w600))))).toList()),
        const SizedBox(height: 20),
        _sect('TAGS (comma separated)'),
        _field(_tags, 'e.g. hope, 30days, alcohol'),
        const SizedBox(height: 16),
        Row(children: [
          Switch(
            value: _anonymous,
            onChanged: (v) => setState(() => _anonymous = v),
            activeColor: const Color(0xFF6C63FF)),
          const SizedBox(width: 8),
          Text('Post anonymously', style: TextStyle(
              color: Colors.white.withOpacity(0.7), fontSize: 14))]),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)]),
              boxShadow: [BoxShadow(
                  color: const Color(0xFF6C63FF).withOpacity(0.4),
                  blurRadius: 20, offset: const Offset(0, 8))]),
            child: ElevatedButton.icon(
              onPressed: _publishing ? null : _publish,
              icon: _publishing
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.publish_rounded,
                      color: Colors.white),
              label: Text(
                  _publishing ? 'Publishing…' : 'Publish Story',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(18))))))])));
 
  Widget _sect(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(t, style: TextStyle(
        color: Colors.white.withOpacity(0.35), fontSize: 11,
        fontWeight: FontWeight.w700, letterSpacing: 2)));
 
  Widget _field(TextEditingController c, String hint) => TextField(
    controller: c,
    style: const TextStyle(color: Colors.white, fontSize: 15),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
      filled: true, fillColor: const Color(0xFF141428),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
              color: Color(0xFF6C63FF), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14)));
}
 