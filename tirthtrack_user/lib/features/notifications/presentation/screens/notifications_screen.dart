// ============================================================
// features/notifications/presentation/screens/notifications_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../models/notification_models.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAllActiveAlertsSeen();
    });
  }

  void _markAllActiveAlertsSeen() {
    final alerts = ref.read(alertsProvider).valueOrNull ?? [];
    final activeIds =
        alerts.where((a) => a.isVisibleToUser).map((a) => a.id).toList();
    if (activeIds.isNotEmpty) {
      ref.read(seenAlertsProvider.notifier).markAllSeen(activeIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Automatically mark active alerts seen whenever loaded or updated
    ref.listen<AsyncValue<List<AlertModel>>>(alertsProvider, (prev, next) {
      final alerts = next.valueOrNull ?? [];
      final activeIds =
          alerts.where((a) => a.isVisibleToUser).map((a) => a.id).toList();
      if (activeIds.isNotEmpty) {
        ref.read(seenAlertsProvider.notifier).markAllSeen(activeIds);
      }
    });

    // Automatically mark personal notifications read whenever loaded or received
    ref.listen<AsyncValue<List<NotificationModel>>>(notificationsProvider,
        (prev, next) {
      final notifs = next.valueOrNull ?? [];
      if (notifs.any((n) => !n.isRead)) {
        ref.read(notificationsProvider.notifier).markAllRead();
      }
    });

    final notifState = ref.watch(notificationsProvider);
    final alertsState = ref.watch(alertsProvider);
    final seenAlertIds = ref.watch(seenAlertsProvider).valueOrNull ?? {};
    final unreadNotifs = ref.watch(unreadNotificationCountProvider);
    final unseenAlerts = ref.watch(unseenAlertsCountProvider);
    final totalUnread = unreadNotifs + unseenAlerts;

    // Check on current frame if there are alerts to mark seen or notifications to mark read
    final activeAlerts = (alertsState.valueOrNull ?? [])
        .where((a) => a.isVisibleToUser)
        .toList();
    final unseenIds = activeAlerts
        .where((a) => !seenAlertIds.contains(a.id))
        .map((a) => a.id)
        .toList();
    if (unseenIds.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(seenAlertsProvider.notifier).markAllSeen(unseenIds);
        }
      });
    }

    final notifs = notifState.valueOrNull ?? [];
    if (notifs.any((n) => !n.isRead)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(notificationsProvider.notifier).markAllRead();
        }
      });
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          actions: [
            if (totalUnread > 0)
              TextButton(
                onPressed: () {
                  ref.read(notificationsProvider.notifier).markAllRead();
                  _markAllActiveAlertsSeen();
                },
                child: const Text('Mark All Read'),
              ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Alerts'),
                    if (unseenAlerts > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$unseenAlerts',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Notifications'),
                    if (unreadNotifs > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$unreadNotifs',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ── Alerts tab ──────────────────────────────────────
            alertsState.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => AppErrorWidget(
                message: e.toString(),
                onRetry: () => ref.refresh(alertsProvider),
              ),
              data: (alerts) {
                final activeAlerts =
                    alerts.where((a) => a.isVisibleToUser).toList();
                if (activeAlerts.isEmpty) {
                  return const EmptyStateWidget(
                    title: 'No Active Alerts',
                    subtitle:
                        'You will see emergency and general alerts here.',
                    icon: Icons.notifications_none_rounded,
                  );
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    await ref.read(alertsProvider.notifier).refresh();
                    _markAllActiveAlertsSeen();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: activeAlerts.length,
                    itemBuilder: (_, i) {
                      final alert = activeAlerts[i];
                      final isSeen = seenAlertIds.contains(alert.id);
                      return _AlertTile(
                        alert: alert,
                        isSeen: isSeen,
                        onTap: () {
                          ref
                              .read(seenAlertsProvider.notifier)
                              .markSeen(alert.id);
                        },
                      );
                    },
                  ),
                );
              },
            ),

            // ── Notifications tab ───────────────────────────────
            notifState.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => AppErrorWidget(
                message: e.toString(),
                onRetry: () => ref.refresh(notificationsProvider),
              ),
              data: (notifications) {
                if (notifications.isEmpty) {
                  return const EmptyStateWidget(
                    title: 'No Notifications',
                    subtitle:
                        'Personal notifications from the admin will appear here.',
                    icon: Icons.inbox_outlined,
                  );
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () =>
                      ref.read(notificationsProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: notifications.length,
                    itemBuilder: (_, i) => _NotificationTile(
                      notification: notifications[i],
                      onTap: () => ref
                          .read(notificationsProvider.notifier)
                          .markRead(notifications[i].id),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Alert tile ────────────────────────────────────────────────
class _AlertTile extends StatelessWidget {
  const _AlertTile({
    required this.alert,
    this.isSeen = true,
    this.onTap,
  });

  final AlertModel alert;
  final bool isSeen;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = alert.priority.color;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSeen
                ? color.withValues(alpha: 0.3)
                : color.withValues(alpha: 0.8),
            width: isSeen ? 1 : 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(alert.alertType.icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            alert.title,
                            style: AppTextStyles.labelLarge
                                .copyWith(color: color),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!isSeen) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            alert.priority.displayLabel,
                            style: AppTextStyles.caption
                                .copyWith(color: color),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(alert.message, style: AppTextStyles.bodySmall),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('dd MMM yyyy, hh:mm a')
                          .format(alert.createdAt.toLocal()),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Notification tile ─────────────────────────────────────────
class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: notification.isRead
            ? AppColors.surface
            : AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: notification.isRead ? AppColors.border : AppColors.primary,
          width: notification.isRead ? 0.5 : 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: notification.isRead
                ? AppColors.surfaceVariant
                : AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.notifications_outlined,
            color: notification.isRead
                ? AppColors.onSurfaceMuted
                : AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(notification.title, style: AppTextStyles.labelLarge),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body, style: AppTextStyles.bodySmall),
            Text(
              DateFormat('dd MMM yyyy, hh:mm a')
                  .format(notification.createdAt.toLocal()),
              style: AppTextStyles.caption,
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: notification.isRead ? null : onTap,
        isThreeLine: true,
      ),
    );
  }
}
