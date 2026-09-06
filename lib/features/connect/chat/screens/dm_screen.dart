// ============================================================
// PATH: lib/features/connect/chat/screens/dm_screen.dart
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/dm_message_model.dart';
import '../services/dm_service.dart';
import '../services/friend_service.dart';

class DmScreen extends StatefulWidget {
  final String otherUid;
  final String otherUsername;
  final String otherDisplayName;
  final String otherPhotoUrl;
  final bool   isOnline;

  const DmScreen({
    super.key,
    required this.otherUid,
    required this.otherUsername,
    required this.otherDisplayName,
    required this.otherPhotoUrl,
    this.isOnline = false,
  });

  @override
  State<DmScreen> createState() => _DmScreenState();
}

class _DmScreenState extends State<DmScreen> with WidgetsBindingObserver {
  final DmService             _svc    = DmService();
  final FriendService         _fsvc   = FriendService();
  final TextEditingController _ctrl   = TextEditingController();
  final ScrollController      _scroll = ScrollController();
  final String _me = FirebaseAuth.instance.currentUser!.uid;

  DmMessageModel? _replyTo;
  DmMessageModel? _editingMsg;
  bool   _sending   = false;
  Timer? _typingTimer;
  bool   _isTyping  = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _svc.markDelivered(widget.otherUid);
    _svc.markAsRead(widget.otherUid);
    _fsvc.setOnline(true);
    _ctrl.addListener(_onTextChanged);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _svc.setTyping(widget.otherUid, false);
      _fsvc.setOnline(false);
    } else if (state == AppLifecycleState.resumed) {
      _fsvc.setOnline(true);
      _svc.markAsRead(widget.otherUid);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _typingTimer?.cancel();
    _svc.setTyping(widget.otherUid, false);
    _ctrl.removeListener(_onTextChanged);
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ── Typing ─────────────────────────────────────────────────
  void _onTextChanged() {
    if (_ctrl.text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      _svc.setTyping(widget.otherUid, true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _isTyping = false;
      _svc.setTyping(widget.otherUid, false);
    });
    if (_ctrl.text.isEmpty) {
      _isTyping = false;
      _svc.setTyping(widget.otherUid, false);
    }
  }

  // ── Send / Edit ────────────────────────────────────────────
  Future<void> _send() async {
    if (_ctrl.text.trim().isEmpty || _sending) return;
    final text    = _ctrl.text.trim();
    final reply   = _replyTo;
    final editing = _editingMsg;
    setState(() { _sending = true; _replyTo = null; _editingMsg = null; });
    _ctrl.clear();
    _typingTimer?.cancel();
    _isTyping = false;

    try {
      if (editing != null) {
        await _svc.editMessage(widget.otherUid, editing.id, text);
      } else {
        await _svc.sendMessage(
          otherUid:         widget.otherUid,
          otherUsername:    widget.otherUsername,
          otherDisplayName: widget.otherDisplayName,
          otherPhotoUrl:    widget.otherPhotoUrl,
          text:             text,
          replyToId:        reply?.id,
          replyPreview:     reply?.text,
          replyToName:      reply?.senderName,
        );
      }
      _scrollBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to send: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _startEditing(DmMessageModel msg) {
    setState(() { _editingMsg = msg; _replyTo = null; });
    _ctrl.text = msg.text;
    _ctrl.selection =
        TextSelection.fromPosition(TextPosition(offset: _ctrl.text.length));
  }

  void _cancelEdit() {
    setState(() => _editingMsg = null);
    _ctrl.clear();
  }

  void _scrollBottom() => Future.delayed(const Duration(milliseconds: 120), () {
    if (_scroll.hasClients) {
      _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  });

  String _initials(String n) => n.trim().isNotEmpty
      ? n.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2)
          .join().toUpperCase()
      : 'U';

  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      // FIX: explicit true (was relying on the default) — the Scaffold
      // already resizes the body to sit above the keyboard. The input
      // bar's own padding must NOT also add viewInsets.bottom on top
      // of this, or the gap gets counted twice (see _buildInputBar).
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(),
      body: Column(children: [
        Expanded(child: _buildMessageList()),
        if (_editingMsg != null) _buildEditBar(),
        if (_replyTo    != null) _buildReplyBar(),
        _buildInputBar(),
      ]),
    );
  }

  // ── App bar ────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    final init = _initials(widget.otherDisplayName);
    return AppBar(
      backgroundColor: const Color(0xFF0D0D1A),
      elevation: 0,
      leadingWidth: 40,
      leading: IconButton(
        padding: EdgeInsets.zero,
        icon: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.arrow_back_ios_new_rounded,
              size: 15, color: Colors.white.withOpacity(0.7))),
        onPressed: () => Navigator.pop(context)),
      title: StreamBuilder<bool>(
        stream: _fsvc.friendOnlineStream(widget.otherUid),
        initialData: widget.isOnline,
        builder: (_, onlineSnap) {
          final online = onlineSnap.data ?? false;
          return StreamBuilder<bool>(
            stream: _svc.typingStream(widget.otherUid),
            initialData: false,
            builder: (_, typingSnap) {
              final typing = typingSnap.data ?? false;
              return Row(children: [
                Stack(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)])),
                    child: widget.otherPhotoUrl.startsWith('http')
                        ? ClipOval(child: Image.network(
                            widget.otherPhotoUrl, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                                child: Text(init, style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700)))))
                        : Center(child: Text(init, style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700)))),
                  Positioned(bottom: 0, right: 0,
                    child: Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: online
                              ? const Color(0xFF00C853)
                              : Colors.grey.shade700,
                          border: Border.all(
                              color: const Color(0xFF0D0D1A), width: 2)))),
                ]),
                const SizedBox(width: 10),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(widget.otherDisplayName,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: typing
                        ? Row(key: const ValueKey('typing'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                            const _TypingDots(),
                            const SizedBox(width: 4),
                            Text('typing…', style: TextStyle(
                                fontSize: 11,
                                color: const Color(0xFF6C63FF).withOpacity(0.85))),
                          ])
                        : Text(
                            online ? 'Online' : '@${widget.otherUsername}',
                            key: const ValueKey('status'),
                            style: TextStyle(
                                fontSize: 11,
                                color: online
                                    ? const Color(0xFF00C853)
                                    : Colors.white.withOpacity(0.4))),
                  ),
                ])),
              ]);
            });
        }),
      actions: [
        IconButton(
          icon: Icon(Icons.more_vert_rounded,
              color: Colors.white.withOpacity(0.6)),
          onPressed: _showChatOptions),
      ],
    );
  }

  // ── Message list ───────────────────────────────────────────
  Widget _buildMessageList() => StreamBuilder<List<DmMessageModel>>(
    stream: _svc.messagesStream(widget.otherUid),
    builder: (_, snap) {
      if (snap.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator(
            color: Color(0xFF6C63FF), strokeWidth: 2));
      }
      final msgs = snap.data ?? [];
      if (msgs.isEmpty) {
        return Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
          const Text('👋', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          Text('Say hello to ${widget.otherDisplayName}',
              style: const TextStyle(
                  color: Colors.white, fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Your messages are private and secure',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.35), fontSize: 13)),
        ]));
      }

      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _svc.markAsRead(widget.otherUid));
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollBottom());

      return ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        itemCount: msgs.length,
        itemBuilder: (_, i) {
          final msg       = msgs[i];
          final isMe      = msg.senderId == _me;
          final showDate  = i == 0 ||
              !_sameDay(msgs[i - 1].timestamp, msg.timestamp);
          final showAvatar = !isMe && !msg.isSystem &&
              (i == msgs.length - 1 ||
                  msgs[i + 1].senderId != msg.senderId);

          return Column(children: [
            if (showDate) _dateDivider(msg.timestamp),
            if (msg.isSystem)
              _SystemBubble(text: msg.text)
            else
              _MessageBubble(
                msg:        msg,
                isMe:       isMe,
                showAvatar: showAvatar,
                otherInit:  _initials(widget.otherDisplayName),
                otherPhoto: widget.otherPhotoUrl,
                myUid:      _me,
                onReply: () => setState(() {
                  _replyTo    = msg;
                  _editingMsg = null;
                }),
                onEdit: isMe && !msg.isDeleted
                    ? () => _startEditing(msg)
                    : null,
                onDelete: isMe && !msg.isDeleted
                    ? () => _svc.deleteMessage(widget.otherUid, msg.id)
                    : null,
                onCopy: () => Clipboard.setData(ClipboardData(text: msg.text)),
                onReact: (emoji) =>
                    _svc.toggleReaction(widget.otherUid, msg.id, emoji),
              ),
          ]);
        });
    });

  // ── Edit bar ───────────────────────────────────────────────
  Widget _buildEditBar() => Container(
    padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
    color: const Color(0xFF141428),
    child: Row(children: [
      Container(width: 3, height: 40,
          decoration: BoxDecoration(
              color: const Color(0xFFFFB300),
              borderRadius: BorderRadius.circular(4))),
      const SizedBox(width: 10),
      const Icon(Icons.edit_rounded, size: 16, color: Color(0xFFFFB300)),
      const SizedBox(width: 8),
      Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        const Text('Edit message', style: TextStyle(
            color: Color(0xFFFFB300), fontSize: 12,
            fontWeight: FontWeight.w700)),
        Text(_editingMsg!.text,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: Colors.white.withOpacity(0.5), fontSize: 12)),
      ])),
      IconButton(
        icon: Icon(Icons.close_rounded,
            color: Colors.white.withOpacity(0.4), size: 18),
        onPressed: _cancelEdit),
    ]));

  // ── Reply bar ──────────────────────────────────────────────
  Widget _buildReplyBar() => Container(
    padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
    color: const Color(0xFF141428),
    child: Row(children: [
      Container(width: 3, height: 40,
          decoration: BoxDecoration(
              color: const Color(0xFF6C63FF),
              borderRadius: BorderRadius.circular(4))),
      const SizedBox(width: 10),
      Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Text(_replyTo!.senderName, style: const TextStyle(
            color: Color(0xFF6C63FF), fontSize: 12,
            fontWeight: FontWeight.w700)),
        Text(_replyTo!.text,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: Colors.white.withOpacity(0.5), fontSize: 12)),
      ])),
      IconButton(
        icon: Icon(Icons.close_rounded,
            color: Colors.white.withOpacity(0.4), size: 18),
        onPressed: () => setState(() => _replyTo = null)),
    ]));

  // ── Input bar ──────────────────────────────────────────────
  // FIX: previously this manually added MediaQuery.viewInsets.bottom
  // (the keyboard height) to its own bottom padding. But the Scaffold
  // already resizes its body to sit above the keyboard by that exact
  // amount (resizeToAvoidBottomInset: true), so the keyboard height
  // was being accounted for TWICE — once by the Scaffold shifting the
  // whole body up, and again by this extra padding on top of that —
  // leaving a large empty gap between the input bar and the actual
  // keyboard. Now it just uses SafeArea for the bottom system inset
  // (home-indicator / gesture bar) when the keyboard is closed, and
  // relies on the Scaffold alone when it's open.
  Widget _buildInputBar() {
    final editing = _editingMsg != null;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D1A),
          border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.06))),
        ),
        child: Row(children: [
          Expanded(child: Container(
            decoration: BoxDecoration(
                color: const Color(0xFF141428),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                    color: editing
                        ? const Color(0xFFFFB300).withOpacity(0.4)
                        : Colors.white.withOpacity(0.08))),
            child: TextField(
              controller: _ctrl,
              maxLines: null,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: editing ? 'Edit message…' : 'Message…',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 12)),
              onSubmitted: (_) => _send()),
          )),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _send,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46, height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: editing
                    ? [const Color(0xFFFFB300), const Color(0xFFFF6F00)]
                    : [const Color(0xFF6C63FF), const Color(0xFF00C4A0)]),
                boxShadow: [BoxShadow(
                    color: (editing
                        ? const Color(0xFFFFB300)
                        : const Color(0xFF6C63FF)).withOpacity(0.4),
                    blurRadius: 12, offset: const Offset(0, 4))]),
              child: _sending
                  ? const Padding(padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Icon(
                      editing ? Icons.check_rounded : Icons.send_rounded,
                      color: Colors.white, size: 20))),
        ]),
      ),
    );
  }

  // ── Chat options ───────────────────────────────────────────
  void _showChatOptions() => showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      decoration: const BoxDecoration(
          color: Color(0xFF141428),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4)))),
        const SizedBox(height: 20),
        Text('@${widget.otherUsername}', style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 16),
        ListTile(
          leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.person_remove_outlined,
                  color: Colors.redAccent, size: 18)),
          title: const Text('Remove friend', style: TextStyle(
              color: Colors.redAccent, fontWeight: FontWeight.w600)),
          onTap: () async {
            Navigator.pop(context);
            await _fsvc.removeFriend(widget.otherUid);
            if (mounted) Navigator.pop(context);
          }),
      ])));

  // ── Helpers ────────────────────────────────────────────────
  Widget _dateDivider(DateTime date) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d     = DateTime(date.year, date.month, date.day);
    final lbl   = d == today
        ? 'Today'
        : d == today.subtract(const Duration(days: 1))
            ? 'Yesterday'
            : DateFormat('MMM d, yyyy').format(date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(children: [
        Expanded(child: Divider(color: Colors.white.withOpacity(0.08))),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20)),
          child: Text(lbl, style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 11, fontWeight: FontWeight.w600))),
        Expanded(child: Divider(color: Colors.white.withOpacity(0.08))),
      ]));
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ══════════════════════════════════════════════════════════════
// SYSTEM BUBBLE
// ══════════════════════════════════════════════════════════════
class _SystemBubble extends StatelessWidget {
  final String text;
  const _SystemBubble({required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Center(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(
          color: Colors.white.withOpacity(0.55),
          fontSize: 12, fontWeight: FontWeight.w500)))));
}

// ══════════════════════════════════════════════════════════════
// MESSAGE BUBBLE
// ══════════════════════════════════════════════════════════════
class _MessageBubble extends StatelessWidget {
  final DmMessageModel msg;
  final bool           isMe;
  final bool           showAvatar;
  final String         otherInit;
  final String         otherPhoto;
  final String         myUid;
  final VoidCallback   onReply;
  final VoidCallback?  onEdit;
  final VoidCallback?  onDelete;
  final VoidCallback   onCopy;
  final void Function(String) onReact;

  const _MessageBubble({
    required this.msg,
    required this.isMe,
    required this.showAvatar,
    required this.otherInit,
    required this.otherPhoto,
    required this.myUid,
    required this.onReply,
    required this.onEdit,
    required this.onDelete,
    required this.onCopy,
    required this.onReact,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onLongPress: () { HapticFeedback.mediumImpact(); _showOptions(context); },
    child: Padding(
      padding: EdgeInsets.only(
          bottom: 2, left: isMe ? 48 : 0, right: isMe ? 0 : 48),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            SizedBox(width: 32,
                child: showAvatar
                    ? _Avatar(init: otherInit, photoUrl: otherPhoto, size: 28)
                    : const SizedBox(width: 28)),
            const SizedBox(width: 6),
          ],
          Flexible(child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
            // Reply quote
            if (msg.replyPreview != null && !msg.isDeleted)
              Container(
                margin: const EdgeInsets.only(bottom: 3),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: const Border(
                        left: BorderSide(
                            color: Color(0xFF6C63FF), width: 3))),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  if (msg.replyToName != null)
                    Text(msg.replyToName!, style: const TextStyle(
                        color: Color(0xFF6C63FF), fontSize: 11,
                        fontWeight: FontWeight.w700)),
                  Text(msg.replyPreview!,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 11)),
                ])),
            // Bubble body
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isMe && !msg.isDeleted
                    ? const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)])
                    : null,
                color: isMe && !msg.isDeleted
                    ? null
                    : msg.isDeleted
                        ? Colors.white.withOpacity(0.04)
                        : const Color(0xFF1E1E38),
                borderRadius: BorderRadius.only(
                    topLeft:     const Radius.circular(18),
                    topRight:    const Radius.circular(18),
                    bottomLeft:  Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18)),
              ),
              child: Text(
                msg.isDeleted ? '🚫  Message deleted' : msg.text,
                style: TextStyle(
                    color: msg.isDeleted
                        ? Colors.white.withOpacity(0.3)
                        : Colors.white,
                    fontSize: 15, height: 1.4,
                    fontStyle: msg.isDeleted
                        ? FontStyle.italic : FontStyle.normal))),
            // Reactions row
            if (msg.reactions.isNotEmpty && !msg.isDeleted)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(spacing: 4,
                    children: msg.reactions.entries.map((e) {
                      final mine = e.value.contains(myUid);
                      return GestureDetector(
                        onTap: () => onReact(e.key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                              color: mine
                                  ? const Color(0xFF6C63FF).withOpacity(0.25)
                                  : Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: mine
                                      ? const Color(0xFF6C63FF).withOpacity(0.5)
                                      : Colors.transparent)),
                          child: Text('${e.key} ${e.value.length}',
                              style: const TextStyle(fontSize: 12))));
                    }).toList())),
            // Timestamp + edited + status
            Padding(
              padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (msg.isEdited && !msg.isDeleted)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text('edited', style: TextStyle(
                        color: Colors.white.withOpacity(0.2),
                        fontSize: 10, fontStyle: FontStyle.italic))),
                Text(DateFormat('HH:mm').format(msg.timestamp),
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.25), fontSize: 10)),
                if (isMe && !msg.isDeleted) ...[
                  const SizedBox(width: 4),
                  _StatusIcon(status: msg.status),
                ],
              ])),
          ])),
        ])));

  void _showOptions(BuildContext context) => showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      decoration: const BoxDecoration(
          color: Color(0xFF141428),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4)))),
        const SizedBox(height: 8),
        if (!msg.isDeleted) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(mainAxisAlignment: MainAxisAlignment.center,
                children: ['❤️', '😂', '😮', '😢', '👍', '🔥'].map((e) =>
                    GestureDetector(
                      onTap: () { Navigator.pop(context); onReact(e); },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(e,
                            style: const TextStyle(fontSize: 26))))).toList())),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 8),
          _Opt(icon: Icons.reply_rounded, label: 'Reply',
              color: const Color(0xFF6C63FF),
              onTap: () { Navigator.pop(context); onReply(); }),
          _Opt(icon: Icons.copy_rounded, label: 'Copy text',
              color: const Color(0xFF00C4A0),
              onTap: () { Navigator.pop(context); onCopy(); }),
        ],
        if (onEdit != null)
          _Opt(icon: Icons.edit_rounded, label: 'Edit message',
              color: const Color(0xFFFFB300),
              onTap: () { Navigator.pop(context); onEdit!(); }),
        if (onDelete != null)
          _Opt(icon: Icons.delete_outline_rounded, label: 'Delete message',
              color: Colors.redAccent,
              onTap: () { Navigator.pop(context); onDelete!(); }),
      ])));
}

class _Opt extends StatelessWidget {
  final IconData icon; final String label;
  final Color color; final VoidCallback onTap;
  const _Opt({required this.icon, required this.label,
      required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18)),
    title: Text(label, style: TextStyle(
        color: color, fontWeight: FontWeight.w600)),
    onTap: onTap);
}

class _Avatar extends StatelessWidget {
  final String init, photoUrl; final double size;
  const _Avatar({required this.init, required this.photoUrl, required this.size});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)])),
    child: photoUrl.startsWith('http')
        ? ClipOval(child: Image.network(photoUrl, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Center(child: Text(init,
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700, fontSize: size * 0.33)))))
        : Center(child: Text(init, style: TextStyle(color: Colors.white,
            fontWeight: FontWeight.w700, fontSize: size * 0.33))));
}

class _StatusIcon extends StatelessWidget {
  final MessageStatus status;
  const _StatusIcon({required this.status});
  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageStatus.read:
        return const Icon(Icons.done_all_rounded,
            size: 13, color: Color(0xFF00C4A0));
      case MessageStatus.delivered:
        return Icon(Icons.done_all_rounded,
            size: 13, color: Colors.white.withOpacity(0.4));
      case MessageStatus.sent:
        return Icon(Icons.done_rounded,
            size: 13, color: Colors.white.withOpacity(0.3));
    }
  }
}

// ── Animated typing dots ──────────────────────────────────────
class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }
  @override
  void dispose() { _anim.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final delay   = i / 3;
        final t       = ((_anim.value - delay) % 1.0).abs();
        final opacity = (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.2, 1.0);
        return Container(
          margin: const EdgeInsets.only(right: 2),
          width: 4, height: 4,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6C63FF).withOpacity(opacity)));
      })));
}