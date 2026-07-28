import 'dart:convert';
import 'package:logging/logging.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/operations_dashboard.dart';
import '../../domain/repositories/operations_repository.dart';

final _logger = Logger('OperationsRepositoryImpl');

class OperationsRepositoryImpl implements OperationsRepository {
  final ApiClient _apiClient;

  OperationsRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<OperationsSummary> getDashboardSummary() async {
    try {
      final res = await _apiClient.get('/operations/dashboard');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return OperationsSummary(
          activeRidesCount: data['active_rides'] as int? ?? 0,
          activeSosAlertsCount: data['active_sos_alerts'] as int? ?? 0,
          totalRevenueToday: (data['total_revenue_today'] as num?)?.toDouble() ?? 0.0,
          pendingCashHandovers: data['pending_cash_handovers'] as int? ?? 0,
          activeSystemAlerts: (data['system_alerts'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        );
      }
      throw Exception('Operations dashboard returned status ${res.statusCode}');
    } catch (e) {
      _logger.warning('Failed to fetch operations dashboard: $e');
      rethrow;
    }
  }

  @override
  Future<List<CashHandoverItem>> getCashHandoverReports() async {
    try {
      final res = await _apiClient.get('/operations/reports/cash-handovers');
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list.map((item) {
          final map = item as Map<String, dynamic>;
          return CashHandoverItem(
            handoverId: map['id'] as String? ?? 'ch-1',
            riderName: map['rider_name'] as String? ?? 'Unknown',
            expectedCash: (map['expected_cash'] as num?)?.toDouble() ?? 0.0,
            actualCash: (map['actual_cash'] as num?)?.toDouble() ?? 0.0,
            status: map['status'] as String? ?? 'UNKNOWN',
          );
        }).toList();
      }
      throw Exception('Cash handover reports returned status ${res.statusCode}');
    } catch (e) {
      _logger.warning('Failed to fetch cash handovers: $e');
      rethrow;
    }
  }

  @override
  Future<void> submitCashHandover({
    required String riderId,
    required double expectedCash,
    required double actualCash,
    String? notes,
  }) async {
    await _apiClient.post(
      '/operations/cash-handovers',
      body: jsonEncode({
        'rider_id': riderId,
        'expected_cash': expectedCash,
        'actual_cash': actualCash,
        if (notes != null) 'notes': notes,
      }),
    );
  }
}
