import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_typography.dart';
import '../providers/rating_provider.dart';

/// Redesigned Ride Rating Screen with 5-star animated feedback,
/// AppCard container, and AppButton.
class RideRatingScreen extends StatefulWidget {
  final String rideId;
  final String driverName;
  final String driverId;

  const RideRatingScreen({
    super.key,
    required this.rideId,
    required this.driverName,
    required this.driverId,
  });

  @override
  State<RideRatingScreen> createState() => _RideRatingScreenState();
}

class _RideRatingScreenState extends State<RideRatingScreen> {
  int _selectedScore = 5;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ratingNotifier = context.watch<RatingNotifier>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rate Your Ride'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AppCard(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, size: 48, color: AppColors.primary),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'How was your ride with ${widget.driverName}?',
                    style: AppTypography.headlineMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your feedback helps us maintain top safety & service quality on 7s.',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // Star Rating Control
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return IconButton(
                        iconSize: 42,
                        icon: Icon(
                          starValue <= _selectedScore ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: AppColors.warning,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedScore = starValue;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getRatingLabel(_selectedScore),
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _commentController,
                    maxLines: 3,
                    style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Add optional feedback (e.g. clean car, polite driver)',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 28),
                  AppButton(
                    text: 'SUBMIT RATING',
                    isLoading: ratingNotifier.isSubmitting,
                    onPressed: ratingNotifier.isSubmitting
                        ? null
                        : () async {
                            final success = await context.read<RatingNotifier>().submitRating(
                                  rideId: widget.rideId,
                                  ratedUser: widget.driverId,
                                  score: _selectedScore,
                                  comment: _commentController.text.trim(),
                                );
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Thank you! Rating submitted successfully.')),
                              );
                              Navigator.of(context).maybePop();
                            }
                          },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingLabel(int score) {
    switch (score) {
      case 5:
        return 'Excellent Ride!';
      case 4:
        return 'Good';
      case 3:
        return 'Average';
      case 2:
        return 'Poor';
      case 1:
        return 'Terrible';
      default:
        return '';
    }
  }
}
