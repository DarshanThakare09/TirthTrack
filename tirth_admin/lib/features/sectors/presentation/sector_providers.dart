import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/sector_model.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/sector_repository.dart';

final sectorRepositoryProvider = Provider<SectorRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SectorRepository(client);
});

final sectorSearchQueryProvider = StateProvider<String>((ref) => '');

final sectorListProvider = FutureProvider<List<SectorModel>>((ref) async {
  final repo = ref.watch(sectorRepositoryProvider);
  final query = ref.watch(sectorSearchQueryProvider);
  return await repo.getSectors(searchQuery: query);
});

final sectorsWithNodesProvider = FutureProvider<List<SectorModel>>((ref) async {
  final repo = ref.watch(sectorRepositoryProvider);
  final query = ref.watch(sectorSearchQueryProvider);
  return await repo.getSectorsWithNodes(searchQuery: query);
});

final sectorDetailProvider =
    FutureProvider.family<SectorModel, String>((ref, sectorId) async {
  final repo = ref.watch(sectorRepositoryProvider);
  return await repo.getSectorById(sectorId);
});

final sectorNodesProvider =
    FutureProvider.family<List<SectorNodeModel>, String>((ref, sectorId) async {
  final repo = ref.watch(sectorRepositoryProvider);
  return await repo.getSectorNodes(sectorId);
});

class SectorActionController extends StateNotifier<AsyncValue<void>> {
  SectorActionController(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  final SectorRepository _repo;
  final Ref _ref;

  Future<bool> createSectorWithNodes({
    required SectorModel sector,
    required List<LatLng> nodes,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.createSectorWithNodes(sector: sector, nodes: nodes);
      _ref.invalidate(sectorListProvider);
      _ref.invalidate(sectorsWithNodesProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> saveSector({
    String? id,
    required SectorModel sector,
  }) async {
    state = const AsyncValue.loading();
    try {
      if (id == null) {
        await _repo.createSector(sector);
      } else {
        await _repo.updateSector(id, sector);
      }
      _ref.invalidate(sectorListProvider);
      _ref.invalidate(sectorsWithNodesProvider);
      if (id != null) _ref.invalidate(sectorDetailProvider(id));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteSector(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteSector(id);
      _ref.invalidate(sectorListProvider);
      _ref.invalidate(sectorsWithNodesProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> addNode(SectorNodeModel node) async {
    try {
      await _repo.addSectorNode(node);
      _ref.invalidate(sectorNodesProvider(node.sectorId));
      _ref.invalidate(sectorDetailProvider(node.sectorId));
      _ref.invalidate(sectorListProvider);
      _ref.invalidate(sectorsWithNodesProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateNode(String nodeId, SectorNodeModel node) async {
    try {
      await _repo.updateSectorNode(nodeId, node);
      _ref.invalidate(sectorNodesProvider(node.sectorId));
      _ref.invalidate(sectorDetailProvider(node.sectorId));
      _ref.invalidate(sectorsWithNodesProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteNode(String nodeId, String sectorId) async {
    try {
      await _repo.deleteSectorNode(nodeId, sectorId);
      _ref.invalidate(sectorNodesProvider(sectorId));
      _ref.invalidate(sectorDetailProvider(sectorId));
      _ref.invalidate(sectorListProvider);
      _ref.invalidate(sectorsWithNodesProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> reorderNodes(
    String sectorId,
    List<SectorNodeModel> reorderedNodes,
  ) async {
    try {
      await _repo.reorderSectorNodes(sectorId, reorderedNodes);
      _ref.invalidate(sectorNodesProvider(sectorId));
      _ref.invalidate(sectorDetailProvider(sectorId));
      _ref.invalidate(sectorsWithNodesProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final sectorActionControllerProvider =
    StateNotifierProvider<SectorActionController, AsyncValue<void>>((ref) {
  final repo = ref.watch(sectorRepositoryProvider);
  return SectorActionController(repo, ref);
});
