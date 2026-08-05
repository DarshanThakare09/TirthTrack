// ============================================================
// features/notifications/providers/notification_provider.dart
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/providers/auth_provider.dart';
import '../models/notification_models.dart';
import '../repositories/notification_repository.dart';

// ── Repository ────────────────────────────────────────────────
final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(ref.watch(supabaseClientProvider)),
);

// ── Active alerts ─────────────────────────────────────────────
final alertsProvider =
    AsyncNotifierProvider<AlertsNotifier, List<AlertModel>>(
        AlertsNotifier.new);

class AlertsNotifier extends AsyncNotifier<List<AlertModel>> {
  @override
  Future<List<AlertModel>> build() =>
      ref.read(notificationRepositoryProvider).fetchActiveAlerts();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(notificationRepositoryProvider).fetchActiveAlerts());
  }
}

// ── User notifications ────────────────────────────────────────
final notificationsProvider = AsyncNotifierProvider<NotificationsNotifier,
    List<NotificationModel>>(NotificationsNotifier.new);

class NotificationsNotifier
    extends AsyncNotifier<List<NotificationModel>> {
  @override
  Future<List<NotificationModel>> build() {
    final uid = ref.watch(currentUserIdProvider);
    if (uid == null) return Future.value([]);
    return ref.read(notificationRepositoryProvider).fetchNotifications(uid);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  Future<void> markRead(String notificationId) async {
    await ref
        .read(notificationRepositoryProvider)
        .markRead(notificationId);
    // Update local state
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.map((n) {
      if (n.id == notificationId) {
        return NotificationModel(
          id: n.id,
          profileId: n.profileId,
          alertId: n.alertId,
          title: n.title,
          body: n.body,
          status: n.status,
          isRead: true,
          sentAt: n.sentAt,
          readAt: DateTime.now(),
          createdAt: n.createdAt,
        );
      }
      return n;
    }).toList());
  }

  Future<void> markAllRead() async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    await ref.read(notificationRepositoryProvider).markAllRead(uid);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.map((n) => NotificationModel(
          id: n.id,
          profileId: n.profileId,
          alertId: n.alertId,
          title: n.title,
          body: n.body,
          status: n.status,
          isRead: true,
          sentAt: n.sentAt,
          readAt: DateTime.now(),
          createdAt: n.createdAt,
        )).toList());
  }
}

// ── Unread count ──────────────────────────────────────────────
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider).valueOrNull ?? [];
  return notifications.where((n) => !n.isRead).length;
});
