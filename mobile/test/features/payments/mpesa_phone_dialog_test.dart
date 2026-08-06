import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/payments/presentation/widgets/mpesa_phone_dialog.dart';

void main() {
  testWidgets('MpesaPhonePromptDialog validates Safaricom phone format', (WidgetTester tester) async {
    String? resultPhone;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                resultPhone = await MpesaPhonePromptDialog.show(context);
              },
              child: const Text('Open Prompt'),
            ),
          ),
        ),
      ),
    );

    // Tap to open dialog
    await tester.tap(find.text('Open Prompt'));
    await tester.pumpAndSettle();

    expect(find.text('Set up M-Pesa'), findsOneWidget);

    // Try submitting empty -> validation error
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('M-Pesa phone number is required'), findsOneWidget);

    // Enter invalid non-Safaricom number
    await tester.enterText(find.byType(TextFormField), '12345');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Enter valid Safaricom number (e.g. 712 345 678)'), findsOneWidget);

    // Enter valid Safaricom number
    await tester.enterText(find.byType(TextFormField), '712345678');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(resultPhone, equals('+254712345678'));
  });
}
