import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/sector_model.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/state_widgets.dart';
import 'sector_providers.dart';

class SectorListScreen extends ConsumerStatefulWidget {
  const SectorListScreen({super.key});

  @override
  ConsumerState<SectorListScreen> createState() => _SectorListScreenState();
}

class _SectorListScreenState extends ConsumerState<SectorListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete(SectorModel sector) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Sector?',
      message:
          'Are you sure you want to delete "${sector.sectorName}"? All ${sector.nodeCount} boundary polygon nodes will be permanently removed.',
      confirmLabel: 'Delete Sector',
      isDestructive: true,
      icon: Icons.delete_forever_rounded,
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(sectorActionControllerProvider.notifier)
          .deleteSector(sector.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.onBackground,
            content: Text('Sector "${sector.sectorName}" deleted.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sectorsAsync = ref.watch(sectorListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/sectors/new'),
        icon: const Icon(Icons.add_location_rounded),
        label: const Text('Add Sector', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.refresh(sectorListProvider.future),
        child: Column(
          children: [
            // Search Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              color: AppColors.surface,
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  ref.read(sectorSearchQueryProvider.notifier).state = val;
                },
                decoration: InputDecoration(
                  hintText: 'Search sectors, codes, police bases...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(sectorSearchQueryProvider.notifier).state =
                                '';
                          },
                        )
                      : null,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const Divider(height: 1),

            // Sectors List
            Expanded(
              child: sectorsAsync.when(
                loading: () =>
                    const LoadingWidget(message: 'Loading mela sectors...'),
                error: (err, _) => ErrorStateWidget(
                  message: err.toString(),
                  onRetry: () => ref.refresh(sectorListProvider),
                ),
                data: (sectors) {
                  if (sectors.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.map_outlined,
                      title: 'No Sectors Defined',
                      message:
                          'Define administrative zonal sectors, boundary polygon nodes, and link them with police bases.',
                      actionLabel: 'Add First Sector',
                      onAction: () => context.go('/sectors/new'),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: sectors.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final sector = sectors[index];
                      return _SectorCard(
                        sector: sector,
                        onTap: () => context.go('/sectors/${sector.id}'),
                        onEdit: () => context.go('/sectors/${sector.id}/edit'),
                        onDelete: () => _handleDelete(sector),
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

class _SectorCard extends StatelessWidget {
  const _SectorCard({
    required this.sector,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final SectorModel sector;
  final VoidCallback onTap;
  final VoidCallback onEdit;
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
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: sector.displayColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: sector.displayColor, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.map_rounded,
                      color: sector.displayColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sector.sectorName,
                          style: AppTextStyles.titleLarge,
                        ),
                        if (sector.sectorCode != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Code: ${sector.sectorCode}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sector.displayColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '${sector.nodeCount} Boundary Nodes',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),

              if (sector.description != null &&
                  sector.description!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  sector.description!,
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

              Row(
                children: [
                  const Icon(Icons.shield_outlined,
                      size: 14, color: AppColors.onSurfaceMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      sector.policeBaseName != null
                          ? 'Base: ${sector.policeBaseName}'
                          : 'No police base assigned',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: sector.policeBaseName != null
                            ? AppColors.onSurface
                            : AppColors.onSurfaceDisabled,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: 'Edit Sector',
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 18, color: AppColors.error),
                    tooltip: 'Delete Sector',
                    onPressed: onDelete,
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
