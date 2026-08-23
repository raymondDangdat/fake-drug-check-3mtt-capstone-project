import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

enum StatusBadgeVariant { genuine, suspicious, caution, neutral, online, offline }

/// Semantic status and verdict badge component.
class StatusBadge extends StatelessWidget {
  final String label;
  final StatusBadgeVariant variant;
  final IconData? icon;
  final bool isCompact;

  const StatusBadge({
    super.key,
    required this.label,
    required this.variant,
    this.icon,
    this.isCompact = false,
  });

  const StatusBadge.genuine({
    super.key,
    this.label = 'Appears Genuine',
    this.icon = Icons.check_circle_rounded,
    this.isCompact = false,
  }) : variant = StatusBadgeVariant.genuine;

  const StatusBadge.suspicious({
    super.key,
    this.label = 'Suspicious',
    this.icon = Icons.warning_amber_rounded,
    this.isCompact = false,
  }) : variant = StatusBadgeVariant.suspicious;

  const StatusBadge.caution({
    super.key,
    this.label = 'Caution',
    this.icon = Icons.info_outline_rounded,
    this.isCompact = false,
  }) : variant = StatusBadgeVariant.caution;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    BorderSide border;
    IconData defaultIcon;

    switch (variant) {
      case StatusBadgeVariant.genuine:
        bg = AppColors.genuineSurface;
        fg = AppColors.genuine;
        border = const BorderSide(color: AppColors.genuineBorder);
        defaultIcon = Icons.check_circle_rounded;
        break;
      case StatusBadgeVariant.suspicious:
        bg = AppColors.suspiciousSurface;
        fg = AppColors.suspicious;
        border = const BorderSide(color: AppColors.suspiciousBorder);
        defaultIcon = Icons.warning_rounded;
        break;
      case StatusBadgeVariant.caution:
        bg = AppColors.warningSurface;
        fg = AppColors.warning;
        border = const BorderSide(color: AppColors.warningBorder);
        defaultIcon = Icons.error_outline_rounded;
        break;
      case StatusBadgeVariant.online:
        bg = AppColors.genuineSurface;
        fg = AppColors.online;
        border = const BorderSide(color: AppColors.genuineBorder);
        defaultIcon = Icons.cloud_done_rounded;
        break;
      case StatusBadgeVariant.offline:
        bg = AppColors.suspiciousSurface;
        fg = AppColors.offline;
        border = const BorderSide(color: AppColors.suspiciousBorder);
        defaultIcon = Icons.cloud_off_rounded;
        break;
      case StatusBadgeVariant.neutral:
        bg = AppColors.surfaceMuted;
        fg = AppColors.textSecondary;
        border = const BorderSide(color: AppColors.border);
        defaultIcon = Icons.info_outline_rounded;
        break;
    }

    final displayIcon = icon ?? defaultIcon;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.pill,
        border: Border.fromBorderSide(border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(displayIcon, size: isCompact ? 13 : 15, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.badge.copyWith(
              color: fg,
              fontSize: isCompact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
