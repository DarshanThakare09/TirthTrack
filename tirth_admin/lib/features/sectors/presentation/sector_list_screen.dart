import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/custom_map_marker_helper.dart';
import '../../../models/sector_model.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../police_bases/presentation/police_base_providers.dart';
import 'sector_providers.dart';

class SectorListScreen extends ConsumerStatefulWidget {
  const SectorListScreen({super.key});

  @override
  ConsumerState<SectorListScreen> createState() => _SectorListScreenState();
}

class _SectorListScreenState extends ConsumerState<SectorListScreen> {
  final _searchController = TextEditingController();
  GoogleMapController? _mapController;
  bool _isMapView = true;

  // Drawing state
  bool _isDrawingMode = false;
  final List<LatLng> _drawingNodes = [];
  SectorModel? _selectedSector;

  final List<String> _presetColors = [
    '#FF7722', // Brand Saffron
    '#3B82F6', // Blue
    '#10B981', // Emerald Green
    '#8B5CF6', // Purple
    '#EC4899', // Pink
    '#F59E0B', // Amber
    '#06B6D4', // Cyan
    '#EF4444', // Red
    '#64748B', // Slate
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapTap(LatLng latLng) {
    if (_isDrawingMode) {
      setState(() {
        _drawingNodes.add(latLng);
      });
    } else if (_selectedSector != null) {
      setState(() {
        _selectedSector = null;
      });
    }
  }

  void _undoLastNode() {
    if (_drawingNodes.isNotEmpty) {
      setState(() {
        _drawingNodes.removeLast();
      });
    }
  }

  void _clearDrawingNodes() {
    setState(() {
      _drawingNodes.clear();
    });
  }

  void _cancelDrawing() {
    setState(() {
      _isDrawingMode = false;
      _drawingNodes.clear();
    });
  }

  Future<void> _submitSectorPolygon() async {
    if (_drawingNodes.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            'A valid sector boundary requires at least 3 nodes to form a polygon.',
          ),
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final descController = TextEditingController();
    String selectedColor = _presetColors.first;
    String? selectedPoliceBaseId;

    final basesAsync = ref.read(policeBaseListProvider);
    final bases = basesAsync.valueOrNull ?? [];

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.save_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Save New Sector',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: SizedBox(
            width: 380,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.polyline_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Closed Polygon: ${_drawingNodes.length} boundary nodes',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    AppTextField(
                      controller: nameController,
                      label: 'Sector Name *',
                      hint: 'e.g. Ramkund VIP Sector, Tapovan Sector 1',
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Sector Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    AppTextField(
                      controller: codeController,
                      label: 'Sector Code',
                      hint: 'e.g. SEC-01, RK-01',
                    ),
                    const SizedBox(height: 12),

                    AppTextField(
                      controller: descController,
                      label: 'Description',
                      hint: 'Key landmarks, crowd flow guidance...',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),

                    // Color Picker
                    const Text(
                      'Sector Map Color *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _presetColors.map((hex) {
                        final color = Color(
                          int.parse('0xFF${hex.replaceAll("#", "")}'),
                        );
                        final isSelected = selectedColor == hex;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() => selectedColor = hex);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.white,
                                width: isSelected ? 3 : 1,
                              ),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.7),
                                    blurRadius: 8,
                                  ),
                              ],
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Police Base Assignment
                    if (bases.isNotEmpty) ...[
                      const Text(
                        'Assigned Police Base (Optional)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: selectedPoliceBaseId,
                        hint: const Text('None (Unassigned)'),
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('None (Unassigned)'),
                          ),
                          ...bases.map(
                            (b) => DropdownMenuItem<String>(
                              value: b.id,
                              child: Text(
                                '${b.baseName} (${b.stationName ?? "Outpost"})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          setDialogState(() => selectedPoliceBaseId = val);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogCtx, true);
                }
              },
              child: const Text('Save Sector'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      final sector = SectorModel(
        id: '',
        sectorName: nameController.text.trim(),
        sectorCode: codeController.text.trim().isNotEmpty
            ? codeController.text.trim()
            : null,
        description: descController.text.trim().isNotEmpty
            ? descController.text.trim()
            : null,
        policeBaseId: selectedPoliceBaseId,
        colorHex: selectedColor,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final latLngList = _drawingNodes
          .map((n) => ll.LatLng(n.latitude, n.longitude))
          .toList();

      final success = await ref
          .read(sectorActionControllerProvider.notifier)
          .createSectorWithNodes(
            sector: sector,
            nodes: latLngList,
          );

      if (success && mounted) {
        setState(() {
          _isDrawingMode = false;
          _drawingNodes.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text(
              'Sector "${sector.sectorName}" created successfully with boundary nodes.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleDelete(SectorModel sector) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Sector?',
      message:
          'Are you sure you want to delete "${sector.sectorName}"? All boundary polygon nodes will be permanently removed.',
      confirmLabel: 'Delete Sector',
      isDestructive: true,
      icon: Icons.delete_forever_rounded,
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(sectorActionControllerProvider.notifier)
          .deleteSector(sector.id);

      if (success && mounted) {
        if (_selectedSector?.id == sector.id) {
          setState(() {
            _selectedSector = null;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.onBackground,
            content: Text('Sector "${sector.sectorName}" deleted.'),
          ),
        );
      }
    }
  }

  Future<Set<Marker>> _generateMapMarkers(List<SectorModel> sectors) async {
    final markers = <Marker>{};

    // 1. Drawing mode markers
    if (_isDrawingMode && _drawingNodes.isNotEmpty) {
      for (int i = 0; i < _drawingNodes.length; i++) {
        final node = _drawingNodes[i];
        final icon = await CustomMapMarkerHelper.getNodeMarker(
          order: i + 1,
          isFirst: i == 0,
          isLast: i == _drawingNodes.length - 1,
        );

        markers.add(
          Marker(
            markerId: MarkerId('draw_node_$i'),
            position: node,
            icon: icon,
            infoWindow: InfoWindow(title: 'Node #${i + 1}'),
          ),
        );
      }
    }

    // 2. Browse mode center markers
    if (!_isDrawingMode) {
      for (final sector in sectors) {
        final center = sector.centerPoint;
        if (center != null) {
          markers.add(
            Marker(
              markerId: MarkerId('sector_center_${sector.id}'),
              position: LatLng(center.latitude, center.longitude),
              infoWindow: InfoWindow(
                title: sector.sectorName,
                snippet:
                    '${sector.sectorCode ?? "Sector"} • ${sector.nodes.length} Nodes',
                onTap: () {
                  setState(() => _selectedSector = sector);
                },
              ),
              onTap: () {
                setState(() => _selectedSector = sector);
              },
            ),
          );
        }
      }
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final sectorsWithNodesAsync = ref.watch(sectorsWithNodesProvider);
    final sectorsAsync = ref.watch(sectorListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: !_isDrawingMode
          ? FloatingActionButton.extended(
              onPressed: () {
                setState(() {
                  _isMapView = true;
                  _isDrawingMode = true;
                  _drawingNodes.clear();
                  _selectedSector = null;
                });
              },
              icon: const Icon(Icons.draw_rounded),
              label: const Text(
                'Draw New Sector',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      body: Column(
        children: [
          // Header Bar with View Toggle & Search
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: AppColors.surface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      ref.read(sectorSearchQueryProvider.notifier).state = val;
                    },
                    decoration: InputDecoration(
                      hintText: 'Search sectors, codes, bases...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(sectorSearchQueryProvider.notifier)
                                    .state = '';
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      icon: Icon(Icons.map_rounded, size: 18),
                      label: Text('Map'),
                    ),
                    ButtonSegment(
                      value: false,
                      icon: Icon(Icons.view_list_rounded, size: 18),
                      label: Text('List'),
                    ),
                  ],
                  selected: {_isMapView},
                  onSelectionChanged: (Set<bool> newSelection) {
                    setState(() {
                      _isMapView = newSelection.first;
                    });
                  },
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Main Content
          Expanded(
            child: _isMapView
                ? sectorsWithNodesAsync.when(
                    loading: () => const LoadingWidget(
                      label: 'Loading Sector Boundaries Map...',
                    ),
                    error: (err, _) => AppErrorWidget(
                      message: err.toString(),
                      onRetry: () => ref.refresh(sectorsWithNodesProvider),
                    ),
                    data: (sectors) => _buildGoogleMapAllocationView(sectors),
                  )
                : sectorsAsync.when(
                    loading: () => const LoadingWidget(
                      label: 'Loading Mela Sectors...',
                    ),
                    error: (err, _) => AppErrorWidget(
                      message: err.toString(),
                      onRetry: () => ref.refresh(sectorListProvider),
                    ),
                    data: (sectors) => _buildListView(sectors),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleMapAllocationView(List<SectorModel> sectors) {
    const kumbhCenter = LatLng(
      AppConfig.kumbhCenterLat,
      AppConfig.kumbhCenterLng,
    );

    // Build Polygons for existing sectors
    final polygons = <Polygon>{};
    final polylines = <Polyline>{};

    for (final sector in sectors) {
      final pts = sector.nodes
          .map((n) => LatLng(n.latitude, n.longitude))
          .toList();
      if (pts.length >= 3) {
        final color = sector.displayColor;
        polygons.add(
          Polygon(
            polygonId: PolygonId(sector.id),
            points: pts,
            fillColor: color.withValues(alpha: 0.25),
            strokeColor: color,
            strokeWidth: _selectedSector?.id == sector.id ? 4 : 2,
            consumeTapEvents: true,
            onTap: () {
              setState(() => _selectedSector = sector);
            },
          ),
        );
      }
    }

    // Live drawing layer
    if (_isDrawingMode && _drawingNodes.isNotEmpty) {
      // Connecting line
      if (_drawingNodes.length >= 2) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('drawing_line'),
            points: _drawingNodes,
            color: AppColors.primary,
            width: 3,
          ),
        );
      }

      // Closed polygon preview
      if (_drawingNodes.length >= 3) {
        polygons.add(
          Polygon(
            polygonId: const PolygonId('drawing_preview_polygon'),
            points: _drawingNodes,
            fillColor: AppColors.primary.withValues(alpha: 0.2),
            strokeColor: AppColors.primary,
            strokeWidth: 2,
          ),
        );
      }
    }

    return Stack(
      children: [
        FutureBuilder<Set<Marker>>(
          future: _generateMapMarkers(sectors),
          builder: (context, snapshot) {
            final markers = snapshot.data ?? {};

            return GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: kumbhCenter,
                zoom: 13.5,
              ),
              onMapCreated: (controller) => _mapController = controller,
              onTap: _onMapTap,
              polygons: polygons,
              polylines: polylines,
              markers: markers,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(
                  () => ScaleGestureRecognizer(),
                ),
              },
            );
          },
        ),

        // Recenter Floating Button
        Positioned(
          top: _isDrawingMode ? 140 : 12,
          right: 12,
          child: FloatingActionButton.small(
            heroTag: 'recenter_sector_map',
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            tooltip: 'Recenter Map to Kumbh Area',
            child: const Icon(Icons.my_location_rounded),
            onPressed: () {
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(kumbhCenter, 13.5),
              );
            },
          ),
        ),

        // Drawing Mode Controller Panel
        if (_isDrawingMode)
          Positioned(
            left: 16,
            right: 16,
            top: 12,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.touch_app_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tap Map to Place Node #${_drawingNodes.length + 1}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.onBackground,
                                ),
                              ),
                              Text(
                                _drawingNodes.length < 3
                                    ? 'Add at least 3 nodes to form polygon (${3 - _drawingNodes.length} more needed)'
                                    : '${_drawingNodes.length} nodes placed • Ready to save sector',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _drawingNodes.length < 3
                                      ? AppColors.error
                                      : AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          tooltip: 'Cancel Drawing',
                          onPressed: _cancelDrawing,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (_drawingNodes.isNotEmpty) ...[
                          OutlinedButton.icon(
                            onPressed: _undoLastNode,
                            icon: const Icon(Icons.undo_rounded, size: 16),
                            label: const Text('Undo Node'),
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: _clearDrawingNodes,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              visualDensity: VisualDensity.compact,
                            ),
                            child: const Text('Clear All'),
                          ),
                          const Spacer(),
                        ] else
                          const Spacer(),
                        ElevatedButton.icon(
                          onPressed: _drawingNodes.length >= 3
                              ? _submitSectorPolygon
                              : null,
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text(
                            'Save Sector',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Selected Sector Details Card (Browse Mode)
        if (!_isDrawingMode && _selectedSector != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: _selectedSector!.displayColor.withValues(alpha: 0.6),
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _selectedSector!.displayColor
                                .withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.map_rounded,
                            color: _selectedSector!.displayColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedSector!.sectorName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.onBackground,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_selectedSector!.sectorCode ?? "No Code"} • ${_selectedSector!.nodes.length} Polygon Nodes',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.onSurfaceMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () =>
                              setState(() => _selectedSector = null),
                        ),
                      ],
                    ),
                    if (_selectedSector!.description != null &&
                        _selectedSector!.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _selectedSector!.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceMuted,
                        ),
                      ),
                    ],
                    if (_selectedSector!.policeBaseName != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.shield_rounded,
                              size: 14,
                              color: Color(0xFF1E40AF),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Base: ${_selectedSector!.policeBaseName!}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1E40AF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context
                                .go('/sectors/${_selectedSector!.id}/edit'),
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            label: const Text('Edit Details'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _handleDelete(_selectedSector!),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                            ),
                            icon: const Icon(Icons.delete_forever_rounded,
                                size: 16),
                            label: const Text('Delete'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildListView(List<SectorModel> sectors) {
    if (sectors.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.map_outlined,
        title: 'No Sectors Defined',
        message:
            'Create zonal boundary sectors to allocate emergency staff and organize crowd management areas.',
        actionLabel: 'Draw First Sector',
        onAction: () {
          setState(() {
            _isMapView = true;
            _isDrawingMode = true;
            _drawingNodes.clear();
          });
        },
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: sectors.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final sector = sectors[index];
        final color = sector.displayColor;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withValues(alpha: 0.4)),
                      ),
                      child: Center(
                        child: Text(
                          sector.sectorCode ?? 'S',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sector.sectorName,
                            style: AppTextStyles.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Sector Code: ${sector.sectorCode ?? "Unassigned"}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceMuted,
                            ),
                          ),
                        ],
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
                      fontSize: 12,
                      color: AppColors.onSurfaceMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: sector.policeBaseName != null
                          ? Row(
                              children: [
                                const Icon(
                                  Icons.shield_outlined,
                                  size: 14,
                                  color: AppColors.onSurfaceMuted,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    sector.policeBaseName!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.onSurfaceMuted,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'No Police Base Assigned',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.onSurfaceMuted,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      tooltip: 'Edit Sector',
                      onPressed: () =>
                          context.go('/sectors/${sector.id}/edit'),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_forever_rounded,
                        size: 18,
                        color: AppColors.error,
                      ),
                      tooltip: 'Delete Sector',
                      onPressed: () => _handleDelete(sector),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
