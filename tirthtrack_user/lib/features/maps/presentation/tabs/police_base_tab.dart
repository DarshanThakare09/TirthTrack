// ============================================================
// features/maps/presentation/tabs/police_base_tab.dart
// ============================================================
//
// Full-Screen Google Maps Tab for Police Bases & Stations
// Features:
//   - Full-screen Google Map canvas (100% tab height)
//   - Custom vector-rendered Police shield badge markers
//   - Emergency contact dialer & directions in detail sheet
//   - Shows ONLY police bases and security posts
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
import '../../models/police_base_model.dart';
import '../../providers/maps_providers.dart';

class PoliceBaseTab extends ConsumerStatefulWidget {
  const PoliceBaseTab({super.key});

  @override
  ConsumerState<PoliceBaseTab> createState() => _PoliceBaseTabState();
}

class _PoliceBaseTabState extends ConsumerState<PoliceBaseTab>
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
    List<PoliceBaseModel> allBases,
    PoliceBaseModel? selectedBase,
  ) async {
    final key =
        '${allBases.map((b) => b.id).join(",")}_sel_${selectedBase?.id ?? "none"}';
    if (key == _markerCacheKey && _cachedMarkers.isNotEmpty) {
      return _cachedMarkers;
    }

    final markers = <Marker>{};
    for (final b in allBases) {
      final isSelected = selectedBase?.id == b.id;
      final icon = await CustomMapMarkerHelper.getPoliceMarker(
        isSelected: isSelected,
      );

      markers.add(
        Marker(
          markerId: MarkerId(b.id),
          position: b.googleLatLng,
          icon: icon,
          infoWindow: InfoWindow(
            title: b.baseName,
            snippet: b.stationName ?? 'Police Base',
          ),
          onTap: () {
            ref.read(selectedPoliceBaseProvider.notifier).state = b;
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(b.googleLatLng, 15.5),
            );
            _showBaseDetailSheet(context, b);
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
    final basesState = ref.watch(policeBasesProvider);
    final selectedBase = ref.watch(selectedPoliceBaseProvider);

    ref.listen<Position?>(currentPositionProvider, (previous, next) {
      if (next != null && !_hasCenteredOnUser) {
        _zoomToPosition(next);
      }
    });

    final currentPos = ref.read(currentPositionProvider);
    final initialTarget = selectedBase != null
        ? selectedBase.googleLatLng
        : (currentPos != null
            ? LatLng(currentPos.latitude, currentPos.longitude)
            : const LatLng(
                AppConfig.kumbhCenterLat,
                AppConfig.kumbhCenterLng,
              ));

    return Scaffold(
      body: Stack(
        children: [
          // ── 1. Full-Screen Google Map ──────────────────────────────
          basesState.when(
            loading: () =>
                const LoadingWidget(label: 'Loading Police Bases Map…'),
            error: (e, _) => AppErrorWidget(
              message: e.toString(),
              onRetry: () => ref.refresh(policeBasesProvider),
            ),
            data: (allBases) {
              return FutureBuilder<Set<Marker>>(
                future: _generateMarkers(allBases, selectedBase),
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
                      ref.read(selectedPoliceBaseProvider.notifier).state = null;
                    },
                  );
                },
              );
            },
          ),

          // ── 2. Top Emergency Notice Badge ─────────────────────────
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF1E40AF).withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.local_police_rounded,
                        color: Color(0xFF1E40AF),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Police Assistance & Bases',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onBackground,
                            ),
                          ),
                          Text(
                            'Find nearest security stations, outposts & help',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.onSurfaceMuted,
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

  void _showBaseDetailSheet(BuildContext context, PoliceBaseModel base) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PoliceBaseDetailBottomSheet(base: base),
    );
  }
}

// ── Police Base Detail Bottom Sheet ─────────────────────────────
class _PoliceBaseDetailBottomSheet extends StatelessWidget {
  const _PoliceBaseDetailBottomSheet({required this.base});

  final PoliceBaseModel base;

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
            // Drag handle
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

            // Header
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF1E40AF).withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.local_police_rounded,
                    color: Color(0xFF1E40AF),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        base.baseName,
                        style: AppTextStyles.headlineSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        base.stationName ?? 'Police Outpost / Chowki',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1E40AF),
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

            const SizedBox(height: 16),

            // Station Metadata & Staff Details
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  if (base.sectorName != null)
                    _DetailRow(
                      icon: Icons.map_rounded,
                      label: 'Sector',
                      value: base.sectorName!,
                    ),
                  if (base.inchargeName != null) ...[
                    const Divider(height: 14),
                    _DetailRow(
                      icon: Icons.badge_outlined,
                      label: 'In-charge Officer',
                      value: base.inchargeName!,
                    ),
                  ],
                  if (base.totalStaff > 0) ...[
                    const Divider(height: 14),
                    _DetailRow(
                      icon: Icons.group_outlined,
                      label: 'Total Staff On Duty',
                      value: '${base.totalStaff} Officers',
                    ),
                  ],
                  if (base.distanceKm != null) ...[
                    const Divider(height: 14),
                    _DetailRow(
                      icon: Icons.straighten_rounded,
                      label: 'Distance',
                      value: DistanceUtils.formatDistance(base.distanceKm!),
                      valueColor: AppColors.primary,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons: Direct Phone Call & Directions
            Row(
              children: [
                if (base.contactNumber != null &&
                    base.contactNumber!.isNotEmpty) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFF1E40AF)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.phone_rounded,
                          size: 18, color: Color(0xFF1E40AF)),
                      label: const Text(
                        'Call Station',
                        style: TextStyle(
                          color: Color(0xFF1E40AF),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: () => launchUrl(
                        Uri.parse('tel:${base.contactNumber}'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFF1E40AF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.directions_rounded, size: 18),
                    label: const Text(
                      'Get Directions',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => launchUrl(
                      Uri.parse(
                        'https://www.google.com/maps/dir/?api=1&destination=${base.latitude},${base.longitude}',
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.onSurfaceMuted),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.onSurfaceMuted),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.onBackground,
            ),
          ),
        ),
      ],
    );
  }
}
