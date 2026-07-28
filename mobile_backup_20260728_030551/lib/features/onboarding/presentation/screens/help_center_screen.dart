import 'package:flutter/material.dart';
import '../../../../core/theming/app_typography.dart';

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
      appBar: AppBar(
        title: const Text('Help & Knowledge Centre'),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _faqs.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final faq = _faqs[index];
            return ExpansionTile(
              title: Text(faq['q']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(faq['a']!, style: AppTypography.caption),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
