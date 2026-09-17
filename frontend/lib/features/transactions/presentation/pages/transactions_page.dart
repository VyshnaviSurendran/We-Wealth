import 'package:flutter/material.dart';

import '../../../../core/widgets/feature_placeholder_page.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      title: 'Transactions',
      icon: Icons.receipt_long_outlined,
    );
  }
}
