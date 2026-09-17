import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:our_balance/shared/widgets/amount_text.dart';

void main() {
  testWidgets('formats a positive amount with the INR symbol and grouping', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AmountText(1234567.8))),
    );
    expect(find.text('₹1,234,567.80'), findsOneWidget);
  });

  testWidgets('formats a negative amount with a leading minus before the symbol', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AmountText(-99.5))),
    );
    expect(find.text('-₹99.50'), findsOneWidget);
  });

  testWidgets('colorBySign renders positive amounts and negative amounts differently',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              AmountText(100, colorBySign: true, key: Key('positive')),
              AmountText(-100, colorBySign: true, key: Key('negative')),
            ],
          ),
        ),
      ),
    );

    final positiveText = tester.widget<Text>(
      find.descendant(of: find.byKey(const Key('positive')), matching: find.byType(Text)),
    );
    final negativeText = tester.widget<Text>(
      find.descendant(of: find.byKey(const Key('negative')), matching: find.byType(Text)),
    );

    expect(positiveText.style?.color, isNot(equals(negativeText.style?.color)));
  });
}
