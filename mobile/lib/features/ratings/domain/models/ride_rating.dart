class RideRating {
  final String ratingId;
  final String rideId;
  final String ratedBy;
  final String ratedUser;
  final int score;
  final String? comment;
  final DateTime createdAt;

  const RideRating({
    required this.ratingId,
    required this.rideId,
    required this.ratedBy,
    required this.ratedUser,
    required this.score,
    this.comment,
    required this.createdAt,
  });
}
