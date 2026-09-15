import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:rewirex/features/connect/chat/rooms/models/room_model.dart';
import 'package:rewirex/features/connect/chat/rooms/services/room_service.dart';

// ============================================================
// PATH: lib/features/connect/rooms/screens/room_screen.dart
// (included below — split into separate file if preferred)
// ============================================================

class RoomScreen extends StatefulWidget {
  final RoomModel room; final String anonName;
  const RoomScreen({super.key, required this.room, required this.anonName});
  @override State<RoomScreen> createState() => _RoomState();
}

class _RoomState extends State<RoomScreen> with WidgetsBindingObserver {
  final RoomService           _svc    = RoomService();
  final TextEditingController _ctrl   = TextEditingController();
  final ScrollController      _scroll = ScrollController();
  final String _me = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _sending = false;
  Timer? _presenceTimer;
  bool _joined = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _join();
  }

  Future<void> _join() async {
    try {
      await _svc.joinRoom(widget.room.id, widget.anonName);
      _joined = true;
      _presenceTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (_joined) _svc.heartbeatRoom(widget.room.id, widget.anonName);
      });
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached || state == AppLifecycleState.hidden) {
      if (_joined) {
        _joined = false;
        _svc.leaveRoom(widget.room.id);
      }
    } else if (state == AppLifecycleState.resumed && !_joined) {
      _join();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _presenceTimer?.cancel();
    if (_joined) _svc.leaveRoom(widget.room.id);
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Color get _cat => widget.room.category == RoomCategory.addiction
      ? const Color(0xFF6C63FF) : widget.room.category == RoomCategory.timeOfDay
      ? const Color(0xFFFFB74D) : const Color(0xFF00C4A0);

  Future<void> _send() async {
    if (_ctrl.text.trim().isEmpty || _sending) return;
    final t = _ctrl.text.trim(); setState(() => _sending = true); _ctrl.clear();
    try { await _svc.sendMessage(widget.room.id, widget.anonName, t); _scrollBottom(); }
    finally { if (mounted) setState(() => _sending = false); }
  }

  void _scrollBottom() => Future.delayed(const Duration(milliseconds: 100), () {
    if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0D0D1A),
    appBar: AppBar(backgroundColor: const Color(0xFF0D0D1A), elevation: 0,
      leading: IconButton(
        icon: Container(width: 36, height: 36,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: Colors.white.withOpacity(0.7))),
        onPressed: () => Navigator.pop(context)),
      title: Row(children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(color: _cat.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(widget.room.emoji, style: const TextStyle(fontSize: 18)))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.room.name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis),
          Text('${widget.room.onlineCount} online · You: ${widget.anonName}',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11))]))])),
    body: Column(children: [
      Expanded(child: StreamBuilder<List<RoomMessageModel>>(
        stream: _svc.messagesStream(widget.room.id),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF), strokeWidth: 2.5));
          final msgs = snap.data ?? [];
          if (msgs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(widget.room.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('Be the first to say something!',
                style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 15))]));
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollBottom());
          return ListView.builder(
            controller: _scroll, padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            itemCount: msgs.length,
            itemBuilder: (_, i) {
              final msg  = msgs[i]; final isMe = msg.senderUid == _me;
              final showDate = i == 0 || !_sameDay(msgs[i-1].timestamp, msg.timestamp);
              final showName = !isMe && !msg.isSystem &&
                  (i == 0 || msgs[i-1].senderUid != msg.senderUid || msgs[i-1].isSystem);
              return Column(children: [
                if (showDate) _dateDivider(msg.timestamp),
                if (msg.isSystem) _sysMsq(msg.text)
                else _bubble(msg, isMe, showName)]);
            });
        })),
      Container(
        padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        color: const Color(0xFF0D0D1A),
        child: Row(children: [
          Expanded(child: Container(
            decoration: BoxDecoration(color: const Color(0xFF141428),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.08))),
            child: TextField(controller: _ctrl, maxLines: null,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Message as ${widget.anonName}…',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
              onSubmitted: (_) => _send()))),
          const SizedBox(width: 10),
          GestureDetector(onTap: _send, child: Container(width: 46, height: 46,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: LinearGradient(colors: [_cat, const Color(0xFF6C63FF)]),
              boxShadow: [BoxShadow(color: _cat.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]),
            child: _sending
                ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded, color: Colors.white, size: 20)))]))]));

  Widget _bubble(RoomMessageModel msg, bool isMe, bool showName) => GestureDetector(
    onLongPress: () { if (!isMe) HapticFeedback.mediumImpact(); },
    child: Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(margin: const EdgeInsets.only(bottom: 4),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
          if (showName) Padding(padding: const EdgeInsets.only(left: 4, bottom: 3),
              child: Text(msg.anonName, style: TextStyle(color: _cat, fontSize: 11, fontWeight: FontWeight.w700))),
          Row(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isMe) GestureDetector(onTap: () => _svc.toggleLike(widget.room.id, msg.id),
                  child: Padding(padding: const EdgeInsets.only(right: 6, bottom: 8),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(msg.likedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 14, color: msg.likedByMe ? const Color(0xFFEF5350) : Colors.white.withOpacity(0.25)),
                      if (msg.likeCount > 0) Text(' ${msg.likeCount}',
                          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10))]))),
                Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isMe ? LinearGradient(colors: [_cat, _cat.withOpacity(0.7)]) : null,
                    color: isMe ? null : const Color(0xFF1E1E38),
                    borderRadius: BorderRadius.only(topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMe ? 18 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 18))),
                  child: Text(msg.text, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)))]),
          Padding(padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
              child: Text(DateFormat('HH:mm').format(msg.timestamp),
                  style: TextStyle(color: Colors.white.withOpacity(0.22), fontSize: 10)))]))));

  Widget _sysMsq(String text) => Padding(padding: const EdgeInsets.symmetric(vertical: 8),
    child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12)))));

  Widget _dateDivider(DateTime date) {
    final now = DateTime.now(); final today = DateTime(now.year, now.month, now.day);
    final d   = DateTime(date.year, date.month, date.day);
    final lbl = d == today ? 'Today' : d == today.subtract(const Duration(days: 1))
        ? 'Yesterday' : DateFormat('MMM d').format(date);
    return Padding(padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Expanded(child: Divider(color: Colors.white.withOpacity(0.07))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(lbl, style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 11, fontWeight: FontWeight.w600))),
        Expanded(child: Divider(color: Colors.white.withOpacity(0.07)))]));
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}