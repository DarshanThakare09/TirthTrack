// ============================================================
// features/profile/presentation/widgets/profile_avatar_widget.dart
// ============================================================

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Displays a user's profile avatar.
/// Falls back to splash logo `assets/icons/app_icon.png` if no photo exists.
class ProfileAvatarWidget extends StatelessWidget {
  const ProfileAvatarWidget({
    super.key,
    this.photoUrl,
    this.name,
    this.radius = 40,
    this.onTap,
    this.showEditBadge = false,
  });

  final String? photoUrl;
  final String? name;
  final double radius;
  final VoidCallback? onTap;
  final bool showEditBadge;

  @override
  Widget build(BuildContext context) {
    Widget avatar;

    if (photoUrl != null && photoUrl!.isNotEmpty) {
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primaryContainer,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: photoUrl!,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            placeholder: (_, __) => const CircularProgressIndicator(
              strokeWidth: 1.5,
              color: AppColors.primary,
            ),
            errorWidget: (_, __, ___) => _fallbackLogoWidget(),
          ),
        ),
      );
    } else {
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.surface,
        child: _fallbackLogoWidget(),
      );
    }

    if (showEditBadge) {
      avatar = Stack(
        children: [
          avatar,
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null && !showEditBadge) {
      return GestureDetector(onTap: onTap, child: avatar);
    }
    return avatar;
  }

  Widget _fallbackLogoWidget() {
    return Padding(
      padding: EdgeInsets.all(radius * 0.25),
      child: Image.asset(
        'assets/icons/app_logo.png',
        width: radius * 1.5,
        height: radius * 1.5,
        color: AppColors.primary,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          Icons.person_rounded,
          color: AppColors.primary,
          size: radius * 0.9,
        ),
      ),
    );
  }
}
