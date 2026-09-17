import 'package:dio/dio.dart';
import 'package:our_balance/core/errors/api_exception.dart';
import 'package:our_balance/core/storage/token_storage.dart';
import 'package:our_balance/features/accounts/data/accounts_api.dart';
import 'package:our_balance/features/accounts/data/models/account.dart';
import 'package:our_balance/features/accounts/data/models/account_detail.dart';
import 'package:our_balance/features/accounts/data/models/account_type.dart';
import 'package:our_balance/features/auth/data/auth_api.dart';
import 'package:our_balance/features/auth/data/models/auth_user.dart';
import 'package:our_balance/features/dashboard/data/dashboard_api.dart';
import 'package:our_balance/features/dashboard/data/models/dashboard_summary.dart';
import 'package:our_balance/features/household/data/household_api.dart';
import 'package:our_balance/features/household/data/models/household.dart';
import 'package:our_balance/shared/models/account_transaction.dart';

/// In-memory [TokenStorage] double — never touches the platform channel
/// that the real `flutter_secure_storage` implementation needs, so it's
/// safe to use in plain `flutter_test` widget tests.
class FakeTokenStorage extends TokenStorage {
  FakeTokenStorage({String? initialToken}) : _token = initialToken;

  String? _token;

  @override
  Future<String?> readAccessToken() async => _token;

  @override
  Future<void> saveAccessToken(String token) async => _token = token;

  @override
  Future<void> clearAccessToken() async => _token = null;
}

const testUser = AuthUser(
  id: '11111111-1111-1111-1111-111111111111',
  name: 'Test User',
  email: 'test@example.com',
  phone: null,
  isActive: true,
);

/// Configurable [AuthApi] double — lets tests script exactly what each
/// endpoint call does without needing a real backend or mocking Dio.
class FakeAuthApi extends AuthApi {
  FakeAuthApi() : super(Dio());

  Future<AuthUser> Function({
    required String name,
    required String email,
    required String password,
  })? registerHandler;

  Future<LoginResult> Function({required String email, required String password})? loginHandler;

  Future<AuthUser> Function()? currentUserHandler;

  @override
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) {
    final handler = registerHandler;
    if (handler == null) {
      throw StateError('registerHandler not set');
    }
    return handler(name: name, email: email, password: password);
  }

  @override
  Future<LoginResult> login({required String email, required String password}) {
    final handler = loginHandler;
    if (handler == null) {
      throw StateError('loginHandler not set');
    }
    return handler(email: email, password: password);
  }

  @override
  Future<AuthUser> currentUser() {
    final handler = currentUserHandler;
    if (handler == null) {
      throw StateError('currentUserHandler not set');
    }
    return handler();
  }
}

/// Convenience: an [AuthException] with a specific message, as
/// `error_mapper.dart` would produce for a 401 response.
ApiException authError([String message = 'Invalid email or password']) =>
    AuthException(message);

const testHousehold = Household(
  id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  name: 'Test Household',
  createdBy: '11111111-1111-1111-1111-111111111111',
  currency: 'INR',
  timezone: 'Asia/Kolkata',
);

/// Configurable [HouseholdApi] double.
class FakeHouseholdApi extends HouseholdApi {
  FakeHouseholdApi({this.households = const [testHousehold]}) : super(Dio());

  List<Household> households;

  @override
  Future<List<Household>> listHouseholds() async => households;
}

final testAccount = Account(
  id: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  householdId: testHousehold.id,
  ownerUserId: null,
  name: 'HDFC Bank',
  accountType: AccountType.bank,
  openingBalance: 25000,
  isShared: true,
  isActive: true,
);

final testAccountDetail = AccountDetail(
  id: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  householdId: testHousehold.id,
  ownerUserId: null,
  name: 'HDFC Bank',
  accountType: AccountType.bank,
  openingBalance: 25000,
  isShared: true,
  isActive: true,
  actualBalance: 42500,
  pendingAmount: 5000,
  safeAvailableBalance: 37500,
);

/// Configurable [AccountsApi] double.
class FakeAccountsApi extends AccountsApi {
  FakeAccountsApi() : super(Dio());

  Future<List<Account>> Function(String householdId)? listAccountsHandler;
  Future<AccountDetail> Function(String accountId)? getAccountDetailHandler;
  Future<Account> Function({
    required String name,
    required AccountType accountType,
    required double openingBalance,
    required bool isShared,
    String? ownerUserId,
  })? createAccountHandler;
  Future<Account> Function({String? name, bool? isShared, bool? isActive})? updateAccountHandler;
  Future<Account> Function(String accountId)? archiveAccountHandler;
  Future<List<AccountTransaction>> Function(String accountId)? getAccountTransactionsHandler;

  @override
  Future<List<Account>> listAccounts(String householdId) {
    final handler = listAccountsHandler;
    if (handler == null) throw StateError('listAccountsHandler not set');
    return handler(householdId);
  }

  @override
  Future<AccountDetail> getAccountDetail(String accountId) {
    final handler = getAccountDetailHandler;
    if (handler == null) throw StateError('getAccountDetailHandler not set');
    return handler(accountId);
  }

  @override
  Future<Account> createAccount(
    String householdId, {
    required String name,
    required AccountType accountType,
    required double openingBalance,
    required bool isShared,
    String? ownerUserId,
  }) {
    final handler = createAccountHandler;
    if (handler == null) throw StateError('createAccountHandler not set');
    return handler(
      name: name,
      accountType: accountType,
      openingBalance: openingBalance,
      isShared: isShared,
      ownerUserId: ownerUserId,
    );
  }

  @override
  Future<Account> updateAccount(String accountId, {String? name, bool? isShared, bool? isActive}) {
    final handler = updateAccountHandler;
    if (handler == null) throw StateError('updateAccountHandler not set');
    return handler(name: name, isShared: isShared, isActive: isActive);
  }

  @override
  Future<Account> archiveAccount(String accountId) {
    final handler = archiveAccountHandler;
    if (handler == null) throw StateError('archiveAccountHandler not set');
    return handler(accountId);
  }

  @override
  Future<List<AccountTransaction>> getAccountTransactions(
    String accountId, {
    DateTime? fromDate,
    DateTime? toDate,
    TransactionType? transactionType,
  }) {
    final handler = getAccountTransactionsHandler;
    if (handler == null) throw StateError('getAccountTransactionsHandler not set');
    return handler(accountId);
  }
}

final testDashboardSummary = DashboardSummary(
  householdId: testHousehold.id,
  totalActualBalance: 42500,
  totalPendingAmount: 5000,
  totalSafeAvailableBalance: 37500,
  monthIncomeReceived: 60000,
  monthExpensesPaid: 20000,
  monthPendingExpenses: 5000,
  netWorth: 42500,
  accounts: [testAccountDetail],
);

/// Configurable [DashboardApi] double. Pass [summary] for the happy path or
/// [error] to script a failure instead.
class FakeDashboardApi extends DashboardApi {
  FakeDashboardApi({DashboardSummary? summary, this.error})
      : summary = summary ?? testDashboardSummary,
        super(Dio());

  DashboardSummary summary;
  ApiException? error;

  @override
  Future<DashboardSummary> getDashboardSummary(String householdId) async {
    final scriptedError = error;
    if (scriptedError != null) throw scriptedError;
    return summary;
  }
}

final testTransaction = AccountTransaction(
  id: 'cccccccc-cccc-cccc-cccc-cccccccccccc',
  transactionType: TransactionType.expense,
  title: 'Groceries',
  amount: 1500,
  transactionDate: DateTime(2026, 9, 1),
  status: 'PAID',
  accountId: testAccountDetail.id,
);
