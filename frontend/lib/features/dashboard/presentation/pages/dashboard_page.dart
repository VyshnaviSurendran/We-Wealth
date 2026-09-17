import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../shared/widgets/account_card.dart';
import '../../../../shared/widgets/balance_card.dart';
import '../../../../shared/widgets/household_scoped_builder.dart';
import '../../../accounts/data/models/account_detail.dart';
import '../../application/dashboard_providers.dart';
import '../widgets/recent_activity_tile.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: HouseholdScopedBuilder(
        builder: (context, ref, householdId) => _DashboardContent(householdId: householdId),
      ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({required this.householdId});

  final String householdId;

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(dashboardSummaryProvider(householdId));
    ref.invalidate(recentActivityProvider(householdId));
    await ref.read(dashboardSummaryProvider(householdId).future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryState = ref.watch(dashboardSummaryProvider(householdId));

    return summaryState.when(
      loading: () => const LoadingView(message: 'Loading dashboard...'),
      error: (error, _) => ErrorView(
        error: error is ApiException ? error : const UnknownApiException(),
        onRetry: () => ref.invalidate(dashboardSummaryProvider(householdId)),
      ),
      data: (summary) {
        final wide = isWideScreen(context);
        final accountsSection = _AccountsSection(householdId: householdId, accounts: summary.accounts);
        final activitySection = _RecentActivitySection(householdId: householdId);

        return RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Balances', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    BalanceCard(
                      label: 'Actual balance',
                      amount: summary.totalActualBalance,
                      icon: Icons.account_balance_outlined,
                    ),
                    BalanceCard(
                      label: 'Pending amount',
                      amount: summary.totalPendingAmount,
                      icon: Icons.schedule_outlined,
                    ),
                    BalanceCard(
                      label: 'Safe available balance',
                      amount: summary.totalSafeAvailableBalance,
                      icon: Icons.verified_outlined,
                    ),
                    BalanceCard(
                      label: 'Net worth',
                      amount: summary.netWorth,
                      icon: Icons.trending_up_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('This month', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    BalanceCard(
                      label: 'Income received',
                      amount: summary.monthIncomeReceived,
                      icon: Icons.arrow_downward_rounded,
                    ),
                    BalanceCard(
                      label: 'Expenses paid',
                      amount: summary.monthExpensesPaid,
                      icon: Icons.arrow_upward_rounded,
                    ),
                    BalanceCard(
                      label: 'Pending expenses',
                      amount: summary.monthPendingExpenses,
                      icon: Icons.hourglass_empty_rounded,
                    ),
                    BalanceCard(
                      label: 'Net this month',
                      amount: summary.monthNetCashFlow,
                      icon: Icons.swap_vert_rounded,
                      colorBySign: true,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (wide)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: accountsSection),
                        const SizedBox(width: 24),
                        Expanded(flex: 2, child: activitySection),
                      ],
                    ),
                  )
                else ...[
                  accountsSection,
                  const SizedBox(height: 24),
                  activitySection,
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AccountsSection extends StatelessWidget {
  const _AccountsSection({required this.householdId, required this.accounts});

  final String householdId;
  final List<AccountDetail> accounts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Account-wise balances', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (accounts.isEmpty)
          const EmptyStateView(
            icon: Icons.account_balance_outlined,
            message: 'No active accounts yet.',
          )
        else
          for (final account in accounts) ...[
            AccountCard(
              account: account,
              onTap: () => context.push('/accounts/${account.id}'),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _RecentActivitySection extends ConsumerWidget {
  const _RecentActivitySection({required this.householdId});

  final String householdId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityState = ref.watch(recentActivityProvider(householdId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent activity', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        activityState.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: LoadingView(),
          ),
          error: (error, _) => ErrorView(
            error: error is ApiException ? error : const UnknownApiException(),
            onRetry: () => ref.invalidate(recentActivityProvider(householdId)),
          ),
          data: (transactions) {
            if (transactions.isEmpty) {
              return const EmptyStateView(
                icon: Icons.receipt_long_outlined,
                message: 'No activity yet.',
              );
            }
            return Card(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final transaction in transactions)
                    RecentActivityTile(transaction: transaction),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
