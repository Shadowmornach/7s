import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/settings_provider.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_typography.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsNotifier>().loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account & Settings'),
      ),
      body: Consumer<SettingsNotifier>(
        builder: (context, settings, child) {
          if (settings.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = settings.profile;

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Profile Header Card
                if (profile != null)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.person, size: 36, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(profile.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              const SizedBox(height: 4),
                              Text(profile.phoneNumber, style: AppTypography.caption),
                              Text(profile.email, style: AppTypography.caption),
                            ],
                          ),
                        ),
                        const Icon(Icons.verified_user_rounded, color: Colors.green),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),
                const Text('Preferences & Services', style: AppTypography.headline),
                const SizedBox(height: 12),

                ListTile(
                  leading: const Icon(Icons.bookmark_border_rounded, color: AppColors.primary),
                  title: const Text('Saved Places', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Home, Work & Favorite destinations'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/saved-places'),
                ),
                const Divider(),

                ListTile(
                  leading: const Icon(Icons.devices_rounded, color: AppColors.primary),
                  title: const Text('Connected Devices & Sessions', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('View active logins & revoke access'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/devices'),
                ),
                const Divider(),

                ListTile(
                  leading: const Icon(Icons.notifications_outlined, color: AppColors.primary),
                  title: const Text('Notifications Centre', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Manage push alerts & inbox'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/notifications'),
                ),
                const Divider(),

                ListTile(
                  leading: const Icon(Icons.help_outline_rounded, color: AppColors.primary),
                  title: const Text('Help & Knowledge Centre', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('FAQs, Safety & Support'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/help-center'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
