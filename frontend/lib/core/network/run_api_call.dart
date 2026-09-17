import 'package:dio/dio.dart';

import '../errors/api_exception.dart';

/// Wraps a Dio call so callers only ever have to catch [ApiException].
///
/// [apiClientProvider]'s error interceptor already converts every
/// [DioException] into an [ApiException] and stashes it in
/// `DioException.error`; this just unwraps that so feature data layers
/// never need to know Dio's exception type exists.
///
/// Usage:
/// ```dart
/// final response = await runApiCall(() => dio.get(ApiEndpoints.me));
/// ```
Future<T> runApiCall<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on DioException catch (error) {
    final mapped = error.error;
    if (mapped is ApiException) {
      throw mapped;
    }
    rethrow;
  }
}
