import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

/// Clinical confidence indicator bar / dial with descriptive risk labels.
class ConfidenceMeter extends StatelessWidget {
  final double confidence; // 0.0 to 1.0
  final bool isGenuine;
  final bool showLabel;

  const ConfidenceMeter({
    super.key,
    required this.confidence,
    required this.isGenuine,
    this.showLabel = true,
  });

  Color get _color => isGenuine ? AppColors.genuine : AppColors.suspicious;
  Color get _surfaceColor => isGenuine ? AppColors.genuineSurface : AppColors.suspiciousSurface;

  String get _confidenceLevelText {
    final pct = (confidence * 100).toInt();
    if (pct >= 85) return 'High Confidence';
    if (pct >= 65) return 'Moderate Confidence';
    return 'Low Confidence';
  }

  @override
  Widget build(BuildContext context) {
    final pct = (confidence * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Model Confidence',
                  style: AppTypography.label,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '$pct% ($_confidenceLevelText)',
                  style: AppTypography.label.copyWith(
                    color: _color,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        // Progress track
        Container(
          height: 10,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: AppRadius.pill,
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: confidence.clamp(0.05, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: _color,
                borderRadius: AppRadius.pill,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
