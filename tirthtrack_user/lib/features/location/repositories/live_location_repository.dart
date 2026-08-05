// ============================================================
// features/location/repositories/live_location_repository.dart
// ============================================================

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/logger.dart';
import '../models/live_location_model.dart';

class LiveLocationRepository {
  LiveLocationRepository(this._client);

  final SupabaseClient _client;

  /// Inserts a live location record.
  Future<void> insertLocation(LiveLocationModel location) async {
    try {
      appLogger.d(
        'LiveLocationRepository: inserting ${location.latitude}, ${location.longitude}',
      );
      await _client
          .from(SupabaseTable.liveLocations)
          .insert(location.toInsertJson());
    } on PostgrestException catch (e) {
      appLogger.e('LiveLocationRepository insertLocation: ${e.message}');
      throw ServerException(e.message);
    } catch (e) {
      appLogger.e('LiveLocationRepository insertLocation unexpected: $e');
      // Don't throw — location updates should fail silently to not disrupt UX
    }
  }
}
