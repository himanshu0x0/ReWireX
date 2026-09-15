// ============================================================
// PATH: lib/features/connect/stories/screens/story_listview_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:rewirex/features/connect/stories/models/story_model.dart';
import 'package:rewirex/features/connect/stories/screens/story_card_screen.dart';
import 'package:rewirex/features/connect/stories/services/story_service.dart';

class StoryListView extends StatelessWidget {
  final Stream<List<StoryModel>> stream;
  final StoryService svc;

  const StoryListView({
    super.key,
    required this.stream,
    required this.svc,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StoryModel>>(
      stream: stream,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting &&
            !snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF6C63FF),
              strokeWidth: 2.5,
            ),
          );
        }

        // The StoryService intentionally keeps featured stories available
        // even when Firestore is unavailable.
        final stories = snap.data ?? const <StoryModel>[];

        if (stories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('📖', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  'No stories available right now.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          itemCount: stories.length,
          itemBuilder: (_, index) {
            return StoryCard(
              story: stories[index],
              svc: svc,
            );
          },
        );
      },
    );
  }
}
