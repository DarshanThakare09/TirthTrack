// ============================================================
// features/profile/repositories/profile_repository.dart
// ============================================================

import 'dart:async';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/logger.dart';
import '../models/profile_model.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  // ── Fetch own profile ─────────────────────────────────────
  Future<ProfileModel> fetchProfile(String userId) async {
    try {
      appLogger.d('ProfileRepository: fetching profile $userId');
      final data = await _client
          .from(SupabaseTable.profiles)
          .select()
          .eq('id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 20));

      if (data == null) {
        appLogger.w(
            'ProfileRepository: profile $userId not found in DB, using fallback profile');
        return _createFallbackProfile(userId);
      }

      return ProfileModel.fromJson(data);
    } on TimeoutException catch (e) {
      appLogger.w('ProfileRepository fetchProfile timeout: $e');
      throw const NoInternetException();
    } on PostgrestException catch (e) {
      appLogger.e('ProfileRepository fetchProfile PostgrestException: ${e.message}');
      throw ServerException(e.message);
    } catch (e) {
      appLogger.w('ProfileRepository fetchProfile network error: $e');
      throw const NoInternetException();
    }
  }

  ProfileModel _createFallbackProfile(String userId) {
    final currentUser = _client.auth.currentUser;
    return ProfileModel(
      id: userId,
      fullName: currentUser?.userMetadata?['full_name'] as String?,
      email: currentUser?.email,
      mobile: currentUser?.phone,
      role: UserRoleEnum.user,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // ── Update own profile ────────────────────────────────────
  Future<ProfileModel> updateProfile({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      appLogger.d('ProfileRepository: updating profile $userId');
      final data = await _client
          .from(SupabaseTable.profiles)
          .update(updates)
          .eq('id', userId)
          .select()
          .maybeSingle()
          .timeout(const Duration(seconds: 20));

      if (data == null) {
        final upserted = await _client
            .from(SupabaseTable.profiles)
            .upsert({'id': userId, ...updates})
            .select()
            .single()
            .timeout(const Duration(seconds: 20));
        return ProfileModel.fromJson(upserted);
      }

      return ProfileModel.fromJson(data);
    } on PostgrestException catch (e) {
      appLogger.e('ProfileRepository updateProfile: ${e.message}');
      throw ServerException(e.message);
    } catch (e) {
      appLogger.e('ProfileRepository updateProfile unexpected: $e');
      throw const UnknownException();
    }
  }

  // ── Upload profile photo ──────────────────────────────────
  Future<String> uploadProfilePhoto({
    required String userId,
    required Uint8List bytes,
    required String extension,
  }) async {
    if (bytes.length > AppConstants.profilePhotoMaxBytes) {
      throw const ValidationException('Photo must be under 5 MB.');
    }

    final path = '$userId/profile.$extension';
    try {
      appLogger.d('ProfileRepository: uploading photo to $path');
      await _client.storage
          .from(SupabaseBucket.profilePhotos)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/$extension',
              upsert: true,
            ),
          );
      return path;
    } on StorageException catch (e) {
      appLogger.e('ProfileRepository uploadPhoto: ${e.message}');
      throw ServerException(e.message);
    } catch (e) {
      appLogger.e('ProfileRepository uploadPhoto unexpected: $e');
      throw const UnknownException();
    }
  }

  // ── Get signed profile photo URL ──────────────────────────
  Future<String?> getProfilePhotoUrl(String? storagePath) async {
    if (storagePath == null || storagePath.isEmpty) return null;
    try {
      final signedUrl = await _client.storage
          .from(SupabaseBucket.profilePhotos)
          .createSignedUrl(storagePath, AppConstants.signedUrlExpiry);
      return signedUrl;
    } catch (e) {
      appLogger.w('ProfileRepository getPhotoUrl: $e');
      return null;
    }
  }
}
