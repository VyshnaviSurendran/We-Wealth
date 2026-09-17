import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/run_api_call.dart';
import '../../../shared/models/account_transaction.dart';
import 'models/account.dart';
import 'models/account_detail.dart';
import 'models/account_type.dart';

/// Thin wrapper around the backend's `/accounts` endpoints.
///
/// Not `final` so tests can subclass it with a fake instead of mocking Dio.
class AccountsApi {
  AccountsApi(this._dio);

  final Dio _dio;

  Future<List<Account>> listAccounts(String householdId) async {
    final response = await runApiCall(
      () => _dio.get(ApiEndpoints.householdAccounts(householdId)),
    );
    return (response.data as List)
        .map((json) => Account.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<AccountDetail> getAccountDetail(String accountId) async {
    final response = await runApiCall(() => _dio.get(ApiEndpoints.account(accountId)));
    return AccountDetail.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Account> createAccount(
    String householdId, {
    required String name,
    required AccountType accountType,
    required double openingBalance,
    required bool isShared,
    String? ownerUserId,
  }) async {
    final response = await runApiCall(
      () => _dio.post(
        ApiEndpoints.householdAccounts(householdId),
        data: {
          'name': name,
          'account_type': accountType.apiValue,
          'opening_balance': openingBalance,
          'is_shared': isShared,
          'owner_user_id': ownerUserId,
        },
      ),
    );
    return Account.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Account> updateAccount(
    String accountId, {
    String? name,
    bool? isShared,
    bool? isActive,
  }) async {
    final response = await runApiCall(
      () => _dio.patch(
        ApiEndpoints.account(accountId),
        data: {
          'name': ?name,
          'is_shared': ?isShared,
          'is_active': ?isActive,
        },
      ),
    );
    return Account.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Account> archiveAccount(String accountId) async {
    final response = await runApiCall(() => _dio.delete(ApiEndpoints.account(accountId)));
    return Account.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<AccountTransaction>> getAccountTransactions(
    String accountId, {
    DateTime? fromDate,
    DateTime? toDate,
    TransactionType? transactionType,
  }) async {
    final response = await runApiCall(
      () => _dio.get(
        ApiEndpoints.accountTransactions(accountId),
        queryParameters: {
          if (fromDate != null) 'from_date': _dateOnly(fromDate),
          if (toDate != null) 'to_date': _dateOnly(toDate),
          if (transactionType != null) 'transaction_type': transactionType.apiValue,
        },
      ),
    );
    return (response.data as List)
        .map(
          (json) => AccountTransaction.fromJson(json as Map<String, dynamic>, accountId: accountId),
        )
        .toList();
  }

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

final accountsApiProvider = Provider<AccountsApi>(
  (ref) => AccountsApi(ref.watch(apiClientProvider)),
);
