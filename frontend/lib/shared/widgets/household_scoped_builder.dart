import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/api_exception.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import '../../features/household/application/current_household_provider.dart';

/// Resolves the current household before handing control to [builder],
/// showing loading/error/no-household states in the meantime.
///
/// Every household-scoped screen (dashboard, accounts, ...) needs this same
/// resolution step, so it lives here once instead of being re-implemented
/// per page.
class HouseholdScopedBuilder extends ConsumerWidget {
  const HouseholdScopedBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, WidgetRef ref, String householdId) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdState = ref.watch(currentHouseholdProvider);

    return householdState.when(
      data: (household) {
        if (household == null) {
          return const EmptyStateView(
            icon: Icons.home_outlined,
            message: 'No household found yet.\nCreate one to start tracking your finances.',
          );
        }
        return builder(context, ref, household.id);
      },
      loading: () => const LoadingView(),
      error: (error, _) => ErrorView(
        error: error is ApiException ? error : const UnknownApiException(),
        onRetry: () => ref.invalidate(currentHouseholdProvider),
      ),
    );
  }
}
