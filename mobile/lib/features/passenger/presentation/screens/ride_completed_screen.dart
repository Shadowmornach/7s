import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/ride_state_notifier.dart';

/// 7s Mobile App — Ride Completed Receipt & Driver Rating Screen
class RideCompletedScreen extends StatefulWidget {
  const RideCompletedScreen({super.key});

  @override
  State<RideCompletedScreen> createState() => _RideCompletedScreenState();
}

class _RideCompletedScreenState extends State<RideCompletedScreen> {
  int _selectedRating = 5;

  static const primaryOrange = Color(0xFFFF7A1A);
  static const bgLight = Color(0xFFF8FAFC);
  static const textDark = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final rideNotifier = context.read<RideStateNotifier>();
    final booking = rideNotifier.activeBooking;

    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Celebration Check Circle Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF10B981),
                  size: 48,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Ride Completed!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Thank you for riding with 7s Delivery platform in Voi Town',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: textMuted),
              ),

              const SizedBox(height: 24),

              // Route & Fare Summary Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 3)),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Pickup Row
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            booking?.pickupName ?? 'Voi SGR Station',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textDark),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 3.5, top: 4, bottom: 4),
                      child: SizedBox(height: 12, child: VerticalDivider(width: 1, color: Color(0xFFCBD5E1))),
                    ),
                    // Destination Row
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: primaryOrange, size: 14),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            booking?.destinationName ?? 'Voi Town Center / Market',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textDark),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                    ),
                    // Fare Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount Paid', style: TextStyle(fontSize: 13, color: textMuted)),
                        Text(
                          booking?.fareAmount ?? 'KSh 150',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: primaryOrange),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Driver Rating Prompt
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 3)),
                  ],
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    const Text(
                      'Rate Your Trip with Francis',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textDark),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        return IconButton(
                          icon: Icon(
                            starValue <= _selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                            color: const Color(0xFFFFB800),
                            size: 32,
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedRating = starValue;
                            });
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Done Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    rideNotifier.reset();
                    context.go('/passenger/home');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Done • Return to Home', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
