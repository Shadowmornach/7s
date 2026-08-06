import 'package:flutter/material.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_typography.dart';

/// Redesigned Help & Knowledge Centre with AppCard FAQ tiles and support headers.
class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  static const List<Map<String, String>> _faqs = [
    {'q': 'How do I request a ride?', 'a': 'Enter your pickup and destination locations, review upfront fare estimates, select your ride category, and tap Request.'},
    {'q': 'How does live tracking work?', 'a': 'Once a driver accepts, you will see their vehicle location and estimated arrival time update live on the map.'},
    {'q': 'What should I do in an emergency?', 'a': 'Tap the red EMERGENCY SOS button. It instantly notifies 7s safety response teams and shares your live location with your emergency contacts.'},
    {'q': 'How do I share my trip with family?', 'a': 'Tap "Share Ride" during an active trip to generate a secure public tracking link that anyone can view in a web browser.'},
    {'q': 'Which payment methods are accepted?', 'a': '7s supports Cash and instant M-Pesa Daraja STK push payments directly from your phone.'},
    {'q': 'How do I become a Rider or Fleet Owner?', 'a': 'Register on 7s, submit your valid driving license/vehicle documents, and complete verification in the Operations Center.'},
    {'q': 'Where can I see my trip history?', 'a': 'Navigate to Menu -> Ride History to view past receipts, route maps, and driver ratings.'},
    {'q': 'How do I contact 7s Support?', 'a': 'Reach our 24/7 Support team via email at support@7s.co.ke or call our helpline directly from the app.'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Help & Knowledge Centre'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Search / Header Tile
            AppCard(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.headset_mic_rounded, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'How can we help?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Search our knowledge base or browse frequently asked questions below.',
                    style: AppTypography.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'FREQUENTLY ASKED QUESTIONS',
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(_faqs.length, (index) {
              final faq = _faqs[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: AppCard(
                  padding: EdgeInsets.zero,
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      title: Text(
                        faq['q']!,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Text(
                            faq['a']!,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
