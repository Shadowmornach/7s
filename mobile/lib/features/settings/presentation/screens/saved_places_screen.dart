import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_typography.dart';

class SavedPlacesScreen extends StatelessWidget {
  const SavedPlacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Places'),
      ),
      body: Consumer<SettingsNotifier>(
        builder: (context, settings, child) {
          return SafeArea(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: settings.savedPlaces.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final place = settings.savedPlaces[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Icon(
                      place.icon == 'home' ? Icons.home_rounded : Icons.work_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(place.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(place.address, style: AppTypography.caption),
                  trailing: const Icon(Icons.edit_outlined),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
