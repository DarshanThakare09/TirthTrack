import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/notification_models.dart';

abstract class INotificationsRepository {
  Future<List<NotificationModel>> getNotifications(String profileId);
  Future<void> markAsRead(String notificationId);
  Future<int> getUnreadCount(String profileId);
}

class NotificationsRepository implements INotificationsRepository {
  final SupabaseClient _supabaseClient;

  NotificationsRepository(this._supabaseClient);

  @override
  Future<List<NotificationModel>> getNotifications(String profileId) async {
    debugPrint('[NOTIFICATIONS] getNotifications: Query started (profileId: $profileId)');
    try {
      final response = await _supabaseClient
          .from('notifications')
          .select()
          .eq('profile_id', profileId)
          .order('created_at', ascending: false);

      final notifications = (response as List)
          .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
          .toList();

      debugPrint('[NOTIFICATIONS] getNotifications: Query succeeded → ${notifications.length} notifications');
      return notifications;
    } catch (e, st) {
      debugPrint('[NOTIFICATIONS] getNotifications: Query failed → $e\n$st');
      rethrow;
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    debugPrint('[NOTIFICATIONS] markAsRead: Query started (notificationId: $notificationId)');
    try {
      await _supabaseClient.from('notifications').update({
        'is_read': true,
        'read_at': DateTime.now().toIso8601String(),
      }).eq('id', notificationId);
      debugPrint('[NOTIFICATIONS] markAsRead: Query succeeded');
    } catch (e, st) {
      debugPrint('[NOTIFICATIONS] markAsRead: Query failed → $e\n$st');
      rethrow;
    }
  }

  @override
  Future<int> getUnreadCount(String profileId) async {
    debugPrint('[NOTIFICATIONS] getUnreadCount: Query started (profileId: $profileId)');
    try {
      final list = await getNotifications(profileId);
      final count = list.where((n) => !n.isRead).length;
      debugPrint('[NOTIFICATIONS] getUnreadCount: Query succeeded → $count unread');
      return count;
    } catch (e, st) {
      debugPrint('[NOTIFICATIONS] getUnreadCount: Query failed → $e\n$st');
      rethrow;
    }
  }
}
