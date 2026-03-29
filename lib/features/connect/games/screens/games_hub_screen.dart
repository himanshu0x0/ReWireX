// ============================================================
// PATH: lib/features/connect/games/screens/games_hub_screen.dart
// ============================================================

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/game_room_model.dart';
import '../services/game_room_service.dart';

// ── Games Hub ─────────────────────────────────────────────────
class GamesHubScreen extends StatefulWidget {
  const GamesHubScreen({super.key});
  @override State<GamesHubScreen> createState() => _HubState();
}

class _HubState extends State<GamesHubScreen> {
  final GameRoomService        _svc      = GameRoomService();
  final TextEditingController  _codCtrl  = TextEditingController();

  @override void dispose() { _codCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0D0D1A),
    appBar: AppBar(
      backgroundColor: const Color(0xFF0D0D1A), elevation: 0,
      leading: IconButton(
        icon: Container(width: 36, height: 36,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.arrow_back_ios_new_rounded, size: 15,
              color: Colors.white.withOpacity(0.7))),
        onPressed: () => Navigator.pop(context)),
      title: ShaderMask(
        shaderCallback: (b) => const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)]).createShader(b),
        child: const Text('Truth & Dare', style: TextStyle(
            color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)))),
    body: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Hero banner
        Container(
          width: double.infinity, padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            boxShadow: [BoxShadow(
                color: const Color(0xFF6C63FF).withOpacity(0.3),
                blurRadius: 24, offset: const Offset(0, 8))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('🎮', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            const Text('Play with Warriors\nWorldwide', style: TextStyle(
                color: Colors.white, fontSize: 22,
                fontWeight: FontWeight.w800, height: 1.3)),
            const SizedBox(height: 8),
            Text('Create public rooms or private rooms with a code.\nTruth & Dare with people from across the globe.',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.75), fontSize: 13, height: 1.5))])),
        const SizedBox(height: 24),

        Row(children: [
          Expanded(child: _ActionBtn(
              label: 'Create Room', icon: Icons.add_rounded,
              color: const Color(0xFF6C63FF),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const CreateGameScreen())))),
          const SizedBox(width: 12),
          Expanded(child: _ActionBtn(
              label: 'Join by Code', icon: Icons.tag_rounded,
              color: const Color(0xFF00C4A0),
              onTap: _showCodeSheet)),
        ]),
        const SizedBox(height: 24),

        _label('OPEN PUBLIC ROOMS'),
        const SizedBox(height: 12),
        StreamBuilder<List<GameRoomModel>>(
          stream: _svc.publicRoomsStream(),
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting)
              return const Center(child: Padding(padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(
                      color: Color(0xFF6C63FF), strokeWidth: 2.5)));
            final rooms = snap.data ?? [];
            if (rooms.isEmpty) return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: const Color(0xFF141428),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.07))),
              child: Center(child: Column(children: [
                const Text('🎲', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                Text('No open rooms yet. Create one!',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.45), fontSize: 14))])));
            return Column(children: rooms.map((r) =>
                _RoomTile(room: r, onTap: () => _joinPublic(r))).toList());
          }),
      ])));

  // ── Join by code sheet ────────────────────────────────────────
  void _showCodeSheet() => showModalBottomSheet(
    context: context, isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(color: Color(0xFF141428),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 20),
          const Text('Enter Room Code', style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          TextField(
            controller: _codCtrl, autofocus: true,
            textCapitalization: TextCapitalization.characters, maxLength: 6,
            style: const TextStyle(color: Colors.white, fontSize: 20,
                fontWeight: FontWeight.w800, letterSpacing: 6),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'XXXXXX',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.2),
                  fontSize: 20, letterSpacing: 6),
              filled: true, fillColor: Colors.white.withOpacity(0.05),
              counterStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: Color(0xFF00C4A0), width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14))),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: () { Navigator.pop(context); _joinByCode(); },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C4A0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: const Text('Join Room', style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700, fontSize: 16))))]))));

  // ── Helpers ───────────────────────────────────────────────────
  Future<void> _joinByCode() async {
    final code = _codCtrl.text.trim().toUpperCase();
    if (code.length != 6) return;
    _showAnonSheet((name, emoji) async {
      final room = await _svc.joinByCode(code, name, emoji);
      if (!mounted) return;
      if (room == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Room not found or full.'),
            backgroundColor: Color(0xFFE53935)));
        return;
      }
      Navigator.push(context, MaterialPageRoute(
          builder: (_) => GameRoomScreen(roomId: room.id, anonName: name)));
    });
  }

  Future<void> _joinPublic(GameRoomModel room) async =>
      _showAnonSheet((name, emoji) async {
        final ok = await _svc.joinRoom(room.id, name, emoji);
        if (!mounted) return;
        if (!ok) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Room is full or no longer available.'),
              backgroundColor: Color(0xFFE53935)));
          return;
        }
        Navigator.push(context, MaterialPageRoute(
            builder: (_) => GameRoomScreen(
                roomId: room.id, anonName: name)));
      });

  void _showAnonSheet(void Function(String, String) onDone) {
    final ctrl = TextEditingController();
    const emojis = ['🦁','🐯','🦊','🐺','🦅','🐉','⚔️','🔥','🌟','💎'];
    String pickedEmoji = emojis[Random().nextInt(emojis.length)];
    const words = ['Warrior','Phoenix','Shadow','Storm','Blaze'];
    ctrl.text = '${words[DateTime.now().millisecond % words.length]}'
        '${DateTime.now().second}';

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(color: Color(0xFF141428),
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(28))),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Center(child: Container(width: 36, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4)))),
              const SizedBox(height: 20),
              const Text('Who are you in this game?', style: TextStyle(
                  color: Colors.white, fontSize: 18,
                  fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              // Emoji picker row
              SizedBox(height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: emojis.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: 8),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () =>
                        setSheet(() => pickedEmoji = emojis[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48, height: 48,
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
                      child: Center(child: Text(emojis[i],
                          style: const TextStyle(fontSize: 24))))))),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl, autofocus: true, maxLength: 20,
                style: const TextStyle(
                    color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Your game name',
                  hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.25)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  counterStyle: TextStyle(
                      color: Colors.white.withOpacity(0.3)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.1))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.1))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: Color(0xFF6C63FF), width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14))),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(colors: [
                        Color(0xFF6C63FF), Color(0xFF00C4A0)])),
                  child: ElevatedButton(
                    onPressed: () {
                      if (ctrl.text.trim().length < 2) return;
                      Navigator.pop(ctx);
                      onDone(ctrl.text.trim(), pickedEmoji);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(16))),
                    child: const Text("Let's Play!", style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)))))])))));
  }

  Widget _label(String t) => Text(t, style: TextStyle(
      color: Colors.white.withOpacity(0.35),
      fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2.5));
}

// ── Action Button ──────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final String label; final IconData icon;
  final Color color; final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.icon,
      required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Column(children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(
            color: color, fontSize: 13, fontWeight: FontWeight.w700))])));
}

// ── Room Tile ──────────────────────────────────────────────────
class _RoomTile extends StatelessWidget {
  final GameRoomModel room; final VoidCallback onTap;
  const _RoomTile({required this.room, required this.onTap});

  Widget _chip(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10)),
    child: Text(t, style: TextStyle(
        color: c, fontSize: 10, fontWeight: FontWeight.w600)));

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF141428),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.07))),
      child: Row(children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF6C63FF).withOpacity(0.2))),
          child: const Center(child: Text('🎮',
              style: TextStyle(fontSize: 22)))),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(room.name, style: const TextStyle(color: Colors.white,
              fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Row(children: [
            _chip('${room.playerCount}/${room.maxPlayers} players',
                const Color(0xFF6C63FF)),
            const SizedBox(width: 6),
            _chip(room.category, const Color(0xFF00C4A0)),
            if (room.status == GameRoomStatus.waiting) ...[
              const SizedBox(width: 6),
              _chip('Waiting', Colors.amber)]])])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20)),
          child: const Text('Join', style: TextStyle(
              color: Color(0xFF6C63FF),
              fontSize: 13, fontWeight: FontWeight.w700)))])));
}

// ============================================================
// PATH: lib/features/connect/games/screens/create_game_screen.dart
// ============================================================

class CreateGameScreen extends StatefulWidget {
  const CreateGameScreen({super.key});
  @override State<CreateGameScreen> createState() => _CreateState();
}

class _CreateState extends State<CreateGameScreen> {
  final GameRoomService       _svc      = GameRoomService();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _anonCtrl = TextEditingController();
  GameRoomType _type       = GameRoomType.public;
  String       _category   = 'mixed';
  int          _maxPlayers = 8;
  int          _rounds     = 10;
  bool         _creating   = false;
  String       _pickedEmoji = '🎮';
  static const _emojis = [
    '🦁','🐯','🦊','🐺','🦅','🐉','⚔️','🔥','🌟','💎'];

  @override void initState() {
    super.initState();
    _nameCtrl.text = 'Game Room ${DateTime.now().minute}';
    _anonCtrl.text = 'Warrior${DateTime.now().second}';
  }
  @override void dispose() {
    _nameCtrl.dispose(); _anonCtrl.dispose(); super.dispose();
  }

  Future<void> _create() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _anonCtrl.text.trim().isEmpty || _creating) return;
    setState(() => _creating = true);
    try {
      final room = await _svc.createRoom(
        name:        _nameCtrl.text.trim(),
        type:        _type,
        anonName:    _anonCtrl.text.trim(),
        emoji:       _pickedEmoji,
        category:    _category,
        maxPlayers:  _maxPlayers,
        totalRounds: _rounds,
      );
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => GameRoomScreen(
              roomId: room.id, anonName: _anonCtrl.text.trim())));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0D0D1A),
    appBar: AppBar(
      backgroundColor: const Color(0xFF0D0D1A), elevation: 0,
      leading: IconButton(
        icon: Container(width: 36, height: 36,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.arrow_back_ios_new_rounded, size: 15,
              color: Colors.white.withOpacity(0.7))),
        onPressed: () => Navigator.pop(context)),
      title: const Text('Create Game Room', style: TextStyle(
          color: Colors.white, fontSize: 20,
          fontWeight: FontWeight.w800))),
    body: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        _sect('ROOM TYPE'),
        Row(children: [
          Expanded(child: _typeBtn('🌍 Public', GameRoomType.public)),
          const SizedBox(width: 12),
          Expanded(child: _typeBtn('🔒 Private', GameRoomType.private))]),
        const SizedBox(height: 20),
        _sect('ROOM NAME'),
        _field(_nameCtrl, 'e.g. Late Night Warriors'),
        const SizedBox(height: 20),
        _sect('YOUR EMOJI'),
        SizedBox(height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _emojis.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => setState(() => _pickedEmoji = _emojis[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44, height: 44,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: _pickedEmoji == _emojis[i]
                      ? const Color(0xFF6C63FF).withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
                  border: Border.all(
                      color: _pickedEmoji == _emojis[i]
                          ? const Color(0xFF6C63FF)
                          : Colors.transparent,
                      width: 2)),
                child: Center(child: Text(_emojis[i],
                    style: const TextStyle(fontSize: 22))))))),
        const SizedBox(height: 10),
        _sect('YOUR GAME NAME'),
        _field(_anonCtrl, 'Your anonymous name'),
        const SizedBox(height: 20),
        _sect('QUESTION CATEGORY'),
        Wrap(spacing: 8, runSpacing: 8,
          children: const {
            'mixed':    '🎲 Mixed',
            'fun':      '😄 Fun',
            'spicy':    '🌶 Spicy',
            'recovery': '💚 Recovery',
          }.entries.map((e) => GestureDetector(
            onTap: () => setState(() => _category = e.key),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _category == e.key
                    ? const Color(0xFF6C63FF).withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _category == e.key
                        ? const Color(0xFF6C63FF)
                        : Colors.white.withOpacity(0.1))),
              child: Text(e.value, style: TextStyle(
                  color: _category == e.key
                      ? const Color(0xFF6C63FF)
                      : Colors.white.withOpacity(0.55),
                  fontSize: 13,
                  fontWeight: FontWeight.w600))))).toList()),
        const SizedBox(height: 20),
        _sect('MAX PLAYERS  ($_maxPlayers)'),
        Slider(
          value: _maxPlayers.toDouble(), min: 2, max: 12, divisions: 10,
          activeColor: const Color(0xFF6C63FF),
          inactiveColor: Colors.white.withOpacity(0.1),
          onChanged: (v) => setState(() => _maxPlayers = v.toInt())),
        _sect('TOTAL ROUNDS  ($_rounds)'),
        Slider(
          value: _rounds.toDouble(), min: 5, max: 30, divisions: 5,
          activeColor: const Color(0xFF00C4A0),
          inactiveColor: Colors.white.withOpacity(0.1),
          onChanged: (v) => setState(() => _rounds = v.toInt())),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)]),
              boxShadow: [BoxShadow(
                  color: const Color(0xFF6C63FF).withOpacity(0.4),
                  blurRadius: 20, offset: const Offset(0, 8))]),
            child: ElevatedButton(
              onPressed: _creating ? null : _create,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18))),
              child: _creating
                  ? const CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)
                  : Text(
                      _type == GameRoomType.private
                          ? '🔒 Create Private Room'
                          : '🌍 Create Public Room',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)))))])));

  Widget _sect(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(t, style: TextStyle(
        color: Colors.white.withOpacity(0.35), fontSize: 11,
        fontWeight: FontWeight.w700, letterSpacing: 2)));

  Widget _field(TextEditingController c, String hint) => TextField(
    controller: c,
    style: const TextStyle(color: Colors.white, fontSize: 15),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
      filled: true, fillColor: const Color(0xFF141428),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
              color: Color(0xFF6C63FF), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14)));

  Widget _typeBtn(String label, GameRoomType t) =>
      Expanded(child: GestureDetector(
        onTap: () => setState(() => _type = t),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _type == t
                ? const Color(0xFF6C63FF).withOpacity(0.15)
                : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: _type == t
                    ? const Color(0xFF6C63FF)
                    : Colors.white.withOpacity(0.1),
                width: 1.5)),
          child: Text(label, textAlign: TextAlign.center,
              style: TextStyle(
                  color: _type == t
                      ? const Color(0xFF6C63FF)
                      : Colors.white.withOpacity(0.45),
                  fontSize: 14,
                  fontWeight: FontWeight.w700)))));
}

// ============================================================
// PATH: lib/features/connect/games/screens/game_room_screen.dart
// ============================================================

class GameRoomScreen extends StatefulWidget {
  final String roomId, anonName;
  const GameRoomScreen({super.key, required this.roomId,
      required this.anonName});
  @override State<GameRoomScreen> createState() => _GameState();
}

class _GameState extends State<GameRoomScreen>
    with SingleTickerProviderStateMixin {
  final GameRoomService _svc = GameRoomService();
  final String _me = FirebaseAuth.instance.currentUser?.uid ?? '';
  GameQuestion? _currentQ;
  final List<String> _usedIds = [];
  bool    _picked   = false;
  Timer?  _timer;
  int     _timeLeft = 0;
  late AnimationController _pulse;

  @override void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }
  @override void dispose() {
    _timer?.cancel(); _pulse.dispose(); super.dispose();
  }

  void _pickQuestion(QuestionType type) {
    final q = _svc.pickQuestion(type, _usedIds);
    setState(() { _currentQ = q; _picked = true; _usedIds.add(q.id); });
    if (q.timeSeconds > 0) {
      setState(() => _timeLeft = q.timeSeconds);
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) { t.cancel(); return; }
        setState(() => _timeLeft--);
        if (_timeLeft <= 0) t.cancel();
      });
    }
  }

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<GameRoomModel?>(
        stream: _svc.roomStream(widget.roomId),
        builder: (_, rSnap) {
          final room = rSnap.data;
          if (room == null) return const Scaffold(
              backgroundColor: Color(0xFF0D0D1A),
              body: Center(child: CircularProgressIndicator(
                  color: Color(0xFF6C63FF))));
          if (room.status == GameRoomStatus.finished)
            return _buildFinished(room);
          return StreamBuilder<List<GamePlayer>>(
            stream: _svc.playersStream(widget.roomId),
            builder: (_, pSnap) {
              final players = pSnap.data ?? [];
              final isMyTurn = room.currentTurnUid == _me;
              final amHost   = room.hostUid == _me;
              return Scaffold(
                backgroundColor: const Color(0xFF0D0D1A),
                appBar: _appBar(room),
                body: Column(children: [
                  _PlayersStrip(players: players,
                      currentTurnUid: room.currentTurnUid),
                  Expanded(child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    child: Column(children: [
                      if (room.type == GameRoomType.private &&
                          room.roomCode != null)
                        _codeCard(room.roomCode!),
                      const SizedBox(height: 16),
                      if (room.status == GameRoomStatus.waiting)
                        _buildWaiting(room, players, amHost)
                      else
                        _buildPlaying(room, players, isMyTurn)])))]));
            });
        });

  // ── Waiting ───────────────────────────────────────────────────
  Widget _buildWaiting(GameRoomModel room,
      List<GamePlayer> players, bool amHost) =>
      Column(children: [
        Container(padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: const Color(0xFF141428),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: const Color(0xFF6C63FF).withOpacity(0.2))),
          child: Column(children: [
            const Text('⏳', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text('Waiting for players…', style: TextStyle(
                color: Colors.white, fontSize: 20,
                fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('${players.length}/${room.maxPlayers} joined',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14)),
            if (!room.canStart) ...[
              const SizedBox(height: 8),
              Text('Need at least 2 players to start',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 12))]])),
        const SizedBox(height: 16),
        if (amHost && room.canStart)
          SizedBox(width: double.infinity, height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(colors: [
                  Color(0xFF6C63FF), Color(0xFF00C4A0)]),
                boxShadow: [BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.4),
                    blurRadius: 20, offset: const Offset(0, 8))]),
              child: ElevatedButton.icon(
                onPressed: () => _svc.startGame(widget.roomId),
                icon: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 24),
                label: const Text('Start Game!', style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700, fontSize: 17)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18))))))
        else if (!amHost)
          Container(padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14)),
            child: Text('Waiting for the host to start…',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 13)))]);

  // ── Playing ───────────────────────────────────────────────────
  Widget _buildPlaying(GameRoomModel room,
      List<GamePlayer> players, bool isMyTurn) =>
      Column(children: [
        Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF141428),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: isMyTurn
                      ? const Color(0xFF6C63FF).withOpacity(0.3)
                      : Colors.white.withOpacity(0.07))),
          child: Row(children: [
            AnimatedBuilder(animation: _pulse, builder: (_, __) =>
                Container(width: 10, height: 10,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    color: (isMyTurn
                            ? const Color(0xFF6C63FF)
                            : const Color(0xFF00C4A0))
                        .withOpacity(isMyTurn
                            ? 0.5 + _pulse.value * 0.5 : 1)))),
            const SizedBox(width: 10),
            Expanded(child: Text(
                isMyTurn
                    ? '🎯 It\'s YOUR turn!'
                    : '⏳ ${room.currentTurnName}\'s turn',
                style: TextStyle(color: Colors.white, fontSize: 16,
                    fontWeight: isMyTurn
                        ? FontWeight.w800 : FontWeight.w500))),
            Text('Round ${room.roundNumber}/${room.totalRounds}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12))])),
        const SizedBox(height: 20),
        if (!_picked && isMyTurn) ...[
          const Text('Choose wisely…', style: TextStyle(
              color: Colors.white, fontSize: 18,
              fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _PickBtn(
                label: '🤔 Truth',
                color: const Color(0xFF6C63FF),
                onTap: () => _pickQuestion(QuestionType.truth))),
            const SizedBox(width: 16),
            Expanded(child: _PickBtn(
                label: '🎲 Dare',
                color: const Color(0xFF00C4A0),
                onTap: () => _pickQuestion(QuestionType.dare)))])]
        else if (_currentQ != null && isMyTurn)
          _buildQuestionCard(_currentQ!, room, players)
        else if (!isMyTurn)
          Container(padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: const Color(0xFF141428),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withOpacity(0.07))),
            child: Column(children: [
              const Text('👀', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text('Watch ${room.currentTurnName} play!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 15))]))]);

  Widget _buildQuestionCard(GameQuestion q, GameRoomModel room,
      List<GamePlayer> players) =>
      Column(children: [
        Container(width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
                colors: q.type == QuestionType.truth
                    ? [const Color(0xFF6C63FF), const Color(0xFF5A52D5)]
                    : [const Color(0xFF00C4A0), const Color(0xFF00A085)])),
          child: Column(children: [
            Text(q.type == QuestionType.truth
                ? '🤔 TRUTH' : '🎲 DARE',
                style: const TextStyle(color: Colors.white, fontSize: 13,
                    fontWeight: FontWeight.w800, letterSpacing: 2)),
            const SizedBox(height: 16),
            Text(q.text, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white,
                    fontSize: 18, fontWeight: FontWeight.w700,
                    height: 1.4)),
            if (q.timeSeconds > 0 && _timeLeft > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('⏱ $_timeLeft seconds', style: const TextStyle(
                    color: Colors.white, fontSize: 14,
                    fontWeight: FontWeight.w700)))]])),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: SizedBox(height: 52,
            child: OutlinedButton.icon(
              onPressed: () async {
                await _svc.completeTurn(
                    roomId: widget.roomId, room: room,
                    players: players, completed: false,
                    questionText: q.text,
                    questionType: q.type);
                setState(() { _picked = false; _currentQ = null; });
              },
              icon: const Icon(Icons.close_rounded,
                  color: Color(0xFFE53935), size: 20),
              label: const Text('Skip', style: TextStyle(
                  color: Color(0xFFE53935),
                  fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE53935)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)))))),
          const SizedBox(width: 12),
          Expanded(child: SizedBox(height: 52,
            child: ElevatedButton.icon(
              onPressed: () async {
                await _svc.completeTurn(
                    roomId: widget.roomId, room: room,
                    players: players, completed: true,
                    questionText: q.text,
                    questionType: q.type);
                setState(() { _picked = false; _currentQ = null; });
              },
              icon: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 20),
              label: const Text('Done! ✅', style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))))))])]);

  Widget _buildFinished(GameRoomModel room) =>
      StreamBuilder<List<GamePlayer>>(
        stream: _svc.playersStream(widget.roomId),
        builder: (_, snap) {
          final players = [...(snap.data ?? [])]
            ..sort((a, b) => b.score.compareTo(a.score));
          return Scaffold(
            backgroundColor: const Color(0xFF0D0D1A),
            body: SafeArea(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                const SizedBox(height: 32),
                const Text('🏆', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                const Text('Game Over!', style: TextStyle(
                    color: Colors.white, fontSize: 28,
                    fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Final Scores', style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 14)),
                const SizedBox(height: 24),
                Expanded(child: ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (_, i) {
                    final p = players[i];
                    const medals = ['🥇','🥈','🥉'];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: const Color(0xFF141428),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: i == 0
                                  ? const Color(0xFFFFD700).withOpacity(0.3)
                                  : Colors.white.withOpacity(0.07))),
                      child: Row(children: [
                        Text(i < 3 ? medals[i] : '${i+1}',
                            style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 12),
                        Text(p.emoji,
                            style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(p.anonName,
                            style: TextStyle(
                                color: p.uid == _me
                                    ? const Color(0xFF6C63FF)
                                    : Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700))),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20)),
                          child: Text('${p.score} pts',
                              style: const TextStyle(
                                  color: Color(0xFF6C63FF),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)))]));
                  })),
                SizedBox(width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.popUntil(
                        context, (r) => r.isFirst),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                    child: const Text('Back to Hub', style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16))))]))));
        });

  AppBar _appBar(GameRoomModel room) => AppBar(
    backgroundColor: const Color(0xFF0D0D1A), elevation: 0,
    leading: IconButton(
      icon: Container(width: 36, height: 36,
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(Icons.arrow_back_ios_new_rounded, size: 15,
            color: Colors.white.withOpacity(0.7))),
      onPressed: () {
        _svc.leaveRoom(widget.roomId);
        Navigator.pop(context);
      }),
    title: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
      Text(room.name, style: const TextStyle(
          color: Colors.white, fontSize: 15,
          fontWeight: FontWeight.w700)),
      Row(children: [
        if (room.type == GameRoomType.private)
          Text('🔒 ${room.roomCode}  ·  ',
              style: const TextStyle(
                  color: Color(0xFF6C63FF),
                  fontSize: 11, fontWeight: FontWeight.w700)),
        Text('${room.playerCount} players  ·  '
            '${room.status == GameRoomStatus.waiting ? "Waiting" : "Playing"}',
            style: TextStyle(
                color: Colors.white.withOpacity(0.4), fontSize: 11))])]),
    actions: [IconButton(
        icon: Icon(Icons.exit_to_app_rounded,
            color: Colors.white.withOpacity(0.4)),
        onPressed: () {
          _svc.leaveRoom(widget.roomId);
          Navigator.pop(context);
        })]);

  Widget _codeCard(String code) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFF6C63FF).withOpacity(0.25))),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.tag_rounded, color: Color(0xFF6C63FF), size: 16),
      const SizedBox(width: 8),
      Text('Room Code: ', style: TextStyle(
          color: Colors.white.withOpacity(0.5), fontSize: 13)),
      Text(code, style: const TextStyle(
          color: Color(0xFF6C63FF), fontSize: 18,
          fontWeight: FontWeight.w800, letterSpacing: 4)),
      const SizedBox(width: 8),
      GestureDetector(
          onTap: () => Clipboard.setData(ClipboardData(text: code)),
          child: const Icon(Icons.copy_rounded,
              color: Color(0xFF6C63FF), size: 16))]));
}

// ── Players Strip ──────────────────────────────────────────────
class _PlayersStrip extends StatelessWidget {
  final List<GamePlayer> players;
  final String currentTurnUid;
  const _PlayersStrip(
      {required this.players, required this.currentTurnUid});
  @override
  Widget build(BuildContext context) =>
      Container(height: 72, color: const Color(0xFF0D0D1A),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: players.length,
          itemBuilder: (_, i) {
            final p        = players[i];
            final isActive = p.uid == currentTurnUid;
            return Container(
              margin: const EdgeInsets.only(
                  right: 12, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
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
                Text(p.emoji,
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(p.anonName, style: TextStyle(
                    color: isActive
                        ? const Color(0xFF6C63FF)
                        : Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: isActive
                        ? FontWeight.w800 : FontWeight.w500)),
                const SizedBox(width: 4),
                Text('${p.score}', style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 11))]));
          }));
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
          boxShadow: [BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 16, offset: const Offset(0, 4))]),
      child: Center(child: Text(label, style: TextStyle(
          color: color, fontSize: 18, fontWeight: FontWeight.w800)))));
}