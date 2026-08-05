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

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifState = ref.watch(notificationsProvider);
    final alertsState = ref.watch(alertsProvider);
    final unread = ref.watch(unreadNotificationCountProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          actions: [
            if (unread > 0)
              TextButton(
                onPressed: () =>
                    ref.read(notificationsProvider.notifier).markAllRead(),
                child: const Text('Mark All Read'),
              ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Alerts'),
              Tab(text: 'Notifications'),
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
                if (alerts.isEmpty) {
                  return const EmptyStateWidget(
                    title: 'No Active Alerts',
                    subtitle:
                        'You will see emergency and general alerts here.',
                    icon: Icons.notifications_none_rounded,
                  );
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () =>
                      ref.read(alertsProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: alerts.length,
                    itemBuilder: (_, i) => _AlertTile(alert: alerts[i]),
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
  const _AlertTile({required this.alert});

  final AlertModel alert;

  @override
  Widget build(BuildContext context) {
    final color = alert.priority.color;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
                    children: [
                      Expanded(
                        child: Text(
                          alert.title,
                          style: AppTextStyles.labelLarge
                              .copyWith(color: color),
                        ),
                      ),
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
                    DateFormat('dd MMM, hh:mm a').format(alert.createdAt),
                    style: AppTextStyles.caption,
                  ),
                  if (alert.expiresAt != null)
                    Text(
                      'Expires: ${DateFormat('dd MMM, hh:mm a').format(alert.expiresAt!)}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.onSurfaceDisabled),
                    ),
                ],
              ),
            ),
          ],
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
              DateFormat('dd MMM, hh:mm a').format(notification.createdAt),
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
