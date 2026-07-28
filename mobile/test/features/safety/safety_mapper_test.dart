import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/safety/data/dto/safety_alert_dto.dart';
import 'package:mobile/features/safety/data/dto/emergency_contact_dto.dart';
import 'package:mobile/features/safety/data/mappers/safety_mapper.dart';
import 'package:mobile/features/safety/domain/models/safety_alert.dart';

void main() {
  group('SafetyMapper Unit Tests', () {
    test('alertFromDto maps SafetyAlertDto to SafetyAlert domain model', () {
      const dto = SafetyAlertDto(
        alertId: 'sos-1',
        rideId: 'ride-99',
        alertType: 'sos',
        status: 'dispatched',
        latitude: -1.2921,
        longitude: 36.7821,
        timestampIso: '2026-07-26T16:00:00Z',
      );

      final alert = SafetyMapper.alertFromDto(dto);

      expect(alert.alertId, equals('sos-1'));
      expect(alert.type, equals(SafetyAlertType.sos));
      expect(alert.status, equals('dispatched'));
    });

    test('contactFromDto maps EmergencyContactDto to EmergencyContact domain model', () {
      const dto = EmergencyContactDto(
        contactId: 'ec-1',
        name: 'Mary Wanjiku',
        phoneNumber: '+254722001122',
        relationship: 'Mother',
      );

      final contact = SafetyMapper.contactFromDto(dto);

      expect(contact.contactId, equals('ec-1'));
      expect(contact.name, equals('Mary Wanjiku'));
      expect(contact.relationship, equals('Mother'));
    });
  });
}
