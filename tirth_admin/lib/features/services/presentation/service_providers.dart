import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/service_model.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/service_repository.dart';

final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ServiceRepository(client);
});

final serviceSearchQueryProvider = StateProvider<String>((ref) => '');
final serviceTypeFilterProvider = StateProvider<ServiceTypeEnum?>((ref) => null);
final serviceActiveFilterProvider = StateProvider<bool?>((ref) => null);

final serviceListProvider = FutureProvider<List<ServiceModel>>((ref) async {
  final repo = ref.watch(serviceRepositoryProvider);
  final type = ref.watch(serviceTypeFilterProvider);
  final activeOnly = ref.watch(serviceActiveFilterProvider);
  final query = ref.watch(serviceSearchQueryProvider);
  return await repo.getServices(
    typeFilter: type,
    activeOnly: activeOnly,
    searchQuery: query,
  );
});

final serviceDetailProvider =
    FutureProvider.family<ServiceModel, String>((ref, serviceId) async {
  final repo = ref.watch(serviceRepositoryProvider);
  return await repo.getServiceById(serviceId);
});

class ServiceActionController extends StateNotifier<AsyncValue<void>> {
  ServiceActionController(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  final ServiceRepository _repo;
  final Ref _ref;

  Future<bool> saveService({
    String? id,
    required ServiceModel service,
  }) async {
    state = const AsyncValue.loading();
    try {
      if (id == null) {
        await _repo.createService(service);
      } else {
        await _repo.updateService(id, service);
      }
      _ref.invalidate(serviceListProvider);
      if (id != null) _ref.invalidate(serviceDetailProvider(id));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> toggleActive(String id, bool currentActive) async {
    try {
      await _repo.toggleServiceActive(id, !currentActive);
      _ref.invalidate(serviceListProvider);
      _ref.invalidate(serviceDetailProvider(id));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteService(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteService(id);
      _ref.invalidate(serviceListProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final serviceActionControllerProvider =
    StateNotifierProvider<ServiceActionController, AsyncValue<void>>((ref) {
  final repo = ref.watch(serviceRepositoryProvider);
  return ServiceActionController(repo, ref);
});
