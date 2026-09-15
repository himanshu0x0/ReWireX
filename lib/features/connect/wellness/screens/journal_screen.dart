import 'package:flutter/material.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key, this.returnAfterSave = false});

  final bool returnAfterSave;
  @override State<JournalScreen> createState() => _JournalState();
}
 
class _JournalState extends State<JournalScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final List<Map<String, String>> _entries = [];
 
  static const _prompts = [
    'What triggered me today and how did I handle it?',
    'Three things I\'m grateful for right now…',
    'What does my recovery mean to me today?',
    'One thing I\'m proud of myself for this week…',
    'What do I need most right now?',
  ];
 
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
 
  void _save() {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() {
      _entries.insert(0, {
        'text': _ctrl.text.trim(),
        'time': DateTime.now().toString().substring(0, 16)
      });
      _ctrl.clear();
    });
    FocusScope.of(context).unfocus();

    if (widget.returnAfterSave && mounted) {
      Navigator.of(context).pop(true);
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
      title: const Text('Journal', style: TextStyle(
          color: Colors.white, fontSize: 20,
          fontWeight: FontWeight.w800))),
    body: Column(children: [
      // Daily prompt
      Container(
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFF6C63FF).withOpacity(0.2))),
        child: Row(children: [
          const Text('💡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(child: Text(
              _prompts[DateTime.now().hour % _prompts.length],
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13, height: 1.4)))])),
      // Input
      Padding(padding: const EdgeInsets.all(20),
        child: Row(children: [
          Expanded(child: TextField(
            controller: _ctrl, maxLines: 3,
            style: const TextStyle(
                color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Write freely…',
              hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.25)),
              filled: true, fillColor: const Color(0xFF141428),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.1))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.1))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: Color(0xFF6C63FF), width: 1.5)),
              contentPadding: const EdgeInsets.all(14)))),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _save,
            child: Container(width: 46, height: 46,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [
                    Color(0xFF6C63FF), Color(0xFF00C4A0)])),
              child: const Icon(Icons.save_rounded,
                  color: Colors.white, size: 20)))])),
      // Entries
      Expanded(child: _entries.isEmpty
          ? Center(child: Text(
              'Your journal entries will appear here',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 14)))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              itemCount: _entries.length,
              itemBuilder: (_, i) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: const Color(0xFF141428),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.07))),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(_entries[i]['time']!, style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 11)),
                  const SizedBox(height: 6),
                  Text(_entries[i]['text']!, style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13, height: 1.5))]))))]));
}
 