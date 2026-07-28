import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/passenger_provider.dart';
import '../../../safety/presentation/providers/safety_provider.dart';
import '../../../../core/widgets/sos_button_shell.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_typography.dart';

class PassengerHomeScreen extends StatelessWidget {
  const PassengerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('7s Passenger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => context.push('/help-center'),
          ),
        ],
      ),
      body: Consumer<PassengerNotifier>(
        builder: (context, passenger, child) {
          return Stack(
            children: [
              // Simulated Map Background
              Container(
                color: Colors.blueGrey.shade100,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map_rounded, size: 80, color: Colors.blueGrey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'Interactive Map Active',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),

              // Top Search Card (Browsing State)
              if (passenger.tripState == PassengerTripState.browsing)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      onTap: () => context.push('/passenger/search'),
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Icon(Icons.search_rounded, color: AppColors.accent),
                            SizedBox(width: 12),
                            Text(
                              'Where to?',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Bottom Sheet — Fare Quote & Payment Selection
              if (passenger.tripState == PassengerTripState.selectingPayment && passenger.currentQuote != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('7s Standard', style: AppTypography.headline),
                            Text(
                              passenger.currentQuote!.formattedFare,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ETA ${passenger.currentQuote!.etaMinutes} mins • Upfront Quote',
                          style: AppTypography.caption,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ChoiceChip(
                              label: const Text('M-Pesa STK'),
                              selected: passenger.selectedPaymentMethodId == 'mpesa',
                              onSelected: (_) => passenger.selectPaymentMethod('mpesa'),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Cash'),
                              selected: passenger.selectedPaymentMethodId == 'cash',
                              onSelected: (_) => passenger.selectPaymentMethod('cash'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => passenger.requestRide(),
                            child: const Text('CONFIRM RIDE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Driver Assigned / Live Tracking Sheet
              if (passenger.tripState == PassengerTripState.driverAssigned)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Row(
                          children: [
                            CircleAvatar(radius: 24, child: Icon(Icons.person)),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Driver Assigned: Joseph M.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text('Toyota Fielder • KCA 123X', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                            Icon(Icons.star, color: Colors.amber),
                            Text('4.9'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Trip share link copied!')),
                                  );
                                },
                                icon: const Icon(Icons.share),
                                label: const Text('SHARE RIDE'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SosButtonShell(
                              onPressed: () => _showSosDialog(
                                context,
                                passenger.activeRideId ?? 'ride-99',
                                1,
                              ),
                            ),
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
  void _showSosDialog(BuildContext context, String rideId, int version) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        String selectedType = 'Medical';
        String selectedSeverity = 'CRITICAL';
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Confirm Emergency SOS',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Emergency Type:'),
                  DropdownButton<String>(
                    value: selectedType,
                    isExpanded: true,
                    onChanged: (val) {
                      if (val != null) setState(() => selectedType = val);
                    },
                    items: const [
                      DropdownMenuItem(value: 'Robbery', child: Text('Robbery')),
                      DropdownMenuItem(value: 'Medical', child: Text('Medical')),
                      DropdownMenuItem(value: 'Accident', child: Text('Accident')),
                      DropdownMenuItem(value: 'Harassment', child: Text('Harassment')),
                      DropdownMenuItem(value: 'Vehicle Breakdown', child: Text('Vehicle Breakdown')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Severity:'),
                  DropdownButton<String>(
                    value: selectedSeverity,
                    isExpanded: true,
                    onChanged: (val) {
                      if (val != null) setState(() => selectedSeverity = val);
                    },
                    items: const [
                      DropdownMenuItem(value: 'CRITICAL', child: Text('CRITICAL')),
                      DropdownMenuItem(value: 'HIGH', child: Text('HIGH')),
                      DropdownMenuItem(value: 'MEDIUM', child: Text('MEDIUM')),
                      DropdownMenuItem(value: 'LOW', child: Text('LOW')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade900,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        await ctx.read<SafetyNotifier>().triggerSos(
                          rideId: rideId,
                          expectedVersion: version,
                          emergencyType: selectedType,
                          severity: selectedSeverity,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('EMERGENCY SOS TRIGGERED: $selectedType ($selectedSeverity)'),
                              backgroundColor: Colors.red.shade900,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to trigger SOS: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('CONFIRM EMERGENCY SOS', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
