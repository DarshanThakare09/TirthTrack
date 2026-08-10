import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/services/location_service.dart';
import '../../../core/utils/logger.dart';
import '../../authentication/providers/auth_provider.dart';
import '../models/live_location_model.dart';
import '../repositories/live_location_repository.dart';

// ── Repository provider ───────────────────────────────────────
final liveLocationRepositoryProvider = Provider<LiveLocationRepository>(
  (ref) => LiveLocationRepository(ref.watch(supabaseClientProvider)),
);

// ── Permission status ─────────────────────────────────────────
enum LocationPermissionStatus { unknown, granted, denied, permanentlyDenied }

final locationPermissionProvider =
    StateNotifierProvider<LocationPermissionNotifier, LocationPermissionStatus>(
  (ref) => LocationPermissionNotifier(),
);

class LocationPermissionNotifier
    extends StateNotifier<LocationPermissionStatus> {
  LocationPermissionNotifier() : super(LocationPermissionStatus.unknown);

  Future<void>? _inFlightRequest;

  Future<void> checkPermissionOnly() async {
    final service = LocationService.instance;
    final perm = await service.checkPermission();
    _updateStatus(perm);
  }

  Future<void> checkAndRequest() async {
    if (_inFlightRequest != null) {
      return _inFlightRequest;
    }
    _inFlightRequest = _performCheckAndRequest();
    try {
      await _inFlightRequest;
    } finally {
      _inFlightRequest = null;
    }
  }

  Future<void> _performCheckAndRequest() async {
    final service = LocationService.instance;
    var perm = await service.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await service.requestPermission();
    }
    _updateStatus(perm);
  }

  void _updateStatus(LocationPermission perm) {
    if (perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse) {
      state = LocationPermissionStatus.granted;
    } else if (perm == LocationPermission.deniedForever) {
      state = LocationPermissionStatus.permanentlyDenied;
    } else {
      state = LocationPermissionStatus.denied;
    }
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }

  Future<void> openLocationSettings() async {
    await LocationService.instance.openLocationSettings();
  }
}

// ── Current position ──────────────────────────────────────────
final currentPositionProvider = StateProvider<Position?>((ref) => null);

// ── Location tracking ─────────────────────────────────────────
final locationTrackingProvider =
    StateNotifierProvider<LocationTrackingNotifier, bool>(
  (ref) => LocationTrackingNotifier(ref),
);

class LocationTrackingNotifier extends StateNotifier<bool> {
  LocationTrackingNotifier(this._ref) : super(false);

  final Ref _ref;
  final Battery _battery = Battery();
  StreamSubscription<Position>? _subscription;
  Timer? _periodicTimer;
  Future<Position?>? _inFlightInit;
  bool _isStarting = false;

  /// Single unified entry point to request permission, start 5s location tracking,
  /// and return current position for map centering.
  Future<Position?> initializeLocationService() async {
    if (_inFlightInit != null) {
      return _inFlightInit;
    }
    _inFlightInit = _performInitialize();
    try {
      return await _inFlightInit;
    } finally {
      _inFlightInit = null;
    }
  }

  Future<Position?> _performInitialize() async {
    await _ref.read(locationPermissionProvider.notifier).checkAndRequest();
    final status = _ref.read(locationPermissionProvider);

    if (status != LocationPermissionStatus.granted) {
      return null;
    }

    await startTracking();
    final pos = _ref.read(currentPositionProvider) ??
        await LocationService.instance.getCurrentPosition();

    if (pos != null) {
      _ref.read(currentPositionProvider.notifier).state = pos;
    }

    return pos;
  }

  Future<void> startTracking() async {
    if (state || _isStarting) return; // already tracking or starting
    _isStarting = true;
    try {
      final available = await LocationService.instance.isAvailable;
      if (!available) {
        appLogger.w('LocationTracking: location service or permission not available.');
        return;
      }

      state = true;
      appLogger.d('LocationTracking: started 5s tracking to Supabase');

      // 1. Initial position fetch & persist immediately
      final initialPos = await LocationService.instance.getCurrentPosition();
      if (initialPos != null) {
        _ref.read(currentPositionProvider.notifier).state = initialPos;
        await _persistLocation(initialPos);
      }

      // Cancel existing if any
      await _subscription?.cancel();
      _periodicTimer?.cancel();

      // 2. Position stream to receive real-time location changes
      _subscription = LocationService.instance.getPositionStream().listen(
        (position) async {
          _ref.read(currentPositionProvider.notifier).state = position;
        },
        onError: (e) {
          appLogger.e('LocationTracking stream error: $e');
        },
      );

      // 3. Periodic timer to fetch and store location data on Supabase every 5 seconds
      _periodicTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        try {
          var pos = await LocationService.instance.getCurrentPosition();
          pos ??= _ref.read(currentPositionProvider);
          if (pos != null) {
            _ref.read(currentPositionProvider.notifier).state = pos;
            await _persistLocation(pos);
          }
        } catch (e) {
          appLogger.e('LocationTracking periodic update error: $e');
        }
      });
    } finally {
      _isStarting = false;
    }
  }

  Future<void> stopTracking() async {
    await _subscription?.cancel();
    _periodicTimer?.cancel();
    _subscription = null;
    _periodicTimer = null;
    state = false;
    appLogger.d('LocationTracking: stopped');
  }

  Future<void> _persistLocation(Position position) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;

    int? batteryLevel;
    try {
      batteryLevel = await _battery.batteryLevel;
    } catch (_) {}

    final model = LiveLocationModel(
      id: '',
      profileId: userId,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      altitude: position.altitude,
      speed: position.speed >= 0 ? position.speed : null,
      heading: position.heading >= 0 ? position.heading : null,
      batteryPercentage: batteryLevel,
      locationSource: LocationSourceEnum.gps,
      recordedAt: DateTime.now(),
    );

    await _ref.read(liveLocationRepositoryProvider).insertLocation(model);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _periodicTimer?.cancel();
    super.dispose();
  }
}
