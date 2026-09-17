import 'package:flutter_test/flutter_test.dart';
import 'package:our_balance/features/accounts/data/models/account.dart';
import 'package:our_balance/features/accounts/data/models/account_detail.dart';
import 'package:our_balance/features/accounts/data/models/account_type.dart';

void main() {
  group('Account.fromJson', () {
    test('parses a full AccountRead payload, including the decimal-as-string balance', () {
      final account = Account.fromJson({
        'id': 'acc-1',
        'household_id': 'house-1',
        'owner_user_id': null,
        'name': 'HDFC Bank',
        'account_type': 'BANK',
        'opening_balance': '25000.00',
        'is_shared': true,
        'is_active': true,
      });

      expect(account.id, 'acc-1');
      expect(account.householdId, 'house-1');
      expect(account.ownerUserId, isNull);
      expect(account.name, 'HDFC Bank');
      expect(account.accountType, AccountType.bank);
      expect(account.openingBalance, 25000.00);
      expect(account.isShared, isTrue);
      expect(account.isActive, isTrue);
    });

    test('parses a non-null owner_user_id and every AccountType value', () {
      for (final entry in {
        'BANK': AccountType.bank,
        'CASH': AccountType.cash,
        'WALLET': AccountType.wallet,
        'CREDIT_CARD': AccountType.creditCard,
        'SAVINGS': AccountType.savings,
        'OTHER': AccountType.other,
      }.entries) {
        final account = Account.fromJson({
          'id': 'acc-1',
          'household_id': 'house-1',
          'owner_user_id': 'user-1',
          'name': 'X',
          'account_type': entry.key,
          'opening_balance': '0.00',
          'is_shared': false,
          'is_active': false,
        });
        expect(account.accountType, entry.value, reason: entry.key);
        expect(account.ownerUserId, 'user-1');
      }
    });
  });

  group('AccountDetail.fromJson', () {
    test('parses AccountDetailRead, including the three computed balance fields', () {
      final detail = AccountDetail.fromJson({
        'id': 'acc-1',
        'household_id': 'house-1',
        'owner_user_id': null,
        'name': 'HDFC Bank',
        'account_type': 'BANK',
        'opening_balance': '25000.00',
        'is_shared': true,
        'is_active': true,
        'actual_balance': '42500.50',
        'pending_amount': '5000.00',
        'safe_available_balance': '37500.50',
      });

      expect(detail.actualBalance, 42500.50);
      expect(detail.pendingAmount, 5000.00);
      expect(detail.safeAvailableBalance, 37500.50);
    });

    test('parses a negative safe_available_balance (pending exceeds actual balance)', () {
      final detail = AccountDetail.fromJson({
        'id': 'acc-1',
        'household_id': 'house-1',
        'owner_user_id': null,
        'name': 'Credit Card',
        'account_type': 'CREDIT_CARD',
        'opening_balance': '0.00',
        'is_shared': false,
        'is_active': true,
        'actual_balance': '-1200.00',
        'pending_amount': '300.00',
        'safe_available_balance': '-1500.00',
      });

      expect(detail.actualBalance, -1200.00);
      expect(detail.safeAvailableBalance, -1500.00);
    });
  });
}
