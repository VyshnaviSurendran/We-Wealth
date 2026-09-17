import 'package:flutter/material.dart';

import '../../core/utils/money.dart';

/// Mirrors the backend's `TransactionType` enum exactly
/// (`backend/src/schemas/transaction.py`).
enum TransactionType {
  income,
  expense,
  transferIn,
  transferOut;

  static TransactionType fromApiValue(String value) => switch (value) {
        'INCOME' => TransactionType.income,
        'EXPENSE' => TransactionType.expense,
        'TRANSFER_IN' => TransactionType.transferIn,
        'TRANSFER_OUT' => TransactionType.transferOut,
        _ => throw FormatException('Unknown transaction_type: $value'),
      };

  String get apiValue => switch (this) {
        TransactionType.income => 'INCOME',
        TransactionType.expense => 'EXPENSE',
        TransactionType.transferIn => 'TRANSFER_IN',
        TransactionType.transferOut => 'TRANSFER_OUT',
      };

  /// Whether this entry increases (true) or decreases (false) the account's
  /// balance — purely a display concern (icon direction/color), not a
  /// recomputation of any balance the backend already gives us.
  bool get isCredit => this == TransactionType.income || this == TransactionType.transferIn;

  IconData get icon => switch (this) {
        TransactionType.income => Icons.arrow_downward_rounded,
        TransactionType.expense => Icons.arrow_upward_rounded,
        TransactionType.transferIn => Icons.call_received_rounded,
        TransactionType.transferOut => Icons.call_made_rounded,
      };
}

/// Mirrors the backend's `TransactionRead` schema exactly
/// (`backend/src/schemas/transaction.py`) — this is a read-only, unified
/// view over an account's incomes/expenses/transfers, not a stored ledger
/// row of its own.
class AccountTransaction {
  const AccountTransaction({
    required this.id,
    required this.transactionType,
    required this.title,
    required this.amount,
    required this.transactionDate,
    required this.status,
    required this.accountId,
  });

  factory AccountTransaction.fromJson(Map<String, dynamic> json, {required String accountId}) {
    return AccountTransaction(
      id: json['id'] as String,
      transactionType: TransactionType.fromApiValue(json['transaction_type'] as String),
      title: json['title'] as String,
      amount: Money.parseApiAmount(json['amount'] as String),
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      status: json['status'] as String?,
      accountId: accountId,
    );
  }

  final String id;
  final TransactionType transactionType;
  final String title;
  final double amount;
  final DateTime transactionDate;
  final String? status;

  /// Not part of the backend payload — threaded through by the caller so a
  /// merged, multi-account feed (e.g. dashboard "recent activity") can still
  /// tell which account each entry came from.
  final String accountId;
}
