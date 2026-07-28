import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_typography.dart';

class PermissionsEducationScreen extends StatelessWidget {
  const PermissionsEducationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions Guide'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Why 7s Asks for Permissions', style: AppTypography.headline),
              const SizedBox(height: 8),
              const Text(
                'We believe in transparency. Here is why 7s uses device permissions:',
                style: AppTypography.caption,
              ),
              const SizedBox(height: 24),
              const _PermissionCard(
                icon: Icons.location_on_rounded,
                iconColor: AppColors.accent,
                title: 'Location Access',
                description:
                    'Allows 7s to pinpoint your pickup location, display nearby drivers on the map, and calculate accurate upfront fare quotes.',
              ),
              const SizedBox(height: 16),
              const _PermissionCard(
                icon: Icons.notifications_active_rounded,
                iconColor: Colors.orange,
                title: 'Notification Alerts',
                description:
                    'Keeps you updated when your driver accepts your request, arrives at pickup, or completes your trip.',
              ),
              const Spacer(),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => context.go('/login'),
                  child: const Text('CONTINUE TO LOGIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _PermissionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(description, style: AppTypography.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
