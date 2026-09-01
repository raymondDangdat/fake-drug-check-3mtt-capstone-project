import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

/// NAFDAC & safety compliance notice card with clean borderless styling.
class DisclaimerCard extends StatelessWidget {
  final String? customText;
  final bool isCompact;

  const DisclaimerCard({
    super.key,
    this.customText,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.warningSurface,
        borderRadius: AppRadius.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.shield_outlined,
            size: 20,
            color: AppColors.warning,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Regulatory Verification Notice',
                  style: AppTypography.label.copyWith(
                    color: AppColors.warning,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  customText ??
                      'This tool provides an AI-assisted risk assessment based on reference patterns. '
                      'It does not replace official NAFDAC verification or professional clinical advice from a licensed pharmacist.',
                  style: AppTypography.bodySmall.copyWith(
                    color: const Color(0xFF78350F), // Dark Amber for high contrast
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
