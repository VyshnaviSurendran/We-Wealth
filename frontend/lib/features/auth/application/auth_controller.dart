import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_status.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_api.dart';
import '../data/models/auth_user.dart';

/// Single source of truth for "who is logged in", used by the router to
/// gate routes and by any screen that needs the current user.
///
/// State meaning:
/// - `AsyncLoading` — restoring the session at app startup.
/// - `AsyncData(null)` — unauthenticated (no token, or a login/registration
///   attempt hasn't succeeded yet).
/// - `AsyncData(user)` — authenticated.
/// - `AsyncError` — startup session restore failed for a reason other than
///   "no/invalid token" (e.g. no network reaching `/auth/me`) — the splash
///   screen shows a retry for this case rather than silently signing the
///   user out over a transient failure.
///
/// [login] and [register] intentionally do *not* route their own failures
/// through this shared state — they rethrow so the calling form can show an
/// inline, field-level error without the whole app reacting.
class AuthController extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    // If the network layer sees a 401 on any request, react by clearing the
    // stale token and resetting to unauthenticated (this is what makes the
    // router redirect to /login mid-session, e.g. once the token expires).
    ref.listen<AuthStatus>(authStatusProvider, (previous, next) async {
      if (next == AuthStatus.unauthenticated && (state.valueOrNull != null)) {
        await ref.read(tokenStorageProvider).clearAccessToken();
        state = const AsyncData(null);
      }
    });

    return _restoreSession();
  }

  Future<AuthUser?> _restoreSession() async {
    final token = await ref.read(tokenStorageProvider).readAccessToken();
    if (token == null) {
      ref.read(authStatusProvider.notifier).markUnauthenticated();
      return null;
    }

    try {
      final user = await ref.read(authApiProvider).currentUser();
      ref.read(authStatusProvider.notifier).markAuthenticated();
      return user;
    } on AuthException {
      await ref.read(tokenStorageProvider).clearAccessToken();
      ref.read(authStatusProvider.notifier).markUnauthenticated();
      return null;
    }
    // Any other ApiException (network/server) propagates and becomes
    // AsyncError — see class doc.
  }

  Future<void> login({required String email, required String password}) async {
    final result = await ref.read(authApiProvider).login(email: email, password: password);
    await ref.read(tokenStorageProvider).saveAccessToken(result.accessToken);
    ref.read(authStatusProvider.notifier).markAuthenticated();
    state = AsyncData(result.user);
  }

  /// Creates the account, then immediately logs in with the same
  /// credentials — `/auth/register` only creates the user and does not
  /// return a token, so a separate login call is required to establish a
  /// session.
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await ref.read(authApiProvider).register(name: name, email: email, password: password);
    await login(email: email, password: password);
  }

  Future<void> logout() async {
    await ref.read(tokenStorageProvider).clearAccessToken();
    ref.read(authStatusProvider.notifier).markUnauthenticated();
    state = const AsyncData(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthUser?>(
  AuthController.new,
);
