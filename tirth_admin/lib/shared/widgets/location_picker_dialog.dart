import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import 'app_button.dart';
import 'app_text_field.dart';

class LocationPickerDialog extends StatefulWidget {
  const LocationPickerDialog({
    super.key,
    this.initialLocation,
    this.title = 'Select Geographic Location',
  });

  final LatLng? initialLocation;
  final String title;

  static Future<LatLng?> show(
    BuildContext context, {
    LatLng? initialLocation,
    String title = 'Select Location on Map',
  }) {
    return showDialog<LatLng>(
      context: context,
      barrierDismissible: false,
      builder: (context) => LocationPickerDialog(
        initialLocation: initialLocation,
        title: title,
      ),
    );
  }

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  late LatLng _selectedPosition;
  late final MapController _mapController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialLocation ??
        const LatLng(AppConfig.kumbhCenterLat, AppConfig.kumbhCenterLng);
    _mapController = MapController();
    _latController = TextEditingController(
      text: _selectedPosition.latitude.toStringAsFixed(6),
    );
    _lngController = TextEditingController(
      text: _selectedPosition.longitude.toStringAsFixed(6),
    );
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _onTapMap(TapPosition tapPosition, LatLng latLng) {
    setState(() {
      _selectedPosition = latLng;
      _latController.text = latLng.latitude.toStringAsFixed(6);
      _lngController.text = latLng.longitude.toStringAsFixed(6);
    });
  }

  void _applyManualCoordinates() {
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    if (lat != null && lng != null) {
      final pos = LatLng(lat, lng);
      setState(() {
        _selectedPosition = pos;
      });
      _mapController.move(pos, 15.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dialogWidth = size.width > 600 ? 550.0 : size.width * 0.92;
    final dialogHeight = size.height > 700 ? 580.0 : size.height * 0.85;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: AppColors.surface,
              child: Row(
                children: [
                  const Icon(Icons.pin_drop_rounded,
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onBackground,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Map Area
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _selectedPosition,
                      initialZoom: 14.0,
                      onTap: _onTapMap,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.tirthtrack.admin',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedPosition,
                            width: 48,
                            height: 48,
                            alignment: Alignment.topCenter,
                            child: const Icon(
                              Icons.location_on,
                              size: 48,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Map instruction chip
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Tap anywhere on the map to place the marker',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Coordinate Inputs & Confirmation
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surface,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _latController,
                          label: 'Latitude',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onFieldSubmitted: (_) => _applyManualCoordinates(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          controller: _lngController,
                          label: 'Longitude',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onFieldSubmitted: (_) => _applyManualCoordinates(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'Cancel',
                          variant: AppButtonVariant.outline,
                          height: 46,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          text: 'Confirm Location',
                          variant: AppButtonVariant.primary,
                          height: 46,
                          onPressed: () {
                            Navigator.of(context).pop(_selectedPosition);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
