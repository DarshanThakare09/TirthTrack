// ============================================================
// features/authentication/providers/auth_provider.dart
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/auth_repository.dart';

// ── Supabase client provider ──────────────────────────────────
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

// ── Auth repository provider ──────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

// ── Auth state stream ─────────────────────────────────────────
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// ── Current user ──────────────────────────────────────────────
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.session?.user;
});

// ── Current user ID ───────────────────────────────────────────
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.id;
});

// ── Phone login state ─────────────────────────────────────────
class PhoneLoginNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> sendOtp(String phone) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).sendOtp(phone),
    );
  }
}

final phoneLoginProvider =
    AsyncNotifierProvider<PhoneLoginNotifier, void>(PhoneLoginNotifier.new);

// ── OTP verification state ────────────────────────────────────
class OtpVerificationNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> verifyOtp({
    required String phone,
    required String token,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).verifyOtp(phone: phone, token: token),
    );
  }
}

final otpVerificationProvider =
    AsyncNotifierProvider<OtpVerificationNotifier, void>(
        OtpVerificationNotifier.new);

// ── Sign out ──────────────────────────────────────────────────
class SignOutNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signOut(),
    );
  }
}

final signOutProvider =
    AsyncNotifierProvider<SignOutNotifier, void>(SignOutNotifier.new);
