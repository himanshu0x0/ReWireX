// ============================================================
// PATH: lib/features/connect/stories/services/story_service.dart
// ============================================================
 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rewirex/features/connect/stories/models/story_model.dart';
 
class StoryService {
  final FirebaseFirestore _db   = FirebaseFirestore.instance;
  final FirebaseAuth      _auth = FirebaseAuth.instance;
  String get _uid => _auth.currentUser?.uid ?? '';
 
  Stream<List<StoryModel>> allStream() => _db
      .collection('stories')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs
          .map((d) => StoryModel.fromMap(d.id, d.data(), _uid))
          .toList());
 
  Stream<List<StoryModel>> byCategoryStream(String cat) => _db
      .collection('stories')
      .where('category', isEqualTo: cat)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs
          .map((d) => StoryModel.fromMap(d.id, d.data(), _uid))
          .toList());
 
  Future<void> publishStory({
    required String title, required String content,
    required String category, required String coverEmoji,
    required bool isAnonymous, required List<String> tags,
  }) async {
    final my     = (await _db.collection('users').doc(_uid).get()).data() ?? {};
    final streak = await _fetchStreak();
    await _db.collection('stories').add(StoryModel(
      id: '', authorUid: _uid,
      authorName: isAnonymous
          ? 'Anonymous Warrior'
          : my['displayName'] as String? ?? 'User',
      title: title, content: content, category: category,
      coverEmoji: coverEmoji, streak: streak,
      isAnonymous: isAnonymous, createdAt: DateTime.now(), tags: tags,
    ).toMap());
  }
 
  Future<void> toggleLike(String storyId) async {
    final ref   = _db.collection('stories').doc(storyId);
    final likes = List<String>.from(
        ((await ref.get()).data()?['likedBy'] as List<dynamic>? ?? [])
            .map((e) => e.toString()));
    likes.contains(_uid) ? likes.remove(_uid) : likes.add(_uid);
    await ref.update({'likedBy': likes});
  }
 
  Future<void> incrementRead(String storyId) async =>
      _db.collection('stories').doc(storyId)
          .update({'readCount': FieldValue.increment(1)});
 
  Future<int> _fetchStreak() async {
    try {
      final s = await _db.collection('users').doc(_uid)
          .collection('stats').doc('streak').get();
      return (s.data()?['currentStreak'] as num?)?.toInt() ?? 0;
    } catch (_) { return 0; }
  }
}