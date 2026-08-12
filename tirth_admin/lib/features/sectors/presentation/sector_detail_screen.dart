import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/sector_model.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/location_picker_dialog.dart';
import '../../../shared/widgets/state_widgets.dart';
import 'sector_providers.dart';

class SectorDetailScreen extends ConsumerStatefulWidget {
  const SectorDetailScreen({
    super.key,
    required this.sectorId,
  });

  final String sectorId;

  @override
  ConsumerState<SectorDetailScreen> createState() => _SectorDetailScreenState();
}

class _SectorDetailScreenState extends ConsumerState<SectorDetailScreen>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _mapController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showAddNodeDialog(
    BuildContext context,
    int nextOrder,
    SectorModel sector,
  ) async {
    final formKey = GlobalKey<FormState>();
    final latController = TextEditingController();
    final lngController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: sector.displayColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.add_location_alt_rounded,
                    color: sector.displayColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text('Add Boundary Node #$nextOrder'),
              ],
            ),
            content: SizedBox(
              width: 360,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        final currentLat = double.tryParse(latController.text);
                        final currentLng = double.tryParse(lngController.text);
                        final initial = (currentLat != null && currentLng != null)
                            ? LatLng(currentLat, currentLng)
                            : null;

                        final picked = await LocationPickerDialog.show(
                          context,
                          initialLocation: initial,
                          title: 'Pick Boundary Coordinate',
                        );

                        if (picked != null) {
                          setDialogState(() {
                            latController.text =
                                picked.latitude.toStringAsFixed(6);
                            lngController.text =
                                picked.longitude.toStringAsFixed(6);
                          });
                        }
                      },
                      icon: const Icon(Icons.pin_drop_rounded),
                      label: const Text('Pick on Map'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: latController,
                      label: 'Latitude *',
                      hint: '19.997500',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Latitude required';
                        }
                        final d = double.tryParse(val.trim());
                        if (d == null || d < -90 || d > 90) {
                          return 'Invalid latitude (-90 to 90)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: lngController,
                      label: 'Longitude *',
                      hint: '73.789800',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Longitude required';
                        }
                        final d = double.tryParse(val.trim());
                        if (d == null || d < -180 || d > 180) {
                          return 'Invalid longitude (-180 to 180)';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final lat = double.parse(latController.text.trim());
                  final lng = double.parse(lngController.text.trim());

                  final node = SectorNodeModel(
                    id: '',
                    sectorId: widget.sectorId,
                    nodeOrder: nextOrder,
                    latitude: lat,
                    longitude: lng,
                    createdAt: DateTime.now(),
                  );

                  final success = await ref
                      .read(sectorActionControllerProvider.notifier)
                      .addNode(node);

                  if (success && context.mounted) {
                    Navigator.pop(dialogCtx);
                  }
                },
                child: const Text('Add Node'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleDeleteNode(SectorNodeModel node) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Boundary Node?',
      message:
          'Are you sure you want to delete Node #${node.nodeOrder}? Remaining boundary nodes will be automatically re-sequenced.',
      confirmLabel: 'Delete Node',
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );

    if (confirmed == true && mounted) {
      await ref
          .read(sectorActionControllerProvider.notifier)
          .deleteNode(node.id, widget.sectorId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sectorAsync = ref.watch(sectorDetailProvider(widget.sectorId));
    final nodesAsync = ref.watch(sectorNodesProvider(widget.sectorId));

    return sectorAsync.when(
      data: (sector) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(sector.sectorName),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Edit Sector',
                onPressed: () => context.go('/sectors/${sector.id}/edit'),
              ),
              const SizedBox(width: 8),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: sector.displayColor,
              labelColor: sector.displayColor,
              unselectedLabelColor: AppColors.onSurfaceMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700),
              tabs: const [
                Tab(icon: Icon(Icons.map_rounded), text: 'Polygon Map'),
                Tab(
                  icon: Icon(Icons.format_list_numbered_rounded),
                  text: 'Boundary Nodes',
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Interactive Map
              _buildMapTab(sector, nodesAsync),

              // Tab 2: Reorderable Nodes List
              _buildNodesTab(sector, nodesAsync),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Sector Details')),
        body: const LoadingWidget(message: 'Loading sector boundary...'),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Sector Details')),
        body: ErrorStateWidget(
          message: e.toString(),
          onRetry: () => ref.refresh(sectorDetailProvider(widget.sectorId)),
        ),
      ),
    );
  }

  Widget _buildMapTab(
    SectorModel sector,
    AsyncValue<List<SectorNodeModel>> nodesAsync,
  ) {
    return nodesAsync.when(
      data: (nodes) {
        final polygonPoints = nodes.map((n) => n.latLng).toList();
        final initialCenter = polygonPoints.isNotEmpty
            ? polygonPoints.first
            : AppConstants.nashikCenter;

        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: polygonPoints.isNotEmpty ? 15.0 : 13.0,
                maxZoom: 18.0,
                minZoom: 5.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: AppConstants.osmTileUrl,
                  userAgentPackageName: 'com.tirthtrack.admin',
                ),

                // Sector Polygon Layer
                if (polygonPoints.length >= 3)
                  PolygonLayer(
                    polygons: [
                      Polygon(
                        points: polygonPoints,
                        color: sector.displayColor.withValues(alpha: 0.25),
                        borderColor: sector.displayColor,
                        borderStrokeWidth: 3.0,
                      ),
                    ],
                  ),

                // Boundary Line if 2 nodes
                if (polygonPoints.length == 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: polygonPoints,
                        strokeWidth: 3.0,
                        color: sector.displayColor,
                      ),
                    ],
                  ),

                // Markers for each node
                MarkerLayer(
                  markers: nodes.map((node) {
                    return Marker(
                      point: node.latLng,
                      width: 32,
                      height: 32,
                      child: Container(
                        decoration: BoxDecoration(
                          color: sector.displayColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '${node.nodeOrder}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

            // Top Overlay Info Card
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: sector.displayColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sector.sectorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            nodes.length < 3
                                ? 'Add at least ${3 - nodes.length} more node(s) to form a closed polygon boundary'
                                : 'Boundary complete (${nodes.length} nodes)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: nodes.length < 3
                                  ? AppColors.warning
                                  : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.my_location_rounded),
                      tooltip: 'Center on Sector',
                      onPressed: () {
                        if (polygonPoints.isNotEmpty) {
                          _mapController.move(polygonPoints.first, 15.0);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const LoadingWidget(message: 'Loading map polygon...'),
      error: (e, _) => ErrorStateWidget(
        message: e.toString(),
        onRetry: () => ref.refresh(sectorNodesProvider(widget.sectorId)),
      ),
    );
  }

  Widget _buildNodesTab(
    SectorModel sector,
    AsyncValue<List<SectorNodeModel>> nodesAsync,
  ) {
    return nodesAsync.when(
      data: (nodes) {
        return Scaffold(
          backgroundColor: AppColors.background,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () =>
                _showAddNodeDialog(context, nodes.length + 1, sector),
            icon: const Icon(Icons.add_location_alt_rounded),
            label: const Text(
              'Add Boundary Node',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          body: nodes.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.polyline_rounded,
                  title: 'No Boundary Nodes',
                  message:
                      'Define at least 3 coordinates to form the geographic boundary polygon for ${sector.sectorName}.',
                  actionLabel: 'Add First Node',
                  onAction: () => _showAddNodeDialog(context, 1, sector),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      color: AppColors.surfaceVariant,
                      child: const Row(
                        children: [
                          Icon(
                            Icons.drag_indicator_rounded,
                            size: 18,
                            color: AppColors.onSurfaceMuted,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Long-press and drag any node to re-order the boundary polygon sequence.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.onSurfaceMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ReorderableListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                        itemCount: nodes.length,
                        onReorder: (oldIndex, newIndex) {
                          if (oldIndex < newIndex) {
                            newIndex -= 1;
                          }
                          final item = nodes.removeAt(oldIndex);
                          nodes.insert(newIndex, item);

                          ref
                              .read(sectorActionControllerProvider.notifier)
                              .reorderNodes(widget.sectorId, nodes);
                        },
                        itemBuilder: (context, index) {
                          final node = nodes[index];
                          return Card(
                            key: ValueKey(node.id),
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            elevation: 0,
                            color: AppColors.surface,
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: sector.displayColor,
                                child: Text(
                                  '${node.nodeOrder}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              title: Text(
                                'Lat: ${node.latitude.toStringAsFixed(6)}, Lng: ${node.longitude.toStringAsFixed(6)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: AppColors.error,
                                      size: 20,
                                    ),
                                    tooltip: 'Delete Node',
                                    onPressed: () => _handleDeleteNode(node),
                                  ),
                                  const Icon(
                                    Icons.drag_handle_rounded,
                                    color: AppColors.onSurfaceMuted,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        );
      },
      loading: () => const LoadingWidget(message: 'Loading nodes...'),
      error: (e, _) => ErrorStateWidget(
        message: e.toString(),
        onRetry: () => ref.refresh(sectorNodesProvider(widget.sectorId)),
      ),
    );
  }
}
