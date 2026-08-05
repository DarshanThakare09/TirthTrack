// ============================================================
// features/maps/presentation/tabs/police_base_tab.dart
// ============================================================
//
// Full-Screen Google Maps Tab for Police Bases & Stations
// Features:
//   - Full-screen Google Map canvas (100% tab height)
//   - Overlay search bar at top for finding stations/sectors
//   - Interactive markers for all police bases
//   - Emergency contact dialer & directions in detail sheet
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/distance_utils.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../location/providers/location_provider.dart';
import '../../models/police_base_model.dart';
import '../../providers/maps_providers.dart';

final policeSearchQueryProvider = StateProvider<String>((ref) => '');

class PoliceBaseTab extends ConsumerStatefulWidget {
  const PoliceBaseTab({super.key});

  @override
  ConsumerState<PoliceBaseTab> createState() => _PoliceBaseTabState();
}

class _PoliceBaseTabState extends ConsumerState<PoliceBaseTab>
    with AutomaticKeepAliveClientMixin {
  GoogleMapController? _mapController;
  bool _hasCenteredOnUser = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initUserLocation();
    });
  }

  Future<void> _initUserLocation() async {
    await ref.read(locationPermissionProvider.notifier).checkAndRequest();
    await ref.read(locationTrackingProvider.notifier).startTracking();

    final pos = await LocationService.instance.getCurrentPosition();
    if (pos != null && mounted) {
      ref.read(currentPositionProvider.notifier).state = pos;
      _zoomToPosition(pos);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    final pos = ref.read(currentPositionProvider);
    if (pos != null) {
      _zoomToPosition(pos);
    } else {
      _initUserLocation();
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

  void _recenterToUser(Position? position) {
    if (position != null) {
      _zoomToPosition(position);
    } else {
      _initUserLocation();
    }
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
    final position = ref.watch(currentPositionProvider);
    final selectedBase = ref.watch(selectedPoliceBaseProvider);
    final searchQuery = ref.watch(policeSearchQueryProvider).toLowerCase().trim();

    ref.listen<Position?>(currentPositionProvider, (previous, next) {
      if (next != null && !_hasCenteredOnUser) {
        _zoomToPosition(next);
      }
    });

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
              final displayedBases = searchQuery.isEmpty
                  ? allBases
                  : allBases.where((b) {
                      return b.baseName.toLowerCase().contains(searchQuery) ||
                          (b.stationName?.toLowerCase().contains(searchQuery) ??
                              false) ||
                          (b.sectorName?.toLowerCase().contains(searchQuery) ??
                              false);
                    }).toList();

              final initialTarget = selectedBase != null
                  ? selectedBase.googleLatLng
                  : (position != null
                      ? LatLng(position.latitude, position.longitude)
                      : const LatLng(
                          AppConfig.kumbhCenterLat,
                          AppConfig.kumbhCenterLng,
                        ));

              final markers = displayedBases.map((b) {
                final isSelected = selectedBase?.id == b.id;
                return Marker(
                  markerId: MarkerId(b.id),
                  position: b.googleLatLng,
                  infoWindow: InfoWindow(
                    title: b.baseName,
                    snippet: b.stationName ?? 'Police Base',
                  ),
                  icon: isSelected
                      ? BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueYellow)
                      : BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueBlue),
                  onTap: () {
                    ref.read(selectedPoliceBaseProvider.notifier).state = b;
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(b.googleLatLng, 15.5),
                    );
                    _showBaseDetailSheet(context, b);
                  },
                );
              }).toSet();

              return GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: initialTarget,
                  zoom: position != null ? 15.5 : 13.5,
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
                mapToolbarEnabled: true,
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
                onTap: (_) {
                  ref.read(selectedPoliceBaseProvider.notifier).state = null;
                },
              );
            },
          ),

          // ── 3. Floating Map Controls Column (Zoom In, Zoom Out, Recenter) ─
          Positioned(
            right: 16,
            bottom: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'police_zoom_in_fab',
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.onSurface,
                  onPressed: () {
                    _mapController?.animateCamera(CameraUpdate.zoomIn());
                  },
                  child: const Icon(Icons.add_rounded),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'police_zoom_out_fab',
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.onSurface,
                  onPressed: () {
                    _mapController?.animateCamera(CameraUpdate.zoomOut());
                  },
                  child: const Icon(Icons.remove_rounded),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'police_recenter_fab',
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  onPressed: () => _recenterToUser(position),
                  child: const Icon(Icons.my_location_rounded),
                ),
              ],
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.servicePolice.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.local_police_rounded,
                  color: AppColors.servicePolice,
                  size: 26,
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
                    if (base.stationName != null)
                      Text(
                        base.stationName!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.servicePolice,
                          fontWeight: FontWeight.w600,
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
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
                  const Divider(height: 12),
                  _DetailRow(
                    icon: Icons.badge_outlined,
                    label: 'In-charge Officer',
                    value: base.inchargeName!,
                  ),
                ],
                if (base.totalStaff > 0) ...[
                  const Divider(height: 12),
                  _DetailRow(
                    icon: Icons.group_outlined,
                    label: 'Total Staff On Duty',
                    value: '${base.totalStaff} Personnel',
                  ),
                ],
                if (base.distanceKm != null) ...[
                  const Divider(height: 12),
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
                      side: const BorderSide(color: AppColors.servicePolice),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.phone_rounded,
                        size: 18, color: AppColors.servicePolice),
                    label: const Text(
                      'Call Station',
                      style: TextStyle(color: AppColors.servicePolice),
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
                    backgroundColor: AppColors.servicePolice,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.directions_rounded, size: 18),
                  label: const Text('Directions'),
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
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}
