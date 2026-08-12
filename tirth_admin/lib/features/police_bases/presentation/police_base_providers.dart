import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/police_base_model.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/police_base_repository.dart';

final policeBaseRepositoryProvider = Provider<PoliceBaseRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PoliceBaseRepository(client);
});

final policeBaseSearchQueryProvider = StateProvider<String>((ref) => '');
final policeBaseActiveFilterProvider = StateProvider<bool?>((ref) => null);

final policeBaseListProvider =
    FutureProvider<List<PoliceBaseModel>>((ref) async {
  final repo = ref.watch(policeBaseRepositoryProvider);
  final activeOnly = ref.watch(policeBaseActiveFilterProvider);
  final query = ref.watch(policeBaseSearchQueryProvider);
  return await repo.getPoliceBases(
    activeOnly: activeOnly,
    searchQuery: query,
  );
});

final policeBaseDetailProvider =
    FutureProvider.family<PoliceBaseModel, String>((ref, id) async {
  final repo = ref.watch(policeBaseRepositoryProvider);
  return await repo.getPoliceBaseById(id);
});

class PoliceBaseActionController extends StateNotifier<AsyncValue<void>> {
  PoliceBaseActionController(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  final PoliceBaseRepository _repo;
  final Ref _ref;

  Future<bool> saveBase({
    String? id,
    required PoliceBaseModel base,
  }) async {
    state = const AsyncValue.loading();
    try {
      if (id == null) {
        await _repo.createPoliceBase(base);
      } else {
        await _repo.updatePoliceBase(id, base);
      }
      _ref.invalidate(policeBaseListProvider);
      if (id != null) _ref.invalidate(policeBaseDetailProvider(id));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> toggleActive(String id, bool currentActive) async {
    try {
      await _repo.toggleBaseActive(id, !currentActive);
      _ref.invalidate(policeBaseListProvider);
      _ref.invalidate(policeBaseDetailProvider(id));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteBase(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deletePoliceBase(id);
      _ref.invalidate(policeBaseListProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final policeBaseActionControllerProvider =
    StateNotifierProvider<PoliceBaseActionController, AsyncValue<void>>((ref) {
  final repo = ref.watch(policeBaseRepositoryProvider);
  return PoliceBaseActionController(repo, ref);
});
