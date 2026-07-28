import '../models/safety_alert.dart';
import '../models/emergency_contact.dart';

abstract class SafetyRepository {
  Future<SafetyAlert> triggerSosAlert({
    required String rideId,
    required int expectedVersion,
    required double latitude,
    required double longitude,
    required String emergencyType,
    required String severity,
  });

  Future<String> getShareableTripLink(String rideId);

  Future<List<EmergencyContact>> getEmergencyContacts();

  Future<void> addEmergencyContact(EmergencyContact contact);

  /// Checks local storage for a queued offline SOS and replays it if present.
  /// Returns the dispatched [SafetyAlert] on success, or null if no pending SOS exists.
  Future<SafetyAlert?> retryPendingSos();
}
