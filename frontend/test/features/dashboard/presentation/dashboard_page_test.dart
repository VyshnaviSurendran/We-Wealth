import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:our_balance/core/errors/api_exception.dart';
import 'package:our_balance/features/accounts/data/accounts_api.dart';
import 'package:our_balance/features/dashboard/data/dashboard_api.dart';
import 'package:our_balance/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:our_balance/features/household/data/household_api.dart';

import '../../../helpers/fakes.dart';

Widget _wrap(Widget child, List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(home: DashboardPage()),
  );
}

void main() {
  group('DashboardPage', () {
    testWidgets('shows an empty state when the user has no household yet', (tester) async {
      await tester.pumpWidget(
        _wrap(const DashboardPage(), [
          householdApiProvider.overrideWithValue(FakeHouseholdApi(households: [])),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('No household found'), findsOneWidget);
    });

    testWidgets('shows the balance cards once the summary loads', (tester) async {
      final accountsApi = FakeAccountsApi()
        ..getAccountTransactionsHandler = (_) async => [testTransaction];

      await tester.pumpWidget(
        _wrap(const DashboardPage(), [
          householdApiProvider.overrideWithValue(FakeHouseholdApi()),
          dashboardApiProvider.overrideWithValue(FakeDashboardApi()),
          accountsApiProvider.overrideWithValue(accountsApi),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Actual balance'), findsOneWidget);
      expect(find.text('₹42,500.00'), findsWidgets);
      expect(find.text('Account-wise balances'), findsOneWidget);
      expect(find.text('HDFC Bank'), findsOneWidget);
      expect(find.text('Recent activity'), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
    });

    testWidgets('shows a retry button when the summary fails to load', (tester) async {
      await tester.pumpWidget(
        _wrap(const DashboardPage(), [
          householdApiProvider.overrideWithValue(FakeHouseholdApi()),
          dashboardApiProvider.overrideWithValue(
            FakeDashboardApi(error: const ServerException()),
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
      expect(find.text(const ServerException().message), findsOneWidget);
    });
  });
}
