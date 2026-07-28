import 'package:flutter/foundation.dart';
import '../../domain/models/ride_rating.dart';
import '../../domain/repositories/rating_repository.dart';

class RatingNotifier extends ChangeNotifier {
  final RatingRepository _repository;

  RideRating? _submittedRating;
  bool _isSubmitting = false;
  String? _errorMessage;

  RatingNotifier({required RatingRepository repository}) : _repository = repository;

  RideRating? get submittedRating => _submittedRating;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<bool> submitRating({
    required String rideId,
    required String ratedUser,
    required int score,
    String? comment,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _submittedRating = await _repository.submitRating(
        rideId: rideId,
        ratedUser: ratedUser,
        score: score,
        comment: comment,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
