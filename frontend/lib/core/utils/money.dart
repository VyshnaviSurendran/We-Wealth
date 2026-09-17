import '../config/app_config.dart';

/// Money helpers for talking to a backend that serializes `Decimal` fields
/// as JSON strings (e.g. `"1234.50"`), not numbers.
///
/// Kept dependency-free on purpose (no `intl`) since simple grouped
/// formatting is all this app needs right now.
class Money {
  Money._();

  /// Parses an amount as returned by the API (a decimal string).
  static double parseApiAmount(String raw) => double.parse(raw);

  /// Formats an amount for display with the app's currency symbol and
  /// thousands separators, e.g. `1234.5` -> `₹1,234.50`.
  static String format(num amount, {String symbol = AppConfig.currencySymbol}) {
    final isNegative = amount < 0;
    final fixed = amount.abs().toStringAsFixed(2);
    final parts = fixed.split('.');
    final grouped = _groupThousands(parts[0]);
    return '${isNegative ? '-' : ''}$symbol$grouped.${parts[1]}';
  }

  static String _groupThousands(String digits) {
    final buffer = StringBuffer();
    final offset = digits.length % 3;
    for (var i = 0; i < digits.length; i++) {
      if (i != 0 && (i - offset) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
