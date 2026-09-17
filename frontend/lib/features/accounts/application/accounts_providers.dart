import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/account_transaction.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../data/accounts_api.dart';
import '../data/models/account_detail.dart';
import '../data/models/account_type.dart';

/// All accounts in the household (active **and** archived), each enriched
/// with its computed balances.
///
/// The backend's list endpoint (`GET /households/{id}/accounts`) doesn't
/// include balances — only `GET /accounts/{id}` does — so this fetches the
/// list, then fetches each account's detail in parallel. Fine for a
/// household-sized account list (a handful of accounts, not hundreds).
final accountsWithBalancesProvider =
    FutureProvider.family<List<AccountDetail>, String>((ref, householdId) async {
  final api = ref.watch(accountsApiProvider);
  final accounts = await api.listAccounts(householdId);
  return Future.wait(accounts.map((account) => api.getAccountDetail(account.id)));
});

/// A single account's detail (balances included), for the account detail
/// page — one direct call, no need to go through the list.
final accountDetailProvider =
    FutureProvider.family<AccountDetail, String>((ref, accountId) async {
  return ref.watch(accountsApiProvider).getAccountDetail(accountId);
});

/// An account's transaction history (incomes/expenses/transfers merged by
/// the backend), most recent first.
final accountTransactionsProvider =
    FutureProvider.family<List<AccountTransaction>, String>((ref, accountId) async {
  final transactions = await ref.watch(accountsApiProvider).getAccountTransactions(accountId);
  return transactions..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
});

/// Mutations (create/edit/archive). These don't hold their own state — each
/// form manages its own local submitting/error state — they just call the
/// API and invalidate the read providers that would otherwise go stale.
class AccountsController {
  AccountsController(this._ref);

  final Ref _ref;

  Future<void> createAccount(
    String householdId, {
    required String name,
    required AccountType accountType,
    required double openingBalance,
    required bool isShared,
  }) async {
    await _ref.read(accountsApiProvider).createAccount(
          householdId,
          name: name,
          accountType: accountType,
          openingBalance: openingBalance,
          isShared: isShared,
        );
    _invalidate(householdId);
  }

  Future<void> updateAccount(
    String householdId,
    String accountId, {
    String? name,
    bool? isShared,
  }) async {
    await _ref.read(accountsApiProvider).updateAccount(accountId, name: name, isShared: isShared);
    _invalidate(householdId, accountId: accountId);
  }

  Future<void> setArchived(String householdId, String accountId, {required bool archived}) async {
    if (archived) {
      await _ref.read(accountsApiProvider).archiveAccount(accountId);
    } else {
      await _ref.read(accountsApiProvider).updateAccount(accountId, isActive: true);
    }
    _invalidate(householdId, accountId: accountId);
  }

  void _invalidate(String householdId, {String? accountId}) {
    _ref.invalidate(accountsWithBalancesProvider(householdId));
    _ref.invalidate(dashboardSummaryProvider(householdId));
    _ref.invalidate(recentActivityProvider(householdId));
    if (accountId != null) {
      _ref.invalidate(accountDetailProvider(accountId));
    }
  }
}

final accountsControllerProvider = Provider<AccountsController>(
  (ref) => AccountsController(ref),
);
