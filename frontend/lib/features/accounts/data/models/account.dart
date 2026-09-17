import '../../../../core/utils/money.dart';
import 'account_type.dart';

/// Mirrors the backend's `AccountRead` schema exactly
/// (`backend/src/schemas/account.py`) — no balance fields here, see
/// [AccountDetail] for those (a separate backend response shape).
class Account {
  const Account({
    required this.id,
    required this.householdId,
    required this.ownerUserId,
    required this.name,
    required this.accountType,
    required this.openingBalance,
    required this.isShared,
    required this.isActive,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      ownerUserId: json['owner_user_id'] as String?,
      name: json['name'] as String,
      accountType: AccountType.fromApiValue(json['account_type'] as String),
      openingBalance: Money.parseApiAmount(json['opening_balance'] as String),
      isShared: json['is_shared'] as bool,
      isActive: json['is_active'] as bool,
    );
  }

  final String id;
  final String householdId;
  final String? ownerUserId;
  final String name;
  final AccountType accountType;
  final double openingBalance;
  final bool isShared;
  final bool isActive;
}
