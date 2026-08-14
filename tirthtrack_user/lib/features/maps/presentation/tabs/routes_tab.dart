// ============================================================
// features/maps/presentation/tabs/routes_tab.dart
// ============================================================
//
// Full-Screen Google Maps Tab for Pilgrimage Routes
// Features:
//   - Full-screen Google Map canvas (100% tab height)
//   - Floating route selector chips overlay at the top
//   - Custom vector-rendered Waypoint Node Markers (1, 2, 3...)
//   - Interactive Bottom Sheet on route or node tap
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
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../location/providers/location_provider.dart';
import '../../models/route_model.dart';
import '../../providers/maps_providers.dart';

class RoutesTab extends ConsumerStatefulWidget {
  const RoutesTab({super.key});

  @override
  ConsumerState<RoutesTab> createState() => _RoutesTabState();
}

class _RoutesTabState extends ConsumerState<RoutesTab>
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

  Future<Set<Marker>> _generateNodeMarkers(
    List<RouteNodeModel> nodes,
    RouteModel? selectedRoute,
  ) async {
    if (nodes.isEmpty || selectedRoute == null) {
      return {};
    }

    final key =
        '${selectedRoute.id}_${nodes.map((n) => "${n.id}_${n.nodeOrder}").join(",")}';
    if (key == _markerCacheKey && _cachedMarkers.isNotEmpty) {
      return _cachedMarkers;
    }

    final markers = <Marker>{};
    for (int i = 0; i < nodes.length; i++) {
      final n = nodes[i];
      final isStart = i == 0;
      final isEnd = i == nodes.length - 1;

      final icon = await CustomMapMarkerHelper.getRouteNodeMarker(
        order: n.nodeOrder,
        isStart: isStart,
        isEnd: isEnd,
      );

      markers.add(
        Marker(
          markerId: MarkerId(n.id),
          position: n.googleLatLng,
          infoWindow: InfoWindow(
            title: isStart
                ? '🚩 Start: ${n.nodeName}'
                : (isEnd ? '🏁 End: ${n.nodeName}' : '#${n.nodeOrder} ${n.nodeName}'),
            snippet: isStart
                ? 'Route Starting Point'
                : (isEnd ? 'Destination Waypoint' : 'Waypoint #${n.nodeOrder}'),
          ),
          icon: icon,
          onTap: () {
            _showRouteDetailSheet(context, selectedRoute, nodes,
                tappedNode: n);
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
    final routesState = ref.watch(routesProvider);
    final selectedRoute = ref.watch(selectedRouteProvider);

    ref.listen<Position?>(currentPositionProvider, (previous, next) {
      if (next != null && !_hasCenteredOnUser) {
        _zoomToPosition(next);
      }
    });

    final nodesState = selectedRoute != null
        ? ref.watch(routeNodesProvider(selectedRoute.id))
        : null;

    final nodes = nodesState?.valueOrNull ?? [];

    final currentPos = ref.read(currentPositionProvider);
    final initialTarget = currentPos != null
        ? LatLng(currentPos.latitude, currentPos.longitude)
        : const LatLng(
            AppConfig.kumbhCenterLat,
            AppConfig.kumbhCenterLng,
          );

    return Scaffold(
      body: Stack(
        children: [
          // ── 1. Full-Screen Google Map ──────────────────────────────
          routesState.when(
            loading: () => const LoadingWidget(label: 'Loading Routes Map…'),
            error: (e, _) => AppErrorWidget(
              message: e.toString(),
              onRetry: () => ref.refresh(routesProvider),
            ),
            data: (routes) {
              // Construct polylines from selected route nodes
              final polylines = <Polyline>{};
              if (selectedRoute != null && nodes.isNotEmpty) {
                final points = nodes.map((n) => n.googleLatLng).toList();
                polylines.add(
                  Polyline(
                    polylineId: PolylineId(selectedRoute.id),
                    points: points,
                    color: AppColors.primary,
                    width: 5,
                    jointType: JointType.round,
                    startCap: Cap.roundCap,
                    endCap: Cap.roundCap,
                    onTap: () {
                      _showRouteDetailSheet(context, selectedRoute, nodes);
                    },
                  ),
                );
              }

              return FutureBuilder<Set<Marker>>(
                future: _generateNodeMarkers(nodes, selectedRoute),
                builder: (context, snapshot) {
                  final markers = snapshot.data ?? _cachedMarkers;

                  return GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: initialTarget,
                      zoom: currentPos != null ? 15.5 : 13.5,
                    ),
                    onMapCreated: _onMapCreated,
                    polylines: polylines,
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
                  );
                },
              );
            },
          ),

          // ── 2. Top Floating Route Selector Overlay ─────────────────
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: routesState.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (routes) {
                    if (routes.isEmpty) return const SizedBox.shrink();

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: const Text('All Routes'),
                                selected: selectedRoute == null,
                                selectedColor: AppColors.primary,
                                labelStyle: AppTextStyles.labelSmall.copyWith(
                                  color: selectedRoute == null
                                      ? Colors.white
                                      : AppColors.onSurface,
                                  fontWeight: selectedRoute == null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                onSelected: (_) {
                                  ref
                                      .read(selectedRouteProvider.notifier)
                                      .state = null;
                                },
                              ),
                            ),
                            ...routes.map(
                              (r) {
                                final isSel = selectedRoute?.id == r.id;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    avatar: Icon(
                                      Icons.route_rounded,
                                      size: 16,
                                      color: isSel
                                          ? Colors.white
                                          : AppColors.primary,
                                    ),
                                    label: Text(r.routeName),
                                    selected: isSel,
                                    selectedColor: AppColors.primary,
                                    labelStyle:
                                        AppTextStyles.labelSmall.copyWith(
                                      color: isSel
                                          ? Colors.white
                                          : AppColors.onSurface,
                                      fontWeight: isSel
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    onSelected: (selected) {
                                      if (selected) {
                                        ref
                                            .read(
                                                selectedRouteProvider.notifier)
                                            .state = r;
                                        _fetchAndCenterRoute(r);
                                      } else {
                                        ref
                                            .read(
                                                selectedRouteProvider.notifier)
                                            .state = null;
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // ── Floating Vertical Map Controls ─────────────
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

  Future<void> _fetchAndCenterRoute(RouteModel route) async {
    final routeNodes = await ref.read(routeNodesProvider(route.id).future);
    if (routeNodes.isNotEmpty && _mapController != null) {
      final firstNode = routeNodes.first;
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(firstNode.googleLatLng, 14.5),
      );
    }
  }

  void _showRouteDetailSheet(
    BuildContext context,
    RouteModel route,
    List<RouteNodeModel> nodes, {
    RouteNodeModel? tappedNode,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RouteDetailBottomSheet(
        route: route,
        nodes: nodes,
        tappedNode: tappedNode,
      ),
    );
  }
}

// ── Route Detail Bottom Sheet ──────────────────────────────────
class _RouteDetailBottomSheet extends StatelessWidget {
  const _RouteDetailBottomSheet({
    required this.route,
    required this.nodes,
    this.tappedNode,
  });

  final RouteModel route;
  final List<RouteNodeModel> nodes;
  final RouteNodeModel? tappedNode;

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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.route_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.routeName,
                        style: AppTextStyles.headlineSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (tappedNode != null)
                        Text(
                          'Selected Node: ${tappedNode!.nodeName}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
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

            if (route.description != null && route.description!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                route.description!,
                style: AppTextStyles.bodyMedium,
              ),
            ],

            const SizedBox(height: 14),

            // Stats Chips (Distance, Time, Waypoints)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _RouteStatChip(
                  icon: Icons.straighten_rounded,
                  label: route.formattedDistance,
                  color: AppColors.primary,
                ),
                _RouteStatChip(
                  icon: Icons.schedule_rounded,
                  label: route.formattedTime,
                  color: AppColors.info,
                ),
                _RouteStatChip(
                  icon: Icons.place_rounded,
                  label: '${nodes.length} Nodes',
                  color: AppColors.accent,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Nodes Timeline Preview
            if (nodes.isNotEmpty) ...[
              Text(
                'Route Waypoints',
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 70,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: nodes.length,
                  separatorBuilder: (_, __) => const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppColors.onSurfaceMuted,
                  ),
                  itemBuilder: (ctx, idx) {
                    final n = nodes[idx];
                    final isSelectedNode = tappedNode?.id == n.id;
                    return Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelectedNode
                            ? AppColors.primaryContainer
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelectedNode
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${n.nodeOrder} ${n.nodeName}',
                            style: AppTextStyles.labelSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isSelectedNode
                                  ? AppColors.primary
                                  : AppColors.onSurface,
                            ),
                          ),
                          if (n.distanceFromStartKm != null)
                            Text(
                              '${n.distanceFromStartKm!.toStringAsFixed(1)} km from start',
                              style: AppTextStyles.caption,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Action Button: Start Navigation / Directions
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.navigation_rounded, size: 20),
                label: const Text('Open in Google Maps'),
                onPressed: () {
                  final dest = nodes.isNotEmpty
                      ? '${nodes.last.latitude},${nodes.last.longitude}'
                      : '${AppConfig.kumbhCenterLat},${AppConfig.kumbhCenterLng}';
                  launchUrl(
                    Uri.parse(
                      'https://www.google.com/maps/dir/?api=1&destination=$dest',
                    ),
                    mode: LaunchMode.externalApplication,
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

class _RouteStatChip extends StatelessWidget {
  const _RouteStatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
