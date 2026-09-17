import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../shared/widgets/amount_text.dart';
import '../../../dashboard/presentation/widgets/recent_activity_tile.dart';
import '../../application/accounts_providers.dart';
import '../../data/models/account_detail.dart';
import '../widgets/account_form_sheet.dart';

class AccountDetailPage extends ConsumerWidget {
  const AccountDetailPage({super.key, required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(accountDetailProvider(accountId));

    return Scaffold(
      appBar: AppBar(title: Text(detailState.valueOrNull?.name ?? 'Account')),
      body: detailState.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          error: error is ApiException ? error : const UnknownApiException(),
          onRetry: () => ref.invalidate(accountDetailProvider(accountId)),
        ),
        data: (account) => _AccountDetailBody(account: account),
      ),
    );
  }
}

class _AccountDetailBody extends ConsumerWidget {
  const _AccountDetailBody({required this.account});

  final AccountDetail account;

  Future<void> _confirmArchive(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive this account?'),
        content: const Text(
          'Archived accounts are hidden from the dashboard but kept for your records. '
          'You can unarchive it later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(accountsControllerProvider)
          .setArchived(account.householdId, account.id, archived: true);
    }
  }

  Future<void> _unarchive(WidgetRef ref) async {
    await ref
        .read(accountsControllerProvider)
        .setArchived(account.householdId, account.id, archived: false);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(accountDetailProvider(account.id));
        ref.invalidate(accountTransactionsProvider(account.id));
        await ref.read(accountDetailProvider(account.id).future);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(account.accountType.icon, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(account.accountType.displayName),
                      const Spacer(),
                      if (!account.isActive) const Chip(label: Text('Archived')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _BalanceRow(label: 'Actual balance', amount: account.actualBalance),
                  _BalanceRow(label: 'Pending amount', amount: account.pendingAmount),
                  _BalanceRow(
                    label: 'Safe available balance',
                    amount: account.safeAvailableBalance,
                  ),
                  const Divider(height: 24),
                  _BalanceRow(label: 'Opening balance', amount: account.openingBalance),
                  const SizedBox(height: 8),
                  Text(
                    account.isShared ? 'Shared with partner' : 'Personal account',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showEditAccountSheet(context, account: account),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: account.isActive
                    ? OutlinedButton.icon(
                        onPressed: () => _confirmArchive(context, ref),
                        icon: const Icon(Icons.archive_outlined),
                        label: const Text('Archive'),
                      )
                    : FilledButton.icon(
                        onPressed: () => _unarchive(ref),
                        icon: const Icon(Icons.unarchive_outlined),
                        label: const Text('Unarchive'),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Transaction history', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _TransactionHistory(accountId: account.id),
        ],
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({required this.label, required this.amount});

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          AmountText(amount, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _TransactionHistory extends ConsumerWidget {
  const _TransactionHistory({required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsState = ref.watch(accountTransactionsProvider(accountId));

    return transactionsState.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: LoadingView(),
      ),
      error: (error, _) => ErrorView(
        error: error is ApiException ? error : const UnknownApiException(),
        onRetry: () => ref.invalidate(accountTransactionsProvider(accountId)),
      ),
      data: (transactions) {
        if (transactions.isEmpty) {
          return const EmptyStateView(
            icon: Icons.receipt_long_outlined,
            message: 'No transactions on this account yet.',
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
    );
  }
}
