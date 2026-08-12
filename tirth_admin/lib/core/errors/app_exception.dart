import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Base exception class for all TirthTrack Admin errors
abstract class AppException implements Exception {
  const AppException(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => message;
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([
    super.message =
        'You do not have Administrator permissions to access this portal.',
    String? code = 'UNAUTHORIZED',
  ]) : super(code: code);
}

class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.code});
}

class StorageException extends AppException {
  const StorageException(super.message, {super.code});
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.code});
}

class NetworkException extends AppException {
  const NetworkException([
    super.message =
        'Network connection failed. Please check your internet.',
    String? code = 'NETWORK_ERROR',
  ]) : super(code: code);
}

class UnknownException extends AppException {
  const UnknownException([
    super.message = 'An unexpected error occurred. Please try again.',
    String? code = 'UNKNOWN_ERROR',
  ]) : super(code: code);
}

/// Helper method to transform Postgrest and Supabase exceptions into clean user-friendly messages
AppException parseSupabaseException(Object error) {
  if (error is sb.AuthException) {
    return AuthException(error.message, code: error.statusCode);
  }
  if (error is sb.PostgrestException) {
    if (error.code == '23505') {
      return DatabaseException(
        'A record with these unique details already exists.',
        code: error.code,
      );
    }
    if (error.code == '42501') {
      return const UnauthorizedException(
        'Row-Level Security: You do not have permission for this action.',
      );
    }
    return DatabaseException(
      error.message.isNotEmpty ? error.message : 'Database operation failed.',
      code: error.code,
    );
  }
  if (error is sb.StorageException) {
    return StorageException(error.message, code: error.statusCode);
  }
  if (error is AppException) {
    return error;
  }
  return UnknownException(error.toString());
}
