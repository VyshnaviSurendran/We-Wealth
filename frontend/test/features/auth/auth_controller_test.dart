import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:our_balance/core/auth/auth_status.dart';
import 'package:our_balance/core/errors/api_exception.dart';
import 'package:our_balance/core/storage/token_storage.dart';
import 'package:our_balance/features/auth/application/auth_controller.dart';
import 'package:our_balance/features/auth/data/auth_api.dart';

import '../../helpers/fakes.dart';

void main() {
  group('AuthController', () {
    test('with no stored token, resolves to unauthenticated without calling the API', () async {
      final authApi = FakeAuthApi()
        ..currentUserHandler = () => throw StateError('should not be called');
      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
          authApiProvider.overrideWithValue(authApi),
        ],
      );
      addTearDown(container.dispose);

      final user = await container.read(authControllerProvider.future);

      expect(user, isNull);
      expect(container.read(authStatusProvider), AuthStatus.unauthenticated);
    });

    test('with a stored token that /auth/me accepts, resolves to authenticated', () async {
      final authApi = FakeAuthApi()..currentUserHandler = () async => testUser;
      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(FakeTokenStorage(initialToken: 'stored-token')),
          authApiProvider.overrideWithValue(authApi),
        ],
      );
      addTearDown(container.dispose);

      final user = await container.read(authControllerProvider.future);

      expect(user?.email, testUser.email);
      expect(container.read(authStatusProvider), AuthStatus.authenticated);
    });

    test('with a stored token that /auth/me rejects (401), clears it and is unauthenticated',
        () async {
      final tokenStorage = FakeTokenStorage(initialToken: 'expired-token');
      final authApi = FakeAuthApi()..currentUserHandler = () async => throw authError();
      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(tokenStorage),
          authApiProvider.overrideWithValue(authApi),
        ],
      );
      addTearDown(container.dispose);

      final user = await container.read(authControllerProvider.future);

      expect(user, isNull);
      expect(await tokenStorage.readAccessToken(), isNull);
      expect(container.read(authStatusProvider), AuthStatus.unauthenticated);
    });

    test('a network failure while restoring the session surfaces as AsyncError, keeps the token',
        () async {
      final tokenStorage = FakeTokenStorage(initialToken: 'some-token');
      final authApi = FakeAuthApi()
        ..currentUserHandler = () async => throw const NetworkException();
      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(tokenStorage),
          authApiProvider.overrideWithValue(authApi),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(container.read(authControllerProvider.future), throwsA(isA<ApiException>()));
      expect(await tokenStorage.readAccessToken(), 'some-token');
    });

    test('login saves the token and resolves to authenticated', () async {
      final tokenStorage = FakeTokenStorage();
      final authApi = FakeAuthApi()
        ..loginHandler = ({required email, required password}) async =>
            LoginResult(accessToken: 'new-token', user: testUser);
      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(tokenStorage),
          authApiProvider.overrideWithValue(authApi),
        ],
      );
      addTearDown(container.dispose);
      await container.read(authControllerProvider.future); // let initial build settle

      await container
          .read(authControllerProvider.notifier)
          .login(email: testUser.email, password: 'whatever-8-chars');

      expect(container.read(authControllerProvider).valueOrNull?.email, testUser.email);
      expect(await tokenStorage.readAccessToken(), 'new-token');
      expect(container.read(authStatusProvider), AuthStatus.authenticated);
    });

    test('a failed login rethrows and leaves the session unauthenticated', () async {
      final tokenStorage = FakeTokenStorage();
      final authApi = FakeAuthApi()
        ..loginHandler = ({required email, required password}) async => throw authError();
      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(tokenStorage),
          authApiProvider.overrideWithValue(authApi),
        ],
      );
      addTearDown(container.dispose);
      await container.read(authControllerProvider.future);

      await expectLater(
        container
            .read(authControllerProvider.notifier)
            .login(email: 'wrong@example.com', password: 'whatever'),
        throwsA(isA<AuthException>()),
      );
      expect(container.read(authControllerProvider).valueOrNull, isNull);
      expect(await tokenStorage.readAccessToken(), isNull);
    });

    test('register creates the account then logs in with the same credentials', () async {
      final tokenStorage = FakeTokenStorage();
      final calls = <String>[];
      final authApi = FakeAuthApi()
        ..registerHandler = ({required name, required email, required password}) async {
          calls.add('register');
          return testUser;
        }
        ..loginHandler = ({required email, required password}) async {
          calls.add('login');
          return LoginResult(accessToken: 'fresh-token', user: testUser);
        };
      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(tokenStorage),
          authApiProvider.overrideWithValue(authApi),
        ],
      );
      addTearDown(container.dispose);
      await container.read(authControllerProvider.future);

      await container.read(authControllerProvider.notifier).register(
            name: testUser.name,
            email: testUser.email,
            password: 'whatever-8-chars',
          );

      expect(calls, ['register', 'login']);
      expect(container.read(authControllerProvider).valueOrNull?.email, testUser.email);
      expect(await tokenStorage.readAccessToken(), 'fresh-token');
    });

    test('logout clears the token and resolves to unauthenticated', () async {
      final tokenStorage = FakeTokenStorage(initialToken: 'existing-token');
      final authApi = FakeAuthApi()..currentUserHandler = () async => testUser;
      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(tokenStorage),
          authApiProvider.overrideWithValue(authApi),
        ],
      );
      addTearDown(container.dispose);
      await container.read(authControllerProvider.future);

      await container.read(authControllerProvider.notifier).logout();

      expect(container.read(authControllerProvider).valueOrNull, isNull);
      expect(await tokenStorage.readAccessToken(), isNull);
      expect(container.read(authStatusProvider), AuthStatus.unauthenticated);
    });

    test('a 401 flagged by the network layer clears the session reactively', () async {
      final tokenStorage = FakeTokenStorage(initialToken: 'will-expire');
      final authApi = FakeAuthApi()..currentUserHandler = () async => testUser;
      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(tokenStorage),
          authApiProvider.overrideWithValue(authApi),
        ],
      );
      addTearDown(container.dispose);
      await container.read(authControllerProvider.future);
      expect(container.read(authControllerProvider).valueOrNull, isNotNull);

      // Simulate what api_client.dart's 401 interceptor does.
      container.read(authStatusProvider.notifier).markUnauthenticated();
      await Future<void>.delayed(Duration.zero);

      expect(container.read(authControllerProvider).valueOrNull, isNull);
      expect(await tokenStorage.readAccessToken(), isNull);
    });
  });
}
