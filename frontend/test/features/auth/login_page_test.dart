import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:our_balance/core/storage/token_storage.dart';
import 'package:our_balance/features/auth/data/auth_api.dart';
import 'package:our_balance/features/auth/presentation/pages/login_page.dart';

import '../../helpers/fakes.dart';

Widget _wrap(Widget child, {required FakeAuthApi authApi, FakeTokenStorage? tokenStorage}) {
  return ProviderScope(
    overrides: [
      tokenStorageProvider.overrideWithValue(tokenStorage ?? FakeTokenStorage()),
      authApiProvider.overrideWithValue(authApi),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  group('LoginPage', () {
    testWidgets('shows validation errors when submitting an empty form', (tester) async {
      await tester.pumpWidget(_wrap(const LoginPage(), authApi: FakeAuthApi()));

      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('shows an inline error message when login fails', (tester) async {
      final authApi = FakeAuthApi()
        ..loginHandler = ({required email, required password}) async => throw authError();

      await tester.pumpWidget(_wrap(const LoginPage(), authApi: authApi));

      await tester.enterText(find.byType(TextFormField).first, 'user@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid email or password'), findsOneWidget);
    });

    testWidgets('shows a loading indicator while the login request is in flight', (tester) async {
      final completer = Completer<LoginResult>();
      final authApi = FakeAuthApi()
        ..loginHandler = ({required email, required password}) => completer.future;

      await tester.pumpWidget(_wrap(const LoginPage(), authApi: authApi));
      await tester.enterText(find.byType(TextFormField).first, 'user@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(LoginResult(accessToken: 'token', user: testUser));
      await tester.pumpAndSettle();
    });

    testWidgets('the password field toggles obscure text', (tester) async {
      await tester.pumpWidget(_wrap(const LoginPage(), authApi: FakeAuthApi()));

      final editableTextFinder = find.descendant(
        of: find.byType(TextFormField).last,
        matching: find.byType(EditableText),
      );
      expect(tester.widget<EditableText>(editableTextFinder).obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      expect(tester.widget<EditableText>(editableTextFinder).obscureText, isFalse);
    });
  });
}
