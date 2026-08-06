import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/voi_town_landmarks.dart';

void main() {
  group('VoiTownLandmarksData Real-Time Filtering Tests', () {
    test('contains all 7 explicitly required Voi landmarks', () {
      final titles = VoiTownLandmarksData.allLandmarks.map((l) => l.title).toList();

      expect(titles, contains('Voi Town Center • Posta Road'));
      expect(titles, contains('Voi SGR Station Terminal'));
      expect(titles, contains('Moi County Referral Hospital • Voi'));
      expect(titles, contains('Voi Main Bus Park & Market'));
      expect(titles, contains('Taita Taveta University (TTU) Main Campus'));
      expect(titles, contains('Caltex Junction • Voi'));
      expect(titles, contains('Voi Safari Lodge Junction'));
    });

    test('contains comprehensive list of all Voi areas and estates', () {
      final titles = VoiTownLandmarksData.allLandmarks.map((l) => l.title).toList();

      expect(titles.length, greaterThanOrEqualTo(25));
      expect(titles, contains('Mwakingali Estate • Voi'));
      expect(titles, contains('Kaloleni Estate • Voi'));
      expect(titles, contains('Tanzanite / Sofia Area • Voi'));
      expect(titles, contains('Maweni Estate • Voi'));
      expect(titles, contains('Mwatate Junction • Voi'));
      expect(titles, contains('KWS Voi Gate • Tsavo East'));
      expect(titles, contains('Voi Youth Polytechnic Area'));
      expect(titles, contains('Voi Law Courts & Sub-County HQ'));
      expect(titles, contains('Voi Police Station & Prison Area'));
    });

    test('filters Voi SGR in real-time as user types "sgr"', () {
      final results = VoiTownLandmarksData.filterLandmarks('sgr');

      expect(results.isNotEmpty, true);
      expect(results.any((item) => item.title.contains('SGR')), true);
    });

    test('filters Posta Road in real-time as user types "posta"', () {
      final results = VoiTownLandmarksData.filterLandmarks('posta');

      expect(results.length, equals(1));
      expect(results.first.title, equals('Voi Town Center • Posta Road'));
    });

    test('filters Moi Hospital in real-time as user types "hospital"', () {
      final results = VoiTownLandmarksData.filterLandmarks('hospital');

      expect(results.any((item) => item.title.contains('Hospital')), true);
    });

    test('filters TTU in real-time as user types "ttu"', () {
      final results = VoiTownLandmarksData.filterLandmarks('ttu');

      expect(results.any((item) => item.title.contains('Taita Taveta University')), true);
    });

    test('filters Caltex in real-time as user types "caltex"', () {
      final results = VoiTownLandmarksData.filterLandmarks('caltex');

      expect(results.first.title, equals('Caltex Junction • Voi'));
    });

    test('returns all landmarks when query is empty', () {
      final results = VoiTownLandmarksData.filterLandmarks('');

      expect(results.length, equals(VoiTownLandmarksData.allLandmarks.length));
    });

    test('case-insensitive search matching for keywords and category', () {
      final upperCaseResults = VoiTownLandmarksData.filterLandmarks('MARKET');
      final lowerCaseResults = VoiTownLandmarksData.filterLandmarks('market');

      expect(upperCaseResults.length, equals(lowerCaseResults.length));
    });
  });
}
