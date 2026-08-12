import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../core/constants/supabase_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/logger.dart';
import '../../../models/police_base_model.dart';

class PoliceBaseRepository {
  PoliceBaseRepository(this._client);

  final sb.SupabaseClient _client;

  /// Fetch police bases with optional active filter and search query
  Future<List<PoliceBaseModel>> getPoliceBases({
    bool? activeOnly,
    String? searchQuery,
  }) async {
    try {
      appLogger.d('PoliceBaseRepository: fetching police bases');
      var query = _client.from(SupabaseTable.policeBases).select();

      if (activeOnly == true) {
        query = query.eq('is_active', true);
      }

      final response = await query.order('created_at', ascending: false);

      final bases = (response as List<dynamic>)
          .map((e) => PoliceBaseModel.fromJson(e as Map<String, dynamic>))
          .toList();

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        return bases.where((b) {
          return b.baseName.toLowerCase().contains(q) ||
              (b.stationName?.toLowerCase().contains(q) ?? false) ||
              (b.sectorName?.toLowerCase().contains(q) ?? false) ||
              (b.inchargeName?.toLowerCase().contains(q) ?? false);
        }).toList();
      }

      return bases;
    } catch (e) {
      appLogger.e('PoliceBaseRepository getPoliceBases error: $e');
      throw parseSupabaseException(e);
    }
  }

  /// Get single police base by ID
  Future<PoliceBaseModel> getPoliceBaseById(String id) async {
    try {
      final response = await _client
          .from(SupabaseTable.policeBases)
          .select()
          .eq('id', id)
          .single();

      return PoliceBaseModel.fromJson(response);
    } catch (e) {
      appLogger.e('PoliceBaseRepository getPoliceBaseById error: $e');
      throw parseSupabaseException(e);
    }
  }

  /// Create police base
  Future<PoliceBaseModel> createPoliceBase(PoliceBaseModel base) async {
    try {
      appLogger.d('PoliceBaseRepository: creating base ${base.baseName}');
      final response = await _client
          .from(SupabaseTable.policeBases)
          .insert(base.toUpsertJson())
          .select()
          .single();

      return PoliceBaseModel.fromJson(response);
    } catch (e) {
      appLogger.e('PoliceBaseRepository createPoliceBase error: $e');
      throw parseSupabaseException(e);
    }
  }

  /// Update police base
  Future<void> updatePoliceBase(String id, PoliceBaseModel base) async {
    try {
      appLogger.d('PoliceBaseRepository: updating base $id');
      await _client
          .from(SupabaseTable.policeBases)
          .update(base.toUpsertJson())
          .eq('id', id);
    } catch (e) {
      appLogger.e('PoliceBaseRepository updatePoliceBase error: $e');
      throw parseSupabaseException(e);
    }
  }

  /// Toggle police base active status
  Future<void> toggleBaseActive(String id, bool isActive) async {
    try {
      await _client.from(SupabaseTable.policeBases).update({
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      appLogger.e('PoliceBaseRepository toggleBaseActive error: $e');
      throw parseSupabaseException(e);
    }
  }

  /// Delete police base
  Future<void> deletePoliceBase(String id) async {
    try {
      appLogger.d('PoliceBaseRepository: deleting base $id');
      await _client.from(SupabaseTable.policeBases).delete().eq('id', id);
    } catch (e) {
      appLogger.e('PoliceBaseRepository deletePoliceBase error: $e');
      throw parseSupabaseException(e);
    }
  }
}
