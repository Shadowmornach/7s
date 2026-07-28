import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/payment_provider.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_typography.dart';

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
      appBar: AppBar(
        title: const Text('M-Pesa STK Payment'),
      ),
      body: Consumer<PaymentNotifier>(
        builder: (context, payment, child) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (payment.stkStatus == StkPaymentStatus.idle) ...[
                    const Icon(Icons.phone_android_rounded, size: 80, color: AppColors.accent),
                    const SizedBox(height: 24),
                    Text('Amount: KES ${amount.toStringAsFixed(0)}', style: AppTypography.headline),
                    const SizedBox(height: 8),
                    Text('STK Push prompt will be sent to $phoneNumber', style: AppTypography.caption),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          payment.initiateStkPush(
                            rideId: rideId,
                            phoneNumber: phoneNumber,
                            amount: amount,
                          );
                        },
                        child: const Text('SEND M-PESA STK PUSH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],

                  if (payment.stkStatus == StkPaymentStatus.sendingPrompt || payment.stkStatus == StkPaymentStatus.waitingForPin) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 24),
                    const Text('Check your phone for M-Pesa STK Prompt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    const Text('Enter your M-Pesa PIN to authorize payment', style: AppTypography.caption),
                  ],

                  if (payment.stkStatus == StkPaymentStatus.success) ...[
                    const Icon(Icons.check_circle_rounded, size: 80, color: Colors.green),
                    const SizedBox(height: 24),
                    const Text('Payment Confirmed!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.green)),
                    const SizedBox(height: 8),
                    Text('Transaction ID: ${payment.transactionId}', style: AppTypography.caption),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                        onPressed: () {
                          payment.resetStkStatus();
                          context.pop();
                        },
                        child: const Text('DONE'),
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
