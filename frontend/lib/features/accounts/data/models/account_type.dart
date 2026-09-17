import 'package:flutter/material.dart';

/// Mirrors the backend's `AccountType` enum exactly
/// (`backend/src/utils/enums.py`) — do not add/rename values here without a
/// matching backend change.
enum AccountType {
  bank,
  cash,
  wallet,
  creditCard,
  savings,
  other;

  String get apiValue => switch (this) {
        AccountType.bank => 'BANK',
        AccountType.cash => 'CASH',
        AccountType.wallet => 'WALLET',
        AccountType.creditCard => 'CREDIT_CARD',
        AccountType.savings => 'SAVINGS',
        AccountType.other => 'OTHER',
      };

  static AccountType fromApiValue(String value) => switch (value) {
        'BANK' => AccountType.bank,
        'CASH' => AccountType.cash,
        'WALLET' => AccountType.wallet,
        'CREDIT_CARD' => AccountType.creditCard,
        'SAVINGS' => AccountType.savings,
        'OTHER' => AccountType.other,
        _ => AccountType.other,
      };

  String get displayName => switch (this) {
        AccountType.bank => 'Bank account',
        AccountType.cash => 'Cash',
        AccountType.wallet => 'Wallet',
        AccountType.creditCard => 'Credit card',
        AccountType.savings => 'Savings',
        AccountType.other => 'Other',
      };

  IconData get icon => switch (this) {
        AccountType.bank => Icons.account_balance_outlined,
        AccountType.cash => Icons.payments_outlined,
        AccountType.wallet => Icons.account_balance_wallet_outlined,
        AccountType.creditCard => Icons.credit_card_outlined,
        AccountType.savings => Icons.savings_outlined,
        AccountType.other => Icons.widgets_outlined,
      };
}
