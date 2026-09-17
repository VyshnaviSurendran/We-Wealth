import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:our_balance/app/app.dart';
import 'package:our_balance/core/storage/token_storage.dart';
import 'package:our_balance/features/auth/data/auth_api.dart';
import 'package:our_balance/features/household/data/household_api.dart';

import '../helpers/fakes.dart';

/// These tests only care about *which screen* the router lands on, not what
/// the dashboard itself renders — but landing on the dashboard still builds
/// its real widget tree, which would otherwise make a real (failing)
/// network call for `GET /households`. This keeps that call from ever
/// leaving the fake layer.
final _noHouseholdOverride = householdApiProvider.overrideWithValue(
  FakeHouseholdApi(households: const []),
);

void main() {
  group('Router auth gating', () {
    testWidgets('unauthenticated: dashboard is not reachable, login is shown', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
            authApiProvider.overrideWithValue(FakeAuthApi()),
          ],
          child: const OurBalanceApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sign in to continue'), findsOneWidget);
    });

    testWidgets('a stored valid token skips login and restores straight into the dashboard',
        (tester) async {
      final authApi = FakeAuthApi()..currentUserHandler = () async => testUser;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(FakeTokenStorage(initialToken: 'valid-token')),
            authApiProvider.overrideWithValue(authApi),
            _noHouseholdOverride,
          ],
          child: const OurBalanceApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sign in to continue'), findsNothing);
      expect(find.byIcon(Icons.dashboard), findsOneWidget); // selected nav destination
    });

    testWidgets('a successful login navigates from /login to the dashboard', (tester) async {
      final authApi = FakeAuthApi()
        ..loginHandler = ({required email, required password}) async =>
            LoginResult(accessToken: 'tok', user: testUser);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
            authApiProvider.overrideWithValue(authApi),
            _noHouseholdOverride,
          ],
          child: const OurBalanceApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sign in to continue'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, testUser.email);
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Sign in to continue'), findsNothing);
      expect(find.byIcon(Icons.dashboard), findsOneWidget);
    });

    testWidgets('signing out from Settings returns to the login screen', (tester) async {
      final authApi = FakeAuthApi()..currentUserHandler = () async => testUser;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(FakeTokenStorage(initialToken: 'valid-token')),
            authApiProvider.overrideWithValue(authApi),
            _noHouseholdOverride,
          ],
          child: const OurBalanceApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Sign out'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
      await tester.pumpAndSettle();

      expect(find.text('Sign in to continue'), findsOneWidget);
    });
  });
}
