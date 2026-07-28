import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/payment_provider.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_typography.dart';

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
      appBar: AppBar(
        title: const Text('Trip Receipt'),
      ),
      body: Consumer<PaymentNotifier>(
        builder: (context, payment, child) {
          if (payment.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final receipt = payment.currentReceipt;
          if (receipt == null) {
            return const Center(child: Text('Receipt not found'));
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.receipt_long_rounded, size: 48, color: AppColors.primary),
                        const SizedBox(height: 12),
                        Text(receipt.formattedTotal, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        const SizedBox(height: 4),
                        Text('Paid via ${receipt.paymentMethodName}', style: AppTypography.caption),
                        const Divider(height: 32),
                        _ReceiptRow(label: 'Base Fare', value: receipt.formattedBase),
                        const SizedBox(height: 8),
                        _ReceiptRow(label: 'Distance Fare', value: receipt.formattedDistance),
                        const SizedBox(height: 8),
                        _ReceiptRow(label: 'Surge Charge', value: '${receipt.currency} ${receipt.surgeAmount.toStringAsFixed(0)}'),
                        const SizedBox(height: 8),
                        _ReceiptRow(label: 'Discounts', value: '- ${receipt.currency} ${receipt.discountAmount.toStringAsFixed(0)}'),
                        const Divider(height: 32),
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
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
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
