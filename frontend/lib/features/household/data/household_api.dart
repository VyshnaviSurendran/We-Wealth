import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/run_api_call.dart';
import 'models/household.dart';

/// Thin wrapper around the backend's `/households` list endpoint.
///
/// Not `final` so tests can subclass it with a fake instead of mocking Dio.
class HouseholdApi {
  HouseholdApi(this._dio);

  final Dio _dio;

  Future<List<Household>> listHouseholds() async {
    final response = await runApiCall(() => _dio.get(ApiEndpoints.households));
    return (response.data as List)
        .map((json) => Household.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}

final householdApiProvider = Provider<HouseholdApi>(
  (ref) => HouseholdApi(ref.watch(apiClientProvider)),
);
