import '../../../../core/utils/money.dart';
import '../../../accounts/data/models/account_detail.dart';

/// Mirrors the backend's `DashboardSummary` schema exactly
/// (`backend/src/schemas/dashboard.py`). Every total here is computed by
/// the backend (`dashboard_service.get_dashboard_summary`) — this app only
/// formats and displays these numbers, it never recomputes balances.
class DashboardSummary {
  const DashboardSummary({
    required this.householdId,
    required this.totalActualBalance,
    required this.totalPendingAmount,
    required this.totalSafeAvailableBalance,
    required this.monthIncomeReceived,
    required this.monthExpensesPaid,
    required this.monthPendingExpenses,
    required this.netWorth,
    required this.accounts,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      householdId: json['household_id'] as String,
      totalActualBalance: Money.parseApiAmount(json['total_actual_balance'] as String),
      totalPendingAmount: Money.parseApiAmount(json['total_pending_amount'] as String),
      totalSafeAvailableBalance:
          Money.parseApiAmount(json['total_safe_available_balance'] as String),
      monthIncomeReceived: Money.parseApiAmount(json['month_income_received'] as String),
      monthExpensesPaid: Money.parseApiAmount(json['month_expenses_paid'] as String),
      monthPendingExpenses: Money.parseApiAmount(json['month_pending_expenses'] as String),
      netWorth: Money.parseApiAmount(json['net_worth'] as String),
      accounts: (json['accounts'] as List)
          .map((account) => AccountDetail.fromJson(account as Map<String, dynamic>))
          .toList(),
    );
  }

  final String householdId;
  final double totalActualBalance;
  final double totalPendingAmount;
  final double totalSafeAvailableBalance;
  final double monthIncomeReceived;
  final double monthExpensesPaid;
  final double monthPendingExpenses;
  final double netWorth;

  /// Only **active** accounts — the backend filters archived ones out of
  /// this list (see `dashboard_service.get_dashboard_summary`).
  final List<AccountDetail> accounts;

  /// Display-only: the difference between two numbers the backend already
  /// computed. Not a new financial calculation — just arithmetic for a
  /// single "net this month" summary line, since the backend has no
  /// dedicated cash-flow field.
  double get monthNetCashFlow => monthIncomeReceived - monthExpensesPaid;
}
