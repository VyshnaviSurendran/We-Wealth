import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:our_balance/core/errors/api_exception.dart';
import 'package:our_balance/core/storage/token_storage.dart';
import 'package:our_balance/features/auth/data/auth_api.dart';
import 'package:our_balance/features/auth/presentation/pages/register_page.dart';

import '../../helpers/fakes.dart';

Widget _wrap(Widget child, {required FakeAuthApi authApi}) {
  return ProviderScope(
    overrides: [
      tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
      authApiProvider.overrideWithValue(authApi),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  group('RegisterPage', () {
    testWidgets('shows validation errors when submitting an empty form', (tester) async {
      await tester.pumpWidget(_wrap(const RegisterPage(), authApi: FakeAuthApi()));

      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pump();

      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(find.text('Please confirm your password'), findsOneWidget);
    });

    testWidgets('rejects a password shorter than 8 characters', (tester) async {
      await tester.pumpWidget(_wrap(const RegisterPage(), authApi: FakeAuthApi()));

      final passwordFields = find.byType(TextFormField);
      await tester.enterText(passwordFields.at(2), 'short');
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pump();

      expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    });

    testWidgets('rejects mismatched confirm-password', (tester) async {
      await tester.pumpWidget(_wrap(const RegisterPage(), authApi: FakeAuthApi()));

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'A User');
      await tester.enterText(fields.at(1), 'a.user@example.com');
      await tester.enterText(fields.at(2), 'password123');
      await tester.enterText(fields.at(3), 'password124');
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('shows an inline error when the email is already registered', (tester) async {
      // A 409 from POST /auth/register falls through error_mapper.dart's
      // switch to UnknownApiException(detail) — there's no dedicated
      // "conflict" exception type, so this is exactly what production code
      // would produce.
      final authApi = FakeAuthApi()
        ..registerHandler = ({required name, required email, required password}) async =>
            throw const UnknownApiException('Email is already registered');

      await tester.pumpWidget(_wrap(const RegisterPage(), authApi: authApi));

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'A User');
      await tester.enterText(fields.at(1), 'a.user@example.com');
      await tester.enterText(fields.at(2), 'password123');
      await tester.enterText(fields.at(3), 'password123');
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();

      expect(find.text('Email is already registered'), findsOneWidget);
    });

    testWidgets('a valid submission calls register then login exactly once each', (tester) async {
      final calls = <String>[];
      final authApi = FakeAuthApi()
        ..registerHandler = ({required name, required email, required password}) async {
          calls.add('register');
          return testUser;
        }
        ..loginHandler = ({required email, required password}) async {
          calls.add('login');
          return LoginResult(accessToken: 'tok', user: testUser);
        };

      await tester.pumpWidget(_wrap(const RegisterPage(), authApi: authApi));

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'A User');
      await tester.enterText(fields.at(1), 'a.user@example.com');
      await tester.enterText(fields.at(2), 'password123');
      await tester.enterText(fields.at(3), 'password123');
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();

      expect(calls, ['register', 'login']);
    });
  });
}
