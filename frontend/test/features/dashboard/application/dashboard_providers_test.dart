import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:our_balance/core/errors/api_exception.dart';
import 'package:our_balance/features/accounts/data/accounts_api.dart';
import 'package:our_balance/features/dashboard/application/dashboard_providers.dart';
import 'package:our_balance/features/dashboard/data/dashboard_api.dart';
import 'package:our_balance/features/dashboard/data/models/dashboard_summary.dart';
import 'package:our_balance/shared/models/account_transaction.dart';

import '../../../helpers/fakes.dart';

void main() {
  group('dashboardSummaryProvider', () {
    test('returns the summary from DashboardApi as-is', () async {
      final container = ProviderContainer(
        overrides: [dashboardApiProvider.overrideWithValue(FakeDashboardApi())],
      );
      addTearDown(container.dispose);

      final summary = await container.read(dashboardSummaryProvider(testHousehold.id).future);

      expect(summary.totalActualBalance, testDashboardSummary.totalActualBalance);
      expect(summary.accounts, hasLength(1));
    });

    test('propagates a backend error as AsyncError', () async {
      final container = ProviderContainer(
        overrides: [
          dashboardApiProvider.overrideWithValue(
            FakeDashboardApi(error: const ServerException()),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(dashboardSummaryProvider(testHousehold.id).future),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('recentActivityProvider', () {
    test('merges and sorts transactions across every account in the summary, most recent first',
        () async {
      final earlier = testTransaction; // 2026-09-01
      final later = AccountTransaction(
        id: 'txn-later',
        transactionType: TransactionType.income,
        title: 'Salary',
        amount: 60000,
        transactionDate: DateTime(2026, 9, 10),
        status: 'RECEIVED',
        accountId: testAccountDetail.id,
      );

      final accountsApi = FakeAccountsApi()
        ..getAccountTransactionsHandler = (accountId) async => [earlier, later];

      final container = ProviderContainer(
        overrides: [
          dashboardApiProvider.overrideWithValue(FakeDashboardApi()),
          accountsApiProvider.overrideWithValue(accountsApi),
        ],
      );
      addTearDown(container.dispose);

      final activity = await container.read(recentActivityProvider(testHousehold.id).future);

      expect(activity, hasLength(2));
      expect(activity.first.id, 'txn-later');
      expect(activity.last.id, testTransaction.id);
    });

    test('returns an empty list when the summary has no accounts, without calling AccountsApi',
        () async {
      final accountsApi = FakeAccountsApi()
        ..getAccountTransactionsHandler = (_) => throw StateError('should not be called');
      final emptySummaryApi = FakeDashboardApi(
        summary: DashboardSummary(
          householdId: testHousehold.id,
          totalActualBalance: 0,
          totalPendingAmount: 0,
          totalSafeAvailableBalance: 0,
          monthIncomeReceived: 0,
          monthExpensesPaid: 0,
          monthPendingExpenses: 0,
          netWorth: 0,
          accounts: const [],
        ),
      );
      final container = ProviderContainer(
        overrides: [
          dashboardApiProvider.overrideWithValue(emptySummaryApi),
          accountsApiProvider.overrideWithValue(accountsApi),
        ],
      );
      addTearDown(container.dispose);

      final activity = await container.read(recentActivityProvider(testHousehold.id).future);

      expect(activity, isEmpty);
    });

    test('caps the merged feed at recentActivityLimit entries', () async {
      final manyTransactions = List.generate(
        recentActivityLimit + 5,
        (i) => AccountTransaction(
          id: 'txn-$i',
          transactionType: TransactionType.expense,
          title: 'Item $i',
          amount: 10,
          transactionDate: DateTime(2026, 9, 1).add(Duration(days: i)),
          status: 'PAID',
          accountId: testAccountDetail.id,
        ),
      );
      final accountsApi = FakeAccountsApi()
        ..getAccountTransactionsHandler = (_) async => manyTransactions;

      final container = ProviderContainer(
        overrides: [
          dashboardApiProvider.overrideWithValue(FakeDashboardApi()),
          accountsApiProvider.overrideWithValue(accountsApi),
        ],
      );
      addTearDown(container.dispose);

      final activity = await container.read(recentActivityProvider(testHousehold.id).future);

      expect(activity, hasLength(recentActivityLimit));
      // Most recent (highest day offset) first.
      expect(activity.first.id, 'txn-${recentActivityLimit + 4}');
    });
  });
}
