class EmergencyContactDto {
  final String contactId;
  final String name;
  final String phoneNumber;
  final String relationship;

  const EmergencyContactDto({
    required this.contactId,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
  });

  factory EmergencyContactDto.fromJson(Map<String, dynamic> json) {
    return EmergencyContactDto(
      contactId: json['contact_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      relationship: json['relationship'] as String? ?? 'Guardian',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contact_id': contactId,
      'name': name,
      'phone_number': phoneNumber,
      'relationship': relationship,
    };
  }
}
