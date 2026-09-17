import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:our_balance/features/accounts/data/models/account_detail.dart';
import 'package:our_balance/shared/widgets/account_card.dart';

import '../../helpers/fakes.dart';

void main() {
  testWidgets('shows the account name, type, actual balance, and safe-balance subtitle',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: AccountCard(account: testAccountDetail))),
    );

    expect(find.text('HDFC Bank'), findsOneWidget);
    expect(find.textContaining('Bank account'), findsOneWidget);
    expect(find.textContaining('Shared'), findsOneWidget);
    expect(find.text('₹42,500.00'), findsOneWidget);
    expect(find.textContaining('Safe: ₹37,500.00'), findsOneWidget);
    expect(find.text('Archived'), findsNothing);
  });

  testWidgets('shows an Archived chip for an inactive account', (tester) async {
    final archived = AccountDetail(
      id: testAccountDetail.id,
      householdId: testAccountDetail.householdId,
      ownerUserId: null,
      name: testAccountDetail.name,
      accountType: testAccountDetail.accountType,
      openingBalance: testAccountDetail.openingBalance,
      isShared: testAccountDetail.isShared,
      isActive: false,
      actualBalance: testAccountDetail.actualBalance,
      pendingAmount: 0,
      safeAvailableBalance: testAccountDetail.actualBalance,
    );

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: AccountCard(account: archived))),
    );

    expect(find.text('Archived'), findsOneWidget);
    // No pending amount => no "Safe:" subtitle line.
    expect(find.textContaining('Safe:'), findsNothing);
  });

  testWidgets('calls onTap when tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AccountCard(account: testAccountDetail, onTap: () => tapped = true),
        ),
      ),
    );

    await tester.tap(find.byType(AccountCard));
    expect(tapped, isTrue);
  });
}
