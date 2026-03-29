// ============================================================
// PATH: lib/features/connect/connect_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'chat/services/friend_service.dart';
import 'chat/services/dm_service.dart';
import 'chat/screens/friends_screen.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});
  @override
  State<ConnectScreen> createState() => _ConnectState();
}

class _ConnectState extends State<ConnectScreen> {
  final FriendService _friendSvc = FriendService();
  final DmService _dmSvc = DmService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: CustomScrollView(slivers: [
        // ── App bar ───────────────────────────────────────────
        SliverAppBar(
          backgroundColor: const Color(0xFF0D0D1A),
          expandedHeight: 130,
          floating: false,
          pinned: true,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)])
                      .createShader(b),
                  child: const Text('Connect',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900)),
                ),
                // Unread badge
                StreamBuilder<int>(
                  stream: _dmSvc.totalUnreadStream(),
                  builder: (_, snap) {
                    final n = snap.data ?? 0;
                    return n == 0
                        ? const SizedBox.shrink()
                        : Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: const Color(0xFF6C63FF),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text('$n new',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800)));
                  },
                ),
              ],
            ),
            background: Container(
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                    Color(0xFF0D0D2A),
                    Color(0xFF0D0D1A),
                  ])),
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Online friends strip ────────────────────────
              _OnlineFriendsStrip(service: _friendSvc),
              const SizedBox(height: 24),

              // ── Section label ───────────────────────────────
              _label('CONNECT'),
              const SizedBox(height: 14),

              // ── Friends & DMs card (full width) ─────────────
              _BigHubCard(
                item: const _HubItem(
                  emoji: '👥',
                  title: 'Friends & DMs',
                  sub: 'Connect privately with warriors',
                  color: Color(0xFF6C63FF),
                  gradient: [Color(0xFF6C63FF), Color(0xFF9C8FFF)],
                ),
                badge: StreamBuilder<int>(
                  stream: _dmSvc.totalUnreadStream(),
                  builder: (_, snap) =>
                      snap.data != null && snap.data! > 0
                          ? _badge('${snap.data}')
                          : const SizedBox.shrink(),
                ),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FriendsScreen())),
              ),

              const SizedBox(height: 24),

              // ── Daily quote ─────────────────────────────────
              _DailyQuote(),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _label(String t) => Text(t,
      style: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 2.5));

  Widget _badge(String t) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: const Color(0xFFE53935),
          borderRadius: BorderRadius.circular(10)),
      child: Text(t,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800)));
}

// ── Online friends strip ───────────────────────────────────────

class _OnlineFriendsStrip extends StatelessWidget {
  final FriendService service;
  const _OnlineFriendsStrip({required this.service});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: service.friendsStream(),
      builder: (_, snap) {
        final friends =
            (snap.data ?? []).where((f) => f.isOnline).toList();
        if (friends.isEmpty) return const SizedBox.shrink();
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF00C853))),
                const SizedBox(width: 6),
                Text('${friends.length} warriors online',
                    style: const TextStyle(
                        color: Color(0xFF00C853),
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 10),
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: friends.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final f = friends[i];
                    final init = f.displayName.isNotEmpty
                        ? f.displayName
                            .trim()
                            .split(' ')
                            .map((w) => w.isNotEmpty ? w[0] : '')
                            .take(2)
                            .join()
                            .toUpperCase()
                        : 'U';
                    return Column(children: [
                      Stack(children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: [
                                Color(0xFF6C63FF),
                                Color(0xFF00C4A0)
                              ])),
                          child: Center(
                              child: Text(init,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13))),
                        ),
                        Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                                width: 11,
                                height: 11,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF00C853),
                                    border: Border.all(
                                        color: const Color(0xFF0D0D1A),
                                        width: 2)))),
                      ]),
                      const SizedBox(height: 4),
                      Text(f.displayName.split(' ').first,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 9)),
                    ]);
                  },
                ),
              ),
            ]);
      },
    );
  }
}

// ── Big wide hub card ──────────────────────────────────────────

class _BigHubCard extends StatelessWidget {
  final _HubItem item;
  final VoidCallback onTap;
  final Widget badge;
  const _BigHubCard(
      {required this.item,
      required this.onTap,
      this.badge = const SizedBox.shrink()});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF141428),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: item.color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
                color: item.color.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: item.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(14)),
            child: Center(
                child: Text(item.emoji,
                    style: const TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Text(item.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(width: 8),
                  badge,
                ]),
                const SizedBox(height: 4),
                Text(item.sub,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 13)),
              ])),
          Icon(Icons.arrow_forward_ios_rounded,
              color: item.color.withOpacity(0.5), size: 16),
        ]),
      ),
    );
  }
}

// ── Daily quote ────────────────────────────────────────────────

class _DailyQuote extends StatelessWidget {
  static const _quotes = [
    'Every warrior you see here chose recovery today. So did you.',
    'You are not fighting alone. Every message — proof.',
    'Connection is the opposite of addiction. You\'re already healing.',
    'One honest conversation can change everything.',
    'The people in these rooms understand you. That\'s power.',
  ];

  @override
  Widget build(BuildContext context) {
    final q = _quotes[DateTime.now().day % _quotes.length];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: [
          const Color(0xFF6C63FF).withOpacity(0.08),
          const Color(0xFF00C4A0).withOpacity(0.08),
        ]),
        border: Border.all(
            color: const Color(0xFF6C63FF).withOpacity(0.15)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('💬', style: TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(
            child: Text(q,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                    height: 1.6,
                    fontStyle: FontStyle.italic))),
      ]),
    );
  }
}

// ── Data class ─────────────────────────────────────────────────

class _HubItem {
  final String emoji, title, sub;
  final Color color;
  final List<Color> gradient;
  const _HubItem({
    required this.emoji,
    required this.title,
    required this.sub,
    required this.color,
    required this.gradient,
  });
}