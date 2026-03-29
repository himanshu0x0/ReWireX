// ============================================================
// PATH: lib/features/connect/wellness/screens/mood_music_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// Top-level helper so canLaunchUrl & LaunchMode are not
// called inside the widget class scope — avoids "not defined
// for type MoodMusicScreen" error.
Future<void> _openSpotify(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class MoodMusicScreen extends StatelessWidget {
  const MoodMusicScreen({super.key});

  static const _playlists = [
    {
      'emoji': '🧘',
      'mood': 'Calm',
      'color': 0xFF6C63FF,
      'songs': [
        'Weightless – Marconi Union',
        'Clair de Lune – Debussy',
        'Gymnopédie No.1 – Satie',
      ],
      'url': 'https://open.spotify.com/playlist/37i9dQZF1DX3Ogo9pFvBkY',
    },
    {
      'emoji': '💪',
      'mood': 'Motivated',
      'color': 0xFF00C4A0,
      'songs': [
        'Eye of the Tiger – Survivor',
        'Lose Yourself – Eminem',
        'Till I Collapse – Eminem',
      ],
      'url': 'https://open.spotify.com/playlist/37i9dQZF1DX76Wlfdnj7AP',
    },
    {
      'emoji': '😌',
      'mood': 'Happy',
      'color': 0xFFFFB74D,
      'songs': [
        'Happy – Pharrell Williams',
        'Good as Hell – Lizzo',
        "Can't Stop the Feeling – JT",
      ],
      'url': 'https://open.spotify.com/playlist/37i9dQZF1DXdPec7aLTmlC',
    },
    {
      'emoji': '🌙',
      'mood': 'Sleep',
      'color': 0xFF4FC3F7,
      'songs': [
        'Moonlight Sonata – Beethoven',
        'Nocturne Op.9 – Chopin',
        'River Flows In You – Yiruma',
      ],
      'url': 'https://open.spotify.com/playlist/37i9dQZF1DWZd79rJ6a7lp',
    },
    {
      'emoji': '🔥',
      'mood': 'Focus',
      'color': 0xFFEF5350,
      'songs': [
        'Interstellar Theme – Hans Zimmer',
        'Time – Hans Zimmer',
        'Experience – Einaudi',
      ],
      'url': 'https://open.spotify.com/playlist/37i9dQZF1DWZeKCadgRdKQ',
    },
    {
      'emoji': '🌱',
      'mood': 'Healing',
      'color': 0xFFAB47BC,
      'songs': [
        'The Sound of Silence – S&G',
        'Here Comes the Sun – Beatles',
        'What a Wonderful World – Armstrong',
      ],
      'url': 'https://open.spotify.com/playlist/37i9dQZF1DX3rxVfibe1L0',
    },
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
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
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 15, color: Colors.white.withOpacity(0.7)),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Music Mood',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text('Match music to your mood 🎵',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6), fontSize: 14)),
            const SizedBox(height: 16),
            ..._playlists.map((p) {
              final c = Color(p['color'] as int);
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                    color: const Color(0xFF141428),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.withOpacity(0.2))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: c.withOpacity(0.08),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20))),
                      child: Row(children: [
                        Text(p['emoji'] as String,
                            style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Text(p['mood'] as String,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800)),
                        const Spacer(),
                        // Spotify button — delegates to top-level _openSpotify
                        GestureDetector(
                          onTap: () => _openSpotify(p['url'] as String),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                color: c.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: c.withOpacity(0.3))),
                            child: Row(children: [
                              Text('▶',
                                  style:
                                      TextStyle(color: c, fontSize: 12)),
                              const SizedBox(width: 4),
                              Text('Spotify',
                                  style: TextStyle(
                                      color: c,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                            ]),
                          ),
                        ),
                      ]),
                    ),
                    // Song list
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      child: Column(
                        children: (p['songs'] as List<dynamic>)
                            .map((s) => Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 6),
                                  child: Row(children: [
                                    Icon(Icons.music_note_rounded,
                                        size: 14,
                                        color: c.withOpacity(0.6)),
                                    const SizedBox(width: 8),
                                    Text(s as String,
                                        style: TextStyle(
                                            color: Colors.white
                                                .withOpacity(0.6),
                                            fontSize: 13)),
                                  ]),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
}