import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/account_transaction.dart';
import '../../accounts/data/accounts_api.dart';
import '../data/dashboard_api.dart';
import '../data/models/dashboard_summary.dart';

final dashboardSummaryProvider =
    FutureProvider.family<DashboardSummary, String>((ref, householdId) async {
  return ref.watch(dashboardApiProvider).getDashboardSummary(householdId);
});

/// How many most-recent transactions to show on the dashboard.
const recentActivityLimit = 10;

/// "Recent activity" across the whole household.
///
/// The backend has no combined, household-wide activity endpoint — only a
/// per-account one (`GET /accounts/{id}/transactions`). This calls that for
/// every active account in the dashboard summary (in parallel) and merges +
/// sorts the results client-side. That's list-merging for display, not a
/// financial calculation — every amount and status still comes straight
/// from the backend.
final recentActivityProvider =
    FutureProvider.family<List<AccountTransaction>, String>((ref, householdId) async {
  final summary = await ref.watch(dashboardSummaryProvider(householdId).future);
  if (summary.accounts.isEmpty) return const [];

  final api = ref.watch(accountsApiProvider);
  final perAccountResults = await Future.wait(
    summary.accounts.map((account) => api.getAccountTransactions(account.id)),
  );

  final merged = perAccountResults.expand((transactions) => transactions).toList()
    ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

  return merged.take(recentActivityLimit).toList();
});
