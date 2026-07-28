import '../models/ride_rating.dart';

abstract class RatingRepository {
  Future<RideRating> submitRating({
    required String rideId,
    required String ratedUser,
    required int score,
    String? comment,
  });
}
