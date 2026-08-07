// ============================================================
// router/router_notifier.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/authentication/providers/auth_provider.dart';
import '../features/profile/providers/profile_provider.dart';
import 'app_router.dart';

/// Listens to auth state changes and triggers router refresh.
/// Also performs route redirects based on auth + profile state.
final routerNotifierProvider =
    AsyncNotifierProvider<RouterNotifier, void>(RouterNotifier.new);

class RouterNotifier extends AsyncNotifier<void> implements Listenable {
  VoidCallback? _routerListener;

  @override
  Future<void> build() async {
    // Watch auth state — rebuild when it changes
    ref.listen(authStateProvider, (_, __) {
      _routerListener?.call();
    });
    // Watch profile — rebuild when profile loads/changes
    ref.listen(profileProvider, (_, __) {
      _routerListener?.call();
    });
  }

  // ── GoRouter Listenable ──────────────────────────────────
  @override
  void addListener(VoidCallback listener) {
    _routerListener = listener;
  }

  @override
  void removeListener(VoidCallback listener) {
    _routerListener = null;
  }

  // ── Redirect Logic ────────────────────────────────────────
  String? redirect(BuildContext context, GoRouterState state) {
    final path = state.uri.path;

    // ── Auth state ──────────────────────────────────────────
    final authState = ref.read(authStateProvider);
    final isAuthenticated = authState.valueOrNull?.session != null;

    final isOnAuthRoute = path == AppRoutes.phoneLogin ||
        path == AppRoutes.otpVerification ||
        path == AppRoutes.splash;

    // Still on splash — let splash handle navigation itself
    if (path == AppRoutes.splash) return null;

    // Not authenticated → auth screens
    if (!isAuthenticated) {
      if (!isOnAuthRoute) return AppRoutes.phoneLogin;
      return null;
    }

    // ── Authenticated ────────────────────────────────────────
    // On auth screens while logged in → go to maps
    if (isOnAuthRoute) return AppRoutes.maps;

    // ── Profile completeness ─────────────────────────────────
    final profileState = ref.read(profileProvider);
    final profile = profileState.valueOrNull;

    // Profile loaded and incomplete → complete profile
    if (profile != null && !profile.isComplete) {
      if (path != AppRoutes.completeProfile) return AppRoutes.completeProfile;
      return null;
    }

    // Complete profile done → Go to Maps (Removed location permission step)
    if (profile != null &&
        profile.isComplete &&
        path == AppRoutes.completeProfile) {
      return AppRoutes.maps;
    }

    return null;
  }
}
