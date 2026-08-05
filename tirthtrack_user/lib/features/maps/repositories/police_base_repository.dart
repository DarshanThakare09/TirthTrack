// ============================================================
// features/maps/repositories/police_base_repository.dart
// ============================================================

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/distance_utils.dart';
import '../../../core/utils/logger.dart';
import '../models/police_base_model.dart';

class PoliceBaseRepository {
  PoliceBaseRepository(this._client);

  final SupabaseClient _client;

  /// Fetch all active police bases, sorted by nearest first.
  Future<List<PoliceBaseModel>> fetchActiveBases({
    double? userLat,
    double? userLng,
  }) async {
    try {
      appLogger.d('PoliceBaseRepository: fetching active bases');
      final data = await _client
          .from(SupabaseTable.policeBases)
          .select()
          .eq('is_active', true)
          .order('base_name');

      var bases = (data as List)
          .map((json) =>
              PoliceBaseModel.fromJson(json as Map<String, dynamic>))
          .toList();

      if (userLat != null && userLng != null) {
        bases = bases.map((b) {
          final km = DistanceUtils.haversineKm(
              userLat, userLng, b.latitude, b.longitude);
          return b.withDistance(km);
        }).toList()
          ..sort((a, b) =>
              (a.distanceKm ?? double.infinity)
                  .compareTo(b.distanceKm ?? double.infinity));
      }
      return bases;
    } on PostgrestException catch (e) {
      appLogger.e('PoliceBaseRepository fetchActiveBases: ${e.message}');
      throw ServerException(e.message);
    } catch (e) {
      appLogger.e('PoliceBaseRepository unexpected: $e');
      throw const UnknownException();
    }
  }
}

// ── Sector Repository ─────────────────────────────────────────
class SectorRepository {
  SectorRepository(this._client);

  final SupabaseClient _client;

  Future<List<SectorModel>> fetchSectors() async {
    try {
      final data = await _client
          .from(SupabaseTable.sectors)
          .select()
          .order('sector_name');
      return (data as List)
          .map((json) =>
              SectorModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw const UnknownException();
    }
  }

  Future<List<SectorNodeModel>> fetchSectorNodes(String sectorId) async {
    try {
      final data = await _client
          .from(SupabaseTable.sectorNodes)
          .select()
          .eq('sector_id', sectorId)
          .order('node_order');
      return (data as List)
          .map((json) =>
              SectorNodeModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw const UnknownException();
    }
  }
}
