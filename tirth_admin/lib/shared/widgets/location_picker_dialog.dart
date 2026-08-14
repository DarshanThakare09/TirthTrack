import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/geocoding_helper.dart';
import 'app_button.dart';
import 'app_text_field.dart';

class LocationPickResult {
  const LocationPickResult({
    required this.location,
    this.address,
  });

  final LatLng location;
  final String? address;

  double get latitude => location.latitude;
  double get longitude => location.longitude;
}

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
  }) async {
    final res = await showDialog<LocationPickResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => LocationPickerDialog(
        initialLocation: initialLocation,
        title: title,
      ),
    );
    return res?.location;
  }

  static Future<LocationPickResult?> showResult(
    BuildContext context, {
    LatLng? initialLocation,
    String title = 'Select Location on Map',
  }) {
    return showDialog<LocationPickResult>(
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
  gmaps.GoogleMapController? _mapController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  String? _detectedAddress;
  bool _isGeocoding = false;

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialLocation ??
        const LatLng(AppConfig.kumbhCenterLat, AppConfig.kumbhCenterLng);
    _latController = TextEditingController(
      text: _selectedPosition.latitude.toStringAsFixed(6),
    );
    _lngController = TextEditingController(
      text: _selectedPosition.longitude.toStringAsFixed(6),
    );
    _fetchAddress(_selectedPosition.latitude, _selectedPosition.longitude);
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _fetchAddress(double lat, double lng) async {
    setState(() {
      _isGeocoding = true;
    });
    try {
      final addr = await GeocodingHelper.reverseGeocode(lat, lng);
      if (mounted) {
        setState(() {
          _detectedAddress = addr;
          _isGeocoding = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isGeocoding = false;
        });
      }
    }
  }

  void _onTapMap(gmaps.LatLng latLng) {
    setState(() {
      _selectedPosition = LatLng(latLng.latitude, latLng.longitude);
      _latController.text = latLng.latitude.toStringAsFixed(6);
      _lngController.text = latLng.longitude.toStringAsFixed(6);
    });
    _fetchAddress(latLng.latitude, latLng.longitude);
  }

  void _applyManualCoordinates() {
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    if (lat != null && lng != null) {
      final pos = LatLng(lat, lng);
      setState(() {
        _selectedPosition = pos;
      });
      _mapController?.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(
          gmaps.LatLng(lat, lng),
          15.5,
        ),
      );
      _fetchAddress(lat, lng);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dialogWidth = size.width > 600 ? 560.0 : size.width * 0.94;
    final dialogHeight = size.height > 750 ? 640.0 : size.height * 0.88;

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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.pin_drop_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onBackground,
                          ),
                        ),
                        const Text(
                          'Tap on map or enter coordinates',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.onSurfaceMuted,
                          ),
                        ),
                      ],
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

            // Map Area with Google Maps
            Expanded(
              child: Stack(
                children: [
                  gmaps.GoogleMap(
                    initialCameraPosition: gmaps.CameraPosition(
                      target: gmaps.LatLng(
                        _selectedPosition.latitude,
                        _selectedPosition.longitude,
                      ),
                      zoom: 14.5,
                    ),
                    onMapCreated: (controller) => _mapController = controller,
                    onTap: _onTapMap,
                    markers: {
                      gmaps.Marker(
                        markerId: const gmaps.MarkerId('selected_pos'),
                        position: gmaps.LatLng(
                          _selectedPosition.latitude,
                          _selectedPosition.longitude,
                        ),
                        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                          gmaps.BitmapDescriptor.hueOrange,
                        ),
                        infoWindow: gmaps.InfoWindow(
                          title: 'Pinned Location',
                          snippet: _detectedAddress ??
                              '${_selectedPosition.latitude.toStringAsFixed(4)}, ${_selectedPosition.longitude.toStringAsFixed(4)}',
                        ),
                      ),
                    },
                    myLocationEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                  ),

                  // Auto-Detected Address Banner Overlay
                  Positioned(
                    top: 12,
                    left: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.96),
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
                          if (_isGeocoding)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary),
                              ),
                            )
                          else
                            const Icon(
                              Icons.location_on_rounded,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _isGeocoding
                                  ? 'Detecting address from map...'
                                  : (_detectedAddress ??
                                      'Tap map to set position pin'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _detectedAddress != null
                                    ? AppColors.onBackground
                                    : AppColors.onSurfaceMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Recenter button
                  Positioned(
                    right: 14,
                    bottom: 14,
                    child: FloatingActionButton.small(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      onPressed: () {
                        _mapController?.animateCamera(
                          gmaps.CameraUpdate.newLatLngZoom(
                            gmaps.LatLng(
                              _selectedPosition.latitude,
                              _selectedPosition.longitude,
                            ),
                            15.5,
                          ),
                        );
                      },
                      child: const Icon(Icons.my_location_rounded),
                    ),
                  ),
                ],
              ),
            ),

            // Coordinate Input & Confirmation Footer
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surface,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _latController,
                          label: 'Latitude',
                          hint: '19.9975',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppTextField(
                          controller: _lngController,
                          label: 'Longitude',
                          hint: '73.7898',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: IconButton(
                          icon: const Icon(Icons.sync_rounded,
                              color: AppColors.primary),
                          tooltip: 'Apply Coordinates',
                          onPressed: _applyManualCoordinates,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'Cancel',
                          variant: AppButtonVariant.outline,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          text: 'Confirm Location',
                          icon: Icons.check_circle_rounded,
                          onPressed: () {
                            Navigator.of(context).pop(
                              LocationPickResult(
                                location: _selectedPosition,
                                address: _detectedAddress,
                              ),
                            );
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
