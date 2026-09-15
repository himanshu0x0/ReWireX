// ============================================================
// PATH: lib/features/connect/stories/services/story_service.dart
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rewirex/features/connect/stories/data/featured_story_catalog.dart';
import 'package:rewirex/features/connect/stories/models/story_model.dart';

class StoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';

  /// Returns a broadcast stream so StreamBuilder rebuilds/navigation do not
  /// cause "Stream has already been listened to" errors.
  ///
  /// Featured stories are emitted immediately and do not depend on Firestore.
  Stream<List<StoryModel>> allStream() {
    final query = _db
        .collection('stories')
        .orderBy('createdAt', descending: true)
        .limit(50);

    return _buildStoryStream(query);
  }

  /// Same as [allStream], but only includes the selected category for
  /// Firestore stories. Featured stories are filtered locally.
  Stream<List<StoryModel>> byCategoryStream(String category) {
    final query = _db
        .collection('stories')
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true);

    return _buildStoryStream(query, category: category);
  }

  Stream<List<StoryModel>> _buildStoryStream(
    Query<Map<String, dynamic>> query, {
    String? category,
  }) {
    return Stream<List<StoryModel>>.multi(
      (controller) {
        final featured = _featuredStories(category);

        // Always show the trusted featured stories immediately.
        controller.add(featured);

        final subscription = query.snapshots().listen(
          (snapshot) {
            final remoteStories = snapshot.docs
                .map((doc) => StoryModel.fromMap(
                      doc.id,
                      doc.data(),
                      _uid,
                    ))
                .toList();

            controller.add(_mergeAndSort(featured, remoteStories));
          },
          onError: (Object error, StackTrace stackTrace) {
            // Featured stories must remain usable even when Firestore has:
            // - no stories collection yet
            // - a missing index
            // - temporary network/rules errors
            //
            // Do not forward the Firestore error to StreamBuilder because
            // that would replace the story UI with Flutter's red error screen.
            controller.add(featured);
          },
          onDone: controller.close,
        );

        controller.onCancel = subscription.cancel;
      },
      isBroadcast: true,
    );
  }

  List<StoryModel> _featuredStories(String? category) {
    final stories = FeaturedStoryCatalog.stories;

    if (category == null) {
      return List<StoryModel>.from(stories);
    }

    return stories
        .where((story) => story.category == category)
        .toList();
  }

  List<StoryModel> _mergeAndSort(
    List<StoryModel> featured,
    List<StoryModel> remoteStories,
  ) {
    final combined = <StoryModel>[
      ...featured,
      ...remoteStories,
    ];

    combined.sort((a, b) {
      if (a.isFeatured != b.isFeatured) {
        return a.isFeatured ? -1 : 1;
      }

      return b.createdAt.compareTo(a.createdAt);
    });

    return combined;
  }

  Future<void> publishStory({
    required String title,
    required String content,
    required String category,
    required String coverEmoji,
    required bool isAnonymous,
    required List<String> tags,
  }) async {
    if (_uid.isEmpty) {
      throw StateError('User must be authenticated to publish a story.');
    }

    final my =
        (await _db.collection('users').doc(_uid).get()).data() ?? {};
    final streak = await _fetchStreak();

    await _db.collection('stories').add(
          StoryModel(
            id: '',
            authorUid: _uid,
            authorName: isAnonymous
                ? 'Anonymous Warrior'
                : my['displayName'] as String? ?? 'User',
            title: title,
            content: content,
            category: category,
            coverEmoji: coverEmoji,
            streak: streak,
            isAnonymous: isAnonymous,
            isFeatured: false,
            createdAt: DateTime.now(),
            tags: tags,
          ).toMap(),
        );
  }

  Future<void> toggleLike(String storyId) async {
    // Featured stories are curated/read-only.
    if (_isFeatured(storyId)) return;

    if (_uid.isEmpty) {
      throw StateError('User must be authenticated.');
    }

    final ref = _db.collection('stories').doc(storyId);

    final rawLikedBy =
        (await ref.get()).data()?['likedBy'] as List<dynamic>? ?? [];

    final likes = rawLikedBy.map((e) => e.toString()).toList();

    likes.contains(_uid) ? likes.remove(_uid) : likes.add(_uid);

    await ref.update({'likedBy': likes});
  }

  Future<void> incrementRead(String storyId) async {
    // Featured stories have no Firestore document.
    if (_isFeatured(storyId)) return;

    await _db.collection('stories').doc(storyId).update(
      {'readCount': FieldValue.increment(1)},
    );
  }

  bool _isFeatured(String storyId) {
    return FeaturedStoryCatalog.stories.any(
      (story) => story.id == storyId,
    );
  }

  Future<int> _fetchStreak() async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(_uid)
          .collection('stats')
          .doc('streak')
          .get();

      return (snapshot.data()?['currentStreak'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }
}
