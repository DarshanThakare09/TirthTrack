import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/route_model.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../../shared/widgets/status_badge.dart';
import 'route_providers.dart';

class RouteListScreen extends ConsumerStatefulWidget {
  const RouteListScreen({super.key});

  @override
  ConsumerState<RouteListScreen> createState() => _RouteListScreenState();
}

class _RouteListScreenState extends ConsumerState<RouteListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete(RouteModel route) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Route?',
      message:
          'Are you sure you want to permanently delete "${route.routeName}"? All associated ${route.nodeCount} route nodes will also be deleted.',
      confirmLabel: 'Delete Route',
      isDestructive: true,
      icon: Icons.delete_forever_rounded,
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(routeActionControllerProvider.notifier)
          .deleteRoute(route.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.onBackground,
            content: Text('Route "${route.routeName}" deleted.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final routesAsync = ref.watch(routeListProvider);
    final activeFilter = ref.watch(routeActiveFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/routes/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Route', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.refresh(routeListProvider.future),
        child: Column(
          children: [
            // Search & Filter Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              color: AppColors.surface,
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      ref.read(routeSearchQueryProvider.notifier).state = val;
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by route name or route code...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(routeSearchQueryProvider.notifier).state = '';
                              },
                            )
                          : null,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All Routes',
                          isSelected: activeFilter == null,
                          onTap: () {
                            ref.read(routeActiveFilterProvider.notifier).state = null;
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Active Only',
                          isSelected: activeFilter == true,
                          icon: Icons.check_circle_rounded,
                          activeColor: AppColors.success,
                          onTap: () {
                            ref.read(routeActiveFilterProvider.notifier).state = true;
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Inactive Only',
                          isSelected: activeFilter == false,
                          icon: Icons.do_not_disturb_on_rounded,
                          activeColor: AppColors.onSurfaceMuted,
                          onTap: () {
                            ref.read(routeActiveFilterProvider.notifier).state = false;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Routes List
            Expanded(
              child: routesAsync.when(
                loading: () => const LoadingWidget(message: 'Loading routes...'),
                error: (err, _) => ErrorStateWidget(
                  message: err.toString(),
                  onRetry: () => ref.refresh(routeListProvider),
                ),
                data: (routes) {
                  if (routes.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.alt_route_rounded,
                      title: 'No Routes Found',
                      message:
                          'Create pilgrimage routes and assign ordered waypoint nodes for navigation.',
                      actionLabel: 'Create First Route',
                      onAction: () => context.go('/routes/new'),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: routes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final route = routes[index];
                      return _RouteCard(
                        route: route,
                        onTap: () => context.go('/routes/${route.id}'),
                        onEdit: () => context.go('/routes/${route.id}/edit'),
                        onToggleActive: () {
                          ref
                              .read(routeActionControllerProvider.notifier)
                              .toggleActive(route.id, route.isActive);
                        },
                        onDelete: () => _handleDelete(route),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.activeColor,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = activeColor ?? AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: isSelected ? effectiveColor : AppColors.onSurfaceMuted,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? effectiveColor : AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.route,
    required this.onTap,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  final RouteModel route;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
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
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.alt_route_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.routeName,
                          style: AppTextStyles.titleLarge,
                        ),
                        if (route.routeCode != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Code: ${route.routeCode}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  StatusBadge.active(route.isActive),
                ],
              ),
              if (route.description != null &&
                  route.description!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  route.description!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurfaceMuted,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Metrics & Quick Actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _MetricBadge(
                          icon: Icons.straighten_rounded,
                          label: route.formattedDistance,
                        ),
                        _MetricBadge(
                          icon: Icons.timer_outlined,
                          label: route.formattedTime,
                        ),
                        _MetricBadge(
                          icon: Icons.pin_drop_outlined,
                          label: '${route.nodeCount} Waypoints',
                        ),
                      ],
                    ),
                  ),
                  // Actions menu
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
                            Text('Edit Route'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              route.isActive
                                  ? Icons.do_not_disturb_on_rounded
                                  : Icons.check_circle_rounded,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(route.isActive ? 'Deactivate' : 'Activate'),
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
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.onSurfaceMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}
