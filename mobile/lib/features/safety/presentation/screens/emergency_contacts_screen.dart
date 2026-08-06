import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/safety_provider.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_typography.dart';

/// Redesigned Emergency Contacts Screen with AppCard items and relationship chips.
class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Consumer<SafetyNotifier>(
        builder: (context, safety, child) {
          return SafeArea(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: safety.contacts.length,
              itemBuilder: (context, index) {
                final contact = safety.contacts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contact.name,
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${contact.relationship} • ${contact.phoneNumber}',
                                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
