import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/alert_model.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../../shared/widgets/status_badge.dart';
import 'alert_providers.dart';

class AlertListScreen extends ConsumerStatefulWidget {
  const AlertListScreen({super.key});

  @override
  ConsumerState<AlertListScreen> createState() => _AlertListScreenState();
}

class _AlertListScreenState extends ConsumerState<AlertListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete(AlertModel alert) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Alert Broadcast?',
      message:
          'Are you sure you want to permanently delete broadcast "${alert.title}"?',
      confirmLabel: 'Delete Alert',
      isDestructive: true,
      icon: Icons.delete_forever_rounded,
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(alertActionControllerProvider.notifier)
          .deleteAlert(alert.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.onBackground,
            content: Text('Alert "${alert.title}" deleted.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(alertListProvider);
    final selectedPriority = ref.watch(alertPriorityFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/alerts/new'),
        icon: const Icon(Icons.campaign_rounded),
        label: const Text('Broadcast Alert', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.refresh(alertListProvider.future),
        child: Column(
          children: [
            // Search & Priority Filter Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              color: AppColors.surface,
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      ref.read(alertSearchQueryProvider.notifier).state = val;
                    },
                    decoration: InputDecoration(
                      hintText: 'Search alerts, emergency broadcasts...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(alertSearchQueryProvider.notifier).state =
                                    '';
                              },
                            )
                          : null,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Priority Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _PriorityFilterChip(
                          label: 'All Priorities',
                          isSelected: selectedPriority == null,
                          onTap: () {
                            ref.read(alertPriorityFilterProvider.notifier).state =
                                null;
                          },
                        ),
                        ...AlertPriorityEnum.values.map((p) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: _PriorityFilterChip(
                              label: p.displayLabel,
                              color: p.color,
                              isSelected: selectedPriority == p,
                              onTap: () {
                                ref
                                    .read(
                                        alertPriorityFilterProvider.notifier)
                                    .state = selectedPriority == p ? null : p;
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Alerts List
            Expanded(
              child: alertsAsync.when(
                loading: () =>
                    const LoadingWidget(message: 'Loading alert broadcasts...'),
                error: (err, _) => ErrorStateWidget(
                  message: err.toString(),
                  onRetry: () => ref.refresh(alertListProvider),
                ),
                data: (alerts) {
                  if (alerts.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.notifications_off_outlined,
                      title: 'No Active Broadcasts',
                      message:
                          'Broadcast crowd updates, weather warnings, medical advisories, and official mela announcements.',
                      actionLabel: 'Broadcast First Alert',
                      onAction: () => context.go('/alerts/new'),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: alerts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
                      return _AlertCard(
                        alert: alert,
                        onEdit: () => context.go('/alerts/${alert.id}/edit'),
                        onToggleActive: () {
                          ref
                              .read(alertActionControllerProvider.notifier)
                              .toggleActive(alert.id, alert.isActive);
                        },
                        onDelete: () => _handleDelete(alert),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityFilterChip extends StatelessWidget {
  const _PriorityFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? effectiveColor.withValues(alpha: 0.14)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? effectiveColor : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? effectiveColor : AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  final AlertModel alert;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isExpired = alert.isExpired;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: alert.priority.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    alert.alertType.icon,
                    color: alert.priority.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: AppTextStyles.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            alert.alertType.displayLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(
                            label: alert.priority.displayLabel.toUpperCase(),
                            color: alert.priority.color,
                            fontSize: 10,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isExpired)
                  const StatusBadge(
                    label: 'Expired',
                    color: AppColors.onSurfaceMuted,
                    icon: Icons.timer_off_outlined,
                  )
                else
                  StatusBadge.active(alert.isActive),
              ],
            ),
            const SizedBox(height: 12),

            // Message Body
            Text(
              alert.message,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.onSurface,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Timestamps & Actions
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 14, color: AppColors.onSurfaceMuted),
                const SizedBox(width: 4),
                Text(
                  'Created: ${DateFormatter.timeAgo(alert.createdAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceMuted,
                  ),
                ),
                if (alert.expiresAt != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.hourglass_bottom_rounded,
                      size: 14, color: AppColors.onSurfaceMuted),
                  const SizedBox(width: 4),
                  Text(
                    'Expires: ${DateFormatter.formatDateTime(alert.expiresAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isExpired ? FontWeight.w700 : FontWeight.w500,
                      color: isExpired ? AppColors.error : AppColors.onSurfaceMuted,
                    ),
                  ),
                ],
                const Spacer(),

                // Action Menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                  onSelected: (val) {
                    if (val == 'edit') onEdit();
                    if (val == 'toggle') onToggleActive();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Edit Broadcast'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            alert.isActive
                                ? Icons.do_not_disturb_on_rounded
                                : Icons.check_circle_rounded,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(alert.isActive ? 'Deactivate' : 'Activate'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              size: 18, color: AppColors.error),
                          SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
