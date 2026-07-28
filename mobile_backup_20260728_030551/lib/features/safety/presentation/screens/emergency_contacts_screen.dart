import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/safety_provider.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_typography.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
      ),
      body: Consumer<SafetyNotifier>(
        builder: (context, safety, child) {
          return SafeArea(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: safety.contacts.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final contact = safety.contacts[index];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.secondary,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${contact.relationship} • ${contact.phoneNumber}', style: AppTypography.caption),
                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
