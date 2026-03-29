import 'package:flutter/material.dart';
import 'package:rewirex/features/connect/stories/models/story_model.dart';
import 'package:rewirex/features/connect/stories/screens/story_reader_screen.dart';
import 'package:rewirex/features/connect/stories/services/story_service.dart';

class StoryCard extends StatelessWidget {
  final StoryModel story;
  final StoryService svc;
  const StoryCard({super.key, required this.story, required this.svc});
 
  Widget _chip(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10)),
    child: Text(t, style: TextStyle(
        color: c, fontSize: 10, fontWeight: FontWeight.w600)));
 
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {
      svc.incrementRead(story.id);
      Navigator.push(context, MaterialPageRoute(
          builder: (_) => StoryReaderScreen(story: story, svc: svc)));
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF141428),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Container(width: 56, height: 56,
          decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFF6C63FF).withOpacity(0.2))),
          child: Center(child: Text(story.coverEmoji,
              style: const TextStyle(fontSize: 28)))),
        const SizedBox(width: 14),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(story.title, style: const TextStyle(
              color: Colors.white, fontSize: 15,
              fontWeight: FontWeight.w700),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(story.isAnonymous
              ? 'Anonymous Warrior' : story.authorName,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12)),
          const SizedBox(height: 8),
          Text(story.content, maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12, height: 1.4)),
          const SizedBox(height: 10),
          Row(children: [
            _chip(story.category, const Color(0xFF6C63FF)),
            const SizedBox(width: 6),
            if (story.streak > 0)
              _chip('🔥 ${story.streak}d', const Color(0xFF00C4A0)),
            const Spacer(),
            GestureDetector(
              onTap: () => svc.toggleLike(story.id),
              child: Row(children: [
                Icon(story.likedByMe
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                    size: 15,
                    color: story.likedByMe
                        ? const Color(0xFFEF5350)
                        : Colors.white.withOpacity(0.3)),
                const SizedBox(width: 4),
                Text('${story.likes}', style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 11))])),
            const SizedBox(width: 10),
            Icon(Icons.visibility_outlined, size: 14,
                color: Colors.white.withOpacity(0.25)),
            const SizedBox(width: 4),
            Text('${story.readCount}', style: TextStyle(
                color: Colors.white.withOpacity(0.25),
                fontSize: 11))])]))])));
  }