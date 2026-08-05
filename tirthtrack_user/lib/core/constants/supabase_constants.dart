// ============================================================
// core/constants/supabase_constants.dart
// ============================================================

/// Single source of truth for all Supabase table names,
/// column names, bucket names, and RPC function names.
/// Never use magic strings in repositories — always reference these.
class SupabaseTable {
  SupabaseTable._();

  static const String profiles = 'profiles';
  static const String liveLocations = 'live_locations';
  static const String routes = 'routes';
  static const String routeNodes = 'route_nodes';
  static const String services = 'services';
  static const String policeBases = 'police_bases';
  static const String sectors = 'sectors';
  static const String sectorNodes = 'sector_nodes';
  static const String alerts = 'alerts';
  static const String alertReads = 'alert_reads';
  static const String notifications = 'notifications';
  static const String deviceTokens = 'device_tokens';
  static const String chatbotSessions = 'chatbot_sessions';
  static const String chatbotMessages = 'chatbot_messages';
  static const String appSettings = 'app_settings';
}

class SupabaseBucket {
  SupabaseBucket._();

  static const String profilePhotos = 'profile-photos';
  static const String chatbotMedia = 'chatbot-media';
  static const String routeAssets = 'route-assets';
  static const String serviceImages = 'service-images';
  static const String appAssets = 'app-assets';
}
