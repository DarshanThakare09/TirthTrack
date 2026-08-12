import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../core/constants/supabase_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/logger.dart';
import '../../../models/alert_model.dart';

class AlertRepository {
  AlertRepository(this._client);

  final sb.SupabaseClient _client;

  /// Fetch alerts with optional type, priority, and active filters
  Future<List<AlertModel>> getAlerts({
    AlertTypeEnum? typeFilter,
    AlertPriorityEnum? priorityFilter,
    bool? activeOnly,
    String? searchQuery,
  }) async {
    try {
      appLogger.d('AlertRepository: fetching alerts');
      var query = _client.from(SupabaseTable.alerts).select();

      if (typeFilter != null) {
        query = query.eq('alert_type', typeFilter.dbValue);
      }
      if (priorityFilter != null) {
        query = query.eq('priority', priorityFilter.dbValue);
      }
      if (activeOnly == true) {
        query = query.eq('is_active', true);
      }

      final response = await query.order('created_at', ascending: false);

      final alerts = (response as List<dynamic>)
          .map((e) => AlertModel.fromJson(e as Map<String, dynamic>))
          .toList();

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        return alerts.where((a) {
          return a.title.toLowerCase().contains(q) ||
              a.message.toLowerCase().contains(q);
        }).toList();
      }

      return alerts;
    } catch (e) {
      appLogger.e('AlertRepository getAlerts error: $e');
      throw parseSupabaseException(e);
    }
  }

  /// Get single alert by ID
  Future<AlertModel> getAlertById(String alertId) async {
    try {
      final response = await _client
          .from(SupabaseTable.alerts)
          .select()
          .eq('id', alertId)
          .single();

      return AlertModel.fromJson(response);
    } catch (e) {
      appLogger.e('AlertRepository getAlertById error: $e');
      throw parseSupabaseException(e);
    }
  }

  /// Create alert with admin_details.id as created_by
  Future<AlertModel> createAlert({
    required AlertModel alert,
    required String adminDetailsId,
  }) async {
    try {
      appLogger.d('AlertRepository: creating alert "${alert.title}" by admin $adminDetailsId');
      final insertData = alert.toUpsertJson(currentAdminId: adminDetailsId);

      final response = await _client
          .from(SupabaseTable.alerts)
          .insert(insertData)
          .select()
          .single();

      return AlertModel.fromJson(response);
    } catch (e) {
      appLogger.e('AlertRepository createAlert error: $e');
      throw parseSupabaseException(e);
    }
  }

  /// Update alert
  Future<void> updateAlert(String id, AlertModel alert) async {
    try {
      appLogger.d('AlertRepository: updating alert $id');
      await _client
          .from(SupabaseTable.alerts)
          .update(alert.toUpsertJson())
          .eq('id', id);
    } catch (e) {
      appLogger.e('AlertRepository updateAlert error: $e');
      throw parseSupabaseException(e);
    }
  }

  /// Toggle active status
  Future<void> toggleAlertActive(String id, bool isActive) async {
    try {
      await _client.from(SupabaseTable.alerts).update({
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      appLogger.e('AlertRepository toggleAlertActive error: $e');
      throw parseSupabaseException(e);
    }
  }

  /// Delete alert
  Future<void> deleteAlert(String id) async {
    try {
      appLogger.d('AlertRepository: deleting alert $id');
      await _client.from(SupabaseTable.alerts).delete().eq('id', id);
    } catch (e) {
      appLogger.e('AlertRepository deleteAlert error: $e');
      throw parseSupabaseException(e);
    }
  }
}
