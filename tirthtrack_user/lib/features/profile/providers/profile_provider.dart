// ============================================================
// features/profile/providers/profile_provider.dart
// ============================================================

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/providers/auth_provider.dart';
import '../models/profile_model.dart';
import '../repositories/profile_repository.dart';

// ── Repository provider ───────────────────────────────────────
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

// ── Profile provider ──────────────────────────────────────────
final profileProvider = AsyncNotifierProvider<ProfileNotifier, ProfileModel>(
  ProfileNotifier.new,
);

class ProfileNotifier extends AsyncNotifier<ProfileModel> {
  @override
  Future<ProfileModel> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) throw Exception('Not authenticated');
    return ref.read(profileRepositoryProvider).fetchProfile(userId);
  }

  /// Re-fetch profile from Supabase.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  /// Update profile fields.
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(profileRepositoryProvider)
          .updateProfile(userId: userId, updates: updates),
    );
  }

  /// Upload a profile photo and update the profile record.
  Future<void> uploadProfilePhoto({
    required Uint8List bytes,
    required String extension,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(profileRepositoryProvider);
      final path = await repo.uploadProfilePhoto(
        userId: userId,
        bytes: bytes,
        extension: extension,
      );
      return repo.updateProfile(
        userId: userId,
        updates: {'profile_photo': path, 'updated_at': DateTime.now().toIso8601String()},
      );
    });
  }
}

// ── Profile photo signed URL ──────────────────────────────────
final profilePhotoUrlProvider = FutureProvider<String?>((ref) async {
  final profile = ref.watch(profileProvider).valueOrNull;
  if (profile?.profilePhoto == null) return null;
  return ref
      .read(profileRepositoryProvider)
      .getProfilePhotoUrl(profile!.profilePhoto);
});
