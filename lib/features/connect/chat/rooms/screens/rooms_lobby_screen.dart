// ============================================================
// PATH: lib/features/connect/rooms/screens/rooms_lobby_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rewirex/features/connect/chat/rooms/screens/room_screen.dart';
import '../models/room_model.dart';
import '../services/room_service.dart';

class RoomsLobbyScreen extends StatefulWidget {
  const RoomsLobbyScreen({super.key});
  @override State<RoomsLobbyScreen> createState() => _LobbyState();
}

class _LobbyState extends State<RoomsLobbyScreen> with SingleTickerProviderStateMixin {
  final RoomService _svc = RoomService();
  late TabController _tab;

  @override void initState() { super.initState(); _tab = TabController(length: 4, vsync: this); _svc.seedRoomsIfNeeded(); }
  @override void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0D0D1A),
    appBar: AppBar(backgroundColor: const Color(0xFF0D0D1A), elevation: 0,
      leading: IconButton(
        icon: Container(width: 36, height: 36,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: Colors.white.withOpacity(0.7))),
        onPressed: () => Navigator.pop(context)),
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ShaderMask(shaderCallback: (b) => const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)]).createShader(b),
          child: const Text('Global Rooms', style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800))),
        Text('Connect with warriors worldwide',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11))]),
      bottom: TabBar(controller: _tab, isScrollable: true, tabAlignment: TabAlignment.start,
        indicatorColor: const Color(0xFF6C63FF), indicatorWeight: 2.5,
        labelColor: const Color(0xFF6C63FF),
        unselectedLabelColor: Colors.white.withOpacity(0.35),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        tabs: const [Tab(text: 'All'), Tab(text: '💊 Addiction'),
                     Tab(text: '💚 Emotion'), Tab(text: '🕐 Time')])),
    body: TabBarView(controller: _tab, children: [
      _RoomList(stream: _svc.allStream()),
      _RoomList(stream: _svc.byCategoryStream(RoomCategory.addiction)),
      _RoomList(stream: _svc.byCategoryStream(RoomCategory.emotion)),
      _RoomList(stream: _svc.byCategoryStream(RoomCategory.timeOfDay)),
    ]));
}

class _RoomList extends StatelessWidget {
  final Stream<List<RoomModel>> stream;
  const _RoomList({required this.stream});

  @override
  Widget build(BuildContext context) => StreamBuilder<List<RoomModel>>(
    stream: stream,
    builder: (_, snap) {
      if (snap.connectionState == ConnectionState.waiting)
        return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF), strokeWidth: 2.5));
      final rooms   = snap.data ?? [];
      if (rooms.isEmpty) return Center(child: Icon(Icons.forum_outlined, size: 56, color: Colors.white.withOpacity(0.1)));
      final pinned  = rooms.where((r) => r.isPinned).toList();
      final regular = rooms.where((r) => !r.isPinned).toList();
      final all     = [...pinned, ...regular];

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        itemCount: all.length + (pinned.isNotEmpty ? 2 : 1),
        itemBuilder: (_, i) {
          if (i == 0 && pinned.isNotEmpty) return _header('FEATURED');
          if (pinned.isNotEmpty && i == pinned.length + 1) return _header('ALL ROOMS');
          final idx = pinned.isNotEmpty ? (i <= pinned.length ? i - 1 : i - 2) : i;
          if (idx < 0 || idx >= all.length) return const SizedBox.shrink();
          final r = all[idx];
          return _RoomCard(room: r, onTap: () => _enter(context, r));
        });
    });

  Widget _header(String t) => Padding(padding: const EdgeInsets.only(bottom: 12, top: 8),
    child: Text(t, style: TextStyle(color: Colors.white.withOpacity(0.35),
        fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2.5)));

  void _enter(BuildContext ctx, RoomModel room) => showModalBottomSheet(
    context: ctx, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => _AnonSheet(room: room, onEnter: (name) {
      Navigator.pop(ctx);
      Navigator.push(ctx, MaterialPageRoute(
          builder: (_) => RoomScreen(room: room, anonName: name)));
    }));
}

class _RoomCard extends StatelessWidget {
  final RoomModel room; final VoidCallback onTap;
  const _RoomCard({required this.room, required this.onTap});

  Color get _color => room.category == RoomCategory.addiction
      ? const Color(0xFF6C63FF) : room.category == RoomCategory.timeOfDay
      ? const Color(0xFFFFB74D) : const Color(0xFF00C4A0);

  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF141428),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: room.isPinned ? _color.withOpacity(0.3) : Colors.white.withOpacity(0.07),
            width: room.isPinned ? 1.5 : 1)),
      child: Row(children: [
        Container(width: 52, height: 52,
          decoration: BoxDecoration(color: _color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _color.withOpacity(0.2))),
          child: Center(child: Text(room.emoji, style: const TextStyle(fontSize: 26)))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(room.name, style: const TextStyle(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis)),
            if (room.isPinned) Container(margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: _color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8)),
                child: Text('Featured', style: TextStyle(color: _color, fontSize: 9, fontWeight: FontWeight.w800)))]),
          const SizedBox(height: 4),
          Text(room.description, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12, height: 1.4)),
          const SizedBox(height: 8),
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: room.onlineCount > 0 ? const Color(0xFF00C853).withOpacity(0.1) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle,
                    color: room.onlineCount > 0 ? const Color(0xFF00C853) : Colors.grey)),
                const SizedBox(width: 4),
                Text('${room.onlineCount} online', style: TextStyle(
                    color: room.onlineCount > 0 ? const Color(0xFF00C853) : Colors.white.withOpacity(0.3),
                    fontSize: 11, fontWeight: FontWeight.w600))])),
            const SizedBox(width: 8),
            Text('${room.totalMessages} msgs', style: TextStyle(
                color: Colors.white.withOpacity(0.25), fontSize: 11))])])),
        Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.2), size: 20)])));
}

class _AnonSheet extends StatefulWidget {
  final RoomModel room; final void Function(String) onEnter;
  const _AnonSheet({required this.room, required this.onEnter});
  @override State<_AnonSheet> createState() => _AnonSheetState();
}

class _AnonSheetState extends State<_AnonSheet> {
  final TextEditingController _ctrl = TextEditingController();
  String _err = '';
  static const _words = ['Warrior','Phoenix','Shadow','Storm','Blaze','Ghost','Titan','Nova','Echo','Comet'];

  @override void initState() { super.initState();
    _ctrl.text = '${_words[DateTime.now().millisecond % _words.length]}${DateTime.now().second}'; }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  void _enter() {
    final n = _ctrl.text.trim();
    if (n.isEmpty)   { setState(() => _err = 'Enter a name'); return; }
    if (n.length < 2){ setState(() => _err = 'Min 2 characters'); return; }
    if (n.length > 20){ setState(() => _err = 'Max 20 characters'); return; }
    HapticFeedback.mediumImpact(); widget.onEnter(n);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: Container(
      decoration: const BoxDecoration(color: Color(0xFF141428),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(4)))),
        const SizedBox(height: 20),
        Row(children: [
          Text(widget.room.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Entering ${widget.room.name}', style: const TextStyle(
                color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
            Text('Choose your anonymous name', style: TextStyle(
                color: Colors.white.withOpacity(0.4), fontSize: 12))]))]),
        const SizedBox(height: 20),
        TextField(controller: _ctrl, autofocus: true, maxLength: 20,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          onChanged: (_) { if (_err.isNotEmpty) setState(() => _err = ''); },
          onSubmitted: (_) => _enter(),
          decoration: InputDecoration(
            hintText: 'e.g. Warrior42',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
            errorText: _err.isNotEmpty ? _err : null,
            errorStyle: const TextStyle(color: Color(0xFFE53935)),
            filled: true, fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5)),
            counterStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8,
          children: _words.take(5).map((w) {
            final n = '$w${DateTime.now().second % 99 + 1}';
            return GestureDetector(onTap: () => setState(() => _ctrl.text = n),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.1))),
                child: Text(n, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12))));
          }).toList()),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 52,
          child: DecoratedBox(decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)])),
            child: ElevatedButton(onPressed: _enter,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('Enter Room', style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)))))])));
}

