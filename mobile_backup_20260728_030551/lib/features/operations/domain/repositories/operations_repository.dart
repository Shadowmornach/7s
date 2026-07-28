import '../models/operations_dashboard.dart';

abstract class OperationsRepository {
  Future<OperationsSummary> getDashboardSummary();
  Future<List<CashHandoverItem>> getCashHandoverReports();
  Future<void> submitCashHandover({
    required String riderId,
    required double expectedCash,
    required double actualCash,
    String? notes,
  });
}
