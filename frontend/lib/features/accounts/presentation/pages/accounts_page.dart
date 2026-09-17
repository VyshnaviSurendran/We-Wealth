import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../shared/widgets/account_card.dart';
import '../../../../shared/widgets/household_scoped_builder.dart';
import '../../application/accounts_providers.dart';
import '../widgets/account_form_sheet.dart';

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      body: HouseholdScopedBuilder(
        builder: (context, ref, householdId) => _AccountsList(householdId: householdId),
      ),
      floatingActionButton: HouseholdScopedBuilder(
        builder: (context, ref, householdId) => FloatingActionButton(
          onPressed: () => showCreateAccountSheet(context, householdId: householdId),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _AccountsList extends ConsumerWidget {
  const _AccountsList({required this.householdId});

  final String householdId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsState = ref.watch(accountsWithBalancesProvider(householdId));

    return accountsState.when(
      loading: () => const LoadingView(message: 'Loading accounts...'),
      error: (error, _) => ErrorView(
        error: error is ApiException ? error : const UnknownApiException(),
        onRetry: () => ref.invalidate(accountsWithBalancesProvider(householdId)),
      ),
      data: (accounts) {
        if (accounts.isEmpty) {
          return const EmptyStateView(
            icon: Icons.account_balance_outlined,
            message: 'No accounts yet.\nTap + to add your first bank account or wallet.',
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(accountsWithBalancesProvider(householdId));
            await ref.read(accountsWithBalancesProvider(householdId).future);
          },
          child: GridView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 480,
              mainAxisExtent: 128,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            children: [
              for (final account in accounts)
                AccountCard(
                  account: account,
                  onTap: () => context.push('/accounts/${account.id}'),
                ),
            ],
          ),
        );
      },
    );
  }
}
