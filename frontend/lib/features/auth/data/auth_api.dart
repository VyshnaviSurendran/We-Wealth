import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/run_api_call.dart';
import 'models/auth_user.dart';

/// Result of a successful login/registration+login: what the app needs to
/// persist (the token) and display (the user).
class LoginResult {
  const LoginResult({required this.accessToken, required this.user});

  final String accessToken;
  final AuthUser user;
}

/// Thin wrapper around the backend's `/auth/*` endpoints.
///
/// Intentionally not `final`/`sealed` so tests can subclass it and override
/// individual methods with fakes instead of mocking Dio.
class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await runApiCall(
      () => _dio.post(
        ApiEndpoints.register,
        data: {'name': name, 'email': email, 'password': password},
      ),
    );
    return AuthUser.fromJson(response.data as Map<String, dynamic>);
  }

  Future<LoginResult> login({required String email, required String password}) async {
    final response = await runApiCall(
      () => _dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      ),
    );
    final data = response.data as Map<String, dynamic>;
    return LoginResult(
      accessToken: data['access_token'] as String,
      user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<AuthUser> currentUser() async {
    final response = await runApiCall(() => _dio.get(ApiEndpoints.me));
    return AuthUser.fromJson(response.data as Map<String, dynamic>);
  }
}

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.watch(apiClientProvider)));
