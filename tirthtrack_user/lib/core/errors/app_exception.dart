// ============================================================
// core/errors/app_exception.dart
// ============================================================

/// Typed exception hierarchy for the application.
/// All repository methods throw subtypes of [AppException].
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Supabase / HTTP / network-level error.
final class NetworkException extends AppException {
  const NetworkException([super.message = 'A network error occurred.']);
}

/// No internet connection.
final class NoInternetException extends AppException {
  const NoInternetException()
      : super('No internet connection. Please check your network.');
}

/// Server returned an unexpected response.
final class ServerException extends AppException {
  const ServerException([super.message = 'Server error. Please try again.']);
}

/// Authentication error (session expired, not logged in, etc.).
final class AuthException extends AppException {
  const AuthException([super.message = 'Authentication failed.']);
}

/// The requested resource was not found.
final class NotFoundException extends AppException {
  const NotFoundException([super.message = 'The requested item was not found.']);
}

/// Permission denied (location, camera, etc.).
final class PermissionException extends AppException {
  const PermissionException([super.message = 'Permission was denied.']);
}

/// Input validation failed.
final class ValidationException extends AppException {
  const ValidationException(super.message);
}

/// Request timed out.
final class TimeoutException extends AppException {
  const TimeoutException()
      : super('The request timed out. Please try again.');
}

/// Unknown / unexpected error.
final class UnknownException extends AppException {
  const UnknownException([super.message = 'An unexpected error occurred.']);
}
