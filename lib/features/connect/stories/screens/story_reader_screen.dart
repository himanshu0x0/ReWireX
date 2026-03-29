// ============================================================
// PATH: lib/features/connect/stories/screens/story_reader_screen.dart
// ============================================================
 
import 'package:flutter/material.dart';
import 'package:rewirex/features/connect/stories/models/story_model.dart';
import 'package:rewirex/features/connect/stories/services/story_service.dart';

class StoryReaderScreen extends StatelessWidget {
  final StoryModel story;
  final StoryService svc;
  const StoryReaderScreen(
      {super.key, required this.story, required this.svc});
 
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
      actions: [IconButton(
          icon: Icon(
              story.likedByMe
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: story.likedByMe
                  ? const Color(0xFFEF5350)
                  : Colors.white.withOpacity(0.5)),
          onPressed: () => svc.toggleLike(story.id))]),
    body: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
      child: Column(children: [
        Center(child: Text(story.coverEmoji,
            style: const TextStyle(fontSize: 64))),
        const SizedBox(height: 20),
        Text(story.title, textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 22,
                fontWeight: FontWeight.w800, height: 1.3)),
        const SizedBox(height: 12),
        Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(story.isAnonymous
              ? 'Anonymous Warrior' : story.authorName,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.45), fontSize: 13)),
          if (story.streak > 0) ...[
            const SizedBox(width: 8),
            Text('🔥 ${story.streak}d streak',
                style: const TextStyle(
                    color: Color(0xFF00C4A0),
                    fontSize: 12, fontWeight: FontWeight.w600))]])),
        const SizedBox(height: 24),
        Container(padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFF141428),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withOpacity(0.07))),
          child: Text(story.content, style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16, height: 1.8))),
        const SizedBox(height: 20),
        if (story.tags.isNotEmpty)
          Wrap(spacing: 8, runSpacing: 8,
            children: story.tags.map((t) => Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFF6C63FF).withOpacity(0.2))),
              child: Text('#$t', style: const TextStyle(
                  color: Color(0xFF6C63FF),
                  fontSize: 12)))).toList())])));
}