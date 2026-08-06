import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/passenger_provider.dart';
import '../providers/ride_state_notifier.dart';
import 'package:mobile/features/payments/presentation/widgets/mpesa_phone_dialog.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';


/// 7s Mobile App — Fare Offer Screen (MVP Business Aligned)
class FareOfferScreen extends StatefulWidget {
  const FareOfferScreen({super.key});

  @override
  State<FareOfferScreen> createState() => _FareOfferScreenState();
}

class _FareOfferScreenState extends State<FareOfferScreen> {

  bool _isBookingConfirmed = false;
  String _selectedPaymentMethod = 'Cash';

  void _showPaymentMethodSelector() async {
    final authNotifier = context.read<AuthNotifier>();
    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.payments_outlined, color: Color(0xFF22C55E), size: 28),
              title: const Text('Cash on Arrival', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Pay driver in cash when trip completes'),
              onTap: () => Navigator.pop(ctx, 'Cash'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.phone_android_rounded, color: Color(0xFF3B82F6), size: 28),
              title: const Text('M-Pesa STK Push', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Instant prompt on your M-Pesa phone number'),
              onTap: () => Navigator.pop(ctx, 'M-Pesa'),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;

    if (selected == 'M-Pesa') {
      final currentPhone = authNotifier.currentSession?.phoneNumber;
      if (currentPhone == null || currentPhone.trim().isEmpty) {
        final newPhone = await MpesaPhonePromptDialog.show(context);
        if (newPhone != null && newPhone.isNotEmpty) {
          authNotifier.updatePhoneNumber(newPhone);
          setState(() => _selectedPaymentMethod = 'M-Pesa');
        }
      } else {
        setState(() => _selectedPaymentMethod = 'M-Pesa');
      }
    } else if (selected == 'Cash') {
      setState(() => _selectedPaymentMethod = 'Cash');
    }
  }

  void _onConfirmBooking() {
    final passenger = context.read<PassengerNotifier>();
    final rideNotifier = context.read<RideStateNotifier>();

    final pickupName = passenger.pickupLocation?.primaryText ?? 'Current Location';
    final pickupLat = passenger.pickupLocation?.latitude ?? -3.3967;
    final pickupLng = passenger.pickupLocation?.longitude ?? 38.5562;

    final destName = passenger.destinationLocation?.primaryText ?? 'Voi SGR Railway Station';
    final destLat = passenger.destinationLocation?.latitude ?? -3.3980;
    final destLng = passenger.destinationLocation?.longitude ?? 38.5580;

    final fareAmount = passenger.currentQuote?.formattedFare ?? 'KSh 150';

    rideNotifier.startRideBooking(
      pickupName: pickupName,
      pickupLatLng: LatLng(pickupLat, pickupLng),
      destinationName: destName,
      destinationLatLng: LatLng(destLat, destLng),
      fareAmount: fareAmount,
      paymentMethod: _selectedPaymentMethod == 'M-Pesa' ? 'M-Pesa STK Push' : 'Cash on Arrival',
    );

    context.push('/passenger/searching-driver');
  }


  @override
  Widget build(BuildContext context) {
    const primaryOrange = Color(0xFFFF7A1A);
    const bgGray = Color(0xFFF8FAFC);
    const textDark = Color(0xFF0F172A);
    const textMuted = Color(0xFF64748B);

    return Consumer<PassengerNotifier>(
      builder: (context, passenger, child) {
        final pickupName = passenger.pickupLocation?.primaryText ?? 'Current location';
        final destinationName = passenger.destinationLocation?.primaryText ?? 'Voi SGR Railway Station';
        final formattedFare = passenger.currentQuote?.formattedFare ?? 'KSh 150';

        return Scaffold(
          backgroundColor: bgGray,
          appBar: AppBar(
            backgroundColor: primaryOrange,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => context.pop(),
            ),
            centerTitle: true,
            title: const Text(
              'Fare Offer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Trip Summary Card ────────────────────────────────────
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0A000000),
                                blurRadius: 16,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Dots & Connecting Line
                              Column(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF22C55E),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Container(
                                    width: 2,
                                    height: 26,
                                    color: const Color(0xFFCBD5E1),
                                  ),
                                  const Icon(
                                    Icons.location_on_rounded,
                                    color: primaryOrange,
                                    size: 16,
                                  ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              // Locations Text
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pickupName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      destinationName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: textDark,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              // Edit Action Button
                              IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF0E6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.edit_outlined,
                                    color: primaryOrange,
                                    size: 18,
                                  ),
                                ),
                                onPressed: () => context.pop(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Vehicle Service Section ──────────────────────────────
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: primaryOrange, width: 1.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0F000000),
                                blurRadius: 18,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Scooter Graphic Container
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF0E6),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.two_wheeler_rounded,
                                        color: primaryOrange,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  // Title & Description
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Text(
                                              'Motorcycle Ride',
                                              style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                                color: textDark,
                                              ),
                                            ),
                                            SizedBox(width: 6),
                                            Icon(
                                              Icons.person_outline_rounded,
                                              size: 14,
                                              color: textMuted,
                                            ),
                                            Text(
                                              '1',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFF0E6),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'Operated by 7s',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: primaryOrange,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        const Text(
                                          'Fast, reliable motorcycle transport across Voi.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Checkmark badge
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                      color: primaryOrange,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(color: Color(0xFFF1F5F9), height: 1),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.schedule_rounded, size: 15, color: textMuted),
                                      SizedBox(width: 4),
                                      Text(
                                        '5–10 min ETA',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    formattedFare,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Bottom Payment & Booking Action Bar ──────────────────────────
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x0C000000),
                        blurRadius: 20,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Cash Selector Pill
                          InkWell(
                            onTap: _showPaymentMethodSelector,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _selectedPaymentMethod == 'M-Pesa' ? Icons.phone_android_rounded : Icons.payments_outlined,
                                    color: _selectedPaymentMethod == 'M-Pesa' ? const Color(0xFF3B82F6) : const Color(0xFF22C55E),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedPaymentMethod,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: textDark,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.keyboard_arrow_down_rounded, color: textMuted, size: 18),
                                ],
                              ),
                            ),
                          ),


                          // Total Fare Summary
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Total Fare',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: textMuted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formattedFare,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Confirm Booking CTA Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isBookingConfirmed ? null : _onConfirmBooking,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryOrange,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: primaryOrange.withValues(alpha: 0.6),
                            elevation: 4,
                            shadowColor: primaryOrange.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            _isBookingConfirmed ? 'Booking Confirmed ✓' : 'Confirm Booking',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
