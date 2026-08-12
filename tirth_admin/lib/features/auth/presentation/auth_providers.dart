import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../models/admin_profile_model.dart';
import '../data/auth_repository.dart';

final supabaseClientProvider = Provider<sb.SupabaseClient>((ref) {
  return sb.Supabase.instance.client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepository(client);
});

final authStateStreamProvider = StreamProvider<sb.AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

/// Current authenticated user
final currentUserProvider = Provider<sb.User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final authState = ref.watch(authStateStreamProvider).valueOrNull;
  return authState?.session?.user ?? repo.currentUser;
});

/// Admin session details — verifies user is an actual Administrator
final adminSessionProvider = FutureProvider<AdminProfileModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final repo = ref.watch(authRepositoryProvider);
  return await repo.getAdminProfile(user.id);
});

/// Login controller
class LoginController extends StateNotifier<AsyncValue<void>> {
  LoginController(this._authRepo, this._ref) : super(const AsyncValue.data(null));

  final AuthRepository _authRepo;
  final Ref _ref;

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final res = await _authRepo.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user != null) {
        // Trigger verification of admin role
        await _authRepo.getAdminProfile(res.user!.id);
        _ref.invalidate(adminSessionProvider);
        state = const AsyncValue.data(null);
        return true;
      } else {
        throw Exception('Sign in failed: No user returned');
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final loginControllerProvider =
    StateNotifierProvider<LoginController, AsyncValue<void>>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return LoginController(repo, ref);
});
