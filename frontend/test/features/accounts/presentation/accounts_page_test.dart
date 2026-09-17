import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:our_balance/core/errors/api_exception.dart';
import 'package:our_balance/features/accounts/data/accounts_api.dart';
import 'package:our_balance/features/accounts/data/models/account.dart';
import 'package:our_balance/features/accounts/presentation/pages/accounts_page.dart';
import 'package:our_balance/features/household/data/household_api.dart';

import '../../../helpers/fakes.dart';

Widget _wrap(List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(home: AccountsPage()),
  );
}

void main() {
  group('AccountsPage', () {
    testWidgets('shows an empty state when there are no accounts', (tester) async {
      final accountsApi = FakeAccountsApi()
        ..listAccountsHandler = (_) async {
          return <Account>[];
        }
        ..getAccountDetailHandler = (_) async {
          throw StateError('not expected');
        };

      await tester.pumpWidget(_wrap([
        householdApiProvider.overrideWithValue(FakeHouseholdApi()),
        accountsApiProvider.overrideWithValue(accountsApi),
      ]));
      await tester.pumpAndSettle();

      expect(find.textContaining('No accounts yet'), findsOneWidget);
    });

    testWidgets('lists accounts enriched with balances', (tester) async {
      final accountsApi = FakeAccountsApi()
        ..listAccountsHandler = (_) async {
          return [testAccount];
        }
        ..getAccountDetailHandler = (_) async {
          return testAccountDetail;
        };

      await tester.pumpWidget(_wrap([
        householdApiProvider.overrideWithValue(FakeHouseholdApi()),
        accountsApiProvider.overrideWithValue(accountsApi),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('HDFC Bank'), findsOneWidget);
      expect(find.text('₹42,500.00'), findsOneWidget);
    });

    testWidgets('shows a retry button when the list fails to load', (tester) async {
      final accountsApi = FakeAccountsApi()
        ..listAccountsHandler = (_) async => throw const ServerException();

      await tester.pumpWidget(_wrap([
        householdApiProvider.overrideWithValue(FakeHouseholdApi()),
        accountsApiProvider.overrideWithValue(accountsApi),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('the + button opens the create-account sheet', (tester) async {
      final accountsApi = FakeAccountsApi()..listAccountsHandler = (_) async => [];

      await tester.pumpWidget(_wrap([
        householdApiProvider.overrideWithValue(FakeHouseholdApi()),
        accountsApiProvider.overrideWithValue(accountsApi),
      ]));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('New account'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Name'), findsOneWidget);
    });
  });
}
