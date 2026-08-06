import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_typography.dart';

/// Redesigned Saved Places Screen with AppCard items for Home, Work, and Favorites.
class SavedPlacesScreen extends StatelessWidget {
  const SavedPlacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Saved Places'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Consumer<SettingsNotifier>(
        builder: (context, settings, child) {
          return SafeArea(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: settings.savedPlaces.length,
              itemBuilder: (context, index) {
                final place = settings.savedPlaces[index];
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
                          child: Icon(
                            place.icon == 'home' ? Icons.home_rounded : Icons.work_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                place.label,
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(place.address, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        const Icon(Icons.edit_outlined, color: AppColors.textMuted, size: 20),
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
