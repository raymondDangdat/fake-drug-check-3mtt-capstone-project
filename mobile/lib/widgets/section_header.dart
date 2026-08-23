import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

/// Clean clinical section header with badge number or icon and subtitle.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? stepNumber;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.stepNumber,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stepNumber != null) ...[
            Container(
              width: 26,
              height: 26,
              margin: const EdgeInsets.only(top: 1, right: 10),
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                stepNumber!,
                style: AppTypography.badge.copyWith(
                  color: AppColors.primary,
                  fontSize: 12,
                ),
              ),
            ),
          ] else if (icon != null) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(top: 1, right: 12),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: AppRadius.sm,
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.h3),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppTypography.bodySmall),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
