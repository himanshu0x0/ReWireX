// ============================================================
// PATH: lib/features/connect/stories/screens/story_reader_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:rewirex/features/connect/stories/models/story_model.dart';
import 'package:rewirex/features/connect/stories/services/story_service.dart';

class StoryReaderScreen extends StatefulWidget {
  final StoryModel story;
  final StoryService svc;

  const StoryReaderScreen({
    super.key,
    required this.story,
    required this.svc,
  });

  @override
  State<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends State<StoryReaderScreen> {
  late final PageController _pageController;
  int _chapterIndex = 0;

  bool get _hasChapters => widget.story.chapters.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Featured stories are local/read-only, so this is safe because the
    // service ignores read-count writes for featured IDs.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.svc.incrementRead(widget.story.id);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextChapter() {
    if (!_hasChapters) return;

    if (_chapterIndex < widget.story.chapters.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _previousChapter() {
    if (!_hasChapters) return;

    if (_chapterIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.story;

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
        actions: [
          IconButton(
            icon: Icon(
              story.likedByMe
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: story.likedByMe
                  ? const Color(0xFFEF5350)
                  : Colors.white.withOpacity(0.5),
            ),
            onPressed: story.isFeatured
                ? null
                : () => widget.svc.toggleLike(story.id),
          ),
        ],
      ),
      body: _hasChapters
          ? _buildChapterReader(story)
          : _buildLegacyReader(story),
    );
  }

  Widget _buildChapterReader(StoryModel story) {
    return Column(
      children: [
        _buildHeader(story),
        _buildChapterProgress(story),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: story.chapters.length,
            onPageChanged: (index) {
              setState(() => _chapterIndex = index);
            },
            itemBuilder: (_, index) {
              final chapter = story.chapters[index];

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _chapterNumber(index),
                    const SizedBox(height: 8),
                    Text(
                      chapter.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _storyText(chapter.content),
                    const SizedBox(height: 24),
                    _buildCliffhanger(chapter.cliffhanger),
                    const SizedBox(height: 22),
                    _buildChapterNavigation(story),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(StoryModel story) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 8),
      child: Column(
        children: [
          Text(
            story.coverEmoji,
            style: const TextStyle(fontSize: 50),
          ),
          const SizedBox(height: 8),
          Text(
            story.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                story.isAnonymous
                    ? 'Anonymous Warrior'
                    : story.authorName,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 13,
                ),
              ),
              if (story.isFeatured) ...[
                const SizedBox(width: 7),
                const Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF00C4A0),
                  size: 16,
                ),
                const SizedBox(width: 4),
                const Text(
                  'Verified source',
                  style: TextStyle(
                    color: Color(0xFF00C4A0),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
          if (story.sourceName != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00C4A0).withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF00C4A0).withOpacity(0.18),
                ),
              ),
              child: Text(
                'Inspired by ${story.sourceName}. '
                'This ReWireX version is an original dramatized adaptation '
                'for in-app reading; scenes and dialogue are fictionalized '
                'and are not the source article.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.58),
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChapterProgress(StoryModel story) {
    final total = story.chapters.length;
    final progress = (_chapterIndex + 1) / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CHAPTER ${_chapterIndex + 1} OF $total',
                style: const TextStyle(
                  color: Color(0xFF00C4A0),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.white.withOpacity(0.07),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF6C63FF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chapterNumber(int index) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6C63FF).withOpacity(0.22),
        ),
      ),
      child: Text(
        'CHAPTER ${index + 1}',
        style: const TextStyle(
          color: Color(0xFF8B84FF),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _storyText(String text) {
    final paragraphs = text.split('\n\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((paragraph) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            paragraph,
            style: TextStyle(
              color: Colors.white.withOpacity(0.80),
              fontSize: 16,
              height: 1.82,
              letterSpacing: 0.05,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCliffhanger(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 19),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withOpacity(0.075),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF6C63FF).withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF8B84FF),
                size: 17,
              ),
              SizedBox(width: 7),
              Text(
                'KEEP READING',
                style: TextStyle(
                  color: Color(0xFF8B84FF),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.55,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterNavigation(StoryModel story) {
    final isFirst = _chapterIndex == 0;
    final isLast = _chapterIndex == story.chapters.length - 1;

    return Row(
      children: [
        if (!isFirst)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _previousChapter,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Previous'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white.withOpacity(0.65),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.12),
                ),
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
        if (!isFirst) const SizedBox(width: 10),
        Expanded(
          flex: isFirst || isLast ? 1 : 2,
          child: FilledButton.icon(
            onPressed: isLast
                ? () => Navigator.pop(context)
                : _nextChapter,
            icon: Icon(
              isLast
                  ? Icons.check_rounded
                  : Icons.arrow_forward_rounded,
            ),
            label: Text(
              isLast ? 'Finish Story' : 'Continue Chapter',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00C4A0),
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegacyReader(StoryModel story) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
      child: Column(
        children: [
          Text(
            story.coverEmoji,
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 20),
          Text(
            story.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            story.isAnonymous
                ? 'Anonymous Warrior'
                : story.authorName,
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 13,
            ),
          ),
          if (story.sourceName != null) ...[
            const SizedBox(height: 14),
            Text(
              'Inspired by ${story.sourceName}. '
              'This ReWireX version is an original adaptation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF141428),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.07),
              ),
            ),
            child: _storyText(story.content),
          ),
        ],
      ),
    );
  }
}
