import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.backgroundColor,
    this.icon,
    this.fontSize = 11,
    this.isFilled = false,
  });

  final String label;
  final Color color;
  final Color? backgroundColor;
  final IconData? icon;
  final double fontSize;
  final bool isFilled;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ??
        (isFilled ? color : color.withValues(alpha: 0.12));
    final textColor = isFilled ? Colors.white : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFilled ? color : color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  factory StatusBadge.police(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return const StatusBadge(
          label: 'Verified',
          color: AppColors.statusVerified,
          icon: Icons.verified_rounded,
        );
      case 'rejected':
        return const StatusBadge(
          label: 'Rejected',
          color: AppColors.statusRejected,
          icon: Icons.cancel_rounded,
        );
      case 'pending':
      default:
        return const StatusBadge(
          label: 'Pending Verification',
          color: AppColors.statusPending,
          icon: Icons.hourglass_top_rounded,
        );
    }
  }

  factory StatusBadge.loginCode(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const StatusBadge(
          label: 'ACTIVE',
          color: AppColors.statusActive,
          icon: Icons.check_circle_rounded,
        );
      case 'used':
        return const StatusBadge(
          label: 'USED',
          color: AppColors.statusUsed,
          icon: Icons.done_all_rounded,
        );
      case 'expired':
        return const StatusBadge(
          label: 'EXPIRED',
          color: AppColors.statusExpired,
          icon: Icons.timer_off_rounded,
        );
      case 'revoked':
        return const StatusBadge(
          label: 'REVOKED',
          color: AppColors.statusRevoked,
          icon: Icons.block_rounded,
        );
      default:
        return StatusBadge(
          label: status.toUpperCase(),
          color: AppColors.onSurfaceMuted,
        );
    }
  }

  factory StatusBadge.active(bool isActive) {
    return isActive
        ? const StatusBadge(
            label: 'Active',
            color: AppColors.success,
            icon: Icons.check_circle_rounded,
          )
        : const StatusBadge(
            label: 'Inactive',
            color: AppColors.onSurfaceMuted,
            icon: Icons.do_not_disturb_on_rounded,
          );
  }
}
