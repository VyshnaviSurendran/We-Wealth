import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Coarse, core-layer session flag.
///
/// This exists purely so `core/network/api_client.dart`'s 401 interceptor
/// has something to flip without `core` depending on `features/auth` (core
/// must stay independent of features). `AuthController`
/// (`features/auth/application/auth_controller.dart`) is the real source of
/// truth for "who is logged in" — it listens to this and reacts by clearing
/// the stored token and updating its own state. UI and routing code should
/// watch `authControllerProvider`, not this.
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthStatusNotifier extends Notifier<AuthStatus> {
  @override
  AuthStatus build() => AuthStatus.unknown;

  void markAuthenticated() => state = AuthStatus.authenticated;

  void markUnauthenticated() => state = AuthStatus.unauthenticated;
}

final authStatusProvider = NotifierProvider<AuthStatusNotifier, AuthStatus>(
  AuthStatusNotifier.new,
);
