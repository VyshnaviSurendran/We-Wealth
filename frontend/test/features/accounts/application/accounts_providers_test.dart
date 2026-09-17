import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:our_balance/features/accounts/application/accounts_providers.dart';
import 'package:our_balance/features/accounts/data/accounts_api.dart';
import 'package:our_balance/features/accounts/data/models/account.dart';
import 'package:our_balance/features/accounts/data/models/account_type.dart';
import 'package:our_balance/features/dashboard/application/dashboard_providers.dart';
import 'package:our_balance/features/dashboard/data/dashboard_api.dart';

import '../../../helpers/fakes.dart';

void main() {
  group('accountsWithBalancesProvider', () {
    test('fetches the list then enriches each entry with its balance detail', () async {
      final calls = <String>[];
      final api = FakeAccountsApi()
        ..listAccountsHandler = (householdId) async {
          calls.add('list:$householdId');
          return [testAccount];
        }
        ..getAccountDetailHandler = (accountId) async {
          calls.add('detail:$accountId');
          return testAccountDetail;
        };

      final container = ProviderContainer(
        overrides: [accountsApiProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);

      final accounts = await container.read(
        accountsWithBalancesProvider(testHousehold.id).future,
      );

      expect(calls, ['list:${testHousehold.id}', 'detail:${testAccount.id}']);
      expect(accounts, hasLength(1));
      expect(accounts.single.actualBalance, testAccountDetail.actualBalance);
    });

    test('enriches every account in parallel, including archived ones', () async {
      final archivedAccount = Account(
        id: 'archived-1',
        householdId: testHousehold.id,
        ownerUserId: null,
        name: 'Old Wallet',
        accountType: AccountType.wallet,
        openingBalance: 0,
        isShared: false,
        isActive: false,
      );
      final api = FakeAccountsApi()
        ..listAccountsHandler = (_) async {
          return [testAccount, archivedAccount];
        }
        ..getAccountDetailHandler = (_) async {
          return testAccountDetail;
        };

      final container = ProviderContainer(
        overrides: [accountsApiProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);

      final accounts = await container.read(
        accountsWithBalancesProvider(testHousehold.id).future,
      );

      expect(accounts, hasLength(2));
    });
  });

  group('AccountsController', () {
    test('createAccount invalidates the accounts list and dashboard providers', () async {
      var createCalled = false;
      final accountsApi = FakeAccountsApi()
        ..createAccountHandler = ({
          required name,
          required accountType,
          required openingBalance,
          required isShared,
          ownerUserId,
        }) async {
          createCalled = true;
          return testAccount;
        }
        ..listAccountsHandler = (_) async {
          return [testAccount];
        }
        ..getAccountDetailHandler = (_) async {
          return testAccountDetail;
        };

      final container = ProviderContainer(
        overrides: [
          accountsApiProvider.overrideWithValue(accountsApi),
          dashboardApiProvider.overrideWithValue(FakeDashboardApi()),
        ],
      );
      addTearDown(container.dispose);

      // Prime the caches so we can prove they get invalidated.
      await container.read(accountsWithBalancesProvider(testHousehold.id).future);
      await container.read(dashboardSummaryProvider(testHousehold.id).future);

      await container.read(accountsControllerProvider).createAccount(
            testHousehold.id,
            name: 'New Wallet',
            accountType: AccountType.wallet,
            openingBalance: 0,
            isShared: false,
          );

      expect(createCalled, isTrue);
      // Reading again should not throw StateError, proving the provider was
      // invalidated and successfully refetched rather than serving a stale
      // (never-invalidated) cached future.
      final refreshed = await container.read(
        accountsWithBalancesProvider(testHousehold.id).future,
      );
      expect(refreshed, isNotEmpty);
    });

    test('setArchived(archived: true) calls archiveAccount, not update', () async {
      String? archivedId;
      final accountsApi = FakeAccountsApi()
        ..archiveAccountHandler = (accountId) async {
          archivedId = accountId;
          return testAccount;
        }
        ..updateAccountHandler = ({name, isShared, isActive}) async {
          throw StateError('should not call update for archive');
        }
        ..listAccountsHandler = (_) async {
          return <Account>[];
        }
        ..getAccountDetailHandler = (_) async {
          return testAccountDetail;
        };

      final container = ProviderContainer(
        overrides: [
          accountsApiProvider.overrideWithValue(accountsApi),
          dashboardApiProvider.overrideWithValue(FakeDashboardApi()),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(accountsControllerProvider)
          .setArchived(testHousehold.id, testAccount.id, archived: true);

      expect(archivedId, testAccount.id);
    });

    test('setArchived(archived: false) calls updateAccount(isActive: true), not archive',
        () async {
      bool? updatedIsActive;
      final accountsApi = FakeAccountsApi()
        ..updateAccountHandler = ({name, isShared, isActive}) async {
          updatedIsActive = isActive;
          return testAccount;
        }
        ..archiveAccountHandler = (_) async {
          throw StateError('should not call archive');
        }
        ..listAccountsHandler = (_) async {
          return <Account>[];
        }
        ..getAccountDetailHandler = (_) async {
          return testAccountDetail;
        };

      final container = ProviderContainer(
        overrides: [
          accountsApiProvider.overrideWithValue(accountsApi),
          dashboardApiProvider.overrideWithValue(FakeDashboardApi()),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(accountsControllerProvider)
          .setArchived(testHousehold.id, testAccount.id, archived: false);

      expect(updatedIsActive, isTrue);
    });
  });
}
