import 'package:flutter/material.dart';

import '../../core/utils/money.dart';
import '../../features/accounts/data/models/account_detail.dart';
import 'amount_text.dart';

/// Card for one account, showing its type, actual balance, and safe
/// available balance — used on both the Accounts list and the Dashboard's
/// account-wise balances section.
class AccountCard extends StatelessWidget {
  const AccountCard({super.key, required this.account, this.onTap});

  final AccountDetail account;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(account.accountType.icon, color: colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            account.name,
                            style: Theme.of(context).textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!account.isActive) ...[
                          const SizedBox(width: 8),
                          Chip(
                            label: const Text('Archived'),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '${account.accountType.displayName}'
                      '${account.isShared ? ' · Shared' : ' · Personal'}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colorScheme.outline),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AmountText(
                    account.actualBalance,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (account.pendingAmount != 0)
                    Text(
                      'Safe: ${Money.format(account.safeAvailableBalance)}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colorScheme.outline),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
