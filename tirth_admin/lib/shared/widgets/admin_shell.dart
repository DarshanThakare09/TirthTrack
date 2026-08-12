import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/presentation/auth_providers.dart';
import 'confirm_dialog.dart';

class AdminShell extends ConsumerWidget {
  const AdminShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final adminSession = ref.watch(adminSessionProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                'assets/icons/app_icon.png',
                width: 22,
                height: 22,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TirthTrack Admin',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Nashik Kumbh Mela Portal',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.onSurfaceMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Alerts & Broadcasts',
            onPressed: () => context.go('/alerts'),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, size: 24),
            tooltip: 'Admin Profile',
            onPressed: () => context.go('/profile'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppColors.surface,
        child: SafeArea(
          child: Column(
            children: [
              // Admin Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceVariant,
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            (adminSession?.fullName.isNotEmpty == true)
                                ? adminSession!.fullName[0].toUpperCase()
                                : 'A',
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                adminSession?.fullName ?? 'Administrator',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onBackground,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                adminSession?.employeeCode != null
                                    ? 'ID: ${adminSession!.employeeCode}'
                                    : 'Admin Console',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.onSurfaceMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        adminSession?.designation ?? 'System Administrator',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Drawer Navigation Items List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _DrawerSectionHeader(title: 'MAIN MONITORING'),
                    _DrawerItem(
                      icon: Icons.dashboard_rounded,
                      title: 'Dashboard Overview',
                      subtitle: 'Live statistics & quick actions',
                      isSelected: location.startsWith('/dashboard'),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/dashboard');
                      },
                    ),

                    _DrawerSectionHeader(title: 'SECURITY & POLICE'),
                    _DrawerItem(
                      icon: Icons.local_police_rounded,
                      title: 'Police Officers',
                      subtitle: 'Verification & badge management',
                      isSelected: location.startsWith('/police') &&
                          !location.startsWith('/police-bases'),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/police');
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.shield_rounded,
                      title: 'Police Bases',
                      subtitle: 'Stations, outposts & staffing',
                      isSelected: location.startsWith('/police-bases'),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/police-bases');
                      },
                    ),

                    _DrawerSectionHeader(title: 'NAVIGATION & SECTORS'),
                    _DrawerItem(
                      icon: Icons.alt_route_rounded,
                      title: 'Pilgrim Routes',
                      subtitle: 'Paths, waypoints & distances',
                      isSelected: location.startsWith('/routes'),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/routes');
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.map_rounded,
                      title: 'Sectors & Boundaries',
                      subtitle: 'Zonal polygons & coordinates',
                      isSelected: location.startsWith('/sectors'),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/sectors');
                      },
                    ),

                    _DrawerSectionHeader(title: 'FACILITIES & ALERTS'),
                    _DrawerItem(
                      icon: Icons.medical_services_rounded,
                      title: 'Services & Facilities',
                      subtitle: 'Medical, water, parking, toilets',
                      isSelected: location.startsWith('/services'),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/services');
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.campaign_rounded,
                      title: 'Alerts & Broadcasts',
                      subtitle: 'Emergency bulletins & updates',
                      isSelected: location.startsWith('/alerts'),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/alerts');
                      },
                    ),

                    const Divider(height: 24, indent: 16, endIndent: 16),
                    _DrawerSectionHeader(title: 'ACCOUNT'),
                    _DrawerItem(
                      icon: Icons.person_rounded,
                      title: 'Administrator Profile',
                      subtitle: 'Account details & permissions',
                      isSelected: location.startsWith('/profile'),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/profile');
                      },
                    ),
                  ],
                ),
              ),

              // Signout Action at bottom of drawer
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.error,
                    ),
                    title: const Text(
                      'Sign Out',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'End current administrative session',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 11,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      final confirmed = await ConfirmDialog.show(
                        context,
                        title: 'Sign Out?',
                        message:
                            'Are you sure you want to end your current session?',
                        confirmLabel: 'Sign Out',
                        isDestructive: true,
                        icon: Icons.logout_rounded,
                      );

                      if (confirmed == true && context.mounted) {
                        await ref.read(authRepositoryProvider).signOut();
                        ref.invalidate(adminSessionProvider);
                        if (context.mounted) {
                          context.go('/login');
                        }
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: child,
    );
  }
}

class _DrawerSectionHeader extends StatelessWidget {
  const _DrawerSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.onSurfaceMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: isSelected
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.2))
            : null,
      ),
      child: ListTile(
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? Colors.white : AppColors.iconDark,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 14,
            color: isSelected ? AppColors.primaryDark : AppColors.onBackground,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? AppColors.primaryDark.withValues(alpha: 0.8)
                      : AppColors.onSurfaceMuted,
                ),
              )
            : null,
        trailing: isSelected
            ? const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.primaryDark,
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
