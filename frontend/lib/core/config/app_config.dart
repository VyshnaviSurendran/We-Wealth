import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

/// Centralized, environment-aware app configuration.
///
/// The API base URL must never be hardcoded inside feature/data code —
/// everything reads it from [AppConfig.apiBaseUrl] instead.
///
/// Override at build/run time with:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000/api/v1
class AppConfig {
  AppConfig._();

  static const String appName = 'Our Balance';
  static const String currencyCode = 'INR';
  static const String currencySymbol = '₹';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  /// Explicit override, e.g. `--dart-define=API_BASE_URL=...`.
  static const String _overrideBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Resolves the backend API base URL for the current platform.
  ///
  /// - If `API_BASE_URL` was passed via `--dart-define`, that value always wins.
  /// - On web, the app is assumed to be served/accessed on the same host as the
  ///   backend (or a reverse proxy in front of it), so `localhost` is used.
  /// - On the Android emulator, `10.0.2.2` is the documented alias for the host
  ///   machine's `localhost`. A physical device needs the host's LAN IP, which
  ///   must be supplied via `--dart-define=API_BASE_URL=...`.
  static String get apiBaseUrl {
    if (_overrideBaseUrl.isNotEmpty) {
      return _overrideBaseUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:8000/api/v1';
    }
    // Default assumes Android emulator; physical devices must override.
    return 'http://10.0.2.2:8000/api/v1';
  }

  static bool get enableNetworkLogging => kDebugMode;
}
