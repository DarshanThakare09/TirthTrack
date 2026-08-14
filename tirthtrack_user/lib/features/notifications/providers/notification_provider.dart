// ============================================================
// features/notifications/providers/notification_provider.dart
// ============================================================

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/local_notification_service.dart';
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
  RealtimeChannel? _realtimeChannel;
  Timer? _pollingTimer;

  @override
  Future<List<AlertModel>> build() async {
    // 1. Fetch current active and non-expired alerts
    final alerts =
        await ref.read(notificationRepositoryProvider).fetchActiveAlerts();

    // 2. Check for any active alerts that haven't been notified on this device yet
    for (final alert in alerts) {
      if (alert.isVisibleToUser &&
          !LocalNotificationService.instance.isAlertNotified(alert.id)) {
        await LocalNotificationService.instance.showNotificationForAlert(alert);
      }
    }

    // 3. Clean up previous subscription and timer if any
    _realtimeChannel?.unsubscribe();
    _pollingTimer?.cancel();

    // 4. Subscribe to Realtime broadcasts/alerts
    _realtimeChannel = ref
        .read(notificationRepositoryProvider)
        .subscribeToAlerts(onAlertReceived: _handleRealtimeAlert);

    // 5. Periodic polling fallback (every 3s) to guarantee updates even if WebSockets drop
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await _syncAlerts();
    });

    ref.onDispose(() {
      _realtimeChannel?.unsubscribe();
      _realtimeChannel = null;
      _pollingTimer?.cancel();
      _pollingTimer = null;
    });

    return alerts;
  }

  Future<void> _syncAlerts() async {
    try {
      final alerts =
          await ref.read(notificationRepositoryProvider).fetchActiveAlerts();
      for (final alert in alerts) {
        if (alert.isVisibleToUser &&
            !LocalNotificationService.instance.isAlertNotified(alert.id)) {
          await LocalNotificationService.instance
              .showNotificationForAlert(alert);
        }
      }
      state = AsyncData(alerts);
    } catch (_) {}
  }

  void _handleRealtimeAlert(AlertModel alert) async {
    if (alert.isVisibleToUser) {
      // Show native device notification (enforces deduplication & validity)
      await LocalNotificationService.instance.showNotificationForAlert(alert);

      // Update in-memory state list
      final currentList = state.valueOrNull ?? [];
      final existsIndex = currentList.indexWhere((a) => a.id == alert.id);
      List<AlertModel> updatedList;
      if (existsIndex >= 0) {
        updatedList = List.of(currentList);
        updatedList[existsIndex] = alert;
      } else {
        updatedList = [alert, ...currentList];
      }

      // Filter and sort active non-expired alerts
      updatedList = updatedList
          .where((a) => a.isVisibleToUser)
          .toList()
        ..sort((a, b) {
          final p = b.priority.index.compareTo(a.priority.index);
          if (p != 0) return p;
          return b.createdAt.compareTo(a.createdAt);
        });

      state = AsyncData(updatedList);
    } else {
      // If alert became inactive or expired, remove from active list
      final currentList = state.valueOrNull ?? [];
      final filtered =
          currentList.where((a) => a.id != alert.id && a.isVisibleToUser).toList();
      state = AsyncData(filtered);
    }
  }

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
  RealtimeChannel? _realtimeChannel;
  Timer? _pollingTimer;

  @override
  Future<List<NotificationModel>> build() async {
    final uid = ref.watch(currentUserIdProvider);
    if (uid == null) return [];

    final notifs =
        await ref.read(notificationRepositoryProvider).fetchNotifications(uid);

    // Show device notification for unread personal notifications if not yet notified
    for (final n in notifs) {
      if (!n.isRead &&
          !LocalNotificationService.instance
              .isPersonalNotificationNotified(n.id)) {
        await LocalNotificationService.instance
            .showNotificationForPersonalNotification(n);
      }
    }

    _realtimeChannel?.unsubscribe();
    _pollingTimer?.cancel();

    _realtimeChannel = ref
        .read(notificationRepositoryProvider)
        .subscribeToNotifications(
          profileId: uid,
          onNotificationReceived: _handleRealtimeNotification,
        );

    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await _syncNotifications(uid);
    });

    ref.onDispose(() {
      _realtimeChannel?.unsubscribe();
      _realtimeChannel = null;
      _pollingTimer?.cancel();
      _pollingTimer = null;
    });

    return notifs;
  }

  Future<void> _syncNotifications(String uid) async {
    try {
      final notifs =
          await ref.read(notificationRepositoryProvider).fetchNotifications(uid);
      for (final n in notifs) {
        if (!n.isRead &&
            !LocalNotificationService.instance
                .isPersonalNotificationNotified(n.id)) {
          await LocalNotificationService.instance
              .showNotificationForPersonalNotification(n);
        }
      }
      state = AsyncData(notifs);
    } catch (_) {}
  }

  void _handleRealtimeNotification(NotificationModel notification) async {
    if (!notification.isRead) {
      await LocalNotificationService.instance
          .showNotificationForPersonalNotification(notification);
    }

    final currentList = state.valueOrNull ?? [];
    final existsIndex =
        currentList.indexWhere((n) => n.id == notification.id);
    List<NotificationModel> updated;
    if (existsIndex >= 0) {
      updated = List.of(currentList);
      updated[existsIndex] = notification;
    } else {
      updated = [notification, ...currentList];
    }
    state = AsyncData(updated);
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

// ── Seen alerts tracking ───────────────────────────────────────
final seenAlertsProvider =
    AsyncNotifierProvider<SeenAlertsNotifier, Set<String>>(
        SeenAlertsNotifier.new);

class SeenAlertsNotifier extends AsyncNotifier<Set<String>> {
  static const String _seenAlertsKey = 'tirthtrack_seen_alert_ids';

  @override
  Future<Set<String>> build() async {
    final seen = <String>{};
    // 1. Load locally cached seen alert IDs
    try {
      final prefs = await SharedPreferences.getInstance();
      final local = prefs.getStringList(_seenAlertsKey) ?? [];
      seen.addAll(local);
    } catch (_) {}

    // 2. If user is logged in, merge with alert_reads table
    final uid = ref.watch(currentUserIdProvider);
    if (uid != null) {
      final remote = await ref
          .read(notificationRepositoryProvider)
          .fetchReadAlertIds(uid);
      seen.addAll(remote);
    }

    return seen;
  }

  Future<void> markSeen(String alertId) async {
    final current = state.valueOrNull ?? {};
    if (current.contains(alertId)) return;

    final updated = Set<String>.from(current)..add(alertId);
    state = AsyncData(updated);

    // Save locally
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_seenAlertsKey, updated.toList());
    } catch (_) {}

    // Save to Supabase if logged in
    final uid = ref.read(currentUserIdProvider);
    if (uid != null) {
      await ref.read(notificationRepositoryProvider).markAlertRead(alertId, uid);
    }
  }

  Future<void> markAllSeen(List<String> alertIds) async {
    if (alertIds.isEmpty) return;
    final current = state.valueOrNull ?? {};
    final updated = Set<String>.from(current)..addAll(alertIds);
    state = AsyncData(updated);

    // Save locally
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_seenAlertsKey, updated.toList());
    } catch (_) {}

    // Save to Supabase if logged in
    final uid = ref.read(currentUserIdProvider);
    if (uid != null) {
      await ref
          .read(notificationRepositoryProvider)
          .markAllAlertsRead(alertIds, uid);
    }
  }
}

// ── Unread & Unseen counts ─────────────────────────────────────
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider).valueOrNull ?? [];
  return notifications.where((n) => !n.isRead).length;
});

final unseenAlertsCountProvider = Provider<int>((ref) {
  final alerts = ref.watch(alertsProvider).valueOrNull ?? [];
  final seenIds = ref.watch(seenAlertsProvider).valueOrNull ?? {};
  return alerts.where((a) => a.isVisibleToUser && !seenIds.contains(a.id)).length;
});

final totalNotificationsAndAlertsCountProvider = Provider<int>((ref) {
  final unreadNotifs = ref.watch(unreadNotificationCountProvider);
  final unseenAlerts = ref.watch(unseenAlertsCountProvider);
  return unreadNotifs + unseenAlerts;
});

