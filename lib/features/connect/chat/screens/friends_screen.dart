// ============================================================
// PATH: lib/features/connect/chat/screens/friends_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/dm_message_model.dart';
import '../models/friend_model.dart';
import '../models/friend_request_model.dart';
import '../services/dm_service.dart';
import '../services/friend_service.dart';
import '../services/presence_service.dart';
import 'dm_screen.dart';
import 'user_search_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});
  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  final FriendService _fsvc = FriendService();
  final DmService     _dsvc = DmService();
  late TabController  _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    PresenceService.instance.start();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0D0D1A),
    appBar: AppBar(
      backgroundColor: const Color(0xFF0D0D1A),
      elevation: 0,
      leading: IconButton(
        icon: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.arrow_back_ios_new_rounded,
              size: 15, color: Colors.white.withOpacity(0.7))),
        onPressed: () => Navigator.pop(context)),
      title: ShaderMask(
        shaderCallback: (b) => const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)]).createShader(b),
        child: const Text('Connect', style: TextStyle(
            color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800))),
      actions: [
        IconButton(
          icon: const Icon(Icons.person_search_rounded, color: Color(0xFF6C63FF)),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const UserSearchScreen()))),
      ],
      bottom: TabBar(
        controller: _tab,
        indicatorColor: const Color(0xFF6C63FF),
        indicatorWeight: 2.5,
        labelColor: const Color(0xFF6C63FF),
        unselectedLabelColor: Colors.white.withOpacity(0.35),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        tabs: [
          const Tab(text: 'Messages'),
          const Tab(text: 'Friends'),
          StreamBuilder<List<FriendRequestModel>>(
            stream: _fsvc.incomingRequestsStream(),
            builder: (_, snap) {
              final n = snap.data?.length ?? 0;
              return Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Requests'),
                if (n > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('$n', style: const TextStyle(
                        color: Colors.white, fontSize: 10,
                        fontWeight: FontWeight.w800))),
                ],
              ]));
            }),
        ]),
    ),
    body: TabBarView(controller: _tab, children: [
      _buildInbox(),
      _buildFriendsList(),
      _buildRequestsTab(),
    ]),
  );

  // ══════════════════════════════════════════════════════════════
  // TAB 1 — INBOX
  // ══════════════════════════════════════════════════════════════
  Widget _buildInbox() => StreamBuilder<List<DmThreadModel>>(
    stream: _dsvc.inboxStream(),
    builder: (_, snap) {
      if (snap.connectionState == ConnectionState.waiting) return _loading();
      final threads = snap.data ?? [];
      if (threads.isEmpty) {
        return _empty(Icons.chat_bubble_outline_rounded,
            'No messages yet', 'Find friends and start chatting');
      }
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: threads.length,
        itemBuilder: (_, i) {
          final t = threads[i];
          return _InboxTile(
            thread: t,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => DmScreen(
                  otherUid:         t.otherUid,
                  otherUsername:    t.otherUsername,
                  otherDisplayName: t.otherDisplayName,
                  otherPhotoUrl:    t.otherPhotoUrl,
                ))));
        });
    });

  // ══════════════════════════════════════════════════════════════
  // TAB 2 — FRIENDS
  // Merges unread counts from inbox into friend tiles.
  // ══════════════════════════════════════════════════════════════
  Widget _buildFriendsList() => StreamBuilder<List<FriendModel>>(
    stream: _fsvc.friendsStream(),
    builder: (_, fSnap) {
      if (fSnap.connectionState == ConnectionState.waiting) return _loading();
      final friends = fSnap.data ?? [];
      if (friends.isEmpty) {
        return _empty(Icons.group_outlined, 'No friends yet',
            'Tap the search icon to find people');
      }
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        itemCount: friends.length,
        itemBuilder: (_, i) => _FriendTile(
          friend: friends[i],
          fsvc: _fsvc,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => DmScreen(
                otherUid:         friends[i].uid,
                otherUsername:    friends[i].username,
                otherDisplayName: friends[i].displayName,
                otherPhotoUrl:    friends[i].photoUrl,
              ))),
          onRemove: () async {
            await _fsvc.removeFriend(friends[i].uid);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(_snack(
                  '${friends[i].displayName} removed'));
            }
          },
        ),
      );
    });

  // ══════════════════════════════════════════════════════════════
  // TAB 3 — REQUESTS (nested Received / Sent sub-tabs)
  // ══════════════════════════════════════════════════════════════
  Widget _buildRequestsTab() => DefaultTabController(
    length: 2,
    child: Column(children: [
      Container(
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        decoration: BoxDecoration(
            color: const Color(0xFF141428),
            borderRadius: BorderRadius.circular(12)),
        child: TabBar(
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
              color: const Color(0xFF6C63FF),
              borderRadius: BorderRadius.circular(10)),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.4),
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [Tab(text: 'Received'), Tab(text: 'Sent')]),
      ),
      Expanded(child: TabBarView(children: [
        _buildIncomingRequests(),
        _buildSentRequests(),
      ])),
    ]));

  Widget _buildIncomingRequests() => StreamBuilder<List<FriendRequestModel>>(
    stream: _fsvc.incomingRequestsStream(),
    builder: (_, snap) {
      if (snap.connectionState == ConnectionState.waiting) return _loading();
      final list = snap.data ?? [];
      if (list.isEmpty) {
        return _empty(Icons.mark_email_read_outlined,
            'No pending requests', 'Friend requests will appear here');
      }
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        itemCount: list.length,
        itemBuilder: (_, i) => _IncomingRequestTile(
          request: list[i],
          fsvc: _fsvc,
          onAccepted: () => ScaffoldMessenger.of(context).showSnackBar(
              _snack('You and ${list[i].fromDisplayName} are now friends! 🎉',
                  color: const Color(0xFF00C4A0))),
        ));
    });

  Widget _buildSentRequests() => StreamBuilder<List<FriendRequestModel>>(
    stream: _fsvc.sentRequestsStream(),
    builder: (_, snap) {
      if (snap.connectionState == ConnectionState.waiting) return _loading();
      final list = snap.data ?? [];
      if (list.isEmpty) {
        return _empty(Icons.send_outlined,
            'No sent requests', 'Requests you send will appear here');
      }
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        itemCount: list.length,
        itemBuilder: (_, i) => _SentRequestTile(
          request: list[i],
          fsvc: _fsvc,
          onCancelled: () => ScaffoldMessenger.of(context)
              .showSnackBar(_snack('Request cancelled')),
        ));
    });

  // ── Shared helpers ─────────────────────────────────────────
  Widget _loading() => const Center(child: CircularProgressIndicator(
      color: Color(0xFF6C63FF), strokeWidth: 2.5));

  Widget _empty(IconData icon, String title, String sub) =>
      Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
          children: [
        Icon(icon, size: 60, color: Colors.white.withOpacity(0.1)),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(sub, style: TextStyle(
            color: Colors.white.withOpacity(0.4), fontSize: 14)),
      ]));

  SnackBar _snack(String msg, {Color color = const Color(0xFF6C63FF)}) =>
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      );
}

// ══════════════════════════════════════════════════════════════
// INBOX TILE
// ══════════════════════════════════════════════════════════════
class _InboxTile extends StatelessWidget {
  final DmThreadModel thread;
  final VoidCallback  onTap;
  const _InboxTile({required this.thread, required this.onTap});

  String _initials(String n) => n.trim().isNotEmpty
      ? n.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '')
          .take(2).join().toUpperCase()
      : 'U';

  @override
  Widget build(BuildContext context) {
    final init      = _initials(thread.otherDisplayName);
    final hasUnread = thread.unreadCount > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: hasUnread
                ? const Color(0xFF6C63FF).withOpacity(0.06)
                : const Color(0xFF141428),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: hasUnread
                    ? const Color(0xFF6C63FF).withOpacity(0.2)
                    : Colors.white.withOpacity(0.07))),
        child: Row(children: [
          _avatar(init, thread.otherPhotoUrl, 50),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(children: [
              Expanded(child: Text(thread.otherDisplayName,
                  style: TextStyle(color: Colors.white, fontSize: 15,
                      fontWeight: hasUnread
                          ? FontWeight.w800 : FontWeight.w600))),
              Text(_formatTime(thread.lastMessageAt),
                  style: TextStyle(
                      color: hasUnread
                          ? const Color(0xFF6C63FF)
                          : Colors.white.withOpacity(0.3),
                      fontSize: 11,
                      fontWeight: hasUnread
                          ? FontWeight.w700 : FontWeight.w400)),
            ]),
            const SizedBox(height: 3),
            Row(children: [
              Expanded(child: Text(
                  thread.lastMessage.isEmpty
                      ? 'Say hello 👋' : thread.lastMessage,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: hasUnread
                          ? Colors.white.withOpacity(0.75)
                          : Colors.white.withOpacity(0.35),
                      fontSize: 13,
                      fontWeight: hasUnread
                          ? FontWeight.w600 : FontWeight.w400))),
              if (hasUnread)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text('${thread.unreadCount}', style: const TextStyle(
                      color: Colors.white, fontSize: 11,
                      fontWeight: FontWeight.w800))),
            ]),
          ])),
        ])));
  }

  Widget _avatar(String init, String photoUrl, double size) => Container(
    width: size, height: size,
    decoration: const BoxDecoration(shape: BoxShape.circle,
        gradient: LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)])),
    child: photoUrl.startsWith('http')
        ? ClipOval(child: Image.network(photoUrl, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Center(child: Text(init,
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700, fontSize: size * 0.33)))))
        : Center(child: Text(init, style: TextStyle(color: Colors.white,
            fontWeight: FontWeight.w700, fontSize: size * 0.33))));

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d     = DateTime(dt.year, dt.month, dt.day);
    if (d == today) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${dt.day}/${dt.month}';
  }
}

// ══════════════════════════════════════════════════════════════
// FRIEND TILE (with real-time online dot)
// ══════════════════════════════════════════════════════════════
class _FriendTile extends StatelessWidget {
  final FriendModel  friend;
  final FriendService fsvc;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FriendTile({
    required this.friend,
    required this.fsvc,
    required this.onTap,
    required this.onRemove,
  });

  String _initials(String n) => n.trim().isNotEmpty
      ? n.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '')
          .take(2).join().toUpperCase()
      : 'U';

  @override
  Widget build(BuildContext context) {
    final init = _initials(friend.displayName);
    return GestureDetector(
      onTap: onTap,
      onLongPress: () { HapticFeedback.mediumImpact(); _showOptions(context); },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: const Color(0xFF141428),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.07))),
        child: Row(children: [
          Stack(children: [
            _buildAvatar(init, friend.photoUrl, 48),
            Positioned(bottom: 1, right: 1,
              child: StreamBuilder<bool>(
                stream: fsvc.friendOnlineStream(friend.uid),
                initialData: friend.isOnline,
                builder: (_, os) => Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (os.data ?? false)
                          ? const Color(0xFF00C853)
                          : Colors.grey.shade700,
                      border: Border.all(
                          color: const Color(0xFF141428), width: 2))))),
          ]),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(friend.displayName, style: const TextStyle(
                color: Colors.white, fontSize: 15,
                fontWeight: FontWeight.w700)),
            Row(children: [
              Text('@${friend.username}', style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 12)),
              if (friend.currentStreak > 0) ...[
                const SizedBox(width: 8),
                Text('🔥 ${friend.currentStreak}d', style: const TextStyle(
                    color: Color(0xFF00C4A0), fontSize: 11,
                    fontWeight: FontWeight.w600)),
              ],
            ]),
          ])),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  color: Color(0xFF6C63FF), size: 18)),
          ]),
        ])));
  }

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
        const SizedBox(height: 16),
        Text(friend.displayName, style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        Text('@${friend.username}', style: TextStyle(
            color: Colors.white.withOpacity(0.4), fontSize: 13)),
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
          onTap: () { Navigator.pop(context); onRemove(); }),
      ])));

  Widget _buildAvatar(String init, String photoUrl, double size) => Container(
    width: size, height: size,
    decoration: const BoxDecoration(shape: BoxShape.circle,
        gradient: LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)])),
    child: photoUrl.startsWith('http')
        ? ClipOval(child: Image.network(photoUrl, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Center(child: Text(init,
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700, fontSize: size * 0.33)))))
        : Center(child: Text(init, style: TextStyle(color: Colors.white,
            fontWeight: FontWeight.w700, fontSize: size * 0.33))));
}

// ══════════════════════════════════════════════════════════════
// INCOMING REQUEST TILE
// FIX: converted to StatefulWidget so Accept/Decline can show a
// loading state, catch errors instead of failing silently (the
// previous StatelessWidget version left both actions unawaited /
// uncaught, so a permission-denied error — or any other failure —
// simply did nothing with no feedback), and disable the buttons
// while a request is in flight to prevent double-taps.
// ══════════════════════════════════════════════════════════════
class _IncomingRequestTile extends StatefulWidget {
  final FriendRequestModel request;
  final FriendService      fsvc;
  final VoidCallback       onAccepted;

  const _IncomingRequestTile({
    required this.request,
    required this.fsvc,
    required this.onAccepted,
  });

  @override
  State<_IncomingRequestTile> createState() => _IncomingRequestTileState();
}

class _IncomingRequestTileState extends State<_IncomingRequestTile> {
  bool _isProcessing = false;

  String _initials(String n) => n.trim().isNotEmpty
      ? n.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '')
          .take(2).join().toUpperCase()
      : 'U';

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFFE53935),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Future<void> _accept() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await widget.fsvc.acceptRequest(widget.request);
      HapticFeedback.mediumImpact();
      widget.onAccepted();
      // No setState after success — the parent stream will remove
      // this tile once the request's status flips to 'accepted'.
    } catch (e) {
      debugPrint('Accept Request Error: $e');
      if (mounted) setState(() => _isProcessing = false);
      _showError('Could not accept request. Please try again.');
    }
  }

  Future<void> _decline() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await widget.fsvc.declineRequest(
          widget.request.id, widget.request.fromUid);
      HapticFeedback.mediumImpact();
      // No setState after success — the parent stream will remove
      // this tile once the request's status flips to 'declined'.
    } catch (e) {
      debugPrint('Decline Request Error: $e');
      if (mounted) setState(() => _isProcessing = false);
      _showError('Could not decline request. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final init = _initials(request.fromDisplayName);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFF141428),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: const Color(0xFF6C63FF).withOpacity(0.15))),
      child: Column(children: [
        Row(children: [
          _avatar(init, request.fromPhotoUrl, 50),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(request.fromDisplayName, style: const TextStyle(
                color: Colors.white, fontSize: 16,
                fontWeight: FontWeight.w700)),
            Text('@${request.fromUsername}', style: TextStyle(
                color: Colors.white.withOpacity(0.4), fontSize: 12)),
          ])),
          if (request.fromStreak > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: const Color(0xFF00C4A0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Text('🔥 ${request.fromStreak}d', style: const TextStyle(
                  color: Color(0xFF00C4A0), fontSize: 12,
                  fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: SizedBox(height: 44,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _accept,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  disabledBackgroundColor:
                      const Color(0xFF6C63FF).withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: _isProcessing
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.2, color: Colors.white))
                  : const Text('Accept', style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700))))),
          const SizedBox(width: 10),
          Expanded(child: SizedBox(height: 44,
            child: OutlinedButton(
              onPressed: _isProcessing ? null : _decline,
              style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withOpacity(0.2)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: Text('Decline', style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontWeight: FontWeight.w600))))),
        ]),
      ]));
  }

  Widget _avatar(String init, String photoUrl, double size) => Container(
    width: size, height: size,
    decoration: const BoxDecoration(shape: BoxShape.circle,
        gradient: LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)])),
    child: photoUrl.startsWith('http')
        ? ClipOval(child: Image.network(photoUrl, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Center(child: Text(init,
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700, fontSize: size * 0.33)))))
        : Center(child: Text(init, style: TextStyle(color: Colors.white,
            fontWeight: FontWeight.w700, fontSize: size * 0.33))));
}

// ══════════════════════════════════════════════════════════════
// SENT REQUEST TILE
// Now shows recipient name (toDisplayName / toUsername) correctly.
// ══════════════════════════════════════════════════════════════
class _SentRequestTile extends StatelessWidget {
  final FriendRequestModel request;
  final FriendService      fsvc;
  final VoidCallback       onCancelled;

  const _SentRequestTile({
    required this.request,
    required this.fsvc,
    required this.onCancelled,
  });

  String _initials(String n) => n.trim().isNotEmpty
      ? n.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '')
          .take(2).join().toUpperCase()
      : 'U';

  @override
  Widget build(BuildContext context) {
    // Use toDisplayName / toUsername (stored at send time)
    final displayName = request.toDisplayName.isNotEmpty
        ? request.toDisplayName
        : request.toUsername.isNotEmpty
            ? '@${request.toUsername}'
            : request.toUid;
    final username = request.toUsername;
    final init     = _initials(displayName);
    final photoUrl = request.toPhotoUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFF141428),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.07))),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: const BoxDecoration(shape: BoxShape.circle,
              gradient: LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)])),
          child: photoUrl.startsWith('http')
              ? ClipOval(child: Image.network(photoUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(child: Text(init,
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w800, fontSize: 14)))))
              : Center(child: Text(init, style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800,
                  fontSize: 14))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(displayName, style: const TextStyle(
              color: Colors.white, fontSize: 14,
              fontWeight: FontWeight.w600)),
          if (username.isNotEmpty)
            Text('@$username', style: TextStyle(
                color: Colors.white.withOpacity(0.4), fontSize: 12)),
          Text('Pending…', style: TextStyle(
              color: Colors.white.withOpacity(0.3), fontSize: 11,
              fontStyle: FontStyle.italic)),
        ])),
        TextButton(
          onPressed: () async {
            await fsvc.cancelRequest(request.toUid, request.id);
            onCancelled();
          },
          style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
          child: const Text('Cancel', style: TextStyle(
              fontWeight: FontWeight.w600, fontSize: 13))),
      ]));
  }
}