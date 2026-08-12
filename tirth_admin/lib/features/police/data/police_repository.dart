import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../core/constants/supabase_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/logger.dart';
import '../../../models/police_login_code_model.dart';
import '../../../models/police_officer_model.dart';

class PoliceRepository {
  PoliceRepository(this._client);

  final sb.SupabaseClient _client;

  /// Fetch police officers with joined profile details
  Future<List<PoliceOfficerModel>> getPoliceOfficers({
    PoliceStatusEnum? statusFilter,
    String? searchQuery,
  }) async {
    try {
      appLogger.d('PoliceRepository: fetching officers (status: $statusFilter, query: $searchQuery)');

      var query = _client
          .from(SupabaseTable.policeDetails)
          .select('*, profiles:profile_id(*)');

      if (statusFilter != null) {
        query = query.eq('verification_status', statusFilter.dbValue);
      }

      final response = await query.order('created_at', ascending: false);

      final officers = (response as List<dynamic>)
          .map((e) => PoliceOfficerModel.fromJson(e as Map<String, dynamic>))
          .toList();

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        return officers.where((officer) {
          final name = officer.fullName?.toLowerCase() ?? '';
          final badge = officer.badgeNumber.toLowerCase();
          final station = officer.policeStation.toLowerCase();
          final district = officer.district.toLowerCase();
          return name.contains(q) ||
              badge.contains(q) ||
              station.contains(q) ||
              district.contains(q);
        }).toList();
      }

      return officers;
    } catch (e) {
      appLogger.e('PoliceRepository getPoliceOfficers error: $e');
      throw parseSupabaseException(e);
    }
  }

  /// Get single police officer detail
  Future<PoliceOfficerModel> getPoliceOfficerById(String policeId) async {
    try {
      final response = await _client
          .from(SupabaseTable.policeDetails)
          .select('*, profiles:profile_id(*)')
          .eq('id', policeId)
          .single();

      return PoliceOfficerModel.fromJson(response);
    } catch (e) {
      appLogger.e('PoliceRepository getPoliceOfficerById error: $e');
      throw parseSupabaseException(e);
    }
  }

  /// Verify Police Officer
  Future<void> verifyOfficer({
    required String policeId,
    required String adminDetailsId,
  }) async {
    try {
      appLogger.d('PoliceRepository: verifying officer $policeId by admin $adminDetailsId');
      await _client.from(SupabaseTable.policeDetails).update({
        'verification_status': 'verified',
        'verified_by': adminDetailsId,
        'verified_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', policeId);
    } catch (e) {
      appLogger.e('PoliceRepository verifyOfficer error: $e');
      throw parseSupabaseException(e);
    }
  }

  /// Reject Police Officer
  Future<void> rejectOfficer({
    required String policeId,
    required String adminDetailsId,
    required String remarks,
  }) async {
    try {
      appLogger.d('PoliceRepository: rejecting officer $policeId by admin $adminDetailsId');
      await _client.from(SupabaseTable.policeDetails).update({
        'verification_status': 'rejected',
        'remarks': remarks.trim(),
        'verified_by': adminDetailsId,
        'verified_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', policeId);
    } catch (e) {
      appLogger.e('PoliceRepository rejectOfficer error: $e');
      throw parseSupabaseException(e);
    }
  }

  /// Generate a signed URL for private police ID card photo/document
  Future<String?> getSignedIdCardUrl(String storagePath) async {
    try {
      if (storagePath.isEmpty) return null;

      // If it's already a full URL
      if (storagePath.startsWith('http')) return storagePath;

      final signedUrl = await _client.storage
          .from(SupabaseBucket.policeIdCards)
          .createSignedUrl(storagePath, 3600); // 1 hour validity

      return signedUrl;
    } catch (e) {
      appLogger.e('PoliceRepository getSignedIdCardUrl error: $e');
      return null;
    }
  }

  // ── Police Login Codes ──────────────────────────────────────────

  /// Get login codes for a police officer
  Future<List<PoliceLoginCodeModel>> getLoginCodes(String policeId) async {
    try {
      final response = await _client
          .from(SupabaseTable.policeLoginCodes)
          .select()
          .eq('police_id', policeId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((e) => PoliceLoginCodeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      appLogger.e('PoliceRepository getLoginCodes error: $e');
      throw parseSupabaseException(e);
    }
  }

  /// Generate and store a new 6-digit numeric login code for a verified police officer
  Future<PoliceLoginCodeModel> generateLoginCode({
    required String policeId,
    required String adminDetailsId,
    required Duration validityDuration,
  }) async {
    try {
      final randomCode = _generateRandomCode(6);
      final expiresAt = DateTime.now().add(validityDuration);

      final insertData = {
        'police_id': policeId,
        'login_code': randomCode,
        'expires_at': expiresAt.toIso8601String(),
        'status': 'active',
        'created_by': adminDetailsId,
      };

      final response = await _client
          .from(SupabaseTable.policeLoginCodes)
          .insert(insertData)
          .select()
          .single();

      return PoliceLoginCodeModel.fromJson(response);
    } catch (e) {
      appLogger.e('PoliceRepository generateLoginCode error: $e');
      throw parseSupabaseException(e);
    }
  }

  /// Revoke an active login code
  Future<void> revokeLoginCode(String codeId) async {
    try {
      appLogger.d('PoliceRepository: revoking code $codeId');
      await _client.from(SupabaseTable.policeLoginCodes).update({
        'status': 'revoked',
      }).eq('id', codeId);
    } catch (e) {
      appLogger.e('PoliceRepository revokeLoginCode error: $e');
      throw parseSupabaseException(e);
    }
  }

  String _generateRandomCode(int length) {
    final random = Random.secure();
    final digits = List.generate(length, (_) => random.nextInt(10).toString());
    return digits.join();
  }
}
