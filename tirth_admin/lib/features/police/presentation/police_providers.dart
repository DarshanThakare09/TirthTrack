import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/police_login_code_model.dart';
import '../../../models/police_officer_model.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/police_repository.dart';

final policeRepositoryProvider = Provider<PoliceRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PoliceRepository(client);
});

final policeFilterProvider = StateProvider<PoliceStatusEnum?>((ref) => null);
final policeSearchQueryProvider = StateProvider<String>((ref) => '');

final policeListProvider = FutureProvider<List<PoliceOfficerModel>>((ref) async {
  final repo = ref.watch(policeRepositoryProvider);
  final filter = ref.watch(policeFilterProvider);
  final query = ref.watch(policeSearchQueryProvider);
  return await repo.getPoliceOfficers(
    statusFilter: filter,
    searchQuery: query,
  );
});

final verifiedPoliceListProvider = FutureProvider<List<PoliceOfficerModel>>((ref) async {
  final repo = ref.watch(policeRepositoryProvider);
  return await repo.getPoliceOfficers(
    statusFilter: PoliceStatusEnum.verified,
  );
});

final policeDetailProvider =
    FutureProvider.family<PoliceOfficerModel, String>((ref, policeId) async {
  final repo = ref.watch(policeRepositoryProvider);
  return await repo.getPoliceOfficerById(policeId);
});

final policeLoginCodesProvider =
    FutureProvider.family<List<PoliceLoginCodeModel>, String>((ref, policeId) async {
  final repo = ref.watch(policeRepositoryProvider);
  return await repo.getLoginCodes(policeId);
});

final loginCodeStatusFilterProvider = StateProvider<LoginCodeStatusEnum?>((ref) => null);
final loginCodeSearchQueryProvider = StateProvider<String>((ref) => '');

final allPoliceLoginCodesProvider =
    FutureProvider<List<PoliceLoginCodeModel>>((ref) async {
  final repo = ref.watch(policeRepositoryProvider);
  final status = ref.watch(loginCodeStatusFilterProvider);
  final query = ref.watch(loginCodeSearchQueryProvider);
  return await repo.getAllLoginCodes(statusFilter: status, searchQuery: query);
});

class PoliceActionController extends StateNotifier<AsyncValue<void>> {
  PoliceActionController(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  final PoliceRepository _repo;
  final Ref _ref;

  Future<bool> verifyOfficer(String policeId) async {
    state = const AsyncValue.loading();
    try {
      final admin = await _ref.read(adminSessionProvider.future);
      if (admin == null) {
        throw Exception('Unauthorized: Admin session not loaded');
      }

      await _repo.verifyOfficer(
        policeId: policeId,
        adminDetailsId: admin.adminId,
      );

      _ref.invalidate(policeListProvider);
      _ref.invalidate(verifiedPoliceListProvider);
      _ref.invalidate(policeDetailProvider(policeId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> rejectOfficer({
    required String policeId,
    required String remarks,
  }) async {
    state = const AsyncValue.loading();
    try {
      final admin = await _ref.read(adminSessionProvider.future);
      if (admin == null) {
        throw Exception('Unauthorized: Admin session not loaded');
      }

      await _repo.rejectOfficer(
        policeId: policeId,
        adminDetailsId: admin.adminId,
        remarks: remarks,
      );

      _ref.invalidate(policeListProvider);
      _ref.invalidate(verifiedPoliceListProvider);
      _ref.invalidate(policeDetailProvider(policeId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<PoliceLoginCodeModel?> generateLoginCode({
    required String policeId,
    required Duration validityDuration,
  }) async {
    state = const AsyncValue.loading();
    try {
      final admin = await _ref.read(adminSessionProvider.future);
      if (admin == null) {
        throw Exception('Unauthorized: Admin session not loaded');
      }

      final code = await _repo.generateLoginCode(
        policeId: policeId,
        adminDetailsId: admin.adminId,
        validityDuration: validityDuration,
      );

      _ref.invalidate(policeLoginCodesProvider(policeId));
      _ref.invalidate(allPoliceLoginCodesProvider);
      state = const AsyncValue.data(null);
      return code;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> revokeLoginCode({
    String? policeId,
    required String codeId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.revokeLoginCode(codeId);
      if (policeId != null) {
        _ref.invalidate(policeLoginCodesProvider(policeId));
      }
      _ref.invalidate(allPoliceLoginCodesProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final policeActionControllerProvider =
    StateNotifierProvider<PoliceActionController, AsyncValue<void>>((ref) {
  final repo = ref.watch(policeRepositoryProvider);
  return PoliceActionController(repo, ref);
});
