// ============================================================
// features/maps/repositories/service_repository.dart
// ============================================================

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/distance_utils.dart';
import '../../../core/utils/logger.dart';
import '../models/service_model.dart';

class ServiceRepository {
  ServiceRepository(this._client);

  final SupabaseClient _client;

  /// Fetch all active services.
  /// Optionally sorted by nearest first when [userLat]/[userLng] provided.
  Future<List<ServiceModel>> fetchActiveServices({
    double? userLat,
    double? userLng,
  }) async {
    try {
      appLogger.d('ServiceRepository: fetching active services');
      final data = await _client
          .from(SupabaseTable.services)
          .select()
          .eq('is_active', true)
          .order('service_name');

      var services = (data as List)
          .map((json) =>
              ServiceModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Compute distances and sort by nearest if user location available
      if (userLat != null && userLng != null) {
        services = services.map((s) {
          final km = DistanceUtils.haversineKm(
              userLat, userLng, s.latitude, s.longitude);
          return s.withDistance(km);
        }).toList()
          ..sort((a, b) =>
              (a.distanceKm ?? double.infinity)
                  .compareTo(b.distanceKm ?? double.infinity));
      }
      return services;
    } on PostgrestException catch (e) {
      appLogger.e('ServiceRepository fetchActiveServices: ${e.message}');
      throw ServerException(e.message);
    } catch (e) {
      appLogger.e('ServiceRepository unexpected: $e');
      throw const UnknownException();
    }
  }

  /// Fetch services filtered by type.
  Future<List<ServiceModel>> fetchServicesByType(
    ServiceTypeEnum type, {
    double? userLat,
    double? userLng,
  }) async {
    try {
      final data = await _client
          .from(SupabaseTable.services)
          .select()
          .eq('is_active', true)
          .eq('service_type', type.dbValue)
          .order('service_name');

      var services = (data as List)
          .map((json) =>
              ServiceModel.fromJson(json as Map<String, dynamic>))
          .toList();

      if (userLat != null && userLng != null) {
        services = services.map((s) {
          final km = DistanceUtils.haversineKm(
              userLat, userLng, s.latitude, s.longitude);
          return s.withDistance(km);
        }).toList()
          ..sort((a, b) =>
              (a.distanceKm ?? double.infinity)
                  .compareTo(b.distanceKm ?? double.infinity));
      }
      return services;
    } on PostgrestException catch (e) {
      appLogger.e('ServiceRepository fetchByType: ${e.message}');
      throw ServerException(e.message);
    } catch (e) {
      appLogger.e('ServiceRepository fetchByType unexpected: $e');
      throw const UnknownException();
    }
  }
}
