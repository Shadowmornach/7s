import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_typography.dart';

/// Redesigned Permissions Education Screen with clear transparency cards,
/// icon badges, and AppButton action.
class PermissionsEducationScreen extends StatelessWidget {
  const PermissionsEducationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Permissions Guide'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Why 7s Asks for Permissions',
                style: AppTypography.displayLarge.copyWith(fontSize: 26),
              ),
              const SizedBox(height: 8),
              Text(
                'We believe in complete transparency. Here is why 7s uses device permissions:',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 28),
              const _PermissionCard(
                icon: Icons.location_on_rounded,
                iconColor: AppColors.primary,
                title: 'Location Access',
                description:
                    'Allows 7s to pinpoint your exact pickup location, display nearby drivers on the map, and calculate accurate upfront fare quotes.',
              ),
              const SizedBox(height: 16),
              const _PermissionCard(
                icon: Icons.notifications_active_rounded,
                iconColor: AppColors.primary,
                title: 'Notification Alerts',
                description:
                    'Keeps you updated when your driver accepts your request, arrives at pickup, or completes your trip.',
              ),
              const Spacer(),
              AppButton(
                text: 'CONTINUE TO LOGIN',
                onPressed: () => context.go('/login'),
                icon: Icons.arrow_forward_rounded,
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
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
