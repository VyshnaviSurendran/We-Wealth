import 'package:flutter_test/flutter_test.dart';
import 'package:our_balance/features/dashboard/data/models/dashboard_summary.dart';

Map<String, dynamic> _accountJson({required String id, required bool isActive}) => {
      'id': id,
      'household_id': 'house-1',
      'owner_user_id': null,
      'name': 'Account $id',
      'account_type': 'BANK',
      'opening_balance': '0.00',
      'is_shared': true,
      'is_active': isActive,
      'actual_balance': '1000.00',
      'pending_amount': '0.00',
      'safe_available_balance': '1000.00',
    };

void main() {
  group('DashboardSummary.fromJson', () {
    test('parses every top-level total from decimal-as-string fields', () {
      final summary = DashboardSummary.fromJson({
        'household_id': 'house-1',
        'total_actual_balance': '42500.00',
        'total_pending_amount': '5000.00',
        'total_safe_available_balance': '37500.00',
        'month_income_received': '60000.00',
        'month_expenses_paid': '20000.00',
        'month_pending_expenses': '5000.00',
        'net_worth': '42500.00',
        'accounts': [_accountJson(id: 'acc-1', isActive: true)],
      });

      expect(summary.householdId, 'house-1');
      expect(summary.totalActualBalance, 42500.00);
      expect(summary.totalPendingAmount, 5000.00);
      expect(summary.totalSafeAvailableBalance, 37500.00);
      expect(summary.monthIncomeReceived, 60000.00);
      expect(summary.monthExpensesPaid, 20000.00);
      expect(summary.monthPendingExpenses, 5000.00);
      expect(summary.netWorth, 42500.00);
      expect(summary.accounts, hasLength(1));
      expect(summary.accounts.single.id, 'acc-1');
    });

    test('monthNetCashFlow is income minus expenses (display-only, not a backend field)', () {
      final summary = DashboardSummary.fromJson({
        'household_id': 'house-1',
        'total_actual_balance': '0.00',
        'total_pending_amount': '0.00',
        'total_safe_available_balance': '0.00',
        'month_income_received': '60000.00',
        'month_expenses_paid': '45000.00',
        'month_pending_expenses': '0.00',
        'net_worth': '0.00',
        'accounts': [],
      });

      expect(summary.monthNetCashFlow, 15000.00);
    });

    test('parses an empty accounts list', () {
      final summary = DashboardSummary.fromJson({
        'household_id': 'house-1',
        'total_actual_balance': '0.00',
        'total_pending_amount': '0.00',
        'total_safe_available_balance': '0.00',
        'month_income_received': '0.00',
        'month_expenses_paid': '0.00',
        'month_pending_expenses': '0.00',
        'net_worth': '0.00',
        'accounts': [],
      });

      expect(summary.accounts, isEmpty);
    });
  });
}
