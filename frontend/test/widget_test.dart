import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:our_balance/app/app.dart';
import 'package:our_balance/core/storage/token_storage.dart';
import 'package:our_balance/features/auth/data/auth_api.dart';

import 'helpers/fakes.dart';

void main() {
  testWidgets('with no stored session, the app boots to the login screen', (tester) async {
    final tokenStorage = FakeTokenStorage();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(tokenStorage),
          authApiProvider.overrideWithValue(FakeAuthApi()),
        ],
        child: const OurBalanceApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in to continue'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
