// ============================================================
// PATH: lib/features/connect/games/screens/game_room_screen.dart
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rewirex/features/connect/games/models/game_question_model.dart';
import '../models/game_room_model.dart';
import '../models/game_chat_message_model.dart';
import '../services/game_room_service.dart';

class GameRoomScreen extends StatefulWidget {
  final String roomId, anonName;
  const GameRoomScreen(
      {super.key, required this.roomId, required this.anonName});
  @override
  State<GameRoomScreen> createState() => _GameState();
}

class _GameState extends State<GameRoomScreen>
    with SingleTickerProviderStateMixin {
  final GameRoomService _svc = GameRoomService();
  final String _me = FirebaseAuth.instance.currentUser?.uid ?? '';
  GameQuestion? _currentQ;
  final List<String> _usedIds = [];
  bool _picked = false;
  Timer? _timer;
  int _timeLeft = 0;
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _pickQuestion(QuestionType type) {
    final q = _svc.pickQuestion(type, _usedIds);
    setState(() {
      _currentQ = q;
      _picked = true;
      _usedIds.add(q.id);
    });
    if (q.timeSeconds > 0) {
      setState(() => _timeLeft = q.timeSeconds);
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() => _timeLeft--);
        if (_timeLeft <= 0) t.cancel();
      });
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<GameRoomModel?>(
      stream: _svc.roomStream(widget.roomId),
      builder: (_, rSnap) {
        final room = rSnap.data;
        if (room == null) {
          return const Scaffold(
              backgroundColor: Color(0xFF0D0D1A),
              body: Center(
                  child: CircularProgressIndicator(color: Color(0xFF6C63FF))));
        }
        if (room.status == GameRoomStatus.finished) return _buildFinished(room);
        return StreamBuilder<List<GamePlayer>>(
            stream: _svc.playersStream(widget.roomId),
            builder: (_, pSnap) {
              final players = pSnap.data ?? [];
              final isMyTurn = room.currentTurnUid == _me;
              final amHost = room.hostUid == _me;
              return Scaffold(
                  backgroundColor: const Color(0xFF0D0D1A),
                  appBar: _appBar(room, players, amHost),
                  body: Column(children: [
                    _PlayersStrip(
                        players: players, currentTurnUid: room.currentTurnUid),
                    Expanded(
                        child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                            child: Column(children: [
                              if (room.type == GameRoomType.private &&
                                  room.roomCode != null)
                                _codeCard(room.roomCode!),
                              const SizedBox(height: 16),
                              if (room.status == GameRoomStatus.waiting)
                                _buildWaiting(room, players, amHost)
                              else
                                _buildPlaying(room, players, isMyTurn)
                            ])))
                  ]));
            });
      });

  // ── Waiting ───────────────────────────────────────────────────
  Widget _buildWaiting(GameRoomModel room, List<GamePlayer> players,
          bool amHost) =>
      Column(children: [
        Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
                color: const Color(0xFF141428),
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: const Color(0xFF6C63FF).withOpacity(0.2))),
            child: Column(children: [
              const Text('⏳', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              const Text('Waiting for players…',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('${players.length}/${room.maxPlayers} joined',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5), fontSize: 14)),
              if (!room.canStart) ...[
                const SizedBox(height: 8),
                Text('Need at least 2 players to start',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.35), fontSize: 12))
              ]
            ])),
        const SizedBox(height: 16),
        if (amHost && room.canStart)
          SizedBox(
              width: double.infinity,
              height: 56,
              child: DecoratedBox(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)]),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFF6C63FF).withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8))
                      ]),
                  child: ElevatedButton.icon(
                      onPressed: () => _svc.startGame(widget.roomId),
                      icon: const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 24),
                      label: const Text('Start Game!',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 17)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18))))))
        else if (!amHost)
          Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14)),
              child: Text('Waiting for the host to start…',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.45), fontSize: 13)))
      ]);

  // ── Playing ───────────────────────────────────────────────────
  Widget _buildPlaying(
          GameRoomModel room, List<GamePlayer> players, bool isMyTurn) =>
      Column(children: [
        Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: const Color(0xFF141428),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: isMyTurn
                        ? const Color(0xFF6C63FF).withOpacity(0.3)
                        : Colors.white.withOpacity(0.07))),
            child: Row(children: [
              AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isMyTurn
                                  ? const Color(0xFF6C63FF)
                                  : const Color(0xFF00C4A0))
                              .withOpacity(
                                  isMyTurn ? 0.5 + _pulse.value * 0.5 : 1)))),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(
                      isMyTurn
                          ? '🎯 It\'s YOUR turn!'
                          : '⏳ ${room.currentTurnName}\'s turn',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight:
                              isMyTurn ? FontWeight.w800 : FontWeight.w500))),
              Text('Round ${room.roundNumber}/${room.totalRounds}',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 12))
            ])),
        const SizedBox(height: 20),
        if (!_picked && isMyTurn) ...[
          const Text('Choose wisely…',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: _PickBtn(
                    label: '🤔 Truth',
                    color: const Color(0xFF6C63FF),
                    onTap: () => _pickQuestion(QuestionType.truth))),
            const SizedBox(width: 16),
            Expanded(
                child: _PickBtn(
                    label: '🎲 Dare',
                    color: const Color(0xFF00C4A0),
                    onTap: () => _pickQuestion(QuestionType.dare)))
          ])
        ] else if (_currentQ != null && isMyTurn)
          _buildQuestionCard(_currentQ!, room, players)
        else if (!isMyTurn)
          Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: const Color(0xFF141428),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.07))),
              child: Column(children: [
                const Text('👀', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                Text('Watch ${room.currentTurnName} play!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 15))
              ])),
        // ── Chat button lives here so it's always reachable while
        // playing — answering a truth or reacting to a dare happens
        // right where the action is.
        const SizedBox(height: 20),
        SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
                onPressed: () => _showChat(players),
                icon: const Icon(Icons.chat_bubble_outline_rounded,
                    color: Color(0xFF00C4A0), size: 18),
                label: const Text('Open Chat',
                    style: TextStyle(
                        color: Color(0xFF00C4A0), fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF00C4A0)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)))))
      ]);

  Widget _buildQuestionCard(
          GameQuestion q, GameRoomModel room, List<GamePlayer> players) =>
      Column(children: [
        Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                    colors: q.type == QuestionType.truth
                        ? [const Color(0xFF6C63FF), const Color(0xFF5A52D5)]
                        : [const Color(0xFF00C4A0), const Color(0xFF00A085)])),
            child: Column(children: [
              Text(q.type == QuestionType.truth ? '🤔 TRUTH' : '🎲 DARE',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2)),
              const SizedBox(height: 16),
              Text(q.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.4)),
              if (q.timeSeconds > 0 && _timeLeft > 0) ...[
                const SizedBox(height: 16),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text('⏱ $_timeLeft seconds',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)))
              ]
            ])),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
              child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                      onPressed: () async {
                        await _svc.completeTurn(
                          roomId: widget.roomId,
                          completed: false,
                          questionText: q.text,
                          questionType: q.type,
                        );
                        setState(() {
                          _picked = false;
                          _currentQ = null;
                        });
                      },
                      icon: const Icon(Icons.close_rounded,
                          color: Color(0xFFE53935), size: 20),
                      label: const Text('Skip',
                          style: TextStyle(
                              color: Color(0xFFE53935),
                              fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE53935)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)))))),
          const SizedBox(width: 12),
          Expanded(
              child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                      onPressed: () async {
                        await _svc.completeTurn(
                          roomId: widget.roomId,
                          completed: true,
                          questionText: q.text,
                          questionType: q.type,
                        );
                        setState(() {
                          _picked = false;
                          _currentQ = null;
                        });
                      },
                      icon: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 20),
                      label: const Text('Done! ✅',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C853),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))))))
        ])
      ]);

  Widget _buildFinished(GameRoomModel room) =>
      StreamBuilder<List<GamePlayer>>(
          stream: _svc.playersStream(widget.roomId),
          builder: (_, snap) {
            final players = [...(snap.data ?? [])]
              ..sort((a, b) => b.score.compareTo(a.score));
            return Scaffold(
                backgroundColor: const Color(0xFF0D0D1A),
                body: SafeArea(
                    child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(children: [
                          const SizedBox(height: 32),
                          const Text('🏆', style: TextStyle(fontSize: 64)),
                          const SizedBox(height: 16),
                          const Text('Game Over!',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Text('Final Scores',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 14)),
                          const SizedBox(height: 24),
                          Expanded(
                              child: ListView.builder(
                                  itemCount: players.length,
                                  itemBuilder: (_, i) {
                                    final p = players[i];
                                    const medals = ['🥇', '🥈', '🥉'];
                                    return Container(
                                        margin: const EdgeInsets.only(bottom: 10),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                            color: const Color(0xFF141428),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                                color: i == 0
                                                    ? const Color(0xFFFFD700)
                                                        .withOpacity(0.3)
                                                    : Colors.white
                                                        .withOpacity(0.07))),
                                        child: Row(children: [
                                          Text(i < 3 ? medals[i] : '${i + 1}',
                                              style:
                                                  const TextStyle(fontSize: 22)),
                                          const SizedBox(width: 12),
                                          Text(p.emoji,
                                              style:
                                                  const TextStyle(fontSize: 24)),
                                          const SizedBox(width: 10),
                                          Expanded(
                                              child: Text(p.anonName,
                                                  style: TextStyle(
                                                      color: p.uid == _me
                                                          ? const Color(
                                                              0xFF6C63FF)
                                                          : Colors.white,
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w700))),
                                          Container(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 12, vertical: 5),
                                              decoration: BoxDecoration(
                                                  color: const Color(0xFF6C63FF)
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(20)),
                                              child: Text('${p.score} pts',
                                                  style: const TextStyle(
                                                      color: Color(0xFF6C63FF),
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w700)))
                                        ]));
                                  })),
                          SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                  onPressed: () =>
                                      Navigator.popUntil(context, (r) => r.isFirst),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6C63FF),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14))),
                                  child: const Text('Back to Hub',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16))))
                        ]))));
          });

  AppBar _appBar(
          GameRoomModel room, List<GamePlayer> players, bool amHost) =>
      AppBar(
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
                      size: 15, color: Colors.white.withOpacity(0.7))),
              onPressed: () {
                _svc.leaveRoom(widget.roomId);
                Navigator.pop(context);
              }),
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(room.name,
                style: const TextStyle(
                    color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            Row(children: [
              if (room.type == GameRoomType.private)
                Text('🔒 ${room.roomCode}  ·  ',
                    style: const TextStyle(
                        color: Color(0xFF6C63FF),
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              Text(
                  '${room.playerCount} players  ·  '
                  '${room.status == GameRoomStatus.waiting ? "Waiting" : "Playing"}',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 11))
            ])
          ]),
          actions: [
            // ── Chat ──────────────────────────────────────────────
            IconButton(
                icon: Icon(Icons.chat_bubble_outline_rounded,
                    color: Colors.white.withOpacity(0.6), size: 20),
                onPressed: () => _showChat(players)),
            // ── Room / profile settings ──────────────────────────
            IconButton(
                icon: Icon(Icons.settings_outlined,
                    color: Colors.white.withOpacity(0.6)),
                onPressed: () => _showRoomSettings(room, players, amHost)),
            IconButton(
                icon: Icon(Icons.exit_to_app_rounded,
                    color: Colors.white.withOpacity(0.4)),
                onPressed: () {
                  _svc.leaveRoom(widget.roomId);
                  Navigator.pop(context);
                })
          ]);

  Widget _codeCard(String code) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: const Color(0xFF6C63FF).withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.25))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.tag_rounded, color: Color(0xFF6C63FF), size: 16),
        const SizedBox(width: 8),
        Text('Room Code: ',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
        Text(code,
            style: const TextStyle(
                color: Color(0xFF6C63FF),
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 4)),
        const SizedBox(width: 8),
        GestureDetector(
            onTap: () => Clipboard.setData(ClipboardData(text: code)),
            child: const Icon(Icons.copy_rounded,
                color: Color(0xFF6C63FF), size: 16))
      ]));

  // ══════════════════════════════════════════════════════════════
  // ROOM SETTINGS SHEET (NEW)
  // Lets a player edit their own anonName / emoji / gender, and if
  // they're the host, also rename the room — matches the "edit your
  // player profile in-room" request.
  // ══════════════════════════════════════════════════════════════
  void _showRoomSettings(
      GameRoomModel room, List<GamePlayer> players, bool amHost) {
    final me = players.firstWhere(
      (p) => p.uid == _me,
      orElse: () => GamePlayer(
          uid: _me,
          anonName: widget.anonName,
          emoji: '🎮',
          joinedAt: DateTime.now()),
    );

    final nameCtrl = TextEditingController(text: me.anonName);
    final roomNameCtrl = TextEditingController(text: room.name);
    String pickedEmoji = me.emoji;
    String pickedGender = me.gender;
    String pickedInterest = me.interest;
    bool saving = false;

    const emojis = ['🦁', '🐯', '🦊', '🐺', '🦅', '🐉', '⚔️', '🔥', '🌟', '💎'];
    const genders = [
      {'value': '', 'label': 'Not specified'},
      {'value': 'male', 'label': 'Male'},
      {'value': 'female', 'label': 'Female'},
      {'value': 'other', 'label': 'Other'},
    ];
    const interests = [
      {'value': '', 'label': 'Not specified'},
      {'value': 'friendship', 'label': '🤝 Friendship'},
      {'value': 'dating', 'label': '💕 Dating'},
      {'value': 'chatting', 'label': '💬 Chatting'},
      {'value': 'fun', 'label': '🎉 Just Fun'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
                color: Color(0xFF141428),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4)))),
                  const SizedBox(height: 20),
                  const Text('Room Settings',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 20),

                  if (amHost) ...[
                    _sheetLabel('ROOM NAME'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: roomNameCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: _sheetInputDecoration('Room name'),
                    ),
                    const SizedBox(height: 20),
                  ],

                  _sheetLabel('YOUR EMOJI'),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 48,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: emojis.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => setSheet(() => pickedEmoji = emojis[i]),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: pickedEmoji == emojis[i]
                                  ? const Color(0xFF6C63FF).withOpacity(0.2)
                                  : Colors.white.withOpacity(0.05),
                              border: Border.all(
                                  color: pickedEmoji == emojis[i]
                                      ? const Color(0xFF6C63FF)
                                      : Colors.transparent,
                                  width: 2)),
                          child: Center(
                              child: Text(emojis[i],
                                  style: const TextStyle(fontSize: 22))),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _sheetLabel('YOUR NAME'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    maxLength: 20,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration:
                        _sheetInputDecoration('Your anonymous name'),
                  ),
                  const SizedBox(height: 12),

                  _sheetLabel('GENDER'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: genders.map((g) {
                      final selected = pickedGender == g['value'];
                      return GestureDetector(
                        onTap: () =>
                            setSheet(() => pickedGender = g['value']!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF6C63FF).withOpacity(0.2)
                                  : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: selected
                                      ? const Color(0xFF6C63FF)
                                      : Colors.white.withOpacity(0.1))),
                          child: Text(g['label']!,
                              style: TextStyle(
                                  color: selected
                                      ? const Color(0xFF6C63FF)
                                      : Colors.white.withOpacity(0.55),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  _sheetLabel('INTEREST'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: interests.map((it) {
                      final selected = pickedInterest == it['value'];
                      return GestureDetector(
                        onTap: () =>
                            setSheet(() => pickedInterest = it['value']!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF00C4A0).withOpacity(0.2)
                                  : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: selected
                                      ? const Color(0xFF00C4A0)
                                      : Colors.white.withOpacity(0.1))),
                          child: Text(it['label']!,
                              style: TextStyle(
                                  color: selected
                                      ? const Color(0xFF00C4A0)
                                      : Colors.white.withOpacity(0.55),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)])),
                      child: ElevatedButton(
                        onPressed: saving
                            ? null
                            : () async {
                                setSheet(() => saving = true);
                                try {
                                  await _svc.updateMyProfile(
                                    roomId: widget.roomId,
                                    anonName: nameCtrl.text,
                                    emoji: pickedEmoji,
                                    gender: pickedGender,
                                    interest: pickedInterest,
                                  );
                                  if (amHost &&
                                      roomNameCtrl.text.trim() !=
                                          room.name) {
                                    await _svc.renameRoom(
                                      roomId: widget.roomId,
                                      newName: roomNameCtrl.text,
                                    );
                                  }
                                  if (ctx.mounted) Navigator.pop(ctx);
                                } catch (e) {
                                  setSheet(() => saving = false);
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                        SnackBar(
                                            content: Text('$e'),
                                            backgroundColor:
                                                const Color(0xFFE53935)));
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16))),
                        child: saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.2))
                            : const Text('Save Changes',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetLabel(String t) => Text(t,
      style: TextStyle(
          color: Colors.white.withOpacity(0.35),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 2));

  InputDecoration _sheetInputDecoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      counterStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14));

  // ══════════════════════════════════════════════════════════════
  // IN-ROOM CHAT SHEET (NEW)
  // For answering truths / reacting to dares / general banter.
  // ══════════════════════════════════════════════════════════════
  void _showChat(List<GamePlayer> players) {
    final me = players.firstWhere(
      (p) => p.uid == _me,
      orElse: () => GamePlayer(
          uid: _me,
          anonName: widget.anonName,
          emoji: '🎮',
          joinedAt: DateTime.now()),
    );
    final chatCtrl = TextEditingController();
    final scrollCtrl = ScrollController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
              color: Color(0xFF141428),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 12),
              Row(
                children: [
                  const SizedBox(width: 20),
                  const Icon(Icons.chat_bubble_rounded,
                      color: Color(0xFF00C4A0), size: 18),
                  const SizedBox(width: 8),
                  const Text('Game Chat',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(color: Colors.white12, height: 1),
              Expanded(
                child: StreamBuilder<List<GameChatMessage>>(
                  stream: _svc.chatStream(widget.roomId),
                  builder: (_, snap) {
                    final msgs = snap.data ?? [];
                    if (msgs.isEmpty) {
                      return Center(
                        child: Text('No messages yet. Say something! 👋',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.35),
                                fontSize: 13)),
                      );
                    }
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (scrollCtrl.hasClients) {
                        scrollCtrl.jumpTo(scrollCtrl.position.maxScrollExtent);
                      }
                    });
                    return ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      itemCount: msgs.length,
                      itemBuilder: (_, i) {
                        final m = msgs[i];
                        final isMe = m.senderUid == _me;
                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.72),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: isMe
                                  ? const LinearGradient(colors: [
                                      Color(0xFF6C63FF),
                                      Color(0xFF5A52D5)
                                    ])
                                  : null,
                              color: isMe ? null : const Color(0xFF1E1E38),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isMe ? 16 : 4),
                                bottomRight: Radius.circular(isMe ? 4 : 16),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMe)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 3),
                                    child: Text(
                                        '${m.senderEmoji} ${m.senderName}',
                                        style: const TextStyle(
                                            color: Color(0xFF00C4A0),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                Text(m.text,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        height: 1.3)),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                              color: const Color(0xFF1E1E38),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.08))),
                          child: TextField(
                            controller: chatCtrl,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                                hintText: 'Type your answer…',
                                hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.25)),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10)),
                            onSubmitted: (_) async {
                              final text = chatCtrl.text;
                              chatCtrl.clear();
                              await _svc.sendChatMessage(
                                roomId: widget.roomId,
                                senderName: me.anonName,
                                senderEmoji: me.emoji,
                                text: text,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          final text = chatCtrl.text;
                          chatCtrl.clear();
                          await _svc.sendChatMessage(
                            roomId: widget.roomId,
                            senderName: me.anonName,
                            senderEmoji: me.emoji,
                            text: text,
                          );
                        },
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: [
                                Color(0xFF6C63FF),
                                Color(0xFF00C4A0)
                              ])),
                          child: const Icon(Icons.send_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Players Strip ──────────────────────────────────────────────
class _PlayersStrip extends StatelessWidget {
  final List<GamePlayer> players;
  final String currentTurnUid;
  const _PlayersStrip({required this.players, required this.currentTurnUid});
  @override
  Widget build(BuildContext context) => Container(
      height: 72,
      color: const Color(0xFF0D0D1A),
      child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: players.length,
          itemBuilder: (_, i) {
            final p = players[i];
            final isActive = p.uid == currentTurnUid;
            return Container(
                margin: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF6C63FF).withOpacity(0.15)
                        : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isActive
                            ? const Color(0xFF6C63FF)
                            : Colors.white.withOpacity(0.08),
                        width: isActive ? 1.5 : 1)),
                child: Row(children: [
                  Text(p.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(p.anonName,
                      style: TextStyle(
                          color: isActive
                              ? const Color(0xFF6C63FF)
                              : Colors.white.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight:
                              isActive ? FontWeight.w800 : FontWeight.w500)),
                  if (p.gender.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(_genderIcon(p.gender),
                        style: const TextStyle(fontSize: 11)),
                  ],
                  if (p.interest.isNotEmpty) ...[
                    const SizedBox(width: 3),
                    Text(_interestIcon(p.interest),
                        style: const TextStyle(fontSize: 11)),
                  ],
                  const SizedBox(width: 4),
                  Text('${p.score}',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.35), fontSize: 11))
                ]));
          }));

  // Small glyphs so gender/interest fit inside the compact strip
  // chip without needing full labels (full labels are shown in the
  // Room Settings sheet where space isn't constrained).
  String _genderIcon(String g) {
    switch (g) {
      case 'male':
        return '♂️';
      case 'female':
        return '♀️';
      case 'other':
        return '⚧';
      default:
        return '';
    }
  }

  String _interestIcon(String i) {
    switch (i) {
      case 'friendship':
        return '🤝';
      case 'dating':
        return '💕';
      case 'chatting':
        return '💬';
      case 'fun':
        return '🎉';
      default:
        return '';
    }
  }
}

// ── Pick Button ────────────────────────────────────────────────
class _PickBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _PickBtn(
      {required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4))
              ]),
          child: Center(
              child: Text(label,
                  style: TextStyle(
                      color: color, fontSize: 18, fontWeight: FontWeight.w800)))));
}