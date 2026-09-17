import 'package:dio/dio.dart';

import 'api_exception.dart';

/// Converts a [DioException] into a typed [ApiException].
///
/// The backend (FastAPI) has no response envelope: errors come back as
/// `{"detail": "message"}` for most failures, or `{"detail": [{loc, msg,
/// type, ...}, ...]}` for 422 validation errors. This mapper is the single
/// place that understands that shape.
ApiException mapDioExceptionToApiException(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
    case DioExceptionType.connectionError:
      return const NetworkException();
    case DioExceptionType.badCertificate:
      return const NetworkException('Could not establish a secure connection.');
    case DioExceptionType.cancel:
      return const UnknownApiException('Request was cancelled.');
    case DioExceptionType.badResponse:
      return _mapBadResponse(error);
    case DioExceptionType.unknown:
      return const NetworkException();
  }
}

ApiException _mapBadResponse(DioException error) {
  final statusCode = error.response?.statusCode;
  final data = error.response?.data;

  if (statusCode == 422) {
    return ValidationException(_extractFieldErrors(data));
  }

  final message = _extractMessage(data);

  switch (statusCode) {
    case 401:
      return AuthException(message ?? const AuthException().message);
    case 403:
      return ForbiddenException(message ?? const ForbiddenException().message);
    case 404:
      return NotFoundException(message ?? const NotFoundException().message);
  }

  if (statusCode != null && statusCode >= 500) {
    return const ServerException();
  }

  return UnknownApiException(message ?? const UnknownApiException().message);
}

/// Pulls a human-readable string out of `{"detail": "..."}`.
String? _extractMessage(Object? data) {
  if (data is Map && data['detail'] is String) {
    return data['detail'] as String;
  }
  return null;
}

/// Pulls `{field: message}` pairs out of FastAPI's 422
/// `{"detail": [{"loc": ["body", "field"], "msg": "...", ...}, ...]}`.
Map<String, String> _extractFieldErrors(Object? data) {
  final fieldErrors = <String, String>{};
  if (data is! Map || data['detail'] is! List) {
    return fieldErrors;
  }

  for (final entry in data['detail'] as List) {
    if (entry is! Map) continue;
    final loc = entry['loc'];
    final msg = entry['msg'];
    if (msg is! String) continue;

    final field = (loc is List && loc.isNotEmpty) ? loc.last.toString() : 'error';
    fieldErrors[field] = msg;
  }

  return fieldErrors;
}
