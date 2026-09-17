/// Base type for every failure the API layer can surface to the UI.
///
/// UI code should catch this (not `DioException`) and switch on the runtime
/// type to decide what to show — see `core/widgets/error_view.dart`.
sealed class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// No connectivity, DNS failure, connection refused, timeouts, etc.
final class NetworkException extends ApiException {
  const NetworkException([super.message = 'Could not reach the server. Check your connection.']);
}

/// 401 — missing/expired/invalid token.
final class AuthException extends ApiException {
  const AuthException([super.message = 'Your session has expired. Please sign in again.']);
}

/// 403 — authenticated but not allowed to perform this action.
final class ForbiddenException extends ApiException {
  const ForbiddenException([super.message = 'You do not have permission to do that.']);
}

/// 404 — resource not found.
final class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'The requested item could not be found.']);
}

/// 422 — request body/query failed backend (Pydantic) validation.
///
/// [fieldErrors] mirrors FastAPI's `detail: [{loc, msg, type}, ...]` shape,
/// keyed by the field name (last entry of `loc`).
final class ValidationException extends ApiException {
  const ValidationException(this.fieldErrors, [super.message = 'Please check the form and try again.']);

  final Map<String, String> fieldErrors;
}

/// 5xx — the backend itself failed. Never expose raw internals to the user.
final class ServerException extends ApiException {
  const ServerException([super.message = 'Something went wrong on our end. Please try again.']);
}

/// Anything else (unexpected shape, parse failure, etc).
final class UnknownApiException extends ApiException {
  const UnknownApiException([super.message = 'Something unexpected happened.']);
}
