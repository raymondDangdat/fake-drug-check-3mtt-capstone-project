import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/drug_check_result.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/confidence_meter.dart';
import '../widgets/disclaimer_card.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/section_header.dart';
import '../widgets/status_badge.dart';

/// Clinical verification report screen displaying verdict, findings, recommendations, and inputs.
class ResultsScreen extends StatelessWidget {
  final DrugCheckResult result;

  const ResultsScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(result.checkedAt);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Verification Report'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/history'),
            icon: const Icon(Icons.history_rounded),
            tooltip: 'View History',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: ResponsiveLayout.isDesktop(context)
            ? AppSpacing.screenPaddingDesktop
            : AppSpacing.screenPaddingMobile,
        child: MaxWidthContainer(
          child: ResponsiveLayout(
            mobile: _buildReportContent(context, formattedDate),
            desktop: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Verdict & Metrics
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      _buildVerdictCard(context, formattedDate),
                      const SizedBox(height: 20),
                      _buildRecommendationCard(),
                      const SizedBox(height: 20),
                      _buildActions(context),
                    ],
                  ),
                ),
                const SizedBox(width: 32),

                // Right Column: Findings & Input Breakdown
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      _buildFindingsCard(context),
                      const SizedBox(height: 20),
                      _buildInputSummaryCard(),
                      const SizedBox(height: 20),
                      const DisclaimerCard(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportContent(BuildContext context, String formattedDate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildVerdictCard(context, formattedDate),
        const SizedBox(height: 16),
        _buildFindingsCard(context),
        const SizedBox(height: 16),
        _buildRecommendationCard(),
        const SizedBox(height: 16),
        _buildInputSummaryCard(),
        const SizedBox(height: 24),
        _buildActions(context),
        const SizedBox(height: 24),
        const DisclaimerCard(isCompact: true),
        const SizedBox(height: 36),
      ],
    );
  }

  Widget _buildVerdictCard(BuildContext context, String formattedDate) {
    final isGenuine = result.isGenuine;
    final color = isGenuine ? AppColors.genuine : AppColors.suspicious;
    final surfaceColor = isGenuine ? AppColors.genuineSurface : AppColors.suspiciousSurface;
    final icon = isGenuine ? Icons.check_circle_rounded : Icons.warning_rounded;

    return AppCard(
      backgroundColor: surfaceColor,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBadge(
                label: isGenuine ? 'Low Risk' : 'Suspicious Anomaly',
                variant: isGenuine ? StatusBadgeVariant.genuine : StatusBadgeVariant.suspicious,
              ),
              Text(
                formattedDate,
                style: AppTypography.caption,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.verdictTitle,
                      style: AppTypography.h2.copyWith(color: color),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.verdictSubtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: isGenuine ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.border),
          const SizedBox(height: 16),

          // Confidence Meter
          ConfidenceMeter(
            confidence: result.confidence,
            isGenuine: isGenuine,
          ),
        ],
      ),
    );
  }

  Widget _buildFindingsCard(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            icon: Icons.checklist_rounded,
            title: 'Diagnostic Findings',
            subtitle: 'Evaluated verification criteria and pattern matches',
          ),
          const SizedBox(height: 14),
          if (result.explanation.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'No specific anomaly notes returned for this record.',
                style: AppTypography.bodySmall,
              ),
            )
          else
            ...result.explanation.map((item) => _buildFindingTile(item)),
        ],
      ),
    );
  }

  Widget _buildFindingTile(String text) {
    final cleanText = text
        .replaceAll('✅', '')
        .replaceAll('⚠️', '')
        .replaceAll('🚩', '')
        .replaceAll('🔍', '')
        .trim();

    final isPositive = text.contains('✅') || text.toLowerCase().contains('match') || text.toLowerCase().contains('valid');
    final isWarning = text.contains('⚠️') || text.contains('🚩') || text.toLowerCase().contains('unusual') || text.toLowerCase().contains('suspicious') || text.toLowerCase().contains('mismatch');

    Color tileColor = AppColors.textPrimary;
    IconData tileIcon = Icons.info_outline_rounded;
    Color iconColor = AppColors.textMuted;

    if (isPositive) {
      tileIcon = Icons.check_circle_outline_rounded;
      iconColor = AppColors.genuine;
    } else if (isWarning) {
      tileIcon = Icons.warning_amber_rounded;
      iconColor = AppColors.suspicious;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isWarning ? AppColors.suspiciousSurface : AppColors.surfaceMuted,
        borderRadius: AppRadius.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(tileIcon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              cleanText,
              style: AppTypography.bodySmall.copyWith(
                color: tileColor,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard() {
    return AppCard(
      backgroundColor: AppColors.accentLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                size: 20,
                color: AppColors.accentDark,
              ),
              const SizedBox(width: 8),
              Text(
                'Clinical Guidance & Next Steps',
                style: AppTypography.title.copyWith(
                  color: AppColors.accentDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result.recommendation,
            style: AppTypography.body.copyWith(
              color: const Color(0xFF0C4A6E),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSummaryCard() {
    if (result.inputData.isEmpty) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            icon: Icons.inventory_2_outlined,
            title: 'Submitted Product Details',
            subtitle: 'Summary of the verified packaging data',
          ),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(4),
              1: FlexColumnWidth(6),
            },
            children: result.inputData.entries.map((entry) {
              final value = entry.value.isEmpty ? 'Not specified' : entry.value;
              return TableRow(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      entry.key,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      value,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        AppButton.primary(
          label: 'Verify Another Medicine',
          icon: Icons.search_rounded,
          height: 50,
          width: double.infinity,
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
          },
        ),
        const SizedBox(height: 10),
        AppButton.outlined(
          label: 'View Verification Archive',
          icon: Icons.history_rounded,
          height: 50,
          width: double.infinity,
          onPressed: () {
            Navigator.pushNamed(context, '/history');
          },
        ),
      ],
    );
  }
}
