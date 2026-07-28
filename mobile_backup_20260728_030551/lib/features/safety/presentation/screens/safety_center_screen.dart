import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/safety_provider.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_typography.dart';

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
      appBar: AppBar(
        title: const Text('Safety Platform & Emergency SOS'),
      ),
      body: Consumer<SafetyNotifier>(
        builder: (context, safety, child) {
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Emergency SOS Banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 48),
                      const SizedBox(height: 12),
                      const Text('7s Emergency Operations Centre', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text(
                        'Press & hold SOS to alert emergency services and your trusted contacts immediately.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.red.shade900,
                          ),
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
                          child: const Text('TRIGGER EMERGENCY SOS', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Text('Safety Tools', style: AppTypography.headline),
                const SizedBox(height: 12),

                ListTile(
                  leading: const Icon(Icons.people_outline_rounded, color: AppColors.primary),
                  title: const Text('Emergency Contacts', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${safety.contacts.length} trusted contacts configured', style: AppTypography.caption),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/safety/contacts'),
                ),
                const Divider(),

                ListTile(
                  leading: const Icon(Icons.pin_rounded, color: AppColors.primary),
                  title: const Text('Mandatory Ride PIN Verification', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('4-digit PIN required before trips start'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/safety/verify-pin'),
                ),
                const Divider(),

                ListTile(
                  leading: const Icon(Icons.share_location_rounded, color: AppColors.primary),
                  title: const Text('Share Live Trip Status', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Generates secure live tracking URL'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    safety.generateShareLink('ride-99');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Trip share link copied to clipboard')),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
