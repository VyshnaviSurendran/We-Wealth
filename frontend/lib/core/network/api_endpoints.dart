/// Single source of truth for every backend path this app calls.
///
/// Paths are relative to [AppConfig.apiBaseUrl] (which already includes the
/// `/api/v1` prefix), so nothing here repeats it. Keeping every path in one
/// place means a backend route rename is a one-line fix, not a grep-and-hope.
///
/// This mirrors exactly what `GET /openapi.json` on the backend reports —
/// no endpoint below was invented; unimplemented feature areas simply have
/// no entry yet and should be added here (and only here) once built.
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String changePassword = '/auth/change-password';
  static const String updateMe = '/users/me';

  // Households
  static const String households = '/households';
  static String household(String householdId) => '/households/$householdId';
  static String householdInvitations(String householdId) =>
      '/households/$householdId/invitations';
  static String acceptInvitation(String invitationId) =>
      '/invitations/$invitationId/accept';
  static String householdMembers(String householdId) =>
      '/households/$householdId/members';
  static String householdMember(String householdId, String memberId) =>
      '/households/$householdId/members/$memberId';

  // Accounts
  static String householdAccounts(String householdId) =>
      '/households/$householdId/accounts';
  static String account(String accountId) => '/accounts/$accountId';
  static String accountTransactions(String accountId) =>
      '/accounts/$accountId/transactions';

  // Categories
  static String householdCategories(String householdId) =>
      '/households/$householdId/categories';
  static String category(String categoryId) => '/categories/$categoryId';

  // Incomes
  static String householdIncomes(String householdId) =>
      '/households/$householdId/incomes';
  static String income(String incomeId) => '/incomes/$incomeId';

  // Expenses
  static String householdExpenses(String householdId) =>
      '/households/$householdId/expenses';
  static String expense(String expenseId) => '/expenses/$expenseId';
  static String payExpense(String expenseId) => '/expenses/$expenseId/pay';

  // Transfers
  static String householdTransfers(String householdId) =>
      '/households/$householdId/transfers';
  static String transfer(String transferId) => '/transfers/$transferId';

  // Savings goals
  static String householdSavingsGoals(String householdId) =>
      '/households/$householdId/savings-goals';
  static String savingsGoal(String goalId) => '/savings-goals/$goalId';
  static String savingsGoalContributions(String goalId) =>
      '/savings-goals/$goalId/contributions';

  // Budgets
  static String householdBudgets(String householdId) =>
      '/households/$householdId/budgets';
  static String budget(String budgetId) => '/budgets/$budgetId';

  // Recurring bills
  static String householdRecurringBills(String householdId) =>
      '/households/$householdId/recurring-bills';
  static String recurringBill(String billId) => '/recurring-bills/$billId';

  // Dashboard & reports
  static String dashboardSummary(String householdId) =>
      '/households/$householdId/dashboard/summary';
  static String monthlyReport(String householdId) =>
      '/households/$householdId/reports/monthly';
}
