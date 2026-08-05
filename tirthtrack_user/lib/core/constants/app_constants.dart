// ============================================================
// core/constants/app_constants.dart
// ============================================================

class AppConstants {
  AppConstants._();

  // OTP resend cooldown in seconds
  static const int otpResendCooldown = 60;

  // OTP length
  static const int otpLength = 6;

  // Location update interval in seconds
  static const int locationUpdateIntervalSeconds = 30;

  // Location update distance in meters (minimum before sending update)
  static const double locationUpdateDistanceMeters = 20.0;

  // Location accuracy threshold in meters
  static const double locationAccuracyThreshold = 50.0;

  // Map default zoom level
  static const double mapDefaultZoom = 14.0;
  static const double mapDetailZoom = 16.0;

  // Chat messages page size
  static const int chatMessagesPageSize = 50;

  // Notifications page size
  static const int notificationsPageSize = 30;

  // Routes page size
  static const int routesPageSize = 50;

  // Services page size
  static const int servicesPageSize = 100;

  // Profile photo max size in bytes (5 MB)
  static const int profilePhotoMaxBytes = 5 * 1024 * 1024;

  // Signed URL expiry in seconds (1 hour)
  static const int signedUrlExpiry = 3600;

  // Timeout for Supabase queries
  static const Duration queryTimeout = Duration(seconds: 15);

  // App support links
  static const String privacyPolicyUrl =
      'https://tirthtrack.app/privacy-policy';
  static const String termsUrl = 'https://tirthtrack.app/terms';
  static const String supportEmail = 'support@tirthtrack.app';

  // App version
  static const String appVersion = '1.0.0';
}
