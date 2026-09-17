import 'package:flutter/material.dart';

import '../../../../shared/models/account_transaction.dart';
import '../../../../shared/widgets/amount_text.dart';

/// One row in the dashboard's "Recent activity" feed.
class RecentActivityTile extends StatelessWidget {
  const RecentActivityTile({super.key, required this.transaction});

  final AccountTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final type = transaction.transactionType;
    final colorScheme = Theme.of(context).colorScheme;
    final signedAmount = type.isCredit ? transaction.amount : -transaction.amount;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: type.isCredit
            ? Colors.green.shade100
            : colorScheme.errorContainer,
        child: Icon(
          type.icon,
          size: 18,
          color: type.isCredit ? Colors.green.shade800 : colorScheme.onErrorContainer,
        ),
      ),
      title: Text(transaction.title, overflow: TextOverflow.ellipsis),
      subtitle: Text(_formatDate(transaction.transactionDate)),
      trailing: AmountText(
        signedAmount,
        colorBySign: true,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
