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
  GoogleMapController? _mapController;
  bool _isMapView = true;
  ServiceModel? _selectedService;
  Set<Marker> _cachedMarkers = {};
  String _markerCacheKey = '';

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
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
        if (_selectedService?.id == service.id) {
          setState(() {
            _selectedService = null;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.onBackground,
            content: Text('Service "${service.serviceName}" deleted.'),
          ),
        );
      }
    }
  }

  void _showServiceDetailsSheet(ServiceModel service) {
    setState(() {
      _selectedService = service;
    });
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(service.latitude, service.longitude),
        16.0,
      ),
    );
  }

  Future<Set<Marker>> _generateMarkers(List<ServiceModel> services) async {
    final key =
        '${services.map((s) => "${s.id}_${s.latitude}_${s.longitude}_${s.isActive}").join(",")}_${_selectedService?.id}';
    if (key == _markerCacheKey && _cachedMarkers.isNotEmpty) {
      return _cachedMarkers;
    }

    final markers = <Marker>{};
    for (final service in services) {
      final isSelected = _selectedService?.id == service.id;
      final icon = await CustomMapMarkerHelper.getServiceMarker(
        type: service.serviceType,
        isSelected: isSelected,
      );

      markers.add(
        Marker(
          markerId: MarkerId(service.id),
          position: LatLng(service.latitude, service.longitude),
          infoWindow: InfoWindow(
            title: service.serviceName,
            snippet:
                '${service.serviceType.displayLabel} • ${service.is24Hours ? "24 Hours" : (service.operatingHours ?? "Active")}',
          ),
          icon: icon,
          onTap: () {
            _showServiceDetailsSheet(service);
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
    final servicesAsync = ref.watch(serviceListProvider);
    final selectedType = ref.watch(serviceTypeFilterProvider);

    // List of pilgrim facility types
    final pilgrimServiceTypes = ServiceTypeEnum.values.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/services/new'),
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text(
          'Add Service',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          // Header Bar with View Toggle & Search
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
                          ref.read(serviceSearchQueryProvider.notifier).state =
                              val;
                        },
                        decoration: InputDecoration(
                          hintText: 'Search services, medical, water...',
                          prefixIcon:
                              const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref
                                        .read(
                                            serviceSearchQueryProvider.notifier)
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

                // Service Types Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _TypeFilterChip(
                        label: 'All Types',
                        isSelected: selectedType == null,
                        onTap: () {
                          ref.read(serviceTypeFilterProvider.notifier).state =
                              null;
                        },
                      ),
                      ...pilgrimServiceTypes.map((t) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 6.0),
                          child: _TypeFilterChip(
                            label: t.displayLabel,
                            icon: t.icon,
                            color: t.color,
                            isSelected: selectedType == t,
                            onTap: () {
                              ref
                                  .read(serviceTypeFilterProvider.notifier)
                                  .state = selectedType == t ? null : t;
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

          // Main View (Map or List)
          Expanded(
            child: servicesAsync.when(
              loading: () => const LoadingWidget(
                label: 'Loading Facilities & Services...',
              ),
              error: (err, _) => AppErrorWidget(
                message: err.toString(),
                onRetry: () => ref.refresh(serviceListProvider),
              ),
              data: (services) {
                if (_isMapView) {
                  return _buildGoogleMapView(services);
                } else {
                  return _buildListView(services);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleMapView(List<ServiceModel> services) {
    const kumbhCenter = LatLng(
      AppConfig.kumbhCenterLat,
      AppConfig.kumbhCenterLng,
    );

    return Stack(
      children: [
        FutureBuilder<Set<Marker>>(
          future: _generateMarkers(services),
          builder: (context, snapshot) {
            final markers = snapshot.data ?? _cachedMarkers;

            return GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: kumbhCenter,
                zoom: 13.5,
              ),
              onMapCreated: (controller) => _mapController = controller,
              markers: markers,
              onLongPress: (latLng) {
                _showAddServiceAtCoordinatesPrompt(latLng);
              },
              onTap: (_) {
                if (_selectedService != null) {
                  setState(() => _selectedService = null);
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
                const Icon(Icons.touch_app_rounded,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'Tap marker for details • Long press to add facility (${services.length} active)',
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

        // Floating Map Controls (Zoom In, Zoom Out, Recenter)
        Positioned(
          right: 16,
          bottom: _selectedService != null ? 220 : 90,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_rounded, size: 20),
                  onPressed: () => _mapController?.animateCamera(
                    CameraUpdate.zoomIn(),
                  ),
                  tooltip: 'Zoom In',
                ),
                const Divider(height: 1, indent: 8, endIndent: 8),
                IconButton(
                  icon: const Icon(Icons.remove_rounded, size: 20),
                  onPressed: () => _mapController?.animateCamera(
                    CameraUpdate.zoomOut(),
                  ),
                  tooltip: 'Zoom Out',
                ),
                const Divider(height: 1, indent: 8, endIndent: 8),
                IconButton(
                  icon: const Icon(Icons.center_focus_strong_rounded,
                      size: 20, color: AppColors.primary),
                  onPressed: () => _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(kumbhCenter, 13.5),
                  ),
                  tooltip: 'Recenter Kumbh Mela',
                ),
              ],
            ),
          ),
        ),

        // Selected Service Detail Card Bottom Sheet
        if (_selectedService != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
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
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _selectedService!.serviceType.color
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _selectedService!.serviceType.icon,
                            color: _selectedService!.serviceType.color,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedService!.serviceName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    _selectedService!.serviceType.displayLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _selectedService!.serviceType.color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (_selectedService!.is24Hours) ...[
                                    const Text(' • ',
                                        style: TextStyle(
                                            color: AppColors.onSurfaceMuted)),
                                    const Text(
                                      '24 Hours',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () =>
                              setState(() => _selectedService = null),
                        ),
                      ],
                    ),
                    if (_selectedService!.description != null &&
                        _selectedService!.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _selectedService!.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceMuted,
                        ),
                      ),
                    ],
                    if (_selectedService!.contactPerson != null ||
                        _selectedService!.contactNumber != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.phone_rounded,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${_selectedService!.contactPerson ?? "Incharge"}: ${_selectedService!.contactNumber ?? "N/A"}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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
                            onPressed: () => context
                                .go('/services/${_selectedService!.id}/edit'),
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            label: const Text('Edit Details'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _handleDelete(_selectedService!),
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

  void _showAddServiceAtCoordinatesPrompt(LatLng latLng) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_location_alt_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Add Service Here?'),
          ],
        ),
        content: Text(
          'Do you want to create a new facility at coordinates:\n${latLng.latitude.toStringAsFixed(6)}, ${latLng.longitude.toStringAsFixed(6)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go(
                '/services/new?lat=${latLng.latitude}&lng=${latLng.longitude}',
              );
            },
            child: const Text('Add Facility'),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<ServiceModel> services) {
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
        final type = service.serviceType;

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
                        color: type.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        type.icon,
                        color: type.color,
                        size: 22,
                      ),
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
                                  service.serviceName,
                                  style: AppTextStyles.titleMedium,
                                ),
                              ),
                              StatusBadge.active(service.isActive),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                type.displayLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: type.color,
                                ),
                              ),
                              if (service.is24Hours) ...[
                                const Text(' • ',
                                    style: TextStyle(
                                        color: AppColors.onSurfaceMuted)),
                                const Text(
                                  '24 Hours',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (service.description != null &&
                    service.description!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    service.description!,
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
                      child: Row(
                        children: [
                          const Icon(
                            Icons.pin_drop_outlined,
                            size: 14,
                            color: AppColors.onSurfaceMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${service.latitude.toStringAsFixed(4)}, ${service.longitude.toStringAsFixed(4)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.onSurfaceMuted,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      tooltip: 'Edit Service',
                      onPressed: () =>
                          context.go('/services/${service.id}/edit'),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_forever_rounded,
                        size: 18,
                        color: AppColors.error,
                      ),
                      tooltip: 'Delete Service',
                      onPressed: () => _handleDelete(service),
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

class _TypeFilterChip extends StatelessWidget {
  const _TypeFilterChip({
    required this.label,
    this.icon,
    this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? AppColors.primary)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : (color ?? AppColors.iconDark),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.onSurfaceMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
