import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/rider_provider.dart';
import '../../domain/models/dispatch_offer.dart';
import '../../domain/models/driver_trip.dart';
import '../../../passenger/presentation/providers/fare_templates_provider.dart';
import '../../../../core/widgets/sos_button_shell.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_typography.dart';

/// Redesigned Rider / Driver Console with interactive telemetry map view,
/// online status toggle badge, dispatch request overlay card, and trip step controller.
class RiderHomeScreen extends StatelessWidget {
  const RiderHomeScreen({super.key});

  void _showFareTemplatesModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Consumer<FareTemplatesNotifier>(
        builder: (ctx, fareNotifier, child) {
          final templates = fareNotifier.templates;
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Voi Fare Templates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Update standard fixed prices for Voi Town routes:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: templates.length,
                    separatorBuilder: (c, i) => const Divider(height: 1),
                    itemBuilder: (c, i) {
                      final item = templates[i];
                      final controller = TextEditingController(text: item.fare.toStringAsFixed(0));
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.routeTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text('${item.estimatedDistanceKm} km • KSh ${item.fare.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11)),
                        trailing: SizedBox(
                          width: 90,
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: controller,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    prefixText: 'KSh ',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.check_circle_rounded, color: Color(0xFFFF7A1A), size: 20),
                                onPressed: () {
                                  final newPrice = double.tryParse(controller.text.trim());
                                  if (newPrice != null && newPrice > 0) {
                                    fareNotifier.updateTemplateFare(item.id, newPrice);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${item.routeTitle} updated to KSh ${newPrice.toStringAsFixed(0)}'),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('7s Rider Console'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.sell_outlined),
            onPressed: () => _showFareTemplatesModal(context),
            tooltip: 'Voi Fare Templates',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => context.push('/help-center'),
            tooltip: 'Help',
          ),
        ],
      ),
      body: Consumer<RiderNotifier>(
        builder: (context, rider, child) {
          return Stack(
            children: [
              // Simulated Vector Map Background
              Container(
                color: rider.isOnline
                    ? const Color(0xFFECFDF5)
                    : const Color(0xFFF1F5F9),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          rider.isOnline
                              ? Icons.two_wheeler_rounded
                              : Icons.two_wheeler_outlined,
                          size: 64,
                          color: rider.isOnline
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        rider.isOnline
                            ? 'ONLINE & WAITING FOR DISPATCH'
                            : 'OFFLINE',
                        style: AppTypography.displayLarge.copyWith(
                          fontSize: 16,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        rider.isOnline
                            ? 'GPS Location Active in Voi Town Service Zone'
                            : 'Go online to receive nearby ride offers in Voi',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ),

              // Rider Top Status Bar overlay
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: rider.isOnline ? AppColors.success : AppColors.textSecondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            rider.isOnline ? 'Online (Voi Town)' : 'Offline',
                            style: AppTypography.titleMedium,
                          ),
                        ],
                      ),
                      Switch.adaptive(
                        value: rider.isOnline,
                        onChanged: (val) => rider.toggleOnline(),
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),

              // Demo Trigger Button (Simulate Incoming Offer)
              if (rider.isOnline && rider.activeOffer == null && rider.activeTrip == null)
                Positioned(
                  top: 90,
                  right: 16,
                  child: FloatingActionButton.extended(
                    heroTag: 'simulate_offer_btn',
                    backgroundColor: AppColors.primary,
                    icon: const Icon(Icons.bolt_rounded, color: Colors.white),
                    label: const Text('Test Offer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      rider.simulateIncomingOffer(
                        DispatchOffer(
                          offerId: 'off-1',
                          rideId: 'ride-99',
                          pickupAddress: 'Voi Town Center / Market',
                          destinationAddress: 'Voi SGR Railway Station',
                          pickupLat: -3.3967,
                          pickupLng: 38.5562,
                          fare: 150.0,
                          currency: 'KES',
                          expiresAt: DateTime.now().toUtc().add(const Duration(seconds: 15)),
                        ),
                      );
                    },
                  ),
                ),

              // Dispatch Offer Card
              if (rider.activeOffer != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AppBottomSheet(
                    showHandle: true,
                    isGlassmorphic: true,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const AppChip(
                              label: 'INCOMING OFFER',
                              icon: Icons.bolt_rounded,
                              isSelected: true,
                            ),
                            Text(
                              rider.activeOffer!.formattedFare,
                              style: AppTypography.displayLarge.copyWith(
                                fontSize: 24,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        AppCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.circle, color: AppColors.primary, size: 12),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Pickup: ${rider.activeOffer!.pickupAddress}',
                                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              Row(
                                children: [
                                  const Icon(Icons.square, color: AppColors.alert, size: 12),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Dropoff: ${rider.activeOffer!.destinationAddress}',
                                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                text: 'DECLINE',
                                variant: AppButtonVariant.secondary,
                                onPressed: () => rider.declineOffer(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppButton(
                                text: 'ACCEPT RIDE',
                                onPressed: () => rider.acceptOffer(),
                                icon: Icons.check_circle_rounded,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // Active Trip Control Sheet
              if (rider.activeTrip != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AppBottomSheet(
                    showHandle: true,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AppChip(
                              label: 'STATUS: ${rider.activeTrip!.status.name.toUpperCase()}',
                              isSelected: true,
                            ),
                            Text(
                              rider.activeTrip!.formattedFare,
                              style: AppTypography.displayLarge.copyWith(
                                fontSize: 24,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                text: _getNextButtonText(rider.activeTrip!.status),
                                icon: Icons.navigation_rounded,
                                onPressed: () => rider.advanceTripState(),
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
