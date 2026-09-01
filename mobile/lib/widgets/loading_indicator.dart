import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

/// Step-by-step clinical verification loading indicator with status messages.
class LoadingIndicator extends StatefulWidget {
  final String? initialMessage;

  const LoadingIndicator({super.key, this.initialMessage});

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator> {
  int _stepIndex = 0;

  final List<String> _steps = const [
    'Parsing medication identifiers...',
    'Checking NAFDAC format & registration patterns...',
    'Cross-referencing manufacturer & origin database...',
    'Evaluating counterfeit risk indicators...',
    'Compiling verification report...',
  ];

  @override
  void initState() {
    super.initState();
    _cycleSteps();
  }

  void _cycleSteps() {
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted && _stepIndex < _steps.length - 1) {
        setState(() => _stepIndex++);
        _cycleSteps();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Analyzing Medication',
            style: AppTypography.h3,
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _steps[_stepIndex],
              key: ValueKey<int>(_stepIndex),
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
