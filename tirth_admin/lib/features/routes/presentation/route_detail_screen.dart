import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/route_model.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/location_picker_dialog.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../../shared/widgets/status_badge.dart';
import 'route_providers.dart';

class RouteDetailScreen extends ConsumerStatefulWidget {
  const RouteDetailScreen({
    super.key,
    required this.routeId,
  });

  final String routeId;

  @override
  ConsumerState<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends ConsumerState<RouteDetailScreen> {
  gmaps.GoogleMapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _showNodeDialog({RouteNodeModel? existingNode, int nextOrder = 1}) async {
    final nameController =
        TextEditingController(text: existingNode?.nodeName ?? '');
    final orderController = TextEditingController(
        text: (existingNode?.nodeOrder ?? nextOrder).toString());
    final latController = TextEditingController(
        text: existingNode?.latitude.toString() ?? '');
    final lngController = TextEditingController(
        text: existingNode?.longitude.toString() ?? '');
    final distController = TextEditingController(
        text: existingNode?.distanceFromStartKm?.toString() ?? '');
    final altController = TextEditingController(
        text: existingNode?.altitude?.toString() ?? '');

    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.pin_drop_rounded,
                  color: AppColors.primary, size: 24),
              const SizedBox(width: 10),
              Text(
                existingNode == null ? 'Add Waypoint Node' : 'Edit Waypoint Node',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(
                    controller: nameController,
                    label: 'Node / Waypoint Name',
                    hint: 'e.g. Ramkund Main Ghat Entry',
                    isRequired: true,
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Name required' : null,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: orderController,
                    label: 'Sequence Order (1, 2, 3...)',
                    hint: '1',
                    keyboardType: TextInputType.number,
                    isRequired: true,
                    validator: (val) {
                      if (val == null || int.tryParse(val.trim()) == null) {
                        return 'Valid integer required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: latController,
                          label: 'Latitude',
                          hint: '19.9975',
                          isRequired: true,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (val) =>
                              double.tryParse(val ?? '') == null
                                  ? 'Valid latitude required'
                                  : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppTextField(
                          controller: lngController,
                          label: 'Longitude',
                          hint: '73.7898',
                          isRequired: true,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (val) =>
                              double.tryParse(val ?? '') == null
                                  ? 'Valid longitude required'
                                  : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.map_rounded, size: 18),
                      label: const Text('Select on Map'),
                      onPressed: () async {
                        final currentLat =
                            double.tryParse(latController.text.trim());
                        final currentLng =
                            double.tryParse(lngController.text.trim());
                        final initialPos = (currentLat != null && currentLng != null)
                            ? LatLng(currentLat, currentLng)
                            : null;

                        final result = await LocationPickerDialog.showResult(
                          context,
                          initialLocation: initialPos,
                          title: 'Pick Waypoint Coordinates',
                        );

                        if (result != null) {
                          setDialogState(() {
                            latController.text =
                                result.latitude.toStringAsFixed(6);
                            lngController.text =
                                result.longitude.toStringAsFixed(6);
                            if (result.address != null &&
                                nameController.text.trim().isEmpty) {
                              nameController.text = result.address!;
                            }
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: distController,
                          label: 'Dist. from Start (km)',
                          hint: 'e.g. 1.2',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppTextField(
                          controller: altController,
                          label: 'Altitude (m)',
                          hint: 'e.g. 580',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(dialogCtx).pop(true);
                }
              },
              child: const Text('Save Node'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final node = RouteNodeModel(
        id: existingNode?.id ?? '',
        routeId: widget.routeId,
        nodeOrder: int.parse(orderController.text.trim()),
        nodeName: nameController.text.trim(),
        latitude: double.parse(latController.text.trim()),
        longitude: double.parse(lngController.text.trim()),
        distanceFromStartKm: double.tryParse(distController.text.trim()),
        altitude: double.tryParse(altController.text.trim()),
        createdAt: DateTime.now(),
      );

      final success = await ref
          .read(routeActionControllerProvider.notifier)
          .saveNode(nodeId: existingNode?.id, node: node);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text(
              existingNode == null
                  ? 'Waypoint added successfully.'
                  : 'Waypoint updated.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteNode(RouteNodeModel node) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Waypoint Node?',
      message: 'Are you sure you want to remove waypoint #${node.nodeOrder} (${node.nodeName})?',
      confirmLabel: 'Delete Node',
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );

    if (confirmed == true && mounted) {
      await ref
          .read(routeActionControllerProvider.notifier)
          .deleteNode(widget.routeId, node.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeAsync = ref.watch(routeDetailProvider(widget.routeId));
    final nodesAsync = ref.watch(routeNodesProvider(widget.routeId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Route Overview & Nodes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit Route Info',
            onPressed: () => context.push('/routes/${widget.routeId}/edit'),
          ),
        ],
      ),
      body: routeAsync.when(
        loading: () => const LoadingWidget(message: 'Loading route data...'),
        error: (err, _) => ErrorStateWidget(
          message: err.toString(),
          onRetry: () => ref.refresh(routeDetailProvider(widget.routeId)),
        ),
        data: (route) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(routeDetailProvider(widget.routeId));
              ref.invalidate(routeNodesProvider(widget.routeId));
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Overview Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.alt_route_rounded,
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
                                      style: AppTextStyles.headlineMedium,
                                    ),
                                    if (route.routeCode != null)
                                      Text(
                                        'Code: ${route.routeCode}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              StatusBadge.active(route.isActive),
                            ],
                          ),
                          if (route.description != null) ...[
                            const SizedBox(height: 14),
                            Text(
                              route.description!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.onSurfaceMuted,
                                height: 1.4,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _MetricBox(
                                  label: 'Distance',
                                  value: route.formattedDistance,
                                  icon: Icons.straighten_rounded,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _MetricBox(
                                  label: 'Est. Time',
                                  value: route.formattedTime,
                                  icon: Icons.timer_outlined,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _MetricBox(
                                  label: 'Waypoints',
                                  value: '${route.nodeCount}',
                                  icon: Icons.pin_drop_outlined,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Route Nodes Section Header
                  nodesAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (nodes) {
                      // Map View if nodes exist
                      if (nodes.isNotEmpty) {
                        final points = nodes
                            .map((n) => gmaps.LatLng(n.latitude, n.longitude))
                            .toList();
                        final center = points.first;

                        final polylines = <gmaps.Polyline>{
                          gmaps.Polyline(
                            polylineId: const gmaps.PolylineId('route_path'),
                            points: points,
                            color: AppColors.primary,
                            width: 5,
                            startCap: gmaps.Cap.roundCap,
                            endCap: gmaps.Cap.roundCap,
                          ),
                        };

                        final markers = nodes.map((n) {
                          return gmaps.Marker(
                            markerId: gmaps.MarkerId(n.id),
                            position:
                                gmaps.LatLng(n.latitude, n.longitude),
                            infoWindow: gmaps.InfoWindow(
                              title: '#${n.nodeOrder} ${n.nodeName}',
                              snippet: n.distanceFromStartKm != null
                                  ? '${n.distanceFromStartKm!.toStringAsFixed(1)} km from start'
                                  : null,
                            ),
                          );
                        }).toSet();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Geographic Route Path',
                              style: AppTextStyles.headlineSmall,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              height: 220,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.border),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: gmaps.GoogleMap(
                                initialCameraPosition: gmaps.CameraPosition(
                                  target: center,
                                  zoom: 14.0,
                                ),
                                onMapCreated: (c) => _mapController = c,
                                polylines: polylines,
                                markers: markers,
                                myLocationEnabled: false,
                                zoomControlsEnabled: false,
                                mapToolbarEnabled: false,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Waypoints Header & Add Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Route Waypoints',
                        style: AppTextStyles.headlineSmall,
                      ),
                      nodesAsync.when(
                        data: (nodes) => AppButton(
                          text: 'Add Waypoint',
                          icon: Icons.add_location_alt_rounded,
                          height: 38,
                          width: 150,
                          onPressed: () => _showNodeDialog(
                            nextOrder: nodes.length + 1,
                          ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Nodes List
                  nodesAsync.when(
                    loading: () =>
                        const LoadingWidget(message: 'Loading waypoints...'),
                    error: (err, _) => ErrorStateWidget(message: err.toString()),
                    data: (nodes) {
                      if (nodes.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(28.0),
                            child: Column(
                              children: [
                                const Icon(Icons.add_location_outlined,
                                    size: 44, color: AppColors.onSurfaceMuted),
                                const SizedBox(height: 12),
                                const Text(
                                  'No Waypoint Nodes Added Yet',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Add ordered sequential coordinates to form the walking navigation path.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.onSurfaceMuted,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                AppButton(
                                  text: 'Add First Waypoint',
                                  variant: AppButtonVariant.primary,
                                  width: 180,
                                  height: 42,
                                  onPressed: () => _showNodeDialog(nextOrder: 1),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: nodes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final node = nodes[index];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryContainer,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${node.nodeOrder}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          node.nodeName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.onBackground,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${node.latitude.toStringAsFixed(5)}, ${node.longitude.toStringAsFixed(5)}${node.distanceFromStartKm != null ? " • ${node.distanceFromStartKm} km from start" : ""}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.onSurfaceMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 18),
                                    tooltip: 'Edit Node',
                                    onPressed: () => _showNodeDialog(
                                      existingNode: node,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                      color: AppColors.error,
                                    ),
                                    tooltip: 'Delete Node',
                                    onPressed: () => _handleDeleteNode(node),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.onSurfaceMuted),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.onSurfaceMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.onBackground,
            ),
          ),
        ],
      ),
    );
  }
}
