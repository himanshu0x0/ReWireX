// lib/features/profile/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final ProfileService _service = ProfileService();

  late AnimationController _fadeController;
  late Animation<double>   _fadeAnim;

  ProfileModel? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadProfile();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final p = await _service.fetchProfile();
    if (mounted) setState(() { _profile = p; _loading = false; });
  }

  // ── Pick profile photo ────────────────────────────────────
  Future<void> _pickProfilePhoto() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF141428),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Update Profile Photo',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _PhotoOptionTile(
              icon: Icons.photo_library_outlined,
              label: 'Choose from Gallery',
              color: const Color(0xFF6C63FF),
              onTap: () async {
                Navigator.pop(context);
                final picked = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 512,
                  maxHeight: 512,
                  imageQuality: 85,
                );
                if (picked != null) {
                  await _service.updateField('photoUrl', picked.path);
                  await _loadProfile();
                }
              },
            ),
            const SizedBox(height: 10),
            _PhotoOptionTile(
              icon: Icons.camera_alt_outlined,
              label: 'Take a Photo',
              color: const Color(0xFF00C4A0),
              onTap: () async {
                Navigator.pop(context);
                final picked = await ImagePicker().pickImage(
                  source: ImageSource.camera,
                  maxWidth: 512,
                  maxHeight: 512,
                  imageQuality: 85,
                );
                if (picked != null) {
                  await _service.updateField('photoUrl', picked.path);
                  await _loadProfile();
                }
              },
            ),
            const SizedBox(height: 10),
            _PhotoOptionTile(
              icon: Icons.link_rounded,
              label: 'Enter Photo URL',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(context);
                _editField(
                  title: 'Photo URL',
                  field: 'photoUrl',
                  current: _profile?.photoUrl ?? '',
                  hint: 'https://example.com/photo.jpg',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Edit a text field ──────────────────────────────────────
  Future<void> _editField({
    required String title,
    required String field,
    required String current,
    String hint = '',
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) async {
    final ctrl = TextEditingController(text: current);
    final saved = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _EditSheet(
            title: title, controller: ctrl,
            hint: hint, maxLines: maxLines, keyboardType: keyboardType),
      ),
    );
    if (saved == null) return;
    await _service.updateField(field, saved);
    await _loadProfile();
  }

  // ── Edit a dropdown field ──────────────────────────────────
  Future<void> _editDropdown({
    required String title,
    required String field,
    required String current,
    required List<String> options,
  }) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(title: title, options: options, current: current),
    );
    if (picked == null) return;
    await _service.updateField(field, picked);
    await _loadProfile();
  }

  // ── Edit a date field ──────────────────────────────────────
  Future<void> _editDate({
    required String title,
    required String field,
    required String current,
  }) async {
    final initial = current.isNotEmpty
        ? DateTime.tryParse(current) ?? DateTime.now()
        : DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF6C63FF),
            onPrimary: Colors.white,
            surface: Color(0xFF1A1A2E),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    final str = picked.toIso8601String().split('T').first;
    await _service.updateField(field, str);
    await _loadProfile();
  }

  // ── Toggle a bool field ────────────────────────────────────
  Future<void> _toggleBool(String field, bool current) async {
    await _service.updateField(field, !current);
    await _loadProfile();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: _buildAppBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF), strokeWidth: 2.5))
          : FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Profile completion banner ─────────────
                    if (_profile != null && _profile!.completionScore < 100)
                      _CompletionBanner(profile: _profile!),

                    if (_profile != null && _profile!.completionScore < 100)
                      const SizedBox(height: 20),

                    // ── Avatar + name ─────────────────────────
                    _buildAvatarSection(),
                    const SizedBox(height: 24),

                    // ── Personal Info ─────────────────────────
                    _sectionHeader('PERSONAL INFORMATION'),
                    const SizedBox(height: 12),
                    _buildPersonalInfoCard(),
                    const SizedBox(height: 20),

                    // ── Recovery Info ─────────────────────────
                    _sectionHeader('RECOVERY PROFILE'),
                    const SizedBox(height: 12),
                    _buildRecoveryCard(),
                    const SizedBox(height: 20),

                    // ── App Settings ──────────────────────────
                    _sectionHeader('APP SETTINGS'),
                    const SizedBox(height: 12),
                    _buildSettingsCard(),
                    const SizedBox(height: 20),

                    // ── Account ───────────────────────────────
                    _sectionHeader('ACCOUNT'),
                    const SizedBox(height: 12),
                    _buildAccountCard(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0D0D1A),
      elevation: 0,
      leading: IconButton(
        icon: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.arrow_back_ios_new_rounded,
              size: 15, color: Colors.white.withOpacity(0.7)),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)],
        ).createShader(bounds),
        child: const Text('My Profile',
            style: TextStyle(
                color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
      ),
      actions: [
        if (_profile != null)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_profile!.completionScore}% complete',
                  style: TextStyle(
                      color: _profile!.completionScore >= 80
                          ? const Color(0xFF00C4A0)
                          : _profile!.completionScore >= 50
                              ? Colors.amber
                              : const Color(0xFFE53935),
                      fontSize: 13,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Avatar section ─────────────────────────────────────────
  Widget _buildAvatarSection() {
    final user = FirebaseAuth.instance.currentUser;
    final name = _profile?.displayName.isNotEmpty == true
        ? _profile!.displayName
        : (user?.email ?? 'User');
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : 'U';

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.35),
                      blurRadius: 24, offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(initials,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 33,
                          fontWeight: FontWeight.w800)),
                ),
              ),
              // Edit badge
              Positioned(
                bottom: 0, right: 0,
                child: GestureDetector(
                  onTap: _pickProfilePhoto,
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0D0D1A), width: 2),
                    ),
                    child: const Icon(Icons.edit_rounded, color: Colors.white, size: 13),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _profile?.displayName.isNotEmpty == true ? _profile!.displayName : 'Add your name',
            style: TextStyle(
              color: _profile?.displayName.isNotEmpty == true
                  ? Colors.white
                  : Colors.white.withOpacity(0.35),
              fontSize: 21, fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(user?.email ?? '',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
          if (_profile?.username.isNotEmpty == true) ...[
            const SizedBox(height: 2),
            Text('@${_profile!.username}',
                style: const TextStyle(color: Color(0xFF6C63FF), fontSize: 13)),
          ],
        ],
      ),
    );
  }

  // ── Section header ─────────────────────────────────────────
  Widget _sectionHeader(String label) => Text(label,
      style: TextStyle(
          color: Colors.white.withOpacity(0.35),
          fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2.5));

  // ── Personal Info Card ─────────────────────────────────────
  Widget _buildPersonalInfoCard() {
    return _ProfileCard(
      children: [
        _ProfileRow(
          icon: Icons.person_outline_rounded,
          label: 'Full Name',
          value: _profile?.displayName ?? '',
          onTap: () => _editField(
              title: 'Full Name', field: 'displayName',
              current: _profile?.displayName ?? '',
              hint: 'Your full name'),
        ),
        _ProfileRow(
          icon: Icons.alternate_email_rounded,
          label: 'Username',
          value: _profile?.username ?? '',
          onTap: () => _editField(
              title: 'Username', field: 'username',
              current: _profile?.username ?? '',
              hint: 'e.g. warrior_2024'),
        ),
        _ProfileRow(
          icon: Icons.notes_rounded,
          label: 'Bio',
          value: _profile?.bio ?? '',
          onTap: () => _editField(
              title: 'Bio', field: 'bio',
              current: _profile?.bio ?? '',
              hint: 'Tell your story in a few words...',
              maxLines: 3),
        ),
        _ProfileRow(
          icon: Icons.wc_rounded,
          label: 'Gender',
          value: _profile?.gender ?? '',
          onTap: () => _editDropdown(
              title: 'Gender', field: 'gender',
              current: _profile?.gender ?? '',
              options: ['Male', 'Female', 'Non-binary', 'Prefer not to say']),
        ),
        _ProfileRow(
          icon: Icons.cake_rounded,
          label: 'Date of Birth',
          value: _profile?.dateOfBirth ?? '',
          onTap: () => _editDate(
              title: 'Date of Birth', field: 'dateOfBirth',
              current: _profile?.dateOfBirth ?? ''),
        ),
        _ProfileRow(
          icon: Icons.location_on_outlined,
          label: 'Country',
          value: _profile?.country ?? '',
          onTap: () => _editField(
              title: 'Country', field: 'country',
              current: _profile?.country ?? '',
              hint: 'e.g. India, USA'),
          isLast: true,
        ),
      ],
    );
  }

  // ── Recovery Card ──────────────────────────────────────────
  Widget _buildRecoveryCard() {
    return _ProfileCard(
      children: [
        _ProfileRow(
          icon: Icons.psychology_outlined,
          label: 'Addiction Type',
          value: _profile?.addictionType ?? '',
          onTap: () => _editDropdown(
              title: 'Addiction Type', field: 'addictionType',
              current: _profile?.addictionType ?? '',
              options: [
                'Pornography', 'Alcohol', 'Social Media', 'Gaming',
                'Smoking', 'Drugs', 'Gambling', 'Other',
              ]),
        ),
        _ProfileRow(
          icon: Icons.flag_outlined,
          label: 'Recovery Goal',
          value: _profile?.recoveryGoal ?? '',
          onTap: () => _editField(
              title: 'Recovery Goal', field: 'recoveryGoal',
              current: _profile?.recoveryGoal ?? '',
              hint: 'e.g. Stay clean for 90 days'),
        ),
        _ProfileRow(
          icon: Icons.calendar_today_rounded,
          label: 'Sobriety Start Date',
          value: _profile?.sobrietyStartDate ?? '',
          onTap: () => _editDate(
              title: 'Sobriety Start Date', field: 'sobrietyStartDate',
              current: _profile?.sobrietyStartDate ?? ''),
          isLast: true,
        ),
      ],
    );
  }

  // ── Settings Card ──────────────────────────────────────────
  Widget _buildSettingsCard() {
    return _ProfileCard(
      children: [
        _ToggleRow(
          icon: Icons.notifications_outlined,
          label: 'Push Notifications',
          value: _profile?.notificationsEnabled ?? true,
          onChanged: () => _toggleBool(
              'notificationsEnabled', _profile?.notificationsEnabled ?? true),
        ),
        _ToggleRow(
          icon: Icons.shield_outlined,
          label: 'Guardian Mode',
          subtitle: 'AI alerts when risk is critical',
          value: _profile?.guardianModeEnabled ?? true,
          onChanged: () => _toggleBool(
              'guardianModeEnabled', _profile?.guardianModeEnabled ?? true),
          isLast: true,
        ),
      ],
    );
  }

  // ── Account Card ───────────────────────────────────────────
  Widget _buildAccountCard() {
    return _ProfileCard(
      children: [
        _ActionRow(
          icon: Icons.phone_outlined,
          label: 'Phone Number',
          value: _profile?.phone ?? '',
          iconColor: const Color(0xFF6C63FF),
          onTap: () => _editField(
              title: 'Phone Number', field: 'phone',
              current: _profile?.phone ?? '',
              hint: '+91 XXXXXXXXXX',
              keyboardType: TextInputType.phone),
        ),

        _ActionRow(
          icon: Icons.delete_outline_rounded,
          label: 'Delete Account',
          iconColor: const Color(0xFFE53935),
          labelColor: const Color(0xFFE53935),
          onTap: _confirmDeleteAccount,
          isLast: true,
        ),
      ],
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF161625),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Account?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          'All your data including streaks, urge logs, and recovery progress will be permanently deleted.',
          style: TextStyle(color: Colors.white.withOpacity(0.6), height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF6C63FF)))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.deleteAccountData();
      await FirebaseAuth.instance.currentUser?.delete();
    }
  }
}

// ══════════════════════════════════════════════════════════════
//  PROFILE COMPLETION BANNER
// ══════════════════════════════════════════════════════════════

class _CompletionBanner extends StatelessWidget {
  final ProfileModel profile;
  const _CompletionBanner({required this.profile});

  @override
  Widget build(BuildContext context) {
    final score   = profile.completionScore;
    final missing = profile.missingFields;
    final color   = score >= 70 ? Colors.amber : const Color(0xFFE53935);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.info_outline_rounded, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Your profile is $score% complete',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
            Text('$score%',
                style: TextStyle(
                    color: color, fontSize: 19, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 5,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Missing: ${missing.take(3).join(', ')}${missing.length > 3 ? '…' : ''}',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5), fontSize: 13, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  REUSABLE CARD + ROW WIDGETS
// ══════════════════════════════════════════════════════════════

class _ProfileCard extends StatelessWidget {
  final List<Widget> children;
  const _ProfileCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF141428),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07), width: 1),
      ),
      child: Column(children: children),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool isLast;

  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = value.trim().isEmpty;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF6C63FF), size: 16),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.45), fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      isEmpty ? 'Tap to add' : value,
                      style: TextStyle(
                        color: isEmpty
                            ? Colors.white.withOpacity(0.25)
                            : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(0.2), size: 20),
            ]),
          ),
          if (!isLast)
            Divider(height: 1, color: Colors.white.withOpacity(0.05),
                indent: 56, endIndent: 18),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final VoidCallback onChanged;
  final bool isLast;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00C4A0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF00C4A0), size: 16),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(color: Colors.white, fontSize: 14)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.38), fontSize: 11)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: (_) => onChanged(),
              activeColor: const Color(0xFF6C63FF),
              inactiveThumbColor: Colors.white.withOpacity(0.3),
              inactiveTrackColor: Colors.white.withOpacity(0.1),
            ),
          ]),
        ),
        if (!isLast)
          Divider(height: 1, color: Colors.white.withOpacity(0.05),
              indent: 56, endIndent: 18),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Color iconColor;
  final Color? labelColor;
  final VoidCallback onTap;
  final bool isLast;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
    this.value,
    this.labelColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            color: labelColor ?? Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500)),
                    if (value?.isNotEmpty == true)
                      Text(value!,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.4), fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(0.2), size: 20),
            ]),
          ),
          if (!isLast)
            Divider(height: 1, color: Colors.white.withOpacity(0.05),
                indent: 56, endIndent: 18),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  EDIT BOTTOM SHEET
// ══════════════════════════════════════════════════════════════

class _EditSheet extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType keyboardType;

  const _EditSheet({
    required this.title,
    required this.controller,
    this.hint      = '',
    this.maxLines  = 1,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141428),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(title,
              style: const TextStyle(
                  color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF00C4A0)]),
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Save',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Picker bottom sheet ────────────────────────────────────────

class _PickerSheet extends StatelessWidget {
  final String title;
  final List<String> options;
  final String current;

  const _PickerSheet({
    required this.title,
    required this.options,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141428),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(title,
              style: const TextStyle(
                  color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ...options.map((opt) => GestureDetector(
            onTap: () => Navigator.pop(context, opt),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: opt == current
                    ? const Color(0xFF6C63FF).withOpacity(0.15)
                    : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: opt == current
                      ? const Color(0xFF6C63FF).withOpacity(0.5)
                      : Colors.white.withOpacity(0.08),
                  width: 1,
                ),
              ),
              child: Row(children: [
                Expanded(
                  child: Text(opt,
                      style: TextStyle(
                          color: opt == current
                              ? const Color(0xFF6C63FF)
                              : Colors.white,
                          fontSize: 15,
                          fontWeight: opt == current
                              ? FontWeight.w700
                              : FontWeight.w400)),
                ),
                if (opt == current)
                  const Icon(Icons.check_rounded,
                      color: Color(0xFF6C63FF), size: 18),
              ]),
            ),
          )),
        ],
      ),
    );
  }
}

// ── Photo option tile ──────────────────────────────────────────

class _PhotoOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PhotoOptionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Text(label,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const Spacer(),
          Icon(Icons.arrow_forward_ios_rounded,
              color: color.withOpacity(0.5), size: 14),
        ]),
      ),
    );
  }
}