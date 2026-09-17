import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/run_api_call.dart';
import 'models/dashboard_summary.dart';

/// Thin wrapper around the backend's `/households/{id}/dashboard/summary`
/// endpoint.
///
/// Not `final` so tests can subclass it with a fake instead of mocking Dio.
class DashboardApi {
  DashboardApi(this._dio);

  final Dio _dio;

  Future<DashboardSummary> getDashboardSummary(String householdId) async {
    final response = await runApiCall(
      () => _dio.get(ApiEndpoints.dashboardSummary(householdId)),
    );
    return DashboardSummary.fromJson(response.data as Map<String, dynamic>);
  }
}

final dashboardApiProvider = Provider<DashboardApi>(
  (ref) => DashboardApi(ref.watch(apiClientProvider)),
);
