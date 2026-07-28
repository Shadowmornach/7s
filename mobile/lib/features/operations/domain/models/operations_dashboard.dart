class OperationsSummary {
  final int activeRidesCount;
  final int activeSosAlertsCount;
  final double totalRevenueToday;
  final int pendingCashHandovers;
  final List<String> activeSystemAlerts;

  const OperationsSummary({
    required this.activeRidesCount,
    required this.activeSosAlertsCount,
    required this.totalRevenueToday,
    required this.pendingCashHandovers,
    required this.activeSystemAlerts,
  });
}

class CashHandoverItem {
  final String handoverId;
  final String riderName;
  final double expectedCash;
  final double actualCash;
  final String status; // BALANCED, SHORTFALL, OVERAGE

  bool get isBalanced => status == 'BALANCED';

  const CashHandoverItem({
    required this.handoverId,
    required this.riderName,
    required this.expectedCash,
    required this.actualCash,
    required this.status,
  });
}
