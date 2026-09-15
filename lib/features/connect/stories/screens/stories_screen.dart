// ============================================================
// PATH: lib/features/connect/stories/screens/stories_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:rewirex/features/connect/stories/models/story_model.dart';
import 'package:rewirex/features/connect/stories/screens/story_listview_screen.dart';
import 'package:rewirex/features/connect/stories/screens/write_story_screen.dart';
import 'package:rewirex/features/connect/stories/services/story_service.dart';

class StoriesScreen extends StatefulWidget {
  const StoriesScreen({super.key, this.rescueMode = false});

  final bool rescueMode;

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen>
    with SingleTickerProviderStateMixin {
  final StoryService _svc = StoryService();

  late TabController _tab;
  late final List<Stream<List<StoryModel>>> _streams;

  static const _cats = [
    'All',
    'Recovery',
    'Motivation',
    'Relapse',
    'Milestone',
    'Life',
  ];

  @override
  void initState() {
    super.initState();

    _tab = TabController(
      length: _cats.length,
      vsync: this,
    );

    // Create each stream once.
    //
    // This prevents StreamBuilder from repeatedly receiving new stream
    // instances during rebuilds and works together with StoryService's
    // broadcast streams.
    _streams = [
      _svc.allStream(),
      ..._cats.skip(1).map(_svc.byCategoryStream),
    ];
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 15,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFF6C63FF),
              Color(0xFF00C4A0),
            ],
          ).createShader(bounds),
          child: const Text(
            'Stories',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.edit_outlined,
              color: Color(0xFF6C63FF),
            ),
            tooltip: 'Write a story',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const WriteStoryScreen(),
              ),
            ),
          ),
          if (widget.rescueMode)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(
                  Icons.check_rounded,
                  size: 17,
                ),
                label: const Text('Done'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF00C4A0),
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: const Color(0xFF6C63FF),
          indicatorWeight: 2.5,
          labelColor: const Color(0xFF6C63FF),
          unselectedLabelColor: Colors.white.withOpacity(0.35),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          tabs: _cats.map((cat) => Tab(text: cat)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: List.generate(
          _cats.length,
          (index) => StoryListView(
            stream: _streams[index],
            svc: _svc,
          ),
        ),
      ),
    );
  }
}
