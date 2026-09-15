// ============================================================
// PATH: lib/features/connect/chat/screens/user_search_screen.dart
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/friend_service.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});
  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final FriendService        _svc       = FriendService();
  final TextEditingController _ctrl     = TextEditingController();
  List<Map<String, dynamic>> _results   = [];
  bool                       _loading   = false;
  bool                       _searched  = false;
  String?                    _error;
  // uid → 'friend' | 'pending' | 'none'
  Map<String, String>        _relations = {};
  // uid → requestId (so user can cancel from this screen)
  Map<String, String>        _requestIds = {};
  Timer?                     _debounce;

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChange(String v) {
    _debounce?.cancel();
    if (v.trim().isEmpty) {
      setState(() {
        _results    = [];
        _loading    = false;
        _searched   = false;
        _error      = null;
        _relations  = {};
        _requestIds = {};
      });
      return;
    }
    setState(() { _loading = true; _error = null; });
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(v));
  }

  Future<void> _search(String q) async {
    try {
      final results  = await _svc.searchByUsername(q.trim());
      if (!mounted) return;

      final uids     = results.map((u) => u['uid'] as String).toList();
      final relations = await _svc.batchRelationshipCheck(uids);

      // Collect pending requestIds so "Sent ✕" can cancel
      final Map<String, String> requestIds = {};
      for (final uid in uids) {
        if (relations[uid] == 'pending') {
          final rid = await _svc.pendingRequestId(uid);
          if (rid != null) requestIds[uid] = rid;
        }
      }

      if (!mounted) return;
      setState(() {
        _results    = results;
        _loading    = false;
        _searched   = true;
        _error      = null;
        _relations  = relations;
        _requestIds = requestIds;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading  = false;
        _searched = true;     
        _error    = 'Something went wrong. Please try again.';
      });
    }
  }

  Future<void> _sendRequest(Map<String, dynamic> u) async {
    final uid = u['uid'] as String;
    HapticFeedback.mediumImpact();
    setState(() => _relations[uid] = 'pending');
    try {
      await _svc.sendRequest(uid);
      final rid = await _svc.pendingRequestId(uid);
      if (mounted && rid != null) setState(() => _requestIds[uid] = rid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Request sent to @${u['username']} ✅'),
        backgroundColor: const Color(0xFF6C63FF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ));
    } catch (e) {
      if (mounted) {
        setState(() => _relations[uid] = 'none');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to send request'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  Future<void> _cancelRequest(Map<String, dynamic> u) async {
    final uid = u['uid'] as String;
    final rid = _requestIds[uid];
    if (rid == null) return;
    HapticFeedback.mediumImpact();
    setState(() => _relations[uid] = 'none');
    try {
      await _svc.cancelRequest(uid, rid);
      if (mounted) setState(() => _requestIds.remove(uid));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Request to @${u['username']} cancelled'),
        backgroundColor: Colors.grey.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ));
    } catch (_) {
      if (mounted) setState(() => _relations[uid] = 'pending');
    }
  }

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
      title: const Text('Find Friends', style: TextStyle(
          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
    ),
    body: Column(children: [
      // ── Search field ─────────────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        child: Container(
          decoration: BoxDecoration(
              color: const Color(0xFF141428),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08))),
          child: TextField(
            controller: _ctrl,
            onChanged: _onChange,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Search by @username',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
              prefixIcon: Icon(Icons.search_rounded,
                  color: Colors.white.withOpacity(0.35)),
              suffixIcon: _buildSuffix(),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14)),
          )),
      ),
      // ── Hint ─────────────────────────────────────────────
      if (!_searched && _ctrl.text.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(children: [
            Icon(Icons.info_outline_rounded,
                size: 13, color: Colors.white.withOpacity(0.25)),
            const SizedBox(width: 6),
            Text('Tip: type with or without the @ symbol',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.25), fontSize: 12)),
          ])),
      Expanded(child: _buildBody()),
    ]),
  );

  Widget? _buildSuffix() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(width: 20, height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: Color(0xFF6C63FF))));
    }
    if (_ctrl.text.isNotEmpty) {
      return IconButton(
        icon: Icon(Icons.clear_rounded,
            color: Colors.white.withOpacity(0.3), size: 18),
        onPressed: () { _ctrl.clear(); _onChange(''); });
    }
    return null;
  }

  Widget _buildBody() {
    if (!_searched && !_loading) {
      return Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🔍', style: TextStyle(fontSize: 52)),
        const SizedBox(height: 16),
        Text('Find friends by @username',
            style: TextStyle(
                color: Colors.white.withOpacity(0.45), fontSize: 15)),
      ]));
    }

    if (_error != null) {
      return Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.wifi_off_rounded, size: 52,
            color: Colors.white.withOpacity(0.2)),
        const SizedBox(height: 16),
        Text(_error!, style: TextStyle(
            color: Colors.white.withOpacity(0.55), fontSize: 15)),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => _search(_ctrl.text),
          child: const Text('Try again',
              style: TextStyle(color: Color(0xFF6C63FF)))),
      ]));
    }

    if (_searched && _results.isEmpty && !_loading) {
      final q = _ctrl.text.trim().replaceFirst(RegExp(r'^@'), '');
      return Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('😶', style: TextStyle(fontSize: 52)),
        const SizedBox(height: 16),
        Text('No one found for "@$q"',
            style: TextStyle(
                color: Colors.white.withOpacity(0.55), fontSize: 15,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Ask them to check their username\nin profile settings.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withOpacity(0.3), fontSize: 13)),
      ]));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      itemCount: _results.length,
      itemBuilder: (_, i) => _buildTile(_results[i]),
    );
  }

  Widget _buildTile(Map<String, dynamic> u) {
    final uid      = u['uid']         as String;
    final name     = u['displayName'] as String? ?? 'User';
    final username = u['username']    as String? ?? '';
    final photo    = u['photoUrl']    as String? ?? '';
    final streak   = (u['currentStreak'] as num?)?.toInt() ?? 0;
    final relation = _relations[uid] ?? 'none';

    final init = name.trim().isNotEmpty
        ? name.trim().split(' ')
            .map((w) => w.isNotEmpty ? w[0] : '')
            .take(2).join().toUpperCase()
        : 'U';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: const Color(0xFF141428),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.07))),
      child: Row(children: [
        // Avatar
        Container(
          width: 48, height: 48,
          decoration: const BoxDecoration(shape: BoxShape.circle,
              gradient: LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)])),
          child: photo.startsWith('http')
              ? ClipOval(child: Image.network(photo, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(child: Text(init,
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w800, fontSize: 15)))))
              : Center(child: Text(init, style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800,
                  fontSize: 15))),
        ),
        const SizedBox(width: 12),
        // Info
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(name, style: const TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
          Row(children: [
            Text('@$username', style: TextStyle(
                color: Colors.white.withOpacity(0.4), fontSize: 12)),
            if (streak > 0) ...[
              const SizedBox(width: 8),
              Text('🔥 ${streak}d', style: const TextStyle(
                  color: Color(0xFF00C4A0), fontSize: 11,
                  fontWeight: FontWeight.w600)),
            ],
          ]),
        ])),
        const SizedBox(width: 8),
        // Action button
        _buildAction(u, uid, username, relation),
      ]));
  }

  Widget _buildAction(Map<String, dynamic> u, String uid,
      String username, String relation) {
    if (relation == 'friend') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            color: const Color(0xFF00C4A0).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20)),
        child: const Text('Friends ✓', style: TextStyle(
            color: Color(0xFF00C4A0), fontSize: 13,
            fontWeight: FontWeight.w600)));
    }

    if (relation == 'pending') {
      return GestureDetector(
        onTap: () => _cancelRequest(u),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.15))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('Sent', style: TextStyle(
                color: Colors.white.withOpacity(0.5), fontSize: 13,
                fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            Icon(Icons.close_rounded,
                size: 14, color: Colors.white.withOpacity(0.3)),
          ])));
    }

    // 'none'
    return ElevatedButton.icon(
      onPressed: () => _sendRequest(u),
      icon: const Icon(Icons.person_add_rounded, size: 14, color: Colors.white),
      label: const Text('Add', style: TextStyle(
          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
      style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C63FF),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)));
  }
}