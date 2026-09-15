import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class _MusicTrack {
  final String title;
  final String artist;
  final String asset;

  const _MusicTrack({
    required this.title,
    required this.artist,
    required this.asset,
  });
}

class _MusicMood {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final List<_MusicTrack> tracks;

  const _MusicMood({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.tracks,
  });
}

class MoodMusicScreen extends StatefulWidget {
  const MoodMusicScreen({super.key, this.rescueMode = false});

  final bool rescueMode;

  @override
  State<MoodMusicScreen> createState() => _MoodMusicScreenState();
}

class _MoodMusicScreenState extends State<MoodMusicScreen> {
  final AudioPlayer _player = AudioPlayer();

  int? _moodIndex;
  int? _trackIndex;
  String? _error;

  static const moods = <_MusicMood>[
    _MusicMood(
      emoji: '🌌',
      title: 'Mindflow',
      subtitle: 'Soft instrumental music for a quiet mind',
      color: Color(0xFF7C6CFF),
      tracks: [
        _MusicTrack(title: 'Deep Calm', artist: 'ReWireX Mindflow', asset: 'assets/audio/mindflow_deep_calm.mp3'),
        _MusicTrack(title: 'Mind Reset', artist: 'ReWireX Mindflow', asset: 'assets/audio/mindflow_mind_reset.mp3'),
        _MusicTrack(title: 'Piano & Rain', artist: 'ReWireX Mindflow', asset: 'assets/audio/mindflow_piano_rain.mp3'),
        _MusicTrack(title: 'Quiet Evening', artist: 'ReWireX Mindflow', asset: 'assets/audio/mindflow_quiet_evening.mp3'),
      ],
    ),
    _MusicMood(
      emoji: '🌙',
      title: 'Late Night',
      subtitle: 'Dreamy, slow and atmospheric',
      color: Color(0xFF536DFE),
      tracks: [
        _MusicTrack(title: 'Midnight Dream', artist: 'ReWireX', asset: 'assets/audio/late_night_midnight_dream.mp3'),
        _MusicTrack(title: 'Lonely Lights', artist: 'ReWireX', asset: 'assets/audio/late_night_lonely_lights.mp3'),
        _MusicTrack(title: 'Young & Dreaming', artist: 'ReWireX', asset: 'assets/audio/late_night_young_dreaming.mp3'),
        _MusicTrack(title: 'Past Midnight', artist: 'ReWireX', asset: 'assets/audio/late_night_past_midnight.mp3'),
      ],
    ),
    _MusicMood(
      emoji: '🖤',
      title: 'Dreamy & Melancholy',
      subtitle: 'Soft, intimate and atmospheric',
      color: Color(0xFF9C7BB8),
      tracks: [
        _MusicTrack(title: 'Nothing Hurts Tonight', artist: 'ReWireX', asset: 'assets/audio/dreamy_nothing_hurts_tonight.mp3'),
        _MusicTrack(title: 'Slow Room', artist: 'ReWireX', asset: 'assets/audio/dreamy_slow_room.mp3'),
        _MusicTrack(title: 'After Midnight', artist: 'ReWireX', asset: 'assets/audio/dreamy_after_midnight.mp3'),
        _MusicTrack(title: 'Falling Slowly', artist: 'ReWireX', asset: 'assets/audio/dreamy_falling_slowly.mp3'),
      ],
    ),
    _MusicMood(
      emoji: '🇮🇳',
      title: 'Hindi Nostalgia',
      subtitle: 'Slow, warm and nostalgic',
      color: Color(0xFFE09F5A),
      tracks: [
        _MusicTrack(title: 'Purani Yaadein', artist: 'ReWireX', asset: 'assets/audio/hindi_purani_yaadein.mp3'),
        _MusicTrack(title: 'Shaam Ki Khamoshi', artist: 'ReWireX', asset: 'assets/audio/hindi_shaam_ki_khamoshi.mp3'),
        _MusicTrack(title: 'Woh Purana Safar', artist: 'ReWireX', asset: 'assets/audio/hindi_purana_safar.mp3'),
        _MusicTrack(title: 'Raat Aur Baarish', artist: 'ReWireX', asset: 'assets/audio/hindi_raat_aur_baarish.mp3'),
      ],
    ),
    _MusicMood(
      emoji: '🌧️',
      title: 'Healing',
      subtitle: 'Gentle music for difficult moments',
      color: Color(0xFF55AFA0),
      tracks: [
        _MusicTrack(title: 'You Are Still Here', artist: 'ReWireX', asset: 'assets/audio/healing_you_are_still_here.mp3'),
        _MusicTrack(title: 'Let It Pass', artist: 'ReWireX', asset: 'assets/audio/healing_let_it_pass.mp3'),
        _MusicTrack(title: 'Breathe Again', artist: 'ReWireX', asset: 'assets/audio/healing_breathe_again.mp3'),
        _MusicTrack(title: 'A Little Lighter', artist: 'ReWireX', asset: 'assets/audio/healing_a_little_lighter.mp3'),
      ],
    ),
    _MusicMood(
      emoji: '🧘',
      title: 'Deep Peace',
      subtitle: 'Minimal piano and ambient textures',
      color: Color(0xFF66A6D9),
      tracks: [
        _MusicTrack(title: 'Still Water', artist: 'ReWireX', asset: 'assets/audio/deep_peace_still_water.mp3'),
        _MusicTrack(title: 'Slow Breath', artist: 'ReWireX', asset: 'assets/audio/deep_peace_slow_breath.mp3'),
        _MusicTrack(title: 'Empty Room', artist: 'ReWireX', asset: 'assets/audio/deep_peace_empty_room.mp3'),
        _MusicTrack(title: 'Before Sleep', artist: 'ReWireX', asset: 'assets/audio/deep_peace_before_sleep.mp3'),
      ],
    ),
    _MusicMood(
      emoji: '☀️',
      title: 'Gentle Uplift',
      subtitle: 'Soft music when you need a little lift',
      color: Color(0xFFD7A84B),
      tracks: [
        _MusicTrack(title: 'One More Step', artist: 'ReWireX', asset: 'assets/audio/uplift_one_more_step.mp3'),
        _MusicTrack(title: 'Morning Window', artist: 'ReWireX', asset: 'assets/audio/uplift_morning_window.mp3'),
        _MusicTrack(title: 'Keep Going', artist: 'ReWireX', asset: 'assets/audio/uplift_keep_going.mp3'),
      ],
    ),
  ];

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  bool _isCurrent(int mood, int track) =>
      _moodIndex == mood && _trackIndex == track;

  Future<void> _toggle(int mood, int track) async {
    final item = moods[mood].tracks[track];

    if (!_isCurrent(mood, track)) {
      setState(() {
        _moodIndex = mood;
        _trackIndex = track;
        _error = null;
      });
      try {
        await _player.setAsset(item.asset);
        await _player.play();
      } catch (_) {
        if (!mounted) return;
        setState(() => _error = 'Add this licensed audio file: ${item.asset}');
      }
      return;
    }

    if (_player.playing) {
      await _player.pause();
    } else {
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      await _player.play();
    }
    if (mounted) setState(() {});
  }

  Future<void> _next() async {
    if (_moodIndex == null || _trackIndex == null) return;
    final list = moods[_moodIndex!].tracks;
    await _toggle(_moodIndex!, (_trackIndex! + 1) % list.length);
  }

  Future<void> _previous() async {
    if (_moodIndex == null || _trackIndex == null) return;
    final list = moods[_moodIndex!].tracks;
    await _toggle(_moodIndex!, _trackIndex! == 0 ? list.length - 1 : _trackIndex! - 1);
  }

  String _time(Duration d) =>
      '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final current = _moodIndex == null || _trackIndex == null
        ? null
        : moods[_moodIndex!].tracks[_trackIndex!];

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Music Mood', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
      ),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(20, 16, 20, current == null ? 32 : 190),
            children: [
              const Text('Match music to your mood 🎵', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 5),
              Text(
                widget.rescueMode ? 'Choose something gentle, then recheck your urge.' : 'Listen without leaving ReWireX.',
                style: const TextStyle(color: Colors.white38, fontSize: 13),
              ),
              const SizedBox(height: 18),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(color: const Color(0xFF19192D), borderRadius: BorderRadius.circular(14)),
                  child: Text(_error!, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ),
                const SizedBox(height: 14),
              ],
              ...List.generate(moods.length, (i) => _moodCard(i, moods[i])),
              if (widget.rescueMode)
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Done — Recheck my urge'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: const Color(0xFF6C63FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
            ],
          ),
          if (current != null)
            Positioned(left: 12, right: 12, bottom: 12, child: _miniPlayer(current)),
        ],
      ),
    );
  }

  Widget _moodCard(int moodIndex, _MusicMood mood) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF141428),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: mood.color.withOpacity(.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
            decoration: BoxDecoration(
              color: mood.color.withOpacity(.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Text(
                  mood.emoji,
                  style: const TextStyle(fontSize: 27),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mood.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        mood.subtitle,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.swipe_rounded,
                  color: mood.color.withOpacity(.65),
                  size: 19,
                ),
              ],
            ),
          ),

          // Songs scroll horizontally. The page itself remains vertically
          // scrollable, while each category gets its own horizontal rail.
          SizedBox(
            height: 174,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              itemCount: mood.tracks.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, index) {
                return _trackCard(
                  moodIndex,
                  index,
                  mood.tracks[index],
                  mood.color,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _trackCard(
    int mood,
    int index,
    _MusicTrack track,
    Color color,
  ) {
    final selected = _isCurrent(mood, index);
    final playing = selected && _player.playing;

    return SizedBox(
      width: 145,
      height: 150,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _toggle(mood, index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected
                ? color.withOpacity(.13)
                : const Color(0xFF1A1A30),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? color.withOpacity(.48)
                  : Colors.white.withOpacity(.045),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Compact album-art style tile.
              SizedBox(
                width: double.infinity,
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withOpacity(.30),
                        color.withOpacity(.07),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.music_note_rounded,
                        size: 27,
                        color: color.withOpacity(.75),
                      ),
                      Positioned(
                        right: 6,
                        bottom: 5,
                        child: Container(
                          width: 29,
                          height: 29,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D0D1A).withOpacity(.84),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white70,
                  fontSize: 12.5,
                  height: 1.15,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                track.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 16,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        selected
                            ? (playing ? 'Playing' : 'Paused')
                            : 'Tap to play',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: TextStyle(
                          color: selected ? color : Colors.white30,
                          fontSize: 9.5,
                          height: 1.1,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (selected)
                      Icon(
                        Icons.equalizer_rounded,
                        color: color,
                        size: 15,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniPlayer(_MusicTrack track) {
    final color = moods[_moodIndex!].color;

    return StreamBuilder<Duration?>(
      stream: _player.durationStream,
      builder: (context, durationSnap) {
        return StreamBuilder<Duration>(
          stream: _player.positionStream,
          initialData: Duration.zero,
          builder: (context, positionSnap) {
            final duration = durationSnap.data ?? Duration.zero;
            final position = positionSnap.data ?? Duration.zero;
            final max = duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;
            final value = position.inMilliseconds.clamp(0, duration.inMilliseconds > 0 ? duration.inMilliseconds : 1).toDouble();

            return Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 7),
              decoration: BoxDecoration(
                color: const Color(0xFF19192D),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(.22)),
                boxShadow: const [BoxShadow(blurRadius: 24, offset: Offset(0, 8), color: Color(0x55000000))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withOpacity(.14), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.music_note_rounded, color: color)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                            Text(track.artist, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                          ],
                        ),
                      ),
                      IconButton(onPressed: _previous, icon: const Icon(Icons.skip_previous_rounded, color: Colors.white70)),
                      StreamBuilder<PlayerState>(
                        stream: _player.playerStateStream,
                        builder: (_, snap) {
                          final state = snap.data;
                          final playing = state?.playing ?? false;
                          final done = state?.processingState == ProcessingState.completed;
                          return IconButton(
                            onPressed: () async {
                              if (done) {
                                await _player.seek(Duration.zero);
                                await _player.play();
                              } else if (playing) {
                                await _player.pause();
                              } else {
                                await _player.play();
                              }
                              if (mounted) setState(() {});
                            },
                            icon: Icon(playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, color: color, size: 35),
                          );
                        },
                      ),
                      IconButton(onPressed: _next, icon: const Icon(Icons.skip_next_rounded, color: Colors.white70)),
                    ],
                  ),
                  Slider(
                    min: 0,
                    max: max,
                    value: value.clamp(0, max),
                    onChanged: duration.inMilliseconds == 0 ? null : (v) => _player.seek(Duration(milliseconds: v.round())),
                    activeColor: color,
                    inactiveColor: Colors.white12,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [Text(_time(position), style: const TextStyle(color: Colors.white38, fontSize: 10)), Text(_time(duration), style: const TextStyle(color: Colors.white38, fontSize: 10))],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
