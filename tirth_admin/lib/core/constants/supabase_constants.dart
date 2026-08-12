/// Single source of truth for Supabase table names,
/// column names, and storage bucket names.
class SupabaseTable {
  SupabaseTable._();

  static const String profiles = 'profiles';
  static const String adminDetails = 'admin_details';
  static const String policeDetails = 'police_details';
  static const String policeLoginCodes = 'police_login_codes';
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
  static const String liveLocations = 'live_locations';
}

class SupabaseBucket {
  SupabaseBucket._();

  static const String profilePhotos = 'profile-photos';
  static const String policeIdCards = 'police-id-cards';
  static const String routeAssets = 'route-assets';
  static const String serviceImages = 'service-images';
  static const String appAssets = 'app-assets';
}
