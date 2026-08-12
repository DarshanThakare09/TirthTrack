import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/alert_model.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/alert_repository.dart';

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AlertRepository(client);
});

final alertSearchQueryProvider = StateProvider<String>((ref) => '');
final alertTypeFilterProvider = StateProvider<AlertTypeEnum?>((ref) => null);
final alertPriorityFilterProvider =
    StateProvider<AlertPriorityEnum?>((ref) => null);
final alertActiveFilterProvider = StateProvider<bool?>((ref) => null);

final alertListProvider = FutureProvider<List<AlertModel>>((ref) async {
  final repo = ref.watch(alertRepositoryProvider);
  final type = ref.watch(alertTypeFilterProvider);
  final priority = ref.watch(alertPriorityFilterProvider);
  final activeOnly = ref.watch(alertActiveFilterProvider);
  final query = ref.watch(alertSearchQueryProvider);

  return await repo.getAlerts(
    typeFilter: type,
    priorityFilter: priority,
    activeOnly: activeOnly,
    searchQuery: query,
  );
});

final alertDetailProvider =
    FutureProvider.family<AlertModel, String>((ref, alertId) async {
  final repo = ref.watch(alertRepositoryProvider);
  return await repo.getAlertById(alertId);
});

class AlertActionController extends StateNotifier<AsyncValue<void>> {
  AlertActionController(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  final AlertRepository _repo;
  final Ref _ref;

  Future<bool> saveAlert({
    String? id,
    required AlertModel alert,
  }) async {
    state = const AsyncValue.loading();
    try {
      if (id == null) {
        final adminSession = _ref.read(adminSessionProvider).valueOrNull;
        if (adminSession == null) {
          throw Exception('Admin session not found. Please log in again.');
        }
        await _repo.createAlert(
          alert: alert,
          adminDetailsId: adminSession.adminId,
        );
      } else {
        await _repo.updateAlert(id, alert);
      }
      _ref.invalidate(alertListProvider);
      if (id != null) _ref.invalidate(alertDetailProvider(id));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> toggleActive(String id, bool currentActive) async {
    try {
      await _repo.toggleAlertActive(id, !currentActive);
      _ref.invalidate(alertListProvider);
      _ref.invalidate(alertDetailProvider(id));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteAlert(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteAlert(id);
      _ref.invalidate(alertListProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final alertActionControllerProvider =
    StateNotifierProvider<AlertActionController, AsyncValue<void>>((ref) {
  final repo = ref.watch(alertRepositoryProvider);
  return AlertActionController(repo, ref);
});
