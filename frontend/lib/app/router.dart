import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/accounts/presentation/pages/account_detail_page.dart';
import '../features/accounts/presentation/pages/accounts_page.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/reports/presentation/pages/reports_page.dart';
import '../features/savings/presentation/pages/savings_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/transactions/presentation/pages/transactions_page.dart';
import 'navigation_shell.dart';

const _authRoutes = {'/login', '/register'};

/// Bridges Riverpod's [authControllerProvider] to GoRouter's
/// `refreshListenable`, so the router re-evaluates `redirect` every time the
/// session state changes (login, logout, session-expired, etc.) — not just
/// on navigation.
class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(Ref ref) {
    ref.listen<AsyncValue<Object?>>(
      authControllerProvider,
      (previous, next) => notifyListeners(),
    );
  }
}

/// App-wide router with auth-gated routing:
/// - Not yet resolved (loading) or failed to restore -> `/splash`.
/// - Resolved, unauthenticated -> only `/login` and `/register` are reachable.
/// - Resolved, authenticated -> `/login`, `/register`, `/splash` bounce to
///   `/dashboard`; every other route is reachable.
final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _AuthRefreshListenable(ref);
  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final location = state.matchedLocation;

      if (authState.isLoading || authState.hasError) {
        return location == '/splash' ? null : '/splash';
      }

      final isAuthenticated = authState.valueOrNull != null;

      if (!isAuthenticated) {
        return _authRoutes.contains(location) ? null : '/login';
      }

      if (location == '/splash' || _authRoutes.contains(location)) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterPage()),
      ShellRoute(
        builder: (context, state, child) => NavigationShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (context, state) => const DashboardPage()),
          GoRoute(
            path: '/accounts',
            builder: (context, state) => const AccountsPage(),
            routes: [
              GoRoute(
                path: ':accountId',
                builder: (context, state) => AccountDetailPage(
                  accountId: state.pathParameters['accountId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/transactions',
            builder: (context, state) => const TransactionsPage(),
          ),
          GoRoute(path: '/savings', builder: (context, state) => const SavingsPage()),
          GoRoute(path: '/reports', builder: (context, state) => const ReportsPage()),
          GoRoute(path: '/settings', builder: (context, state) => const SettingsPage()),
        ],
      ),
    ],
  );
});
