import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/payment_provider.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_typography.dart';

/// Redesigned M-Pesa STK Push Payment Processing Screen with radar status,
/// amount card, and step verification states.
class PaymentProcessingScreen extends StatelessWidget {
  final String rideId;
  final double amount;
  final String phoneNumber;

  const PaymentProcessingScreen({
    super.key,
    required this.rideId,
    required this.amount,
    required this.phoneNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('M-Pesa STK Payment'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Consumer<PaymentNotifier>(
        builder: (context, payment, child) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (payment.stkStatus == StkPaymentStatus.idle) ...[
                    AppCard(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.phone_android_rounded, size: 56, color: AppColors.primary),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'KES ${amount.toStringAsFixed(0)}',
                            style: AppTypography.displayLarge.copyWith(
                              fontSize: 36,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'An M-Pesa STK Push prompt will be sent to $phoneNumber',
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),
                          AppButton(
                            text: 'SEND M-PESA STK PUSH',
                            icon: Icons.send_rounded,
                            onPressed: () {
                              payment.initiateStkPush(
                                rideId: rideId,
                                phoneNumber: phoneNumber,
                                amount: amount,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (payment.stkStatus == StkPaymentStatus.sendingPrompt || payment.stkStatus == StkPaymentStatus.waitingForPin) ...[
                    AppCard(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const LoadingIndicator(size: 48),
                          const SizedBox(height: 28),
                          Text(
                            'Check Phone for M-Pesa Prompt',
                            style: AppTypography.titleMedium.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Enter your M-Pesa SIM PIN on your mobile device to authorize payment.',
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (payment.stkStatus == StkPaymentStatus.success) ...[
                    AppCard(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle_rounded, size: 64, color: AppColors.success),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Payment Confirmed!',
                            style: AppTypography.displayLarge.copyWith(
                              fontSize: 26,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Transaction ID: ${payment.transactionId}',
                            style: AppTypography.labelMedium.copyWith(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 28),
                          AppButton(
                            text: 'DONE',
                            icon: Icons.done_rounded,
                            onPressed: () {
                              payment.resetStkStatus();
                              context.pop();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
