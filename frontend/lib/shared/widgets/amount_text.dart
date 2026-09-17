import 'package:flutter/material.dart';

import '../../core/utils/money.dart';

/// Formats an amount with the app's currency (INR by default) and,
/// optionally, colors it green/red by sign — used for transaction lists
/// where credits and debits need to be visually distinct.
class AmountText extends StatelessWidget {
  const AmountText(
    this.amount, {
    super.key,
    this.style,
    this.colorBySign = false,
  });

  final double amount;
  final TextStyle? style;

  /// When true, positive amounts render in the theme's success-ish green
  /// and negative amounts in the theme's error color.
  final bool colorBySign;

  @override
  Widget build(BuildContext context) {
    Color? color;
    if (colorBySign) {
      final scheme = Theme.of(context).colorScheme;
      color = amount < 0 ? scheme.error : Colors.green.shade700;
    }
    return Text(Money.format(amount), style: (style ?? const TextStyle()).copyWith(color: color));
  }
}
