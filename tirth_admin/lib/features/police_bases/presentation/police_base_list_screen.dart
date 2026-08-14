import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/custom_map_marker_helper.dart';
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
  GoogleMapController? _mapController;
  bool _isMapView = true;
  PoliceBaseModel? _selectedBase;
  Set<Marker> _cachedMarkers = {};
  String _markerCacheKey = '';

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
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
        if (_selectedBase?.id == base.id) {
          setState(() {
            _selectedBase = null;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.onBackground,
            content: Text('Police Base "${base.baseName}" deleted.'),
          ),
        );
      }
    }
  }

  Future<Set<Marker>> _generateMarkers(List<PoliceBaseModel> bases) async {
    final key =
        '${bases.map((b) => "${b.id}_${b.latitude}_${b.longitude}_${b.isActive}").join(",")}_${_selectedBase?.id}';
    if (key == _markerCacheKey && _cachedMarkers.isNotEmpty) {
      return _cachedMarkers;
    }

    final markers = <Marker>{};
    for (final base in bases) {
      final isSelected = _selectedBase?.id == base.id;
      final icon = await CustomMapMarkerHelper.getPoliceMarker(
        isSelected: isSelected,
      );

      markers.add(
        Marker(
          markerId: MarkerId(base.id),
          position: LatLng(base.latitude, base.longitude),
          icon: icon,
          infoWindow: InfoWindow(
            title: base.baseName,
            snippet:
                '${base.stationName ?? "Police Outpost"} • ${base.totalStaff} Officers',
          ),
          onTap: () {
            setState(() => _selectedBase = base);
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng(base.latitude, base.longitude),
                16.0,
              ),
            );
          },
        ),
      );
    }

    _markerCacheKey = key;
    _cachedMarkers = markers;
    return markers;
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
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: AppColors.surface,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          ref.read(policeBaseSearchQueryProvider.notifier).state =
                              val;
                        },
                        decoration: InputDecoration(
                          hintText: 'Search bases, station name, incharge...',
                          prefixIcon:
                              const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref
                                        .read(
                                            policeBaseSearchQueryProvider
                                                .notifier)
                                        .state = '';
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // View Toggle (Map / List)
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
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
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

          // Main View (Google Map or List)
          Expanded(
            child: basesAsync.when(
              loading: () =>
                  const LoadingWidget(label: 'Loading Police Bases...'),
              error: (err, _) => AppErrorWidget(
                message: err.toString(),
                onRetry: () => ref.refresh(policeBaseListProvider),
              ),
              data: (bases) {
                if (_isMapView) {
                  return _buildGoogleMapView(bases);
                } else {
                  return _buildListView(bases);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleMapView(List<PoliceBaseModel> bases) {
    const kumbhCenter = LatLng(
      AppConfig.kumbhCenterLat,
      AppConfig.kumbhCenterLng,
    );

    return Stack(
      children: [
        FutureBuilder<Set<Marker>>(
          future: _generateMarkers(bases),
          builder: (context, snapshot) {
            final markers = snapshot.data ?? _cachedMarkers;

            return GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: kumbhCenter,
                zoom: 13.5,
              ),
              onMapCreated: (controller) => _mapController = controller,
              markers: markers,
              onTap: (_) {
                if (_selectedBase != null) {
                  setState(() => _selectedBase = null);
                }
              },
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

        // Hint Pill
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield_rounded,
                    size: 16, color: Color(0xFF1E40AF)),
                const SizedBox(width: 6),
                Text(
                  '${bases.length} Police Stations & Control Posts mapped',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onBackground,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Floating Recenter Button
        Positioned(
          right: 16,
          bottom: _selectedBase != null ? 220 : 90,
          child: FloatingActionButton.small(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1E40AF),
            onPressed: () {
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(kumbhCenter, 13.5),
              );
            },
            child: const Icon(Icons.center_focus_strong_rounded),
          ),
        ),

        // Selected Base Details Card
        if (_selectedBase != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFF93C5FD)),
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
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.shield_rounded,
                            color: Color(0xFF1E40AF),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedBase!.baseName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${_selectedBase!.stationName ?? "Outpost"} • ${_selectedBase!.totalStaff} Officers',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF1E40AF),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () =>
                              setState(() => _selectedBase = null),
                        ),
                      ],
                    ),
                    if (_selectedBase!.inchargeName != null ||
                        _selectedBase!.contactNumber != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person_rounded,
                              size: 14, color: AppColors.onSurfaceMuted),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Incharge: ${_selectedBase!.inchargeName ?? "Officer"} (${_selectedBase!.contactNumber ?? "N/A"})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.onSurfaceMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.go(
                                '/police-bases/${_selectedBase!.id}/edit'),
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            label: const Text('Edit Base'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _handleDelete(_selectedBase!),
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

  Widget _buildListView(List<PoliceBaseModel> bases) {
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
          onEdit: () => context.go('/police-bases/${base.id}/edit'),
          onToggleActive: () {
            ref
                .read(policeBaseActionControllerProvider.notifier)
                .toggleActive(base.id, base.isActive);
          },
          onDelete: () => _handleDelete(base),
        );
      },
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

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
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
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                        ],
                      ),
                    ],
                  ),
                ),
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
                  Expanded(
                    child: Text(
                      'Incharge: ${base.inchargeName ?? "N/A"}${base.contactNumber != null ? " • ${base.contactNumber!}" : ""}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceMuted,
                      ),
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
