import '../../../../core/utils/money.dart';
import 'account_type.dart';

/// Mirrors the backend's `AccountDetailRead` schema exactly
/// (`backend/src/schemas/account.py`): every `AccountRead` field plus the
/// three balance figures the backend computes from ledger rows
/// (`actual_balance`, `pending_amount`, `safe_available_balance`) — see
/// `backend/src/services/balance_service.py`. This app never recomputes
/// these; it only formats and displays whatever the backend returns.
class AccountDetail {
  const AccountDetail({
    required this.id,
    required this.householdId,
    required this.ownerUserId,
    required this.name,
    required this.accountType,
    required this.openingBalance,
    required this.isShared,
    required this.isActive,
    required this.actualBalance,
    required this.pendingAmount,
    required this.safeAvailableBalance,
  });

  factory AccountDetail.fromJson(Map<String, dynamic> json) {
    return AccountDetail(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      ownerUserId: json['owner_user_id'] as String?,
      name: json['name'] as String,
      accountType: AccountType.fromApiValue(json['account_type'] as String),
      openingBalance: Money.parseApiAmount(json['opening_balance'] as String),
      isShared: json['is_shared'] as bool,
      isActive: json['is_active'] as bool,
      actualBalance: Money.parseApiAmount(json['actual_balance'] as String),
      pendingAmount: Money.parseApiAmount(json['pending_amount'] as String),
      safeAvailableBalance: Money.parseApiAmount(json['safe_available_balance'] as String),
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
  final double actualBalance;
  final double pendingAmount;
  final double safeAvailableBalance;
}
