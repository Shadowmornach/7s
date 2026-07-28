import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_typography.dart';
import '../providers/operations_provider.dart';

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
      appBar: AppBar(
        title: const Text('7s Operations Center'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<OperationsNotifier>().loadDashboard(),
          ),
        ],
      ),
      body: ops.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ops.errorMessage != null && ops.summary == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('No connection', style: AppTypography.headline.copyWith(color: Colors.grey.shade600)),
                        const SizedBox(height: 8),
                        const Text(
                          'Dashboard data unavailable. Check your connection and retry.',
                          textAlign: TextAlign.center,
                          style: AppTypography.body,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          onPressed: () => context.read<OperationsNotifier>().loadDashboard(),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ops.errorMessage != null)
                    _StaleDataBanner(
                      onRetry: () => context.read<OperationsNotifier>().loadDashboard(),
                    ),
                  const Text('Real-Time Fleet & Dispatch Metrics', style: AppTypography.headline),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          title: 'Active Rides',
                          value: '${summary?.activeRidesCount ?? 0}',
                          icon: Icons.directions_car,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          title: 'SOS Alerts',
                          value: '${summary?.activeSosAlertsCount ?? 0}',
                          icon: Icons.warning_amber_rounded,
                          color: summary?.activeSosAlertsCount != 0 ? Colors.red : AppColors.secondary,
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
                          icon: Icons.account_balance_wallet,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          title: 'Cash Handovers',
                          value: '${summary?.pendingCashHandovers ?? 0}',
                          icon: Icons.payments,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('System Health & Safety Status', style: AppTypography.headline),
                  const SizedBox(height: 8),
                  Card(
                    color: AppColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (summary?.activeSystemAlerts.isEmpty ?? true)
                            const Text('âœ“ All network gateways and telemetry services nominal.', style: AppTypography.body)
                          else
                            ...?summary?.activeSystemAlerts.map(
                              (alert) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(alert, style: AppTypography.body)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Pending Cash Reconciliations', style: AppTypography.headline),
                  const SizedBox(height: 8),
                  if (ops.handovers.isEmpty)
                    const Text('No pending cash handovers.')
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: ops.handovers.length,
                      itemBuilder: (context, index) {
                        final item = ops.handovers[index];
                        final isBalanced = item.isBalanced;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              isBalanced ? Icons.check_circle : Icons.warning,
                              color: isBalanced ? Colors.green : Colors.orange,
                            ),
                            title: Text(item.riderName, style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
                            subtitle: Text('Expected: KES ${item.expectedCash} | Actual: KES ${item.actualCash}'),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isBalanced ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.status,
                                style: TextStyle(
                                  color: isBalanced ? Colors.green : Colors.orange.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTypography.caption),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: AppTypography.headline.copyWith(fontSize: 22, color: color)),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade900,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '⚡ No connection — showing last known data',
              style: TextStyle(color: Colors.white, fontSize: 12),
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
