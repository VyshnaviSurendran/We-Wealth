import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_status.dart';
import '../config/app_config.dart';
import '../errors/error_mapper.dart';
import '../storage/token_storage.dart';

/// The one and only [Dio] instance for the app.
///
/// Every feature's data layer should depend on [apiClientProvider] rather
/// than constructing its own `Dio()` — that's what keeps the base URL,
/// auth header, and error handling centralized instead of duplicated.
final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      contentType: 'application/json',
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await ref.read(tokenStorageProvider).readAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Flip the coarse session flag; AuthController listens for this
          // and reacts by clearing the stored token and its own state,
          // which in turn makes the router redirect to /login.
          ref.read(authStatusProvider.notifier).markUnauthenticated();
        }
        handler.reject(
          DioException(
            requestOptions: error.requestOptions,
            error: mapDioExceptionToApiException(error),
            response: error.response,
            type: error.type,
            message: error.message,
          ),
        );
      },
    ),
  );

  if (AppConfig.enableNetworkLogging) {
    dio.interceptors.add(_RedactingLogInterceptor());
  }

  return dio;
});

/// Debug-only request/response logger.
///
/// Deliberately does **not** use [LogInterceptor] as-is: that logs request
/// headers by default, which would print the `Authorization: Bearer <token>`
/// header to the console. This also redacts `password`/`access_token`
/// fields from logged bodies, since `/auth/login` and `/auth/register`
/// bodies contain the user's plaintext password.
class _RedactingLogInterceptor extends Interceptor {
  static const _sensitiveKeys = {'password', 'new_password', 'current_password', 'access_token'};

  Object? _redact(Object? data) {
    if (data is Map) {
      return data.map(
        (key, value) => MapEntry(key, _sensitiveKeys.contains(key) ? '***' : _redact(value)),
      );
    }
    return data;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // ignore: avoid_print
    print('--> ${options.method} ${options.uri}\n${_redact(options.data)}');
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    // ignore: avoid_print
    print('<-- ${response.statusCode} ${response.requestOptions.uri}\n${_redact(response.data)}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // ignore: avoid_print
    print('<-- ERROR ${err.response?.statusCode} ${err.requestOptions.uri}\n${err.message}');
    handler.next(err);
  }
}
