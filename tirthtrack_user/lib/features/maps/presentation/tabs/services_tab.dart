// ============================================================
// features/maps/presentation/tabs/services_tab.dart
// ============================================================
//
// Full-Screen Google Maps Tab for Services
// Features:
//   - Full-screen Google Map canvas (100% tab height)
//   - Shows ALL services (including Police Bases, Hospitals, Food, Water, etc.)
//   - Custom modern vector-rendered circular badge markers
//   - Overlay category filter chips & search bar at the top
//   - Interactive markers with bottom detail modal sheet on marker tap
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/custom_map_marker_helper.dart';
import '../../../../core/utils/distance_utils.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../location/providers/location_provider.dart';
import '../../models/service_model.dart';
import '../../providers/maps_providers.dart';

class ServicesTab extends ConsumerStatefulWidget {
  const ServicesTab({super.key});

  @override
  ConsumerState<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends ConsumerState<ServicesTab>
    with AutomaticKeepAliveClientMixin {
  GoogleMapController? _mapController;
  bool _hasCenteredOnUser = false;
  Set<Marker> _cachedMarkers = {};
  String _markerCacheKey = '';

  @override
  bool get wantKeepAlive => true;

  Future<void> _initUserLocation() async {
    final pos = await ref
        .read(locationTrackingProvider.notifier)
        .initializeLocationService();
    if (pos != null && mounted) {
      _zoomToPosition(pos);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    final pos = ref.read(currentPositionProvider);
    if (pos != null) {
      _zoomToPosition(pos);
    }
  }

  void _zoomToPosition(Position position) {
    if (_mapController != null) {
      _hasCenteredOnUser = true;
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15.5,
        ),
      );
    }
  }

  void _recenterToUser() {
    final position = ref.read(currentPositionProvider);
    if (position != null) {
      _zoomToPosition(position);
    } else {
      _initUserLocation();
    }
  }

  Future<Set<Marker>> _generateMarkers(
    List<ServiceModel> displayedServices,
    ServiceModel? selectedService,
  ) async {
    final key =
        '${displayedServices.map((s) => s.id).join(",")}_sel_${selectedService?.id ?? "none"}';
    if (key == _markerCacheKey && _cachedMarkers.isNotEmpty) {
      return _cachedMarkers;
    }

    final markers = <Marker>{};
    for (final s in displayedServices) {
      final isSelected = selectedService?.id == s.id;
      final icon = await CustomMapMarkerHelper.getServiceMarker(
        type: s.serviceType,
        isSelected: isSelected,
      );

      markers.add(
        Marker(
          markerId: MarkerId(s.id),
          position: s.googleLatLng,
          icon: icon,
          infoWindow: InfoWindow(
            title: s.serviceName,
            snippet: s.serviceType.displayLabel,
          ),
          onTap: () {
            ref.read(selectedServiceProvider.notifier).state = s;
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(s.googleLatLng, 16.0),
            );
            _showServiceDetailSheet(context, s);
          },
        ),
      );
    }

    _markerCacheKey = key;
    _cachedMarkers = markers;
    return markers;
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final servicesState = ref.watch(servicesProvider);
    final filtered = ref.watch(filteredServicesProvider);
    final selectedType = ref.watch(serviceTypeFilterProvider);
    final selectedService = ref.watch(selectedServiceProvider);
    final searchQuery = ref.watch(serviceSearchQueryProvider).trim();
    final isFiltering = selectedType != null || searchQuery.isNotEmpty;

    ref.listen<Position?>(currentPositionProvider, (previous, next) {
      if (next != null && !_hasCenteredOnUser) {
        _zoomToPosition(next);
      }
    });

    final currentPos = ref.read(currentPositionProvider);
    final initialTarget = selectedService != null
        ? selectedService.googleLatLng
        : (currentPos != null
            ? LatLng(currentPos.latitude, currentPos.longitude)
            : const LatLng(
                AppConfig.kumbhCenterLat,
                AppConfig.kumbhCenterLng,
              ));

    return Scaffold(
      body: Stack(
        children: [
          // ── 1. Full-Screen Google Map Canvas ─────────────────────
          servicesState.when(
            loading: () => const LoadingWidget(label: 'Loading Services Map…'),
            error: (e, _) => AppErrorWidget(
              message: e.toString(),
              onRetry: () => ref.refresh(servicesProvider),
            ),
            data: (allServices) {
              final displayedServices = isFiltering ? filtered : allServices;

              return FutureBuilder<Set<Marker>>(
                future: _generateMarkers(displayedServices, selectedService),
                builder: (context, snapshot) {
                  final markers = snapshot.data ?? _cachedMarkers;

                  return GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: initialTarget,
                      zoom: currentPos != null ? 15.5 : 13.5,
                    ),
                    onMapCreated: _onMapCreated,
                    markers: markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    zoomGesturesEnabled: true,
                    scrollGesturesEnabled: true,
                    rotateGesturesEnabled: true,
                    tiltGesturesEnabled: true,
                    compassEnabled: true,
                    mapToolbarEnabled: false,
                    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                      Factory<OneSequenceGestureRecognizer>(
                        () => ScaleGestureRecognizer(),
                      ),
                    },
                    onTap: (_) {
                      ref.read(selectedServiceProvider.notifier).state = null;
                    },
                  );
                },
              );
            },
          ),

          // ── 2. Top Floating Controls (Search & Category Chips) ───
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search Bar Overlay Card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: AppColors.surface.withValues(alpha: 0.96),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded,
                                color: AppColors.primary, size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  hintText:
                                      'Search all services, police, food, medical…',
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  isDense: true,
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 8),
                                ),
                                style: AppTextStyles.bodyMedium,
                                onChanged: (val) {
                                  ref
                                      .read(
                                          serviceSearchQueryProvider.notifier)
                                      .state = val;
                                },
                              ),
                            ),
                            if (searchQuery.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  ref
                                      .read(
                                          serviceSearchQueryProvider.notifier)
                                      .state = '';
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Horizontal Category Chips
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _TypeChip(
                            label: 'All Services',
                            isSelected: selectedType == null,
                            icon: Icons.apps_rounded,
                            color: AppColors.primary,
                            onTap: () => ref
                                .read(serviceTypeFilterProvider.notifier)
                                .state = null,
                          ),
                          ...ServiceTypeEnum.values.map(
                            (t) => _TypeChip(
                              label: t.displayLabel,
                              isSelected: selectedType == t,
                              icon: t.icon,
                              color: t.color,
                              onTap: () => ref
                                  .read(serviceTypeFilterProvider.notifier)
                                  .state = t,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Empty filtered notice overlay
          if (isFiltering && filtered.isEmpty && servicesState.hasValue)
            Align(
              alignment: Alignment.center,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white.withValues(alpha: 0.95),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'No facilities found matching "${selectedType?.displayLabel ?? searchQuery}"',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onBackground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── 3. Floating Vertical Map Controls ─────────────────────
          Positioned(
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        _mapController?.animateCamera(CameraUpdate.zoomIn());
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.add_rounded,
                            size: 22, color: AppColors.onSurface),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 24,
                    child: Divider(height: 1, color: AppColors.divider),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        _mapController?.animateCamera(CameraUpdate.zoomOut());
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.remove_rounded,
                            size: 22, color: AppColors.onSurface),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 24,
                    child: Divider(height: 1, color: AppColors.divider),
                  ),
                  Material(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _recenterToUser,
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.my_location_rounded,
                            size: 22, color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showServiceDetailSheet(BuildContext context, ServiceModel service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ServiceDetailBottomSheet(service: service),
    );
  }
}

// ── Category Filter Chip Widget ────────────────────────────────
class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? color
                : AppColors.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : color,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isSelected ? Colors.white : AppColors.onSurface,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Service Detail Bottom Sheet Widget ──────────────────────────
class _ServiceDetailBottomSheet extends StatelessWidget {
  const _ServiceDetailBottomSheet({required this.service});

  final ServiceModel service;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header with category icon and close button
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: service.serviceType.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: service.serviceType.color.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    service.serviceType.icon,
                    color: service.serviceType.color,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.serviceName,
                        style: AppTextStyles.headlineSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        service.serviceType.displayLabel,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: service.serviceType.color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            if (service.description != null &&
                service.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                service.description!,
                style: AppTextStyles.bodyMedium,
              ),
            ],

            if (service.contactPerson != null &&
                service.contactPerson!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded,
                      size: 16, color: AppColors.onSurfaceMuted),
                  const SizedBox(width: 6),
                  Text(
                    'In-charge: ${service.contactPerson}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Metadata row (Hours, Distance, 24/7)
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                if (service.is24Hours)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Open 24/7',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (service.operatingHours != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 13, color: AppColors.onSurfaceMuted),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            service.operatingHours!,
                            style: AppTextStyles.caption,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (service.distanceKm != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.straighten_rounded,
                            size: 13, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          DistanceUtils.formatDistance(service.distanceKm!),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // Action Buttons: Call & Directions
            Row(
              children: [
                if (service.contactNumber != null &&
                    service.contactNumber!.isNotEmpty) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.phone_rounded, size: 18),
                      label: const Text('Call Facility'),
                      onPressed: () => launchUrl(
                        Uri.parse('tel:${service.contactNumber}'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.directions_rounded, size: 18),
                    label: const Text('Get Directions'),
                    onPressed: () => launchUrl(
                      Uri.parse(
                        'https://www.google.com/maps/dir/?api=1&destination=${service.latitude},${service.longitude}',
                      ),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
