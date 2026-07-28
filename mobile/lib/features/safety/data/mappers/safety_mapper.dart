import '../dto/safety_alert_dto.dart';
import '../dto/emergency_contact_dto.dart';
import '../../domain/models/safety_alert.dart';
import '../../domain/models/emergency_contact.dart';

class SafetyMapper {
  static SafetyAlert alertFromDto(SafetyAlertDto dto) {
    return SafetyAlert(
      alertId: dto.alertId,
      rideId: dto.rideId,
      type: SafetyAlert.parseType(dto.alertType),
      status: dto.status,
      latitude: dto.latitude,
      longitude: dto.longitude,
      timestamp: DateTime.tryParse(dto.timestampIso) ?? DateTime.now().toUtc(),
    );
  }

  static EmergencyContact contactFromDto(EmergencyContactDto dto) {
    return EmergencyContact(
      contactId: dto.contactId,
      name: dto.name,
      phoneNumber: dto.phoneNumber,
      relationship: dto.relationship,
    );
  }
}
