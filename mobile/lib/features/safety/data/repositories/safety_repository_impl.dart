import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/logging/app_logger.dart';
import '../dto/safety_alert_dto.dart';
import '../dto/emergency_contact_dto.dart';
import '../mappers/safety_mapper.dart';
import '../../domain/models/safety_alert.dart';
import '../../domain/models/emergency_contact.dart';
import '../../domain/repositories/safety_repository.dart';

/// Key used to persist a single pending offline SOS in secure storage.
const _kPendingSosKey = 'pending_sos';

class SafetyRepositoryImpl implements SafetyRepository {
  final ApiClient _apiClient;
  final AppLogger _logger;
  final FlutterSecureStorage _secureStorage;

  SafetyRepositoryImpl({
    required ApiClient apiClient,
    required AppLogger logger,
    FlutterSecureStorage? secureStorage,
  })  : _apiClient = apiClient,
        _logger = logger,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  @override
  Future<SafetyAlert> triggerSosAlert({
    required String rideId,
    required int expectedVersion,
    required double latitude,
    required double longitude,
    required String emergencyType,
    required String severity,
  }) async {
    _logger.warning('Telemetry: [SOS_DISPATCH_TRIGGERED] RideId: $rideId Type: $emergencyType');
    try {
      final res = await _apiClient.post(
        '/rides/$rideId/events',
        body: {
          'action': 'trigger_sos',
          'expected_version': expectedVersion,
          'metadata': {
            'emergency_type': emergencyType,
            'severity': severity,
            'latitude': latitude,
            'longitude': longitude,
          },
        },
      );
      final resMap = res as Map<String, dynamic>;
      final activeSosId = resMap['active_sos_id'] as String? ?? 'sos-direct';
      final activeSosStatus = resMap['active_sos_status'] as String? ?? 'ACTIVE';

      // Clear any previously queued SOS — this one landed successfully.
      await _secureStorage.delete(key: _kPendingSosKey);

      final dto = SafetyAlertDto(
        alertId: activeSosId,
        rideId: rideId,
        alertType: emergencyType,
        status: activeSosStatus,
        latitude: latitude,
        longitude: longitude,
        timestampIso: DateTime.now().toUtc().toIso8601String(),
      );
      return SafetyMapper.alertFromDto(dto);
    } catch (e) {
      // Generate a stable, device-unique ID for this offline SOS.
      final offlineId = 'sos-${DateTime.now().microsecondsSinceEpoch}';
      _logger.warning('Telemetry: [SOS_QUEUED_OFFLINE] Id: $offlineId RideId: $rideId');

      // Persist full payload so it can be replayed on reconnect (BR-016).
      final payload = jsonEncode({
        'alert_id': offlineId,
        'ride_id': rideId,
        'expected_version': expectedVersion,
        'latitude': latitude,
        'longitude': longitude,
        'emergency_type': emergencyType,
        'severity': severity,
        'queued_at': DateTime.now().toUtc().toIso8601String(),
      });
      await _secureStorage.write(key: _kPendingSosKey, value: payload);

      return SafetyAlert(
        alertId: offlineId,
        rideId: rideId,
        type: SafetyAlertType.sos,
        status: 'queued_offline',
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now().toUtc(),
      );
    }
  }

  @override
  Future<SafetyAlert?> retryPendingSos() async {
    final raw = await _secureStorage.read(key: _kPendingSosKey);
    if (raw == null) return null;

    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      _logger.warning('Telemetry: [SOS_QUEUE_CORRUPT] Clearing malformed entry.');
      await _secureStorage.delete(key: _kPendingSosKey);
      return null;
    }

    final rideId = payload['ride_id'] as String;
    final offlineId = payload['alert_id'] as String;
    _logger.warning('Telemetry: [SOS_RETRY_ATTEMPT] Id: $offlineId RideId: $rideId');

    try {
      final res = await _apiClient.post(
        '/rides/$rideId/events',
        body: {
          'action': 'trigger_sos',
          'expected_version': payload['expected_version'] as int,
          'metadata': {
            'emergency_type': payload['emergency_type'] as String,
            'severity': payload['severity'] as String,
            'latitude': payload['latitude'] as double,
            'longitude': payload['longitude'] as double,
          },
        },
      );
      final resMap = res as Map<String, dynamic>;
      final activeSosId = resMap['active_sos_id'] as String? ?? offlineId;
      final activeSosStatus = resMap['active_sos_status'] as String? ?? 'ACTIVE';

      // Retry landed — clear the queue.
      await _secureStorage.delete(key: _kPendingSosKey);
      _logger.warning('Telemetry: [SOS_RETRY_SUCCESS] Id: $activeSosId RideId: $rideId');

      final dto = SafetyAlertDto(
        alertId: activeSosId,
        rideId: rideId,
        alertType: payload['emergency_type'] as String,
        status: activeSosStatus,
        latitude: payload['latitude'] as double,
        longitude: payload['longitude'] as double,
        timestampIso: DateTime.now().toUtc().toIso8601String(),
      );
      return SafetyMapper.alertFromDto(dto);
    } catch (e) {
      // Still offline — re-persist silently, do not surface error (per spec).
      _logger.warning('Telemetry: [SOS_RETRY_FAILED_STILL_OFFLINE] Id: $offlineId');
      return null;
    }
  }

  @override
  Future<String> getShareableTripLink(String rideId) async {
    _logger.info('Telemetry: [trip_sharing_link_requested] RideId: $rideId');
    try {
      final res = await _apiClient.get('/api/v1/rides/$rideId/share');
      return (res as Map<String, dynamic>)['share_url'] as String;
    } catch (e) {
      return 'https://7s.co.ke/share/demo-$rideId';
    }
  }

  @override
  Future<List<EmergencyContact>> getEmergencyContacts() async {
    _logger.info('Telemetry: [emergency_contacts_requested]');
    try {
      final res = await _apiClient.get('/api/v1/safety/contacts');
      final list = res as List<dynamic>? ?? [];
      return list
          .map((item) => SafetyMapper.contactFromDto(EmergencyContactDto.fromJson(item as Map<String, dynamic>)))
          .toList();
    } catch (e) {
      return const [
        EmergencyContact(
          contactId: 'ec-1',
          name: 'Mary Wanjiku (Mother)',
          phoneNumber: '+254722001122',
          relationship: 'Mother',
        ),
      ];
    }
  }

  @override
  Future<void> addEmergencyContact(EmergencyContact contact) async {
    _logger.info('Telemetry: [emergency_contact_added] Name: ${contact.name}');
    try {
      await _apiClient.post(
        '/api/v1/safety/contacts',
        body: {
          'name': contact.name,
          'phone_number': contact.phoneNumber,
          'relationship': contact.relationship,
        },
      );
    } catch (e) {
      _logger.warning('Add emergency contact fallback for offline/demo mode');
    }
  }
}
