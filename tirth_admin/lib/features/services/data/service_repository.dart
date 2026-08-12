import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../core/constants/supabase_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/logger.dart';
import '../../../models/service_model.dart';

class ServiceRepository {
  ServiceRepository(this._client);

  final sb.SupabaseClient _client;

  /// Fetch services with optional type and active filter
  Future<List<ServiceModel>> getServices({
    ServiceTypeEnum? typeFilter,
    bool? activeOnly,
    String? searchQuery,
  }) async {
    try {
      appLogger.d('ServiceRepository: fetching services');
      var query = _client.from(SupabaseTable.services).select();

      if (typeFilter != null) {
        query = query.eq('service_type', typeFilter.dbValue);
      }
      if (activeOnly == true) {
        query = query.eq('is_active', true);
      }

      final response = await query.order('created_at', ascending: false);

      final services = (response as List<dynamic>)
          .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
          .toList();

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        return services.where((s) {
          return s.serviceName.toLowerCase().contains(q) ||
              (s.contactPerson?.toLowerCase().contains(q) ?? false) ||
              (s.contactNumber?.toLowerCase().contains(q) ?? false);
        }).toList();
      }

      return services;
    } catch (e) {
      appLogger.e('ServiceRepository getServices error: $e');
      throw parseSupabaseException(e);
    }
  }

  /// Get single service by ID
  Future<ServiceModel> getServiceById(String serviceId) async {
    try {
      final response = await _client
          .from(SupabaseTable.services)
          .select()
          .eq('id', serviceId)
          .single();

      return ServiceModel.fromJson(response);
    } catch (e) {
      appLogger.e('ServiceRepository getServiceById error: $e');
      throw parseSupabaseException(e);
    }
  }

  /// Create service
  Future<ServiceModel> createService(ServiceModel service) async {
    try {
      appLogger.d('ServiceRepository: creating service ${service.serviceName}');
      final response = await _client
          .from(SupabaseTable.services)
          .insert(service.toUpsertJson())
          .select()
          .single();

      return ServiceModel.fromJson(response);
    } catch (e) {
      appLogger.e('ServiceRepository createService error: $e');
      throw parseSupabaseException(e);
    }
  }

  /// Update service
  Future<void> updateService(String id, ServiceModel service) async {
    try {
      appLogger.d('ServiceRepository: updating service $id');
      await _client
          .from(SupabaseTable.services)
          .update(service.toUpsertJson())
          .eq('id', id);
    } catch (e) {
      appLogger.e('ServiceRepository updateService error: $e');
      throw parseSupabaseException(e);
    }
  }

  /// Toggle service active status
  Future<void> toggleServiceActive(String id, bool isActive) async {
    try {
      await _client.from(SupabaseTable.services).update({
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      appLogger.e('ServiceRepository toggleServiceActive error: $e');
      throw parseSupabaseException(e);
    }
  }

  /// Delete service
  Future<void> deleteService(String id) async {
    try {
      appLogger.d('ServiceRepository: deleting service $id');
      await _client.from(SupabaseTable.services).delete().eq('id', id);
    } catch (e) {
      appLogger.e('ServiceRepository deleteService error: $e');
      throw parseSupabaseException(e);
    }
  }
}
