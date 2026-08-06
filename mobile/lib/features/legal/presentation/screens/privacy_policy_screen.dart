import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 7s Mobile App — Privacy Policy Screen (/privacy-policy)
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const primaryOrange = Color(0xFFFF7A1A);
  static const textDark = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Privacy Policy', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textDark, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '7s Delivery Privacy Policy',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textDark),
              ),
              const SizedBox(height: 4),
              const Text('Version v1.0 • GDPR & Data Protection Compliant', style: TextStyle(fontSize: 12, color: textMuted)),
              const SizedBox(height: 24),

              // ── Voi Town Location Clause ─────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF0E6),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  border: Border.fromBorderSide(BorderSide(color: Color(0xFFFFE0CC))),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on_rounded, color: primaryOrange, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Location access is requested only while booking or using ride services within our supported service area (Voi Town). Your location is not continuously tracked when the app is idle.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                '1. Data We Collect',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryOrange),
              ),
              const SizedBox(height: 6),
              const Text(
                'We collect your email address, nickname, optional profile photo, and GPS coordinates during active ride requests. We do not sell your personal data.',
                style: TextStyle(fontSize: 14, color: textDark, height: 1.5),
              ),
              const SizedBox(height: 20),
              const Text(
                '2. Your Rights (Access, Export & Erasure)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryOrange),
              ),
              const SizedBox(height: 6),
              const Text(
                'Under GDPR & data protection laws, you have the right to download a full copy of your data ("Download My Data") and request permanent deletion ("Delete Account") with a 30-day recovery window directly in Settings.',
                style: TextStyle(fontSize: 14, color: textDark, height: 1.5),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
