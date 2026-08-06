import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_typography.dart';
import '../providers/operations_provider.dart';

/// Redesigned Operations Center Dashboard with fleet metrics,
/// cash reconciliation tiles, and system health status.
class OperationsCenterScreen extends StatefulWidget {
  const OperationsCenterScreen({super.key});

  @override
  State<OperationsCenterScreen> createState() => _OperationsCenterScreenState();
}

class _OperationsCenterScreenState extends State<OperationsCenterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OperationsNotifier>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ops = context.watch<OperationsNotifier>();
    final summary = ops.summary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('7s Operations Center'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<OperationsNotifier>().loadDashboard(),
          ),
        ],
      ),
      body: ops.isLoading
          ? const LoadingIndicator(message: 'Loading operations dashboard...')
          : ops.errorMessage != null && ops.summary == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off_rounded, size: 64, color: AppColors.textMuted),
                        const SizedBox(height: 16),
                        Text('No connection', style: AppTypography.headlineMedium.copyWith(color: AppColors.textMuted)),
                        const SizedBox(height: 8),
                        Text(
                          'Dashboard data unavailable. Check your connection and retry.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        AppButton(
                          fullWidth: false,
                          icon: Icons.refresh_rounded,
                          text: 'Retry',
                          onPressed: () => context.read<OperationsNotifier>().loadDashboard(),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ops.errorMessage != null)
                        _StaleDataBanner(
                          onRetry: () => context.read<OperationsNotifier>().loadDashboard(),
                        ),
                      Text('Real-Time Fleet & Dispatch Metrics', style: AppTypography.displayLarge.copyWith(fontSize: 22)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              title: 'Active Rides',
                              value: '${summary?.activeRidesCount ?? 0}',
                              icon: Icons.directions_car_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricCard(
                              title: 'SOS Alerts',
                              value: '${summary?.activeSosAlertsCount ?? 0}',
                              icon: Icons.warning_amber_rounded,
                              color: summary?.activeSosAlertsCount != 0 ? AppColors.alert : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              title: 'Daily Revenue',
                              value: 'KES ${summary?.totalRevenueToday.toStringAsFixed(0) ?? '0'}',
                              icon: Icons.account_balance_wallet_rounded,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricCard(
                              title: 'Cash Handovers',
                              value: '${summary?.pendingCashHandovers ?? 0}',
                              icon: Icons.payments_rounded,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text('System Health & Safety Status', style: AppTypography.displayLarge.copyWith(fontSize: 22)),
                      const SizedBox(height: 12),
                      AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (summary?.activeSystemAlerts.isEmpty ?? true)
                              Text('✓ All network gateways and telemetry services nominal.', style: AppTypography.bodyMedium)
                            else
                              ...?summary?.activeSystemAlerts.map(
                                (alert) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text(alert, style: AppTypography.bodyMedium)),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text('Pending Cash Reconciliations', style: AppTypography.displayLarge.copyWith(fontSize: 22)),
                      const SizedBox(height: 12),
                      if (ops.handovers.isEmpty)
                        Text('No pending cash handovers.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted))
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: ops.handovers.length,
                          itemBuilder: (context, index) {
                            final item = ops.handovers[index];
                            final isBalanced = item.isBalanced;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: AppCard(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: (isBalanced ? AppColors.success : AppColors.warning).withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isBalanced ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                                        color: isBalanced ? AppColors.success : AppColors.warning,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.riderName, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Expected: KES ${item.expectedCash} | Actual: KES ${item.actualCash}',
                                            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    AppChip(
                                      label: item.status,
                                      isSelected: true,
                                      color: isBalanced ? AppColors.success : AppColors.warning,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTypography.labelMedium.copyWith(color: AppColors.textMuted)),
              Icon(icon, color: color, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTypography.displayLarge.copyWith(
              fontSize: 22,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StaleDataBanner extends StatelessWidget {
  final VoidCallback onRetry;

  const _StaleDataBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              '⚡ No connection — showing last known data',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
