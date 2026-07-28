import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile/features/operations/domain/models/operations_dashboard.dart';
import 'package:mobile/features/operations/domain/repositories/operations_repository.dart';
import 'package:mobile/features/operations/presentation/providers/operations_provider.dart';
import 'package:mobile/features/operations/presentation/screens/operations_center_screen.dart';

class MockOperationsRepository implements OperationsRepository {
  @override
  Future<OperationsSummary> getDashboardSummary() async {
    return const OperationsSummary(
      activeRidesCount: 25,
      activeSosAlertsCount: 1,
      totalRevenueToday: 95000.0,
      pendingCashHandovers: 3,
      activeSystemAlerts: ['Database connected', 'Telemetry active'],
    );
  }

  @override
  Future<List<CashHandoverItem>> getCashHandoverReports() async {
    return const [
      CashHandoverItem(
        handoverId: 'ch-test-1',
        riderName: 'Samuel Njuguna',
        expectedCash: 5000.0,
        actualCash: 5000.0,
        status: 'BALANCED',
      ),
    ];
  }

  @override
  Future<void> submitCashHandover({
    required String riderId,
    required double expectedCash,
    required double actualCash,
    String? notes,
  }) async {}
}

void main() {
  group('OperationsCenter Flutter Tests', () {
    late MockOperationsRepository repo;

    setUp(() {
      repo = MockOperationsRepository();
    });

    test('OperationsNotifier loads dashboard metrics and handovers', () async {
      final notifier = OperationsNotifier(repository: repo);
      expect(notifier.summary, isNull);

      await notifier.loadDashboard();

      expect(notifier.summary, isNotNull);
      expect(notifier.summary!.activeRidesCount, equals(25));
      expect(notifier.summary!.activeSosAlertsCount, equals(1));
      expect(notifier.handovers.length, equals(1));
      expect(notifier.handovers.first.riderName, equals('Samuel Njuguna'));
    });

    testWidgets('OperationsCenterScreen renders metrics and cash handover UI', (WidgetTester tester) async {
      final notifier = OperationsNotifier(repository: repo);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<OperationsNotifier>.value(
            value: notifier,
            child: const OperationsCenterScreen(),
          ),
        ),
      );

      // Trigger frame & postFrameCallback loading
      await tester.pumpAndSettle();

      expect(find.text('7s Operations Center'), findsOneWidget);
      expect(find.text('Real-Time Fleet & Dispatch Metrics'), findsOneWidget);
      expect(find.text('Active Rides'), findsOneWidget);
      expect(find.text('25'), findsOneWidget);
      expect(find.text('SOS Alerts'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Samuel Njuguna'), findsOneWidget);
      expect(find.text('BALANCED'), findsOneWidget);
    });
  });
}
