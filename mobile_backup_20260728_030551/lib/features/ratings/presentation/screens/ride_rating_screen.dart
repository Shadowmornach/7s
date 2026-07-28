import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_typography.dart';
import '../providers/rating_provider.dart';

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
      appBar: AppBar(
        title: const Text('Rate Your Ride'),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person, size: 44, color: Colors.black),
            ),
            const SizedBox(height: 16),
            Text(
              'How was your ride with ${widget.driverName}?',
              style: AppTypography.headline,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Your feedback helps us maintain top safety & service quality on 7s.',
              style: AppTypography.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Star Rating Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                return IconButton(
                  iconSize: 40,
                  icon: Icon(
                    starValue <= _selectedScore ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber.shade600,
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
              style: AppTypography.body.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 24),

            // Optional Feedback Input
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Add optional feedback (e.g. clean car, polite driver)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: AppColors.surface,
              ),
            ),
            const SizedBox(height: 32),

            if (ratingNotifier.isSubmitting)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
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
                child: const Text('SUBMIT RATING', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
