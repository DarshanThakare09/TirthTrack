import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../core/constants/supabase_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/logger.dart';
import '../../../models/admin_profile_model.dart';

class AuthRepository {
  AuthRepository(this._client);

  final sb.SupabaseClient _client;

  sb.Session? get currentSession => _client.auth.currentSession;
  sb.User? get currentUser => _client.auth.currentUser;
  Stream<sb.AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Sign in with Email and Password
  Future<sb.AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      appLogger.d('AuthRepository: signing in admin $email');
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return response;
    } catch (e) {
      appLogger.e('AuthRepository signInWithPassword error: $e');
      throw parseSupabaseException(e);
    }
  }

  /// Verify and load Admin Profile from admin_details & profiles
  Future<AdminProfileModel> getAdminProfile(String userId) async {
    try {
      appLogger.d('AuthRepository: verifying admin permissions for $userId');

      // 1. Fetch Profile
      final profileRes = await _client
          .from(SupabaseTable.profiles)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (profileRes == null) {
        throw const UnauthorizedException(
          'Profile record not found in system.',
        );
      }

      // 2. Fetch Admin Details
      final adminDetailsRes = await _client
          .from(SupabaseTable.adminDetails)
          .select()
          .eq('profile_id', userId)
          .maybeSingle();

      if (adminDetailsRes == null) {
        throw const UnauthorizedException(
          'Access Denied: This account is not registered as an Administrator.',
        );
      }

      return AdminProfileModel.fromSupabase(
        profileJson: profileRes,
        adminDetailsJson: adminDetailsRes,
      );
    } catch (e) {
      appLogger.e('AuthRepository getAdminProfile error: $e');
      if (e is AppException) rethrow;
      throw parseSupabaseException(e);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      appLogger.d('AuthRepository: signing out admin');
      await _client.auth.signOut();
    } catch (e) {
      appLogger.e('AuthRepository signOut error: $e');
      throw parseSupabaseException(e);
    }
  }
}
