import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/onboarding_provider.dart';
import '../../domain/models/onboarding_page_item.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_typography.dart';

/// Redesigned Onboarding Carousel with custom pill indicators,
/// hero icon badges, and AppButton action controllers.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  static const List<OnboardingPageItem> _pages = [
    OnboardingPageItem(
      title: 'Request a Ride in Seconds',
      description: 'Upfront fare estimates, verified local drivers, and instant pickup anywhere in town.',
      icon: Icons.local_taxi_rounded,
      accentColor: AppColors.primary,
    ),
    OnboardingPageItem(
      title: 'Real-Time Live Tracking',
      description: 'Watch your driver approach on the map in real time with accurate arrival times.',
      icon: Icons.map_rounded,
      accentColor: AppColors.primary,
    ),
    OnboardingPageItem(
      title: 'Instant Emergency SOS',
      description: 'One-tap emergency alert triggers live location sharing to response teams and contacts.',
      icon: Icons.warning_amber_rounded,
      accentColor: AppColors.alert,
    ),
    OnboardingPageItem(
      title: 'Share Your Trip Live',
      description: 'Send a secure public link to family and friends so they can follow your trip in real time.',
      icon: Icons.share_rounded,
      accentColor: AppColors.primary,
    ),
    OnboardingPageItem(
      title: 'Cash & Secure M-Pesa',
      description: 'Pay seamlessly with Cash or instant M-Pesa Daraja STK push notifications.',
      icon: Icons.account_balance_wallet_rounded,
      accentColor: AppColors.primary,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finishOnboarding(BuildContext context) async {
    final provider = context.read<OnboardingProvider>();
    await provider.completeOnboarding();
    if (context.mounted) {
      context.go('/permissions-explain');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => _finishOnboarding(context),
            child: Text(
              'SKIP',
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  context.read<OnboardingProvider>().setPageIndex(index);
                },
                itemBuilder: (context, index) {
                  final item = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: item.accentColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(item.icon, size: 70, color: item.accentColor),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: AppTypography.displayLarge.copyWith(fontSize: 26),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          item.description,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Consumer<OnboardingProvider>(
              builder: (context, provider, child) {
                final isLast = provider.currentPageIndex == _pages.length - 1;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: provider.currentPageIndex == i ? 28 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: provider.currentPageIndex == i ? AppColors.primary : AppColors.border,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      AppButton(
                        text: isLast ? 'GET STARTED' : 'NEXT',
                        suffixIcon: isLast ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                        onPressed: () {
                          if (isLast) {
                            _finishOnboarding(context);
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
