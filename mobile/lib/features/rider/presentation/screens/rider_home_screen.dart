import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/rider_provider.dart';
import '../../domain/models/dispatch_offer.dart';
import '../../domain/models/driver_trip.dart';
import '../../../../core/widgets/sos_button_shell.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_typography.dart';

class RiderHomeScreen extends StatelessWidget {
  const RiderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('7s Rider Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => context.push('/help-center'),
          ),
        ],
      ),
      body: Consumer<RiderNotifier>(
        builder: (context, rider, child) {
          return Stack(
            children: [
              // Simulated Driver Map
              Container(
                color: rider.isOnline ? Colors.green.shade50 : Colors.grey.shade200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        rider.isOnline ? Icons.navigation_rounded : Icons.power_settings_new_rounded,
                        size: 80,
                        color: rider.isOnline ? AppColors.accent : Colors.grey,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        rider.isOnline ? 'ONLINE — Searching for nearby rides...' : 'OFFLINE — Go online to receive dispatch offers',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: rider.isOnline ? Colors.red : AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        onPressed: () => rider.toggleOnline(),
                        icon: Icon(rider.isOnline ? Icons.stop : Icons.play_arrow),
                        label: Text(rider.isOnline ? 'GO OFFLINE' : 'GO ONLINE'),
                      ),
                    ],
                  ),
                ),
              ),

              // Test Offer Trigger (For Demo / Integration Testing)
              if (rider.isOnline && rider.activeOffer == null && rider.activeTrip == null)
                Positioned(
                  top: 16,
                  right: 16,
                  child: FloatingActionButton.extended(
                    label: const Text('Simulate Offer'),
                    icon: const Icon(Icons.flash_on),
                    onPressed: () {
                      rider.simulateIncomingOffer(
                        DispatchOffer(
                          offerId: 'off-1',
                          rideId: 'ride-99',
                          pickupAddress: 'Kenyatta Avenue, CBD',
                          destinationAddress: 'Waiyaki Way, Westlands',
                          pickupLat: -1.2863,
                          pickupLng: 36.8172,
                          fare: 420.0,
                          currency: 'KES',
                          expiresAt: DateTime.now().toUtc().add(const Duration(seconds: 15)),
                        ),
                      );
                    },
                  ),
                ),

              // Dispatch Offer Card (15s Window — OA-03)
              if (rider.activeOffer != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12)],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('DISPATCH OFFER', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent)),
                            Text(rider.activeOffer!.formattedFare, style: AppTypography.headline),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Pickup: ${rider.activeOffer!.pickupAddress}', style: AppTypography.caption),
                        Text('Dropoff: ${rider.activeOffer!.destinationAddress}', style: AppTypography.caption),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => rider.declineOffer(),
                                child: const Text('DECLINE'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => rider.acceptOffer(),
                                child: const Text('ACCEPT RIDE'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // Active Trip Sheet
              if (rider.activeTrip != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12)],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Status: ${rider.activeTrip!.status.name.toUpperCase()}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                            Text(rider.activeTrip!.formattedFare, style: AppTypography.headline),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => rider.advanceTripState(),
                                child: Text(_getNextButtonText(rider.activeTrip!.status)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const SosButtonShell(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _getNextButtonText(DriverTripStatus status) {
    switch (status) {
      case DriverTripStatus.accepted:
        return 'START NAVIGATION';
      case DriverTripStatus.navigatingToPickup:
        return 'ARRIVED AT PICKUP';
      case DriverTripStatus.arrivedAtPickup:
        return 'START TRIP';
      case DriverTripStatus.inProgress:
        return 'COMPLETE RIDE';
      case DriverTripStatus.completed:
        return 'DONE';
    }
  }
}
