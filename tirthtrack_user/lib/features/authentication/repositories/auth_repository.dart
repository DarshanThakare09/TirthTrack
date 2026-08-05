// ============================================================
// features/authentication/repositories/auth_repository.dart
// ============================================================

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/logger.dart';

class AuthRepository {
  AuthRepository(this._client);

  final sb.SupabaseClient _client;

  // ── Current session ──────────────────────────────────────
  sb.Session? get currentSession => _client.auth.currentSession;
  sb.User? get currentUser => _client.auth.currentUser;

  /// Stream of auth state changes.
  Stream<sb.AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;

  // ── Phone OTP — Send ─────────────────────────────────────
  Future<void> sendOtp(String phone) async {
    try {
      appLogger.d('AuthRepository: sending OTP to $phone');
      await _client.auth.signInWithOtp(phone: phone);
    } on sb.AuthException catch (e) {
      appLogger.e('AuthRepository sendOtp: ${e.message}');
      throw AuthException(e.message);
    } catch (e) {
      appLogger.e('AuthRepository sendOtp unexpected: $e');
      throw const UnknownException();
    }
  }

  // ── Phone OTP — Verify ───────────────────────────────────
  Future<sb.AuthResponse> verifyOtp({
    required String phone,
    required String token,
  }) async {
    try {
      appLogger.d('AuthRepository: verifying OTP for $phone');
      final response = await _client.auth.verifyOTP(
        phone: phone,
        token: token,
        type: sb.OtpType.sms,
      );
      return response;
    } on sb.AuthException catch (e) {
      appLogger.e('AuthRepository verifyOtp: ${e.message}');
      throw AuthException(e.message);
    } catch (e) {
      appLogger.e('AuthRepository verifyOtp unexpected: $e');
      throw const UnknownException();
    }
  }

  // ── Sign Out ─────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      appLogger.d('AuthRepository: signing out');
      await _client.auth.signOut();
    } on sb.AuthException catch (e) {
      appLogger.e('AuthRepository signOut: ${e.message}');
      throw AuthException(e.message);
    } catch (e) {
      appLogger.e('AuthRepository signOut unexpected: $e');
      throw const UnknownException();
    }
  }
}
