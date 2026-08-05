// ============================================================
// features/maps/providers/maps_providers.dart
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/providers/auth_provider.dart';
import '../../location/providers/location_provider.dart';
import '../models/police_base_model.dart';
import '../models/route_model.dart';
import '../models/service_model.dart';
import '../repositories/police_base_repository.dart';
import '../repositories/route_repository.dart';
import '../repositories/service_repository.dart';

// ── Repositories ──────────────────────────────────────────────
final routeRepositoryProvider = Provider<RouteRepository>(
  (ref) => RouteRepository(ref.watch(supabaseClientProvider)),
);

final serviceRepositoryProvider = Provider<ServiceRepository>(
  (ref) => ServiceRepository(ref.watch(supabaseClientProvider)),
);

final policeBaseRepositoryProvider = Provider<PoliceBaseRepository>(
  (ref) => PoliceBaseRepository(ref.watch(supabaseClientProvider)),
);

final sectorRepositoryProvider = Provider<SectorRepository>(
  (ref) => SectorRepository(ref.watch(supabaseClientProvider)),
);

// ── Maps tab index ─────────────────────────────────────────────
final mapsTabIndexProvider = StateProvider<int>((ref) => 0);

// ── Routes ────────────────────────────────────────────────────
final routesProvider =
    AsyncNotifierProvider<RoutesNotifier, List<RouteModel>>(
        RoutesNotifier.new);

class RoutesNotifier extends AsyncNotifier<List<RouteModel>> {
  @override
  Future<List<RouteModel>> build() =>
      ref.read(routeRepositoryProvider).fetchActiveRoutes();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(routeRepositoryProvider).fetchActiveRoutes());
  }
}

// ── Selected route ────────────────────────────────────────────
final selectedRouteProvider = StateProvider<RouteModel?>((ref) => null);

// ── Route nodes ───────────────────────────────────────────────
final routeNodesProvider =
    FutureProvider.family<List<RouteNodeModel>, String>((ref, routeId) {
  return ref.read(routeRepositoryProvider).fetchRouteNodes(routeId);
});

// ── Services ──────────────────────────────────────────────────
final servicesProvider =
    AsyncNotifierProvider<ServicesNotifier, List<ServiceModel>>(
        ServicesNotifier.new);

class ServicesNotifier extends AsyncNotifier<List<ServiceModel>> {
  @override
  Future<List<ServiceModel>> build() {
    final position = ref.watch(currentPositionProvider);
    return ref.read(serviceRepositoryProvider).fetchActiveServices(
          userLat: position?.latitude,
          userLng: position?.longitude,
        );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final position = ref.read(currentPositionProvider);
    state = await AsyncValue.guard(
      () => ref.read(serviceRepositoryProvider).fetchActiveServices(
            userLat: position?.latitude,
            userLng: position?.longitude,
          ),
    );
  }
}

// ── Service filter ────────────────────────────────────────────
final serviceTypeFilterProvider = StateProvider<ServiceTypeEnum?>((ref) => null);

final serviceSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredServicesProvider = Provider<List<ServiceModel>>((ref) {
  final services = ref.watch(servicesProvider).valueOrNull ?? [];
  final typeFilter = ref.watch(serviceTypeFilterProvider);
  final query = ref.watch(serviceSearchQueryProvider).toLowerCase().trim();

  var filtered = services;
  if (typeFilter != null) {
    filtered = filtered
        .where((s) => s.serviceType == typeFilter)
        .toList();
  }
  if (query.isNotEmpty) {
    filtered = filtered
        .where((s) =>
            s.serviceName.toLowerCase().contains(query) ||
            (s.description?.toLowerCase().contains(query) ?? false))
        .toList();
  }
  return filtered;
});

// ── Police Bases ──────────────────────────────────────────────
final policeBasesProvider =
    AsyncNotifierProvider<PoliceBasesNotifier, List<PoliceBaseModel>>(
        PoliceBasesNotifier.new);

class PoliceBasesNotifier extends AsyncNotifier<List<PoliceBaseModel>> {
  @override
  Future<List<PoliceBaseModel>> build() {
    final position = ref.watch(currentPositionProvider);
    return ref.read(policeBaseRepositoryProvider).fetchActiveBases(
          userLat: position?.latitude,
          userLng: position?.longitude,
        );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final position = ref.read(currentPositionProvider);
    state = await AsyncValue.guard(
      () => ref.read(policeBaseRepositoryProvider).fetchActiveBases(
            userLat: position?.latitude,
            userLng: position?.longitude,
          ),
    );
  }
}

// ── Sectors ───────────────────────────────────────────────────
final sectorsProvider =
    FutureProvider<List<SectorModel>>((ref) {
  return ref.read(sectorRepositoryProvider).fetchSectors();
});

final sectorNodesProvider =
    FutureProvider.family<List<SectorNodeModel>, String>((ref, sectorId) {
  return ref.read(sectorRepositoryProvider).fetchSectorNodes(sectorId);
});

// ── Selected service for map detail ───────────────────────────
final selectedServiceProvider = StateProvider<ServiceModel?>((ref) => null);

// ── Selected police base for map detail ───────────────────────
final selectedPoliceBaseProvider = StateProvider<PoliceBaseModel?>((ref) => null);
