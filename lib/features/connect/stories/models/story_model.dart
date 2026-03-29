// ============================================================
// PATH: lib/features/connect/stories/models/story_model.dart
// ============================================================
 
import 'package:cloud_firestore/cloud_firestore.dart';
 
class StoryModel {
  final String id, authorUid, authorName, title, content,
      category, coverEmoji;
  final int    likes, readCount, streak;
  final bool   likedByMe, isAnonymous;
  final DateTime createdAt;
  final List<String> tags;
 
  const StoryModel({
    required this.id, required this.authorUid,
    required this.authorName, required this.title,
    required this.content, required this.category,
    this.coverEmoji = '📖', this.likes = 0, this.readCount = 0,
    this.streak = 0, this.likedByMe = false,
    this.isAnonymous = false, required this.createdAt,
    this.tags = const [],
  });
 
  factory StoryModel.fromMap(String id, Map<String, dynamic> d,
      String myUid) {
    final liked = (d['likedBy'] as List<dynamic>? ?? [])
        .map((e) => e.toString()).toList();
    return StoryModel(
      id: id,
      authorUid:   d['authorUid']   as String? ?? '',
      authorName:  d['authorName']  as String? ?? 'Anonymous',
      title:       d['title']       as String? ?? '',
      content:     d['content']     as String? ?? '',
      category:    d['category']    as String? ?? 'Recovery',
      coverEmoji:  d['coverEmoji']  as String? ?? '📖',
      likes:       liked.length,
      readCount:   (d['readCount']  as num?)?.toInt() ?? 0,
      streak:      (d['streak']     as num?)?.toInt() ?? 0,
      likedByMe:   liked.contains(myUid),
      isAnonymous: d['isAnonymous'] as bool? ?? false,
      createdAt:   d['createdAt'] is Timestamp
          ? (d['createdAt'] as Timestamp).toDate() : DateTime.now(),
      tags: List<String>.from(d['tags'] ?? []),
    );
  }
 
  Map<String, dynamic> toMap() => {
    'authorUid': authorUid, 'authorName': authorName,
    'title': title, 'content': content, 'category': category,
    'coverEmoji': coverEmoji, 'readCount': readCount,
    'streak': streak, 'isAnonymous': isAnonymous,
    'createdAt': Timestamp.fromDate(createdAt),
    'tags': tags, 'likedBy': [],
  };
}