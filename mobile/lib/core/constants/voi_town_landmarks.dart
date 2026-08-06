import 'package:flutter/foundation.dart';

/// Single source of truth model for Voi Town landmarks and areas
@immutable
class VoiLandmarkItem {
  final String title;
  final String subtitle;
  final String category;
  final double latitude;
  final double longitude;
  final List<String> keywords;

  const VoiLandmarkItem({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.keywords = const [],
  });

  /// Checks if this landmark matches the search query in real-time
  bool matchesQuery(String query) {
    if (query.trim().isEmpty) return true;
    final normalized = query.trim().toLowerCase();
    
    if (title.toLowerCase().contains(normalized)) return true;
    if (subtitle.toLowerCase().contains(normalized)) return true;
    if (category.toLowerCase().contains(normalized)) return true;
    
    for (final kw in keywords) {
      if (kw.toLowerCase().contains(normalized)) return true;
    }
    return false;
  }
}

/// Comprehensive Voi Town dataset containing all areas and landmarks
class VoiTownLandmarksData {
  static const List<VoiLandmarkItem> allLandmarks = [
    // ── Primary Requested Landmarks ──────────────────────────────────────────
    VoiLandmarkItem(
      title: 'Voi Town Center • Posta Road',
      subtitle: 'Posta Road, Voi CBD, Kenya',
      category: 'CBD & Commerce',
      latitude: -3.3967,
      longitude: 38.5562,
      keywords: ['posta', 'town center', 'cbd', 'central', 'bank', 'post office'],
    ),
    VoiLandmarkItem(
      title: 'Voi SGR Station Terminal',
      subtitle: 'Voi SGR Link Road, Voi Town',
      category: 'Railway & Transit',
      latitude: -3.3708,
      longitude: 38.5598,
      keywords: ['sgr', 'train', 'railway', 'madaraka express', 'terminal', 'station'],
    ),
    VoiLandmarkItem(
      title: 'Moi County Referral Hospital • Voi',
      subtitle: 'Hospital Road, Voi Town',
      category: 'Healthcare',
      latitude: -3.3885,
      longitude: 38.5637,
      keywords: ['hospital', 'moi referral', 'clinic', 'health', 'medical', 'dispensary'],
    ),
    VoiLandmarkItem(
      title: 'Voi Main Bus Park & Market',
      subtitle: 'Biashara Street, Voi Town Center',
      category: 'Transit & Market',
      latitude: -3.3948,
      longitude: 38.5569,
      keywords: ['bus park', 'market', 'matatu stage', 'stage', 'bus stop', 'biashara'],
    ),
    VoiLandmarkItem(
      title: 'Taita Taveta University (TTU) Main Campus',
      subtitle: 'TTU Road, Voi',
      category: 'Education',
      latitude: -3.3980,
      longitude: 38.5680,
      keywords: ['ttu', 'taita taveta university', 'campus', 'college', 'varsity', 'school'],
    ),
    VoiLandmarkItem(
      title: 'Caltex Junction • Voi',
      subtitle: 'Mombasa - Nairobi Highway, Voi',
      category: 'Road Junction',
      latitude: -3.3930,
      longitude: 38.5530,
      keywords: ['caltex', 'junction', 'highway', 'petrol station', 'mombasa road'],
    ),
    VoiLandmarkItem(
      title: 'Voi Safari Lodge Junction',
      subtitle: 'Tsavo East Gate Access Road, Voi',
      category: 'Tourism & Junction',
      latitude: -3.3820,
      longitude: 38.5710,
      keywords: ['safari lodge', 'junction', 'tsavo gate', 'lodge', 'tourism'],
    ),

    // ── All Additional Voi Estates, Hubs & Surroundings ─────────────────────
    VoiLandmarkItem(
      title: 'KWS Voi Gate • Tsavo East',
      subtitle: 'Tsavo East National Park Gate, Voi',
      category: 'Tourism & Park',
      latitude: -3.3650,
      longitude: 38.5800,
      keywords: ['kws', 'tsavo east', 'park gate', 'wildlife', 'safari'],
    ),
    VoiLandmarkItem(
      title: 'Mwakingali Estate • Voi',
      subtitle: 'Mwakingali Residential Quarter, Voi',
      category: 'Residential',
      latitude: -3.3915,
      longitude: 38.5490,
      keywords: ['mwakingali', 'estate', 'residential'],
    ),
    VoiLandmarkItem(
      title: 'Kaloleni Estate • Voi',
      subtitle: 'Kaloleni Road, Voi Town',
      category: 'Residential',
      latitude: -3.4010,
      longitude: 38.5590,
      keywords: ['kaloleni', 'estate', 'residential'],
    ),
    VoiLandmarkItem(
      title: 'Tanzanite / Sofia Area • Voi',
      subtitle: 'Sofia Commercial & Residential Hub, Voi',
      category: 'Commercial & Residential',
      latitude: -3.3955,
      longitude: 38.5610,
      keywords: ['tanzanite', 'sofia', 'area', 'estate'],
    ),
    VoiLandmarkItem(
      title: 'Maweni Estate • Voi',
      subtitle: 'Maweni Heights, Voi Town',
      category: 'Residential',
      latitude: -3.4050,
      longitude: 38.5520,
      keywords: ['maweni', 'estate', 'residential'],
    ),
    VoiLandmarkItem(
      title: 'Mwatate Junction • Voi',
      subtitle: 'Voi - Mwatate Highway Interchange, Voi',
      category: 'Transit & Junction',
      latitude: -3.4020,
      longitude: 38.5450,
      keywords: ['mwatate junction', 'taveta road', 'interchange', 'bypass'],
    ),
    VoiLandmarkItem(
      title: 'Voi Railway Station (Old Metre Gauge)',
      subtitle: 'Station Road, Voi Town',
      category: 'Transit',
      latitude: -3.3960,
      longitude: 38.5580,
      keywords: ['old station', 'metre gauge', 'railway', 'krc'],
    ),
    VoiLandmarkItem(
      title: 'Voi Wildlife Lodge',
      subtitle: 'Tsavo East Park Border, Voi',
      category: 'Hotels & Tourism',
      latitude: -3.3750,
      longitude: 38.5750,
      keywords: ['wildlife lodge', 'hotel', 'resort', 'tsavo'],
    ),
    VoiLandmarkItem(
      title: 'Voi Safari Lodge',
      subtitle: 'Tsavo East National Park, Voi',
      category: 'Hotels & Tourism',
      latitude: -3.3550,
      longitude: 38.5900,
      keywords: ['safari lodge', 'tsavo lodge', 'viewpoint'],
    ),
    VoiLandmarkItem(
      title: 'One Stop Area • Voi',
      subtitle: 'Mombasa-Nairobi Highway, Voi',
      category: 'Highway Commercial',
      latitude: -3.3890,
      longitude: 38.5510,
      keywords: ['one stop', 'highway rest', 'fuel', 'rest area'],
    ),
    VoiLandmarkItem(
      title: 'Sikujua Area • Voi',
      subtitle: 'Sikujua Road, Voi Town',
      category: 'Residential',
      latitude: -3.3995,
      longitude: 38.5540,
      keywords: ['sikujua', 'estate', 'area'],
    ),
    VoiLandmarkItem(
      title: 'Birikani Estate • Voi',
      subtitle: 'Birikani Road, Voi',
      category: 'Residential',
      latitude: -3.3850,
      longitude: 38.5670,
      keywords: ['birikani', 'estate', 'residential'],
    ),
    VoiLandmarkItem(
      title: 'Kariokor Area • Voi',
      subtitle: 'Kariokor Sub-location, Voi',
      category: 'Residential & Retail',
      latitude: -3.3935,
      longitude: 38.5620,
      keywords: ['kariokor', 'market', 'area'],
    ),
    VoiLandmarkItem(
      title: 'Voi Youth Polytechnic Area',
      subtitle: 'Polytechnic Road, Voi',
      category: 'Education',
      latitude: -3.4030,
      longitude: 38.5640,
      keywords: ['polytechnic', 'youth poly', 'vocational', 'college'],
    ),
    VoiLandmarkItem(
      title: 'Voi Law Courts & Sub-County HQ',
      subtitle: 'Civic Center Road, Voi Town',
      category: 'Government Civic Center',
      latitude: -3.3950,
      longitude: 38.5595,
      keywords: ['law courts', 'sub-county', 'governance', 'dc office', 'huduma'],
    ),
    VoiLandmarkItem(
      title: 'Voi Police Station & Prison Area',
      subtitle: 'Police Line Road, Voi Town',
      category: 'Public Safety',
      latitude: -3.3920,
      longitude: 38.5585,
      keywords: ['police station', 'cop', 'prison', 'security'],
    ),
    VoiLandmarkItem(
      title: 'Voi Airstrip / Airport Area',
      subtitle: 'Airstrip Road, Voi',
      category: 'Aviation & Transit',
      latitude: -3.3610,
      longitude: 38.5540,
      keywords: ['airstrip', 'airport', 'flights', 'planes'],
    ),
    VoiLandmarkItem(
      title: 'Mbololo Junction • Voi',
      subtitle: 'Nairobi Highway, Mbololo-Voi',
      category: 'Road Junction',
      latitude: -3.3500,
      longitude: 38.5300,
      keywords: ['mbololo', 'junction', 'nairobi road'],
    ),
    VoiLandmarkItem(
      title: 'Ikanga Area • Voi',
      subtitle: 'Ikanga Bypass Road, Voi',
      category: 'Suburban Area',
      latitude: -3.4150,
      longitude: 38.5500,
      keywords: ['ikanga', 'bypass', 'area'],
    ),
    VoiLandmarkItem(
      title: 'Biashara Street • Voi Town',
      subtitle: 'Voi CBD Commercial Hub',
      category: 'Commerce & Shops',
      latitude: -3.3962,
      longitude: 38.5565,
      keywords: ['biashara', 'shops', 'retail', 'street'],
    ),
    VoiLandmarkItem(
      title: 'Danida Estate • Voi',
      subtitle: 'Danida Sub-location, Voi',
      category: 'Residential',
      latitude: -3.3900,
      longitude: 38.5720,
      keywords: ['danida', 'estate', 'residential'],
    ),
  ];

  /// Performs real-time filtering across all Voi Town landmarks and areas
  static List<VoiLandmarkItem> filterLandmarks(String query) {
    if (query.trim().isEmpty) {
      return allLandmarks;
    }
    return allLandmarks.where((item) => item.matchesQuery(query)).toList();
  }
}
