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

  Future<void> checkAndRequest() async {
    final service = LocationService.instance;
    var perm = await service.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await service.requestPermission();
    }

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

  Future<void> startTracking() async {
    if (state) return; // already tracking
    final available = await LocationService.instance.isAvailable;
    if (!available) return;

    state = true;
    appLogger.d('LocationTracking: started');

    _subscription = LocationService.instance.getPositionStream().listen(
      (position) async {
        _ref.read(currentPositionProvider.notifier).state = position;
        await _persistLocation(position);
      },
      onError: (e) {
        appLogger.e('LocationTracking stream error: $e');
      },
    );
  }

  Future<void> stopTracking() async {
    await _subscription?.cancel();
    _subscription = null;
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
    super.dispose();
  }
}
