import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/device_token_models.dart';

abstract class IDeviceTokenRepository {
  Future<void> registerDeviceToken(DeviceTokenModel token);
}

class DeviceTokenRepository implements IDeviceTokenRepository {
  final SupabaseClient _supabaseClient;

  DeviceTokenRepository(this._supabaseClient);

  @override
  Future<void> registerDeviceToken(DeviceTokenModel token) async {
    try {
      await _supabaseClient.from('device_tokens').upsert(token.toJson());
      debugPrint('Device token registered successfully for user: ${token.profileId}');
    } catch (e) {
      debugPrint('registerDeviceToken error: $e');
    }
  }
}
