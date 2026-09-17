import 'package:flutter_test/flutter_test.dart';
import 'package:our_balance/shared/models/account_transaction.dart';

void main() {
  group('AccountTransaction.fromJson', () {
    test('parses an EXPENSE entry, threading through the caller-supplied accountId', () {
      final transaction = AccountTransaction.fromJson(
        {
          'id': 'txn-1',
          'transaction_type': 'EXPENSE',
          'title': 'Groceries',
          'amount': '1500.00',
          'transaction_date': '2026-09-01',
          'status': 'PAID',
        },
        accountId: 'acc-1',
      );

      expect(transaction.transactionType, TransactionType.expense);
      expect(transaction.transactionType.isCredit, isFalse);
      expect(transaction.amount, 1500.00);
      expect(transaction.transactionDate, DateTime(2026, 9, 1));
      expect(transaction.status, 'PAID');
      expect(transaction.accountId, 'acc-1');
    });

    test('parses a TRANSFER_IN entry with a null status', () {
      final transaction = AccountTransaction.fromJson(
        {
          'id': 'txn-2',
          'transaction_type': 'TRANSFER_IN',
          'title': 'Transfer in',
          'amount': '2000.00',
          'transaction_date': '2026-09-05',
          'status': null,
        },
        accountId: 'acc-2',
      );

      expect(transaction.transactionType, TransactionType.transferIn);
      expect(transaction.transactionType.isCredit, isTrue);
      expect(transaction.status, isNull);
    });

    test('every TransactionType round-trips through apiValue/fromApiValue', () {
      for (final type in TransactionType.values) {
        expect(TransactionType.fromApiValue(type.apiValue), type);
      }
    });

    test('an unrecognized transaction_type throws rather than silently defaulting', () {
      expect(
        () => AccountTransaction.fromJson(
          {
            'id': 'txn-3',
            'transaction_type': 'SOMETHING_NEW',
            'title': 'X',
            'amount': '1.00',
            'transaction_date': '2026-09-01',
            'status': null,
          },
          accountId: 'acc-1',
        ),
        throwsFormatException,
      );
    });
  });
}
