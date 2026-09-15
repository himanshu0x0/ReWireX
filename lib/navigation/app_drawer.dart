// lib/navigation/app_drawer.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rewirex/features/ai_coach/screens/ai_coach_screen.dart';
import 'package:rewirex/features/connect/connect_screen.dart';
import 'package:rewirex/features/connect/games/screens/games_hub_screen.dart';
import 'package:rewirex/features/connect/stories/screens/stories_screen.dart';
import 'package:rewirex/features/connect/wellness/screens/wellness_hub_screen.dart';
import 'package:rewirex/features/profile/screens/profile_screen.dart';
import 'package:rewirex/features/profile/services/profile_service.dart';
import 'package:rewirex/features/terms/screens/terms_screen.dart';
import 'package:rewirex/features/urge/screens/urge_history_screen.dart';
import 'package:rewirex/features/settings/screens/settings_screen.dart';

/// 🗂 App Drawer
/// Slides in from the left (hamburger menu).
class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final ProfileService _profileService = ProfileService();
  ProfileModel? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final p = await _profileService.fetchProfile();
    if (mounted) setState(() => _profile = p);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = _profile?.displayName.isNotEmpty == true
        ? _profile!.displayName
        : (user?.email?.split('@').first ?? 'User');
    final initials = name.trim().isNotEmpty
        ? name
            .trim()
            .split(' ')
            .map((w) => w.isNotEmpty ? w[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : 'U';
    final score = _profile?.completionScore ?? 0;

    return Drawer(
      backgroundColor: const Color(0xFF0D0D1A),
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            _buildHeader(context, name, initials, score, user?.email ?? ''),

            const SizedBox(height: 8),

            // ── Profile incomplete nudge ─────────────────────
            if (score < 100) _buildProfileNudge(context, score),

            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  // ── Main nav ──────────────────────────────────
                  _DrawerSection(label: 'MAIN'),
                  _DrawerTile(
                    icon: Icons.home_outlined,
                    label: 'Home',
                    onTap: () => Navigator.pop(context),
                  ),

                  const SizedBox(height: 8),

                  // ── Connect & Community ───────────────────────
                  _DrawerSection(label: 'COMMUNITY'),

                  // 1. Full Connect Hub
                  _DrawerTile(
                    icon: Icons.people_alt_outlined,
                    label: 'Connect Hub',
                    subtitle: 'Friends, rooms, games & wellness',
                    gradient: true,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ConnectScreen()));
                    },
                  ),

                  // 2. Truth & Dare quick-link
                  _DrawerTile(
                    icon: Icons.casino_outlined,
                    label: 'Truth & Dare',
                    subtitle: 'Play with warriors worldwide',
                    iconColor: const Color(0xFFFF6B6B),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const GamesHubScreen()));
                    },
                  ),

                  // 3. Stories quick-link
                  _DrawerTile(
                    icon: Icons.auto_stories_outlined,
                    label: 'Recovery Stories',
                    subtitle: 'Read & share journeys',
                    iconColor: const Color(0xFFFFB74D),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const StoriesScreen()));
                    },
                  ),

                  // 4. Wellness quick-link
                  _DrawerTile(
                    icon: Icons.self_improvement_rounded,
                    label: 'Wellness Hub',
                    subtitle: 'Breathe, meditate, journal',
                    iconColor: const Color(0xFF4FC3F7),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const WellnessHubScreen()));
                    },
                  ),

                  const SizedBox(height: 8),

                  // ── History & Settings ────────────────────────
                  _DrawerSection(label: 'TOOLS'),
                  _DrawerTile(
                    icon: Icons.history_rounded,
                    label: 'Urge History',
                    subtitle: 'Review all logged urges',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const UrgeHistoryScreen()));
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SettingsScreen()));
                    },
                  ),

                  const SizedBox(height: 8),

                  // ── Support ───────────────────────────────────
                  _DrawerSection(label: 'SUPPORT'),
                  _DrawerTile(
                    icon: Icons.support_agent_rounded,
                    label: 'Help & Support',
                    subtitle: 'Chat with your AI recovery coach',
                    gradient: true,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AICoachScreen()));
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.info_outline_rounded,
                    label: 'About ReWireX',
                    onTap: () {
                      Navigator.pop(context);
                      _showAbout(context);
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    onTap: () => Navigator.pop(context),
                  ),
                  _DrawerTile(
                    icon: Icons.description_outlined,
                    label: 'Terms of Service',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const TermsScreen()));
                    },
                  ),

                  const SizedBox(height: 8),

                  // ── Account ───────────────────────────────────
                  _DrawerSection(label: 'ACCOUNT'),
                  _DrawerTile(
                    icon: Icons.logout_rounded,
                    label: 'Sign Out',
                    iconColor: Colors.orange,
                    onTap: () async {
                      Navigator.pop(context);
                      await FirebaseAuth.instance.signOut();
                    },
                  ),
                ],
              ),
            ),

            // ── Footer ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'ReWireX v1.0.0',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.2), fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, String name, String initials,
      int score, String email) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()));
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF6C63FF).withOpacity(0.15),
              const Color(0xFF00C4A0).withOpacity(0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border(
            bottom:
                BorderSide(color: Colors.white.withOpacity(0.07), width: 1),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.3),
                      blurRadius: 12),
                ],
              ),
              child: Center(
                child: Text(initials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(email,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: score / 100,
                          minHeight: 4,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            score >= 80
                                ? const Color(0xFF00C4A0)
                                : score >= 50
                                    ? Colors.amber
                                    : const Color(0xFFE53935),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('$score%',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ]),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.2), size: 18),
          ],
        ),
      ),
    );
  }

  // ── Profile incomplete nudge ───────────────────────────────────
  Widget _buildProfileNudge(BuildContext context, int score) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withOpacity(0.25), width: 1),
        ),
        child: Row(children: [
          const Icon(Icons.workspace_premium_rounded,
              color: Colors.amber, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Complete your profile to unlock full AI personalisation',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 12,
                  height: 1.4),
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: Colors.amber, size: 12),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  ABOUT DIALOG
// ══════════════════════════════════════════════════════════════

void _showAbout(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF161625),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)]),
            ),
            child: const Icon(Icons.electric_bolt_rounded,
                color: Colors.white, size: 32),
          ),
          const SizedBox(height: 14),
          const Text('ReWireX',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Version 1.0.0',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 13)),
          const SizedBox(height: 14),
          Text(
            'ReWireX is an AI-powered addiction recovery companion that '
            'helps you build lasting habits through behavioral analytics, '
            'risk prediction, and intelligent coaching.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 14,
                height: 1.6),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child:
              const Text('Close', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════
//  REUSABLE DRAWER WIDGETS
// ══════════════════════════════════════════════════════════════

class _DrawerSection extends StatelessWidget {
  final String label;
  const _DrawerSection({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Text(label,
          style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0)),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool gradient;
  final Color? iconColor;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.gradient = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final ic = iconColor ?? const Color(0xFF6C63FF);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: gradient
              ? const Color(0xFF6C63FF).withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: gradient
              ? Border.all(
                  color: const Color(0xFF6C63FF).withOpacity(0.2), width: 1)
              : null,
        ),
        child: Row(children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              color: gradient ? Colors.transparent : ic.withOpacity(0.08),
              gradient: gradient
                  ? const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
            ),
            child:
                Icon(icon, color: gradient ? Colors.white : ic, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: gradient
                            ? Colors.white
                            : Colors.white.withOpacity(0.85),
                        fontSize: 15,
                        fontWeight: gradient
                            ? FontWeight.w700
                            : FontWeight.w500)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.35),
                          fontSize: 11)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.15), size: 16),
        ]),
      ),
    );
  }
}