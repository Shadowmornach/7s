import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/payment_provider.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_typography.dart';

/// Redesigned Digital Receipt Screen with clean item breakdown table
/// and total pricing summary.
class PaymentReceiptScreen extends StatefulWidget {
  final String receiptId;

  const PaymentReceiptScreen({super.key, required this.receiptId});

  @override
  State<PaymentReceiptScreen> createState() => _PaymentReceiptScreenState();
}

class _PaymentReceiptScreenState extends State<PaymentReceiptScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentNotifier>().loadReceipt(widget.receiptId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Trip Receipt'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Consumer<PaymentNotifier>(
        builder: (context, payment, child) {
          if (payment.isLoading) {
            return const LoadingIndicator(message: 'Retrieving digital receipt...');
          }

          final receipt = payment.currentReceipt;
          if (receipt == null) {
            return Center(
              child: Text(
                'Receipt not found',
                style: AppTypography.titleMedium.copyWith(color: AppColors.textMuted),
              ),
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.receipt_long_rounded, size: 40, color: AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          receipt.formattedTotal,
                          style: AppTypography.displayLarge.copyWith(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Paid via ${receipt.paymentMethodName}',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                        const Divider(height: 36),
                        _ReceiptRow(label: 'Base Fare', value: receipt.formattedBase),
                        const SizedBox(height: 12),
                        _ReceiptRow(label: 'Distance Fare', value: receipt.formattedDistance),
                        const SizedBox(height: 12),
                        _ReceiptRow(
                          label: 'Surge Charge',
                          value: '${receipt.currency} ${receipt.surgeAmount.toStringAsFixed(0)}',
                        ),
                        const SizedBox(height: 12),
                        _ReceiptRow(
                          label: 'Discounts',
                          value: '- ${receipt.currency} ${receipt.discountAmount.toStringAsFixed(0)}',
                        ),
                        const Divider(height: 36),
                        _ReceiptRow(label: 'Total Paid', value: receipt.formattedTotal, isBold: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _ReceiptRow({required this.label, required this.value, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
      fontSize: isBold ? 18 : 14,
      color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}
