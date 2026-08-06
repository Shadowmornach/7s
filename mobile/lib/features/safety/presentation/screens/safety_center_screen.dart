import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/safety_provider.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_typography.dart';

/// Redesigned Safety Center Screen with emergency response card,
/// safety tools list tiles, and live trip status sharing.
class SafetyCenterScreen extends StatefulWidget {
  const SafetyCenterScreen({super.key});

  @override
  State<SafetyCenterScreen> createState() => _SafetyCenterScreenState();
}

class _SafetyCenterScreenState extends State<SafetyCenterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SafetyNotifier>().loadContacts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Safety Platform & Emergency SOS'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Consumer<SafetyNotifier>(
        builder: (context, safety, child) {
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Emergency Operations Card
                AppCard(
                  backgroundColor: AppColors.alert,
                  elevation: 4,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 48),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '7s Emergency Operations Centre',
                        style: AppTypography.titleLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Press & hold SOS to alert emergency services and your trusted contacts immediately.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 20),
                      AppButton(
                        text: 'TRIGGER EMERGENCY SOS',
                        variant: AppButtonVariant.secondary,
                        icon: Icons.shield_rounded,
                        onPressed: () {
                          safety.triggerSos(
                            rideId: 'active-ride-99',
                            expectedVersion: 1,
                            emergencyType: 'CRITICAL_PANIC',
                            severity: 'CRITICAL',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('EMERGENCY SOS DISPATCHED TO 7S OPERATIONS')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'SAFETY TOOLS',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.people_outline_rounded, color: AppColors.primary, size: 22),
                        ),
                        title: const Text('Emergency Contacts', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${safety.contacts.length} trusted contacts configured', style: AppTypography.caption),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                        onTap: () => context.push('/safety/contacts'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.pin_rounded, color: AppColors.primary, size: 22),
                        ),
                        title: const Text('Mandatory Ride PIN Verification', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('4-digit PIN required before trips start'),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                        onTap: () => context.push('/safety/verify-pin'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.share_location_rounded, color: AppColors.primary, size: 22),
                        ),
                        title: const Text('Share Live Trip Status', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Generates secure live tracking URL'),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                        onTap: () {
                          safety.generateShareLink('ride-99');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Trip share link copied to clipboard')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
