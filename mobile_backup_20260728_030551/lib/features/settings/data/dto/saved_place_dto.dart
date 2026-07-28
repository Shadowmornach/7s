class SavedPlaceDto {
  final String placeId;
  final String label;
  final String address;
  final double latitude;
  final double longitude;
  final String icon;

  const SavedPlaceDto({
    required this.placeId,
    required this.label,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.icon,
  });

  factory SavedPlaceDto.fromJson(Map<String, dynamic> json) {
    return SavedPlaceDto(
      placeId: json['place_id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      icon: json['icon'] as String? ?? 'place',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'place_id': placeId,
      'label': label,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'icon': icon,
    };
  }
}
