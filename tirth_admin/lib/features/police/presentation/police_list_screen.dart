import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/police_officer_model.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../../shared/widgets/status_badge.dart';
import 'police_providers.dart';

class PoliceListScreen extends ConsumerStatefulWidget {
  const PoliceListScreen({
    super.key,
    this.initialFilter,
  });

  final String? initialFilter;

  @override
  ConsumerState<PoliceListScreen> createState() => _PoliceListScreenState();
}

class _PoliceListScreenState extends ConsumerState<PoliceListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null) {
      if (widget.initialFilter == 'pending') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(policeFilterProvider.notifier).state = PoliceStatusEnum.pending;
        });
      } else if (widget.initialFilter == 'verified') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(policeFilterProvider.notifier).state = PoliceStatusEnum.verified;
        });
      } else if (widget.initialFilter == 'rejected') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(policeFilterProvider.notifier).state = PoliceStatusEnum.rejected;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final officersAsync = ref.watch(policeListProvider);
    final currentFilter = ref.watch(policeFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.refresh(policeListProvider.future),
        child: Column(
          children: [
            // Search & Filter Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              color: AppColors.surface,
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      ref.read(policeSearchQueryProvider.notifier).state = val;
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by officer name, badge, station...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(policeSearchQueryProvider.notifier).state = '';
                              },
                            )
                          : null,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All Officers',
                          isSelected: currentFilter == null,
                          onTap: () {
                            ref.read(policeFilterProvider.notifier).state = null;
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Pending Review',
                          isSelected: currentFilter == PoliceStatusEnum.pending,
                          icon: Icons.hourglass_top_rounded,
                          activeColor: AppColors.statusPending,
                          onTap: () {
                            ref.read(policeFilterProvider.notifier).state =
                                PoliceStatusEnum.pending;
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Verified',
                          isSelected: currentFilter == PoliceStatusEnum.verified,
                          icon: Icons.verified_rounded,
                          activeColor: AppColors.statusVerified,
                          onTap: () {
                            ref.read(policeFilterProvider.notifier).state =
                                PoliceStatusEnum.verified;
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Rejected',
                          isSelected: currentFilter == PoliceStatusEnum.rejected,
                          icon: Icons.cancel_rounded,
                          activeColor: AppColors.statusRejected,
                          onTap: () {
                            ref.read(policeFilterProvider.notifier).state =
                                PoliceStatusEnum.rejected;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Officers List
            Expanded(
              child: officersAsync.when(
                loading: () => const LoadingWidget(message: 'Loading police officers...'),
                error: (err, _) => ErrorStateWidget(
                  message: err.toString(),
                  onRetry: () => ref.refresh(policeListProvider),
                ),
                data: (officers) {
                  if (officers.isEmpty) {
                    return const EmptyStateWidget(
                      icon: Icons.local_police_outlined,
                      title: 'No Police Records Found',
                      message:
                          'No officers match the selected filter criteria or search query.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: officers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final officer = officers[index];
                      return _PoliceOfficerCard(
                        officer: officer,
                        onTap: () => context.go('/police/${officer.id}'),
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

class _PoliceOfficerCard extends StatelessWidget {
  const _PoliceOfficerCard({
    required this.officer,
    required this.onTap,
  });

  final PoliceOfficerModel officer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primaryContainer,
                child: Text(
                  officer.officerDisplayName.isNotEmpty
                      ? officer.officerDisplayName[0].toUpperCase()
                      : 'P',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            officer.officerDisplayName,
                            style: AppTextStyles.titleLarge,
                          ),
                        ),
                        StatusBadge.police(officer.verificationStatus.dbValue),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Badge: ${officer.badgeNumber}${officer.designation != null ? " • ${officer.designation}" : ""}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.business_rounded,
                          size: 14,
                          color: AppColors.onSurfaceMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${officer.policeStation}, ${officer.district}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (officer.mobile != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: AppColors.onSurfaceMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            officer.mobile!,
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

              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.onSurfaceDisabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
