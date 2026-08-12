import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/route_model.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/route_repository.dart';

final routeRepositoryProvider = Provider<RouteRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RouteRepository(client);
});

final routeSearchQueryProvider = StateProvider<String>((ref) => '');
final routeActiveFilterProvider = StateProvider<bool?>((ref) => null);

final routeListProvider = FutureProvider<List<RouteModel>>((ref) async {
  final repo = ref.watch(routeRepositoryProvider);
  final activeOnly = ref.watch(routeActiveFilterProvider);
  final query = ref.watch(routeSearchQueryProvider);
  return await repo.getRoutes(activeOnly: activeOnly, searchQuery: query);
});

final routeDetailProvider =
    FutureProvider.family<RouteModel, String>((ref, routeId) async {
  final repo = ref.watch(routeRepositoryProvider);
  return await repo.getRouteById(routeId);
});

final routeNodesProvider =
    FutureProvider.family<List<RouteNodeModel>, String>((ref, routeId) async {
  final repo = ref.watch(routeRepositoryProvider);
  return await repo.getRouteNodes(routeId);
});

class RouteActionController extends StateNotifier<AsyncValue<void>> {
  RouteActionController(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  final RouteRepository _repo;
  final Ref _ref;

  Future<bool> saveRoute({
    String? id,
    required RouteModel route,
  }) async {
    state = const AsyncValue.loading();
    try {
      if (id == null) {
        await _repo.createRoute(route);
      } else {
        await _repo.updateRoute(id, route);
      }
      _ref.invalidate(routeListProvider);
      if (id != null) _ref.invalidate(routeDetailProvider(id));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> toggleActive(String id, bool currentActive) async {
    try {
      await _repo.toggleRouteActive(id, !currentActive);
      _ref.invalidate(routeListProvider);
      _ref.invalidate(routeDetailProvider(id));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteRoute(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteRoute(id);
      _ref.invalidate(routeListProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> saveNode({
    String? nodeId,
    required RouteNodeModel node,
  }) async {
    state = const AsyncValue.loading();
    try {
      if (nodeId == null) {
        await _repo.addRouteNode(node);
      } else {
        await _repo.updateRouteNode(nodeId, node);
      }
      _ref.invalidate(routeNodesProvider(node.routeId));
      _ref.invalidate(routeDetailProvider(node.routeId));
      _ref.invalidate(routeListProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteNode(String routeId, String nodeId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteRouteNode(nodeId);
      _ref.invalidate(routeNodesProvider(routeId));
      _ref.invalidate(routeDetailProvider(routeId));
      _ref.invalidate(routeListProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final routeActionControllerProvider =
    StateNotifierProvider<RouteActionController, AsyncValue<void>>((ref) {
  final repo = ref.watch(routeRepositoryProvider);
  return RouteActionController(repo, ref);
});
