import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/police_base_model.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../../shared/widgets/status_badge.dart';
import 'police_base_providers.dart';

class PoliceBaseListScreen extends ConsumerStatefulWidget {
  const PoliceBaseListScreen({super.key});

  @override
  ConsumerState<PoliceBaseListScreen> createState() =>
      _PoliceBaseListScreenState();
}

class _PoliceBaseListScreenState extends ConsumerState<PoliceBaseListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete(PoliceBaseModel base) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Police Base?',
      message:
          'Are you sure you want to delete "${base.baseName}"? Sectors assigned to this police base will have their base association unlinked.',
      confirmLabel: 'Delete Police Base',
      isDestructive: true,
      icon: Icons.delete_forever_rounded,
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(policeBaseActionControllerProvider.notifier)
          .deleteBase(base.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.onBackground,
            content: Text('Police Base "${base.baseName}" deleted.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final basesAsync = ref.watch(policeBaseListProvider);
    final activeFilter = ref.watch(policeBaseActiveFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/police-bases/new'),
        icon: const Icon(Icons.add_moderator_rounded),
        label: const Text('Add Police Base',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.refresh(policeBaseListProvider.future),
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
                      ref.read(policeBaseSearchQueryProvider.notifier).state =
                          val;
                    },
                    decoration: InputDecoration(
                      hintText: 'Search bases, station name, incharge...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(
                                        policeBaseSearchQueryProvider.notifier)
                                    .state = '';
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All Bases',
                          isSelected: activeFilter == null,
                          onTap: () {
                            ref
                                .read(policeBaseActiveFilterProvider.notifier)
                                .state = null;
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Active Only',
                          isSelected: activeFilter == true,
                          icon: Icons.check_circle_rounded,
                          activeColor: AppColors.success,
                          onTap: () {
                            ref
                                .read(policeBaseActiveFilterProvider.notifier)
                                .state = true;
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Inactive Only',
                          isSelected: activeFilter == false,
                          icon: Icons.do_not_disturb_on_rounded,
                          activeColor: AppColors.onSurfaceMuted,
                          onTap: () {
                            ref
                                .read(policeBaseActiveFilterProvider.notifier)
                                .state = false;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Bases List
            Expanded(
              child: basesAsync.when(
                loading: () =>
                    const LoadingWidget(message: 'Loading police bases...'),
                error: (err, _) => ErrorStateWidget(
                  message: err.toString(),
                  onRetry: () => ref.refresh(policeBaseListProvider),
                ),
                data: (bases) {
                  if (bases.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.shield_outlined,
                      title: 'No Police Bases Found',
                      message:
                          'Register police stations, chowkis, and outpost control posts across sectors.',
                      actionLabel: 'Add First Police Base',
                      onAction: () => context.go('/police-bases/new'),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: bases.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final base = bases[index];
                      return _PoliceBaseCard(
                        base: base,
                        onEdit: () =>
                            context.go('/police-bases/${base.id}/edit'),
                        onToggleActive: () {
                          ref
                              .read(
                                  policeBaseActionControllerProvider.notifier)
                              .toggleActive(base.id, base.isActive);
                        },
                        onDelete: () => _handleDelete(base),
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

class _PoliceBaseCard extends StatelessWidget {
  const _PoliceBaseCard({
    required this.base,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  final PoliceBaseModel base;
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
                    color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    color: Color(0xFF6366F1),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        base.baseName,
                        style: AppTextStyles.titleLarge,
                      ),
                      if (base.stationName != null ||
                          base.sectorName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${base.stationName ?? ""}${base.stationName != null && base.sectorName != null ? " • " : ""}${base.sectorName != null ? "Sector: ${base.sectorName!}" : ""}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                StatusBadge.active(base.isActive),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Base Details
            Row(
              children: [
                const Icon(Icons.people_outline_rounded,
                    size: 14, color: AppColors.onSurfaceMuted),
                const SizedBox(width: 4),
                Text(
                  '${base.totalStaff} Personnel',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(width: 14),
                const Icon(Icons.pin_drop_outlined,
                    size: 14, color: AppColors.onSurfaceMuted),
                const SizedBox(width: 4),
                Text(
                  '${base.latitude.toStringAsFixed(4)}, ${base.longitude.toStringAsFixed(4)}',
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
                          Text('Edit Base'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            base.isActive
                                ? Icons.do_not_disturb_on_rounded
                                : Icons.check_circle_rounded,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(base.isActive ? 'Deactivate' : 'Activate'),
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

            if (base.inchargeName != null || base.contactNumber != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded,
                      size: 14, color: AppColors.onSurfaceMuted),
                  const SizedBox(width: 4),
                  Text(
                    'Incharge: ${base.inchargeName ?? "N/A"}${base.contactNumber != null ? " • ${base.contactNumber!}" : ""}',
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
