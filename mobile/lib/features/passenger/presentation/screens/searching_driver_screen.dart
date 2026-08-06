import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/map_service.dart';
import '../providers/ride_state_notifier.dart';

/// 7s Mobile App — Searching Driver Screen
/// Features radar pulse searching animation, mini OpenStreetMap preview, internal status transitions,
/// and smooth navigation into Driver En Route once matched.
class SearchingDriverScreen extends StatefulWidget {
  const SearchingDriverScreen({super.key});

  @override
  State<SearchingDriverScreen> createState() => _SearchingDriverScreenState();
}

class _SearchingDriverScreenState extends State<SearchingDriverScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const primaryOrange = Color(0xFFFF7A1A);
  static const bgLight = Color(0xFFF8FAFC);
  static const textDark = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rideNotifier = context.watch<RideStateNotifier>();
    final activeBooking = rideNotifier.activeBooking;

    final status = rideNotifier.currentStatus;
    final isNoDriver = status == RideLifecycleStatus.noDriverFound;
    final isMatched = status == RideLifecycleStatus.matched ||
        status == RideLifecycleStatus.accepted ||
        status == RideLifecycleStatus.arriving;

    // Trigger navigation to Driver En Route Screen when matched/accepted/arriving
    if (isMatched) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/passenger/driver-en-route');
      });
    }

    final pickupPoint = activeBooking?.pickupLatLng ?? const LatLng(-3.3967, 38.5562);
    final destPoint = activeBooking?.destinationLatLng ?? const LatLng(-3.3980, 38.5580);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: textDark),
          onPressed: () {
            rideNotifier.cancelRide();
            context.pop();
          },
        ),
        title: const Text(
          'Searching Driver',
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Mini OpenStreetMap Route Preview ─────────────────────
            SizedBox(
              height: 220,
              width: double.infinity,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: pickupPoint,
                  initialZoom: 14.5,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  MapService.buildOpenStreetMapTileLayer(),
                  MapService.buildRoutePolyline([pickupPoint, destPoint]),
                  MarkerLayer(
                    markers: [
                      MapService.buildPickupMarker(pickupPoint),
                      MapService.buildDestinationMarker(destPoint),
                    ],
                  ),
                ],
              ),
            ),

            // ── Main Searching Content Body ──────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),

                    if (!isNoDriver) ...[
                      // Animated Radar Pulse Sweep Container
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Pulse Wave Outer Circle
                              Container(
                                width: 140 * _pulseAnimation.value,
                                height: 140 * _pulseAnimation.value,
                                decoration: BoxDecoration(
                                  color: primaryOrange.withValues(alpha: 0.15 / _pulseAnimation.value),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              // Pulse Wave Inner Circle
                              Container(
                                width: 110 * _pulseAnimation.value,
                                height: 110 * _pulseAnimation.value,
                                decoration: BoxDecoration(
                                  color: primaryOrange.withValues(alpha: 0.25 / _pulseAnimation.value),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              // Center Scooter Icon Badge
                              Container(
                                width: 76,
                                height: 76,
                                decoration: const BoxDecoration(
                                  color: primaryOrange,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x33FF7A1A),
                                      blurRadius: 16,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.two_wheeler_rounded,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 28),

                      // Internal Status Update Text
                      Text(
                        status == RideLifecycleStatus.matching
                            ? 'Searching nearby riders...'
                            : status == RideLifecycleStatus.matched
                                ? 'Driver Found!'
                                : 'Connecting to Driver...',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        status == RideLifecycleStatus.matching
                            ? 'Finding the closest available motorcycle in Voi Town'
                            : 'Francis accepted your ride request. Loading route...',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: textMuted,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Estimated Wait Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF5ED),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFFE3D1)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time_rounded, color: primaryOrange, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Estimated wait: 2–3 minutes',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: primaryOrange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // 30-Second Timeout / No Driver Found State
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFEE2E2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.two_wheeler_rounded, color: Color(0xFFEF4444), size: 48),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'No Riders Available Right Now',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        activeBooking?.eventLogs.lastOrNull?.note ??
                            'All riders in Voi Town are currently busy. Please try again in a few moments.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: textMuted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.pop();
                          },
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                          label: const Text('Try Again / Change Location', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryOrange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Bottom Information Card ──────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(color: Color(0x0C000000), blurRadius: 16, offset: Offset(0, -4)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: primaryOrange, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Searching within Voi Town • ${activeBooking?.pickupName ?? 'Current Location'}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () {
                        rideNotifier.cancelRide();
                        context.pop();
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFEE2E2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        'Cancel Request',
                        style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
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
  }
}
