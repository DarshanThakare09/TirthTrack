// ============================================================
// features/notifications/repositories/notification_repository.dart
// ============================================================

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/logger.dart';
import '../models/notification_models.dart';

class NotificationRepository {
  NotificationRepository(this._client);

  final SupabaseClient _client;

  // ── Alerts ────────────────────────────────────────────────
  Future<List<AlertModel>> fetchActiveAlerts() async {
    try {
      appLogger.d('NotificationRepository: fetching active alerts');
      final now = DateTime.now().toIso8601String();
      final data = await _client
          .from(SupabaseTable.alerts)
          .select()
          .eq('is_active', true)
          .or('expires_at.is.null,expires_at.gt.$now')
          .order('priority', ascending: false)
          .order('created_at', ascending: false);
      return (data as List)
          .map((j) => AlertModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      appLogger.e('NotificationRepository fetchAlerts: ${e.message}');
      throw ServerException(e.message);
    } catch (e) {
      appLogger.e('NotificationRepository fetchAlerts unexpected: $e');
      throw const UnknownException();
    }
  }

  // ── Notifications for user ────────────────────────────────
  Future<List<NotificationModel>> fetchNotifications(
      String profileId) async {
    try {
      appLogger.d('NotificationRepository: fetching notifications');
      final data = await _client
          .from(SupabaseTable.notifications)
          .select()
          .eq('profile_id', profileId)
          .order('created_at', ascending: false)
          .limit(50);
      return (data as List)
          .map((j) =>
              NotificationModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      appLogger.e('NotificationRepository fetchNotifications: ${e.message}');
      throw ServerException(e.message);
    } catch (e) {
      throw const UnknownException();
    }
  }

  /// Mark a notification as read.
  Future<void> markRead(String notificationId) async {
    try {
      await _client
          .from(SupabaseTable.notifications)
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);
    } on PostgrestException catch (e) {
      appLogger.e('NotificationRepository markRead: ${e.message}');
      throw ServerException(e.message);
    } catch (e) {
      throw const UnknownException();
    }
  }

  /// Mark all as read for user.
  Future<void> markAllRead(String profileId) async {
    try {
      await _client
          .from(SupabaseTable.notifications)
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('profile_id', profileId)
          .eq('is_read', false);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw const UnknownException();
    }
  }

  // ── Device token ──────────────────────────────────────────
  Future<void> upsertDeviceToken({
    required String profileId,
    required String fcmToken,
    required String platform,
    String? deviceName,
    String? deviceId,
    String? appVersion,
    String? osVersion,
  }) async {
    try {
      await _client.from(SupabaseTable.deviceTokens).upsert(
        {
          'profile_id': profileId,
          'fcm_token': fcmToken,
          'platform': platform,
          if (deviceName != null) 'device_name': deviceName,
          if (deviceId != null) 'device_id': deviceId,
          if (appVersion != null) 'app_version': appVersion,
          if (osVersion != null) 'os_version': osVersion,
          'is_active': true,
        },
        onConflict: 'device_id',
      );
    } on PostgrestException catch (e) {
      appLogger.e('NotificationRepository upsertToken: ${e.message}');
      throw ServerException(e.message);
    } catch (e) {
      throw const UnknownException();
    }
  }
}
