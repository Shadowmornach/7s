import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile/features/ratings/domain/models/ride_rating.dart';
import 'package:mobile/features/ratings/domain/repositories/rating_repository.dart';
import 'package:mobile/features/ratings/presentation/providers/rating_provider.dart';
import 'package:mobile/features/ratings/presentation/screens/ride_rating_screen.dart';

class MockRatingRepository implements RatingRepository {
  @override
  Future<RideRating> submitRating({
    required String rideId,
    required String ratedUser,
    required int score,
    String? comment,
  }) async {
    return RideRating(
      ratingId: 'rat-mock-1',
      rideId: rideId,
      ratedBy: 'passenger-1',
      ratedUser: ratedUser,
      score: score,
      comment: comment,
      createdAt: DateTime.now().toUtc(),
    );
  }
}

void main() {
  group('RideRating Flutter Tests', () {
    late MockRatingRepository repo;

    setUp(() {
      repo = MockRatingRepository();
    });

    test('RatingNotifier submits rating successfully', () async {
      final notifier = RatingNotifier(repository: repo);
      expect(notifier.submittedRating, isNull);

      final success = await notifier.submitRating(
        rideId: 'ride-100',
        ratedUser: 'driver-200',
        score: 5,
        comment: 'Great driving!',
      );

      expect(success, isTrue);
      expect(notifier.submittedRating, isNotNull);
      expect(notifier.submittedRating!.score, equals(5));
      expect(notifier.submittedRating!.comment, equals('Great driving!'));
    });

    testWidgets('RideRatingScreen renders stars and submits user rating', (WidgetTester tester) async {
      final notifier = RatingNotifier(repository: repo);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<RatingNotifier>.value(
            value: notifier,
            child: const RideRatingScreen(
              rideId: 'ride-100',
              driverName: 'David Omondi',
              driverId: 'driver-200',
            ),
          ),
        ),
      );

      expect(find.text('Rate Your Ride'), findsOneWidget);
      expect(find.text('How was your ride with David Omondi?'), findsOneWidget);
      expect(find.text('Excellent Ride!'), findsOneWidget);
      expect(find.text('SUBMIT RATING'), findsOneWidget);

      // Tap submit button
      await tester.tap(find.text('SUBMIT RATING'));
      await tester.pumpAndSettle();

      expect(notifier.submittedRating, isNotNull);
      expect(notifier.submittedRating!.rideId, equals('ride-100'));
      expect(notifier.submittedRating!.score, equals(5));
    });
  });
}
