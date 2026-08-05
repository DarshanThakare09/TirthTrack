// ============================================================
// shared/widgets/loading_widget.dart
// ============================================================

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Centered loading indicator with optional label and brand logo.
class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key, this.label, this.showLogo = true});

  final String? label;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLogo) ...[
            Image.asset(
              'assets/icons/app_logo.png',
              width: 48,
              height: 48,
              color: AppColors.primary,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.temple_hindu_rounded,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary,
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: 14),
            Text(label!, style: AppTextStyles.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// Shimmer-style loading placeholder for list items.
class ShimmerListItem extends StatelessWidget {
  const ShimmerListItem({super.key, this.height = 80});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
    );
  }
}

/// A full list of shimmer placeholders.
class ShimmerList extends StatelessWidget {
  const ShimmerList({super.key, this.count = 5, this.itemHeight = 80});

  final int count;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (_, __) => ShimmerListItem(height: itemHeight),
    );
  }
}
