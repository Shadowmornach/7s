import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/map_service.dart';
import '../providers/ride_state_notifier.dart';

/// 7s Mobile App — Driver En Route & Interactive Ride Tracking Screen
/// Interactive OpenStreetMap with live moving driver marker, dynamic ETA, and driver detail bottom sheet.
class DriverEnRouteScreen extends StatefulWidget {
  const DriverEnRouteScreen({super.key});

  @override
  State<DriverEnRouteScreen> createState() => _DriverEnRouteScreenState();
}

class _DriverEnRouteScreenState extends State<DriverEnRouteScreen> {
  final MapController _mapController = MapController();

  static const primaryOrange = Color(0xFFFF7A1A);
  static const bgLight = Color(0xFFF8FAFC);
  static const textDark = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final rideNotifier = context.watch<RideStateNotifier>();
    final booking = rideNotifier.activeBooking;

    final status = rideNotifier.currentStatus;
    final driver = booking?.assignedDriver;

    final pickupPoint = booking?.pickupLatLng ?? const LatLng(-3.3967, 38.5562);
    final destPoint = booking?.destinationLatLng ?? const LatLng(-3.3980, 38.5580);
    final driverPos = booking?.driverPosition ?? pickupPoint;

    // Trigger navigation to Ride Completed Screen when finished
    if (status == RideLifecycleStatus.completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/passenger/ride-completed');
      });
    }

    final isArrived = status == RideLifecycleStatus.arrived;
    final isInProgress = status == RideLifecycleStatus.inProgress || status == RideLifecycleStatus.passengerOnboard;

    final statusText = isInProgress
        ? 'Ride In Progress'
        : isArrived
            ? 'Driver Has Arrived!'
            : 'Driver En Route';

    final statusSubtitle = isInProgress
        ? 'Heading to ${booking?.destinationName}'
        : isArrived
            ? 'Francis is waiting at pickup location'
            : 'Estimated Arrival: ${booking?.etaMinutes ?? 2} mins';

    return Scaffold(
      backgroundColor: bgLight,
      body: Stack(
        children: [
          // ── 1. Full-Screen OpenStreetMap ───────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: driverPos,
              initialZoom: 15.0,
            ),
            children: [
              MapService.buildOpenStreetMapTileLayer(),
              MapService.buildRoutePolyline([driverPos, isInProgress ? destPoint : pickupPoint]),
              MarkerLayer(
                markers: [
                  MapService.buildPickupMarker(pickupPoint),
                  MapService.buildDestinationMarker(destPoint),
                  MapService.buildDriverMarker(driverPos),
                ],
              ),
            ],
          ),

          // ── 2. Top Floating Ride Status Header ──────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4)),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isInProgress
                            ? const Color(0xFFDCFCE7)
                            : isArrived
                                ? const Color(0xFFFEF3C7)
                                : const Color(0xFFFFF0E6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isInProgress
                            ? Icons.navigation_rounded
                            : isArrived
                                ? Icons.pin_drop_rounded
                                : Icons.two_wheeler_rounded,
                        color: isInProgress
                            ? const Color(0xFF10B981)
                            : isArrived
                                ? const Color(0xFFF59E0B)
                                : primaryOrange,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            statusText,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            statusSubtitle,
                            style: const TextStyle(fontSize: 12, color: textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${booking?.distanceRemainingKm.toStringAsFixed(1) ?? '1.2'} km',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── 3. Bottom Sheet with Driver Details & Actions ───────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, -6)),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Driver Profile & Vehicle Info Row
                    Row(
                      children: [
                        // Driver Avatar Circle
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFFF9548), Color(0xFFFF6B00)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              'F',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Name & Rating
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driver?.fullName ?? 'Francis (Owner / Rider)',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${driver?.rating ?? 4.9} • (${driver?.totalTrips ?? 1420} trips)',
                                    style: const TextStyle(fontSize: 12, color: textMuted),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Vehicle License Plate Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF5ED),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFE3D1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                driver?.vehiclePlate ?? 'KMCR 777S',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: primaryOrange,
                                ),
                              ),
                              Text(
                                driver?.vehicleModel ?? 'Toyota Premio',
                                style: const TextStyle(fontSize: 10, color: textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                    ),

                    // Fare & Route Summary Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Fare Price', style: TextStyle(fontSize: 11, color: textMuted)),
                            const SizedBox(height: 2),
                            Text(
                              booking?.fareAmount ?? 'KSh 150',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: primaryOrange,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Payment Method', style: TextStyle(fontSize: 11, color: textMuted)),
                            const SizedBox(height: 2),
                            Text(
                              booking?.paymentMethod ?? 'Cash on Arrival',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Call, Message & Cancel Action Buttons
                    Row(
                      children: [
                        // Call Button
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Calling Francis (${driver?.phone ?? '+254712345678'})...'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.call_rounded, color: Colors.white, size: 18),
                              label: const Text('Call Rider', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF22C55E),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Message Button
                        Container(
                          height: 46,
                          width: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.chat_bubble_outline_rounded, color: textDark, size: 20),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Opening chat with Francis...'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Cancel Button
                        Container(
                          height: 46,
                          width: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 20),
                            onPressed: () {
                              rideNotifier.cancelRide();
                              context.go('/passenger/home');
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
