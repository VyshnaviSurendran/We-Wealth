import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:our_balance/shared/widgets/balance_card.dart';

void main() {
  testWidgets('BalanceCard shows the label and INR-formatted amount', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BalanceCard(label: 'Actual balance', amount: 42500.5),
        ),
      ),
    );

    expect(find.text('Actual balance'), findsOneWidget);
    expect(find.text('₹42,500.50'), findsOneWidget);
  });

  testWidgets('BalanceCard colors a negative amount when colorBySign is true', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BalanceCard(label: 'Net this month', amount: -500, colorBySign: true),
        ),
      ),
    );

    expect(find.text('-₹500.00'), findsOneWidget);
  });
}
