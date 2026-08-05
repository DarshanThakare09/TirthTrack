// ============================================================
// core/utils/validators.dart
// ============================================================

/// Input validation helpers.
/// Used by form fields in presentation layer.
class Validators {
  Validators._();

  /// Returns null if valid, error string if invalid.
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required.';
    }
    // Accept +91XXXXXXXXXX or 10-digit number
    final clean = value.replaceAll(RegExp(r'\s+'), '');
    if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(clean)) {
      return 'Enter a valid phone number.';
    }
    return null;
  }

  static String? required(String? value, [String label = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required.';
    }
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required.';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters.';
    }
    if (value.trim().length > 100) {
      return 'Name must be under 100 characters.';
    }
    return null;
  }

  static String? otp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP is required.';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'Enter a valid 6-digit OTP.';
    }
    return null;
  }

  /// Normalises phone to +91XXXXXXXXXX format if needed.
  static String normalisePhone(String raw) {
    final clean = raw.replaceAll(RegExp(r'\s+'), '');
    if (clean.startsWith('+')) return clean;
    if (clean.length == 10) return '+91$clean';
    return clean;
  }
}
