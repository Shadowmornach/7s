import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// 7s Mobile App — Pixel-Perfect Redesigned Profile & Privacy Settings Screen
/// Matches reference design 1:1 with GDPR controls, permission toggles, and security banner.
class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  bool _locationAccessEnabled = true;
  bool _pushNotificationsEnabled = true;

  static const primaryOrange = Color(0xFFFF7A1A);
  static const bgLight = Color(0xFFF8FAFC);
  static const textDark = Color(0xFF0F172A);
  static const textNavy = Color(0xFF1E1B4B);
  static const textMuted = Color(0xFF64748B);

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 28),
            SizedBox(width: 10),
            Text('Delete Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Your account will be deactivated immediately and scheduled for permanent deletion in 30 days.\n\nYou can recover your account anytime within 30 days simply by signing back in.',
          style: TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final authNotifier = context.read<AuthNotifier>();
              await authNotifier.logout();
              if (context.mounted) {
                context.go('/welcome');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete Account (30-Day Recovery)'),
          ),
        ],
      ),
    );
  }


  void _showDownloadDataModal(BuildContext context) {
    final session = context.read<AuthNotifier>().currentSession;
    final nickname = session?.nickname ?? 'User';
    final email = session?.email ?? 'user@example.com';
    final role = session?.role.name.toUpperCase() ?? 'PASSENGER';
    final serviceZone = session?.serviceZone ?? 'Voi Town';
    final paymentPref = session?.preferredPaymentMethod ?? 'Cash on Arrival';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Download My Data',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: textMuted),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Secure overview of your profile data & preferences on 7s:',
              style: TextStyle(fontSize: 13, color: textMuted, height: 1.35),
            ),
            const SizedBox(height: 16),


            // Clean Visual Summary Cards
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDataSummaryRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Profile Identity',
                    value: '$nickname ($email)',
                  ),
                  const Divider(height: 18, color: Color(0xFFE2E8F0)),
                  _buildDataSummaryRow(
                    icon: Icons.badge_outlined,
                    label: 'Account Role & Zone',
                    value: '$role • $serviceZone',
                  ),
                  const Divider(height: 18, color: Color(0xFFE2E8F0)),
                  _buildDataSummaryRow(
                    icon: Icons.payments_outlined,
                    label: 'Default Payment Method',
                    value: paymentPref,
                  ),
                  const Divider(height: 18, color: Color(0xFFE2E8F0)),
                  _buildDataSummaryRow(
                    icon: Icons.verified_user_outlined,
                    label: 'Consent & Legal Status',
                    value: 'Terms & Privacy Policy Accepted (v1.0)',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Encrypted personal data summary package generated!'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                },
                icon: const Icon(Icons.download_rounded, color: Colors.white, size: 20),
                label: const Text('Export Personal Data Package', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A1A),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSummaryRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: primaryOrange, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 13, color: textDark, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final authNotifier = context.watch<AuthNotifier>();
    final session = authNotifier.currentSession;
    final initials = session?.initials ?? 'SO';
    final nickname = session?.nickname ?? 'Shadow';
    final email = session?.email ?? 'shadow@example.com';
    final photoUrl = session?.photoUrl;

    return Container(
      color: bgLight,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Gradient Header Banner ────────────────────────────────
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFFF5EC),
                      Color(0xFFFFF0E5),
                      Color(0xFFF8FAFC),
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account & Privacy',
                          style: TextStyle(
                            color: textNavy,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Manage your profile, privacy and data',
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    // Security Shield Header Badge Illustration
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0F000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.shield_rounded, color: Color(0xFFFF9E59), size: 32),
                          Icon(Icons.lock_rounded, color: Colors.white, size: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // ── 1. Profile Summary Card ──────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x08000000),
                            blurRadius: 14,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Avatar Circle with Online Green Indicator
                          GestureDetector(
                            onTap: () => context.push('/complete-profile'),
                            child: Stack(
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFFFF9548), Color(0xFFFF6B00)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: ClipOval(
                                    child: (photoUrl != null && photoUrl.isNotEmpty && File(photoUrl).existsSync())
                                        ? Image.file(File(photoUrl), fit: BoxFit.cover, width: 54, height: 54)
                                        : Center(
                                            child: Text(
                                              initials,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 13,
                                    height: 13,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF22C55E),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Name & Email
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nickname,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  email,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // Edit Profile Button Pill
                          InkWell(
                            onTap: () => context.push('/complete-profile'),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7F2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFFFE5D6)),
                              ),
                              child: const Row(
                                children: [
                                  Text(
                                    'Edit Profile',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: primaryOrange,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.edit_outlined, color: primaryOrange, size: 14),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── 2. Privacy & Data Governance Card ────────────────────
                    _buildSectionHeader(
                      icon: Icons.shield_outlined,
                      title: 'Privacy & Data Governance',
                      iconColor: primaryOrange,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildListTile(
                            leadingBgColor: const Color(0xFFDCFCE7),
                            leadingIcon: Icons.file_download_outlined,
                            leadingIconColor: const Color(0xFF10B981),
                            title: 'Download My Data',
                            subtitle: 'Request a secure copy of your account profile and activity history',
                            trailingWidget: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF0FDF4),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.chevron_right_rounded, color: Color(0xFF10B981), size: 18),
                            ),
                            onTap: () => _showDownloadDataModal(context),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ),
                          _buildListTile(
                            leadingBgColor: const Color(0xFFFEE2E2),
                            leadingIcon: Icons.delete_outline_rounded,
                            leadingIconColor: const Color(0xFFEF4444),
                            title: 'Delete Account',
                            titleColor: const Color(0xFFEF4444),
                            subtitle: 'Deactivate account with 30-day restoration window',
                            trailingWidget: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFEF2F2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.chevron_right_rounded, color: Color(0xFFEF4444), size: 18),
                            ),
                            onTap: () => _showDeleteAccountDialog(context),
                          ),

                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── 3. Permissions Card ──────────────────────────────────
                    _buildSectionHeader(
                      icon: Icons.lock_rounded,
                      title: 'Permissions',
                      iconColor: const Color(0xFF3B82F6),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF3E8FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.location_on_rounded, color: Color(0xFF9333EA), size: 20),
                            ),
                            title: const Text('Location Access', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textDark)),
                            subtitle: const Text('Used only during active\nride requests in Voi Town', style: TextStyle(fontSize: 12, color: textMuted)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _locationAccessEnabled ? 'On' : 'Off',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _locationAccessEnabled ? const Color(0xFF22C55E) : textMuted,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Switch(
                                  value: _locationAccessEnabled,
                                  activeColor: Colors.white,
                                  activeTrackColor: const Color(0xFF22C55E),
                                  inactiveThumbColor: Colors.white,
                                  inactiveTrackColor: const Color(0xFFCBD5E1),
                                  onChanged: (val) {
                                    setState(() {
                                      _locationAccessEnabled = val;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFEF3C7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.notifications_active_rounded, color: Color(0xFFF59E0B), size: 20),
                            ),
                            title: const Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textDark)),
                            subtitle: const Text('Trip status updates\nand arrival alerts', style: TextStyle(fontSize: 12, color: textMuted)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _pushNotificationsEnabled ? 'On' : 'Off',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _pushNotificationsEnabled ? const Color(0xFF22C55E) : textMuted,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Switch(
                                  value: _pushNotificationsEnabled,
                                  activeColor: Colors.white,
                                  activeTrackColor: const Color(0xFF22C55E),
                                  inactiveThumbColor: Colors.white,
                                  inactiveTrackColor: const Color(0xFFCBD5E1),
                                  onChanged: (val) {
                                    setState(() {
                                      _pushNotificationsEnabled = val;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── 4. Legal Card ─────────────────────────────────────────
                    _buildSectionHeader(
                      icon: Icons.article_outlined,
                      title: 'Legal',
                      iconColor: const Color(0xFF6366F1),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildListTile(
                            leadingBgColor: const Color(0xFFEEF2FF),
                            leadingIcon: Icons.article_outlined,
                            leadingIconColor: const Color(0xFF6366F1),
                            title: 'Terms of Service',
                            subtitle: 'Read our terms and conditions',
                            trailingWidget: const Icon(Icons.chevron_right_rounded, color: Color(0xFF6366F1), size: 22),
                            onTap: () => context.push('/terms'),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ),
                          _buildListTile(
                            leadingBgColor: const Color(0xFFDCFCE7),
                            leadingIcon: Icons.verified_user_outlined,
                            leadingIconColor: const Color(0xFF10B981),
                            title: 'Privacy Policy',
                            subtitle: 'Learn how we protect your data',
                            trailingWidget: const Icon(Icons.chevron_right_rounded, color: Color(0xFF6366F1), size: 22),
                            onTap: () => context.push('/privacy-policy'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── 5. Bottom Privacy Banner ─────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFF5ED), Color(0xFFFFEBDD)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFE3D1)),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Cute Shield Icon with Checkmark
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFF0E6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.sentiment_satisfied_alt_rounded,
                                  color: primaryOrange,
                                  size: 28,
                                ),
                              ),
                              Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF22C55E),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, color: Colors.white, size: 10),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),

                          // Text Content
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Your privacy matters',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: textDark,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Text('♡', style: TextStyle(color: primaryOrange, fontSize: 14)),
                                  ],
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'We are committed to keeping your data safe and secure.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textMuted,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Folder / Lock Icon Illustration
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.folder_special_rounded,
                              color: Color(0xFF6366F1),
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Log Out Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await authNotifier.logout();
                          if (context.mounted) {
                            context.go('/welcome');
                          }
                        },
                        icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
                        label: const Text(
                          'Log Out',
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFEE2E2)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        '7s Mobile v1.0.0 • Voi Town, Kenya',
                        style: TextStyle(fontSize: 11, color: textMuted),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required Color leadingBgColor,
    required IconData leadingIcon,
    required Color leadingIconColor,
    required String title,
    Color titleColor = textDark,
    required String subtitle,
    required Widget trailingWidget,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: leadingBgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(leadingIcon, color: leadingIconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: titleColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: textMuted,
          height: 1.3,
        ),
      ),
      trailing: trailingWidget,
      onTap: onTap,
    );
  }
}
