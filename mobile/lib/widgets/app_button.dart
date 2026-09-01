import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, outlined, danger }

/// Reusable primary and secondary action button with inline loading state.
class AppButton extends StatelessWidget {
  final String label;
  final String? loadingLabel;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final AppButtonVariant variant;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loadingLabel,
    this.icon,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.width,
    this.height = 48.0,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.loadingLabel,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 48.0,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.loadingLabel,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 48.0,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.outlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.loadingLabel,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 48.0,
  }) : variant = AppButtonVariant.outlined;

  const AppButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.loadingLabel,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 48.0,
  }) : variant = AppButtonVariant.danger;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    Color bg;
    Color fg;
    BorderSide? border;

    switch (variant) {
      case AppButtonVariant.primary:
        bg = isEnabled ? AppColors.primary : AppColors.primary.withValues(alpha: 0.7);
        fg = AppColors.textOnPrimary;
        break;
      case AppButtonVariant.secondary:
        bg = isEnabled ? AppColors.accentLight : AppColors.surfaceMuted;
        fg = isEnabled ? AppColors.accentDark : AppColors.textMuted;
        break;
      case AppButtonVariant.outlined:
        bg = Colors.transparent;
        fg = isEnabled ? AppColors.primary : AppColors.textMuted;
        border = BorderSide(
          color: isEnabled ? AppColors.primary : AppColors.border,
          width: 1.5,
        );
        break;
      case AppButtonVariant.danger:
        bg = isEnabled ? AppColors.suspicious : AppColors.suspicious.withValues(alpha: 0.7);
        fg = Colors.white;
        break;
    }

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          ),
          if (loadingLabel != null) ...[
            const SizedBox(width: 10),
            Text(
              loadingLabel!,
              style: AppTypography.button.copyWith(color: fg),
            ),
          ],
        ] else ...[
          if (icon != null) ...[
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: AppTypography.button.copyWith(color: fg),
          ),
        ],
      ],
    );

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: bg,
        borderRadius: AppRadius.md,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: AppRadius.md,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: AppRadius.md,
              border: border != null ? Border.fromBorderSide(border) : null,
            ),
            alignment: Alignment.center,
            child: content,
          ),
        ),
      ),
    );
  }
}
