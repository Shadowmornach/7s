import 'package:flutter/foundation.dart';
import '../../domain/models/operations_dashboard.dart';
import '../../domain/repositories/operations_repository.dart';

class OperationsNotifier extends ChangeNotifier {
  final OperationsRepository _repository;

  OperationsSummary? _summary;
  List<CashHandoverItem> _handovers = [];
  bool _isLoading = false;
  String? _errorMessage;

  OperationsNotifier({required OperationsRepository repository}) : _repository = repository;

  OperationsSummary? get summary => _summary;
  List<CashHandoverItem> get handovers => _handovers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final summaryRes = await _repository.getDashboardSummary();
      final handoversRes = await _repository.getCashHandoverReports();
      _summary = summaryRes;
      _handovers = handoversRes;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reconcileCashHandover({
    required String riderId,
    required double expectedCash,
    required double actualCash,
    String? notes,
  }) async {
    await _repository.submitCashHandover(
      riderId: riderId,
      expectedCash: expectedCash,
      actualCash: actualCash,
      notes: notes,
    );
    await loadDashboard();
  }
}
