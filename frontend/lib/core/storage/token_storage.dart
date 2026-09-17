import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the JWT access token issued by `POST /auth/login`.
///
/// Backed by `flutter_secure_storage`:
/// - Android: Keystore-backed EncryptedSharedPreferences.
/// - Web: falls back to browser storage under the hood, which is **not**
///   hardware-encrypted. This is a known platform limitation of the package,
///   not something this app can fully close — acceptable for now since the
///   token is short-lived (see `AppConfig`/backend `ACCESS_TOKEN_EXPIRE_MINUTES`).
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  static const _accessTokenKey = 'we_wealth.access_token';

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<void> clearAccessToken() => _storage.delete(key: _accessTokenKey);
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());
