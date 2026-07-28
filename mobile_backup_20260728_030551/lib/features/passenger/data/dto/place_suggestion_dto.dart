class PlaceSuggestionDto {
  final String placeId;
  final String primaryText;
  final String secondaryText;
  final double latitude;
  final double longitude;

  const PlaceSuggestionDto({
    required this.placeId,
    required this.primaryText,
    required this.secondaryText,
    required this.latitude,
    required this.longitude,
  });

  factory PlaceSuggestionDto.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestionDto(
      placeId: json['place_id'] as String? ?? '',
      primaryText: json['primary_text'] as String? ?? '',
      secondaryText: json['secondary_text'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'place_id': placeId,
      'primary_text': primaryText,
      'secondary_text': secondaryText,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
