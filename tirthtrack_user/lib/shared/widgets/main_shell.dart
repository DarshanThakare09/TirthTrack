// ============================================================
// shared/widgets/main_shell.dart
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/local_notification_service.dart';
import '../../core/services/location_service.dart';
import '../../core/theme/app_colors.dart';
import '../../features/location/providers/location_provider.dart';
import '../../features/notifications/providers/notification_provider.dart';
import '../../router/app_router.dart';

/// Main shell with bottom navigation bar attached to the bottom.
/// Only 3 tabs: Maps, Chatbot, Profile.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
  StreamSubscription<String?>? _notificationTapSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureLocationActive();
      LocalNotificationService.instance.requestPermissions();
    });

    // Listen for notification tap events to navigate to Alerts screen
    _notificationTapSub =
        LocalNotificationService.instance.onNotificationTapped.listen((payload) {
      if (mounted) {
        context.push(AppRoutes.notifications);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _ensureLocationActive();
      ref.read(alertsProvider.notifier).refresh();
      ref.read(notificationsProvider.notifier).refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationTapSub?.cancel();
    super.dispose();
  }

  Future<void> _ensureLocationActive() async {
    final isAvailable = await LocationService.instance.isAvailable;
    if (!isAvailable && mounted) {
      context.go(AppRoutes.locationPermission);
      return;
    }

    if (mounted) {
      ref.read(locationTrackingProvider.notifier).startTracking();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep alerts and notifications providers active for Realtime & periodic sync
    ref.watch(alertsProvider);
    ref.watch(notificationsProvider);
    final totalCount =
        ref.watch(totalNotificationsAndAlertsCountProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(
              top: BorderSide(color: AppColors.border, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: NavigationBar(
              selectedIndex: widget.navigationShell.currentIndex,
              elevation: 0,
              backgroundColor: Colors.white,
              onDestinationSelected: (index) {
                widget.navigationShell.goBranch(
                  index,
                  initialLocation: index == widget.navigationShell.currentIndex,
                );
              },
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore_rounded),
                  label: 'Explore Maps',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.forum_outlined),
                  selectedIcon: Icon(Icons.forum_rounded),
                  label: 'Pilgrim AI',
                ),
                NavigationDestination(
                  icon: totalCount > 0
                      ? Badge(
                          label: Text(
                            totalCount > 99 ? '99+' : '$totalCount',
                            style: const TextStyle(fontSize: 10),
                          ),
                          child: const Icon(Icons.person_outline_rounded),
                        )
                      : const Icon(Icons.person_outline_rounded),
                  selectedIcon: const Icon(Icons.person_rounded),
                  label: 'My Account',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
