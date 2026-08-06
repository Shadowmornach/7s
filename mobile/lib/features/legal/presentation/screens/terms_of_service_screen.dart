import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 7s Mobile App — Terms of Service Screen (/terms)
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  static const primaryOrange = Color(0xFFFF7A1A);
  static const textDark = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Terms of Service', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textDark, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '7s Delivery Terms of Service',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textDark),
              ),
              SizedBox(height: 4),
              Text('Version v1.0 • Effective Date: July 2026', style: TextStyle(fontSize: 12, color: textMuted)),
              SizedBox(height: 24),
              Text(
                '1. Operating Service Zone',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryOrange),
              ),
              SizedBox(height: 6),
              Text(
                '7s Delivery currently operates exclusively within Voi Town, Kenya. Booking requests with pickup or destination points outside the supported service area will not be accepted.',
                style: TextStyle(fontSize: 14, color: textDark, height: 1.5),
              ),
              SizedBox(height: 20),
              Text(
                '2. Ride Booking & Cash Payments',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryOrange),
              ),
              SizedBox(height: 6),
              Text(
                'Fares shown in the app are estimated calculations based on distance and standard Voi Town motorcycle rates. Cash is paid directly to the rider upon trip completion.',
                style: TextStyle(fontSize: 14, color: textDark, height: 1.5),
              ),
              SizedBox(height: 20),
              Text(
                '3. Passenger Code of Conduct',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryOrange),
              ),
              SizedBox(height: 6),
              Text(
                'Passengers must treat riders with respect and wear protective helmets provided during the ride. Repeated no-shows or unsafe behavior may result in account suspension.',
                style: TextStyle(fontSize: 14, color: textDark, height: 1.5),
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
