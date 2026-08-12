import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/service_model.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../../shared/widgets/status_badge.dart';
import 'service_providers.dart';

class ServiceListScreen extends ConsumerStatefulWidget {
  const ServiceListScreen({super.key});

  @override
  ConsumerState<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends ConsumerState<ServiceListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete(ServiceModel service) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Facility / Service?',
      message:
          'Are you sure you want to delete "${service.serviceName}"? Pilgrims will no longer see this location on the public map.',
      confirmLabel: 'Delete Service',
      isDestructive: true,
      icon: Icons.delete_forever_rounded,
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(serviceActionControllerProvider.notifier)
          .deleteService(service.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.onBackground,
            content: Text('Service "${service.serviceName}" deleted.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(serviceListProvider);
    final selectedType = ref.watch(serviceTypeFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/services/new'),
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text('Add Service', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.refresh(serviceListProvider.future),
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
                      ref.read(serviceSearchQueryProvider.notifier).state = val;
                    },
                    decoration: InputDecoration(
                      hintText: 'Search services, facilities, contacts...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(serviceSearchQueryProvider.notifier).state = '';
                              },
                            )
                          : null,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Service Types Filter
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _TypeFilterChip(
                          label: 'All Types',
                          isSelected: selectedType == null,
                          onTap: () {
                            ref.read(serviceTypeFilterProvider.notifier).state = null;
                          },
                        ),
                        ...ServiceTypeEnum.values.map((t) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: _TypeFilterChip(
                              label: t.displayLabel,
                              icon: t.icon,
                              color: t.color,
                              isSelected: selectedType == t,
                              onTap: () {
                                ref.read(serviceTypeFilterProvider.notifier).state =
                                    selectedType == t ? null : t;
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

            // Services List
            Expanded(
              child: servicesAsync.when(
                loading: () => const LoadingWidget(message: 'Loading facilities & services...'),
                error: (err, _) => ErrorStateWidget(
                  message: err.toString(),
                  onRetry: () => ref.refresh(serviceListProvider),
                ),
                data: (services) {
                  if (services.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.medical_services_outlined,
                      title: 'No Facilities Found',
                      message:
                          'Add medical camps, water booths, food distribution centers, restrooms, and parking lots for pilgrims.',
                      actionLabel: 'Add First Service',
                      onAction: () => context.go('/services/new'),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: services.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final service = services[index];
                      return _ServiceCard(
                        service: service,
                        onEdit: () => context.go('/services/${service.id}/edit'),
                        onToggleActive: () {
                          ref
                              .read(serviceActionControllerProvider.notifier)
                              .toggleActive(service.id, service.isActive);
                        },
                        onDelete: () => _handleDelete(service),
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

class _TypeFilterChip extends StatelessWidget {
  const _TypeFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.color,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
                fontSize: 12,
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

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  final ServiceModel service;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
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
                    color: service.serviceType.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    service.serviceType.icon,
                    color: service.serviceType.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.serviceName,
                        style: AppTextStyles.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        service.serviceType.displayLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: service.serviceType.color,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge.active(service.isActive),
              ],
            ),

            if (service.description != null &&
                service.description!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                service.description!,
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
            const SizedBox(height: 10),

            // Operational Details
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 14, color: AppColors.onSurfaceMuted),
                const SizedBox(width: 4),
                Text(
                  service.formattedHours,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(width: 14),
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.onSurfaceMuted),
                const SizedBox(width: 4),
                Text(
                  '${service.latitude.toStringAsFixed(4)}, ${service.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurface,
                  ),
                ),
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
                          Text('Edit Service'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            service.isActive
                                ? Icons.do_not_disturb_on_rounded
                                : Icons.check_circle_rounded,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(service.isActive ? 'Deactivate' : 'Activate'),
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

            if (service.contactPerson != null ||
                service.contactNumber != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded,
                      size: 14, color: AppColors.onSurfaceMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${service.contactPerson ?? "Incharge"}${service.contactNumber != null ? " • ${service.contactNumber!}" : ""}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
