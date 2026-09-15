// ============================================================
// PATH: lib/features/connect/stories/models/story_model.dart
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class StoryChapter {
  final String title;
  final String content;
  final String cliffhanger;

  const StoryChapter({
    required this.title,
    required this.content,
    required this.cliffhanger,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'content': content,
        'cliffhanger': cliffhanger,
      };

  factory StoryChapter.fromMap(Map<String, dynamic> map) {
    return StoryChapter(
      title: map['title'] as String? ?? 'Chapter',
      content: map['content'] as String? ?? '',
      cliffhanger: map['cliffhanger'] as String? ?? '',
    );
  }
}

class StoryModel {
  final String id;
  final String authorUid;
  final String authorName;
  final String title;
  final String content;
  final String category;
  final String coverEmoji;
  final int likes;
  final int readCount;
  final int streak;
  final bool likedByMe;
  final bool isAnonymous;
  final bool isFeatured;
  final String? sourceName;
  final String? sourceUrl;
  final DateTime createdAt;
  final List<String> tags;
  final List<StoryChapter> chapters;

  const StoryModel({
    required this.id,
    required this.authorUid,
    required this.authorName,
    required this.title,
    required this.content,
    required this.category,
    this.coverEmoji = '📖',
    this.likes = 0,
    this.readCount = 0,
    this.streak = 0,
    this.likedByMe = false,
    this.isAnonymous = false,
    this.isFeatured = false,
    this.sourceName,
    this.sourceUrl,
    required this.createdAt,
    this.tags = const [],
    this.chapters = const [],
  });

  factory StoryModel.fromMap(
    String id,
    Map<String, dynamic> d,
    String myUid,
  ) {
    final liked = (d['likedBy'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    final rawChapters = d['chapters'] as List<dynamic>? ?? [];

    return StoryModel(
      id: id,
      authorUid: d['authorUid'] as String? ?? '',
      authorName: d['authorName'] as String? ?? 'Anonymous',
      title: d['title'] as String? ?? '',
      content: d['content'] as String? ?? '',
      category: d['category'] as String? ?? 'Recovery',
      coverEmoji: d['coverEmoji'] as String? ?? '📖',
      likes: liked.length,
      readCount: (d['readCount'] as num?)?.toInt() ?? 0,
      streak: (d['streak'] as num?)?.toInt() ?? 0,
      likedByMe: liked.contains(myUid),
      isAnonymous: d['isAnonymous'] as bool? ?? false,
      isFeatured: d['isFeatured'] as bool? ?? false,
      sourceName: d['sourceName'] as String?,
      sourceUrl: d['sourceUrl'] as String?,
      createdAt: d['createdAt'] is Timestamp
          ? (d['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      tags: (d['tags'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      chapters: rawChapters
          .whereType<Map>()
          .map((e) => StoryChapter.fromMap(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'authorUid': authorUid,
        'authorName': authorName,
        'title': title,
        'content': content,
        'category': category,
        'coverEmoji': coverEmoji,
        'readCount': readCount,
        'streak': streak,
        'isAnonymous': isAnonymous,
        'isFeatured': isFeatured,
        'sourceName': sourceName,
        'sourceUrl': sourceUrl,
        'createdAt': Timestamp.fromDate(createdAt),
        'tags': tags,
        'likedBy': <String>[],
        'chapters': chapters.map((e) => e.toMap()).toList(),
      };
}
