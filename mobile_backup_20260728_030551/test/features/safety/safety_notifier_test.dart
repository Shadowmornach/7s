import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/connectivity/connectivity_service.dart';
import 'package:mobile/features/safety/domain/models/safety_alert.dart';
import 'package:mobile/features/safety/domain/models/emergency_contact.dart';
import 'package:mobile/features/safety/domain/repositories/safety_repository.dart';
import 'package:mobile/features/safety/presentation/providers/safety_provider.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockSafetyRepository implements SafetyRepository {
  SafetyAlert? _pendingOfflineSos;

  @override
  Future<SafetyAlert> triggerSosAlert({
    required String rideId,
    required int expectedVersion,
    required double latitude,
    required double longitude,
    required String emergencyType,
    required String severity,
  }) async {
    return SafetyAlert(
      alertId: 'sos-mock-1',
      rideId: rideId,
      type: SafetyAlertType.sos,
      status: 'dispatched',
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now().toUtc(),
    );
  }

  @override
  Future<SafetyAlert?> retryPendingSos() async => _pendingOfflineSos;

  /// Test helper: simulate a queued offline SOS in storage.
  void simulateQueuedSos(SafetyAlert alert) => _pendingOfflineSos = alert;

  @override
  Future<String> getShareableTripLink(String rideId) async =>
      'https://7s.co.ke/share/test-link';

  @override
  Future<List<EmergencyContact>> getEmergencyContacts() async => const [
        EmergencyContact(
          contactId: 'ec-1',
          name: 'Mary Wanjiku',
          phoneNumber: '+254722001122',
          relationship: 'Mother',
        ),
      ];

  @override
  Future<void> addEmergencyContact(EmergencyContact contact) async {}
}

/// Minimal ConnectivityService stub — starts offline so _init() does not
/// trigger a spurious retryPendingSos() call during normal test setup.
class MockConnectivityService implements ConnectivityService {
  final StreamController<ConnectivityStatus> _controller =
      StreamController<ConnectivityStatus>.broadcast();

  ConnectivityStatus _status = ConnectivityStatus.offline;

  @override
  Future<ConnectivityStatus> checkConnectivity() async => _status;

  @override
  Stream<ConnectivityStatus> get onConnectivityChanged => _controller.stream;

  @override
  bool get isBackendReachable => _status == ConnectivityStatus.online;

  void goOnline() {
    _status = ConnectivityStatus.online;
    _controller.add(_status);
  }

  void dispose() => _controller.close();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('SafetyNotifier Unit Tests', () {
    late MockSafetyRepository repo;
    late MockConnectivityService connectivity;

    setUp(() {
      repo = MockSafetyRepository();
      connectivity = MockConnectivityService();
    });

    tearDown(() => connectivity.dispose());

    test('triggerSos dispatches emergency alert with dynamic device GPS location', () async {
      final notifier = SafetyNotifier(
        repository: repo,
        connectivityService: connectivity,
      );

      expect(notifier.activeAlert, isNull);

      await notifier.triggerSos(
        rideId: 'ride-99',
        expectedVersion: 1,
        emergencyType: 'Medical',
        severity: 'CRITICAL',
      );

      expect(notifier.activeAlert, isNotNull);
      expect(notifier.activeAlert!.alertId, equals('sos-mock-1'));
      expect(notifier.activeAlert!.type, equals(SafetyAlertType.sos));
      // Dynamic device GPS coords resolved automatically
      expect(notifier.activeAlert!.latitude, equals(-1.286389));
      expect(notifier.activeAlert!.longitude, equals(36.817223));

      notifier.dispose();
    });

    test('loadContacts populates emergency contacts list', () async {
      final notifier = SafetyNotifier(
        repository: repo,
        connectivityService: connectivity,
      );

      expect(notifier.contacts, isEmpty);
      await notifier.loadContacts();

      expect(notifier.contacts.length, equals(1));
      expect(notifier.contacts.first.relationship, equals('Mother'));

      notifier.dispose();
    });

    test('retryPendingSos replays queued offline SOS on reconnect and updates activeAlert', () async {
      final queuedAlert = SafetyAlert(
        alertId: 'sos-123456789',
        rideId: 'ride-99',
        type: SafetyAlertType.sos,
        status: 'ACTIVE',
        latitude: -1.286389,
        longitude: 36.817223,
        timestamp: DateTime.now().toUtc(),
      );
      repo.simulateQueuedSos(queuedAlert);

      final notifier = SafetyNotifier(
        repository: repo,
        connectivityService: connectivity,
      );

      // activeAlert starts null — no prior successful dispatch this session.
      expect(notifier.activeAlert, isNull);

      // Simulate reconnect — triggers _replayPendingSos() via stream.
      connectivity.goOnline();

      // Allow microtasks to flush.
      await Future<void>.delayed(Duration.zero);

      expect(notifier.activeAlert, isNotNull);
      expect(notifier.activeAlert!.alertId, equals('sos-123456789'));
      expect(notifier.activeAlert!.status, equals('ACTIVE'));

      notifier.dispose();
    });
  });
}
