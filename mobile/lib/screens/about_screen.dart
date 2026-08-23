import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_card.dart';
import '../widgets/disclaimer_card.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/section_header.dart';

/// Informational, regulatory, and capstone attribution guide screen.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('About & Verification Guide'),
      ),
      body: SingleChildScrollView(
        padding: ResponsiveLayout.isDesktop(context)
            ? AppSpacing.screenPaddingDesktop
            : AppSpacing.screenPaddingMobile,
        child: MaxWidthContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project Intro Card
              AppCard(
                backgroundColor: AppColors.primarySurface,
                borderColor: AppColors.primaryBorder,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: AppRadius.sm,
                          ),
                          child: const Icon(
                            Icons.local_pharmacy_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('3MTT Capstone Project', style: AppTypography.h3),
                              Text(
                                'AI-Assisted Drug Verification System for Nigeria',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.primaryDark),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'FakeDrugChecker addresses the critical challenge of counterfeit and substandard pharmaceuticals in Nigeria. '
                      'Using machine learning pattern recognition across NAFDAC numbers, barcodes, manufacturer entities, and packaging characteristics, '
                      'it flags suspicious anomalies to protect consumers and healthcare providers.',
                      style: AppTypography.body.copyWith(height: 1.55),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section: How the AI Model Works
              const SectionHeader(
                icon: Icons.psychology_outlined,
                title: 'How The Machine Learning Model Works',
                subtitle: 'Transparent, interpretable risk assessment breakdown',
              ),
              const SizedBox(height: 10),
              AppCard(
                child: Column(
                  children: [
                    _buildFeatureExplanation(
                      icon: Icons.qr_code_2_rounded,
                      title: '1. Barcode & EAN-13 Analysis',
                      description:
                          'Extracts country-of-origin prefixes and checks structural validity against GS1 standard registry rules.',
                    ),
                    const Divider(height: 20),
                    _buildFeatureExplanation(
                      icon: Icons.verified_outlined,
                      title: '2. NAFDAC Format & Regex Matching',
                      description:
                          'Validates NAFDAC registration numbering schemas (e.g. A4-XXXX, 04-XXXX) against genuine registered drug records.',
                    ),
                    const Divider(height: 20),
                    _buildFeatureExplanation(
                      icon: Icons.account_balance_outlined,
                      title: '3. Manufacturer Entity Verification',
                      description:
                          'Evaluates manufacturer names against known registered pharmaceutical manufacturers licensed in Nigeria and internationally.',
                    ),
                    const Divider(height: 20),
                    _buildFeatureExplanation(
                      icon: Icons.balance_outlined,
                      title: '4. Formulation & Strength Consistency',
                      description:
                          'Cross-checks dosage forms (tablets, capsules, suspensions) with standard active ingredient strengths to catch formulation counterfeits.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section: Understanding Results
              const SectionHeader(
                icon: Icons.fact_check_outlined,
                title: 'Understanding Verdict Terminology',
                subtitle: 'What each risk level means for consumers',
              ),
              const SizedBox(height: 10),
              ResponsiveLayout(
                mobile: Column(
                  children: [
                    _buildVerdictExplanationCard(
                      isGenuine: true,
                      title: 'Appears Consistent',
                      description:
                          'All checked identifiers, formats, and entities closely match verified pharmaceutical standards.',
                    ),
                    const SizedBox(height: 12),
                    _buildVerdictExplanationCard(
                      isGenuine: false,
                      title: 'Suspicious Indicators',
                      description:
                          'One or more fields failed verification checks (e.g. invalid NAFDAC format or unknown manufacturer).',
                    ),
                  ],
                ),
                desktop: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildVerdictExplanationCard(
                        isGenuine: true,
                        title: 'Appears Consistent',
                        description:
                            'All checked identifiers, formats, and entities closely match verified pharmaceutical standards.',
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildVerdictExplanationCard(
                        isGenuine: false,
                        title: 'Suspicious Indicators',
                        description:
                            'One or more fields failed verification checks (e.g. invalid NAFDAC format or unknown manufacturer).',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section: Official NAFDAC MAS Guide
              const SectionHeader(
                icon: Icons.security_rounded,
                title: 'Official NAFDAC Verification Tips',
                subtitle: 'Physical checks to perform on every medication pack',
              ),
              const SizedBox(height: 10),
              AppCard(
                child: Column(
                  children: [
                    _buildTipItem(
                      number: '1',
                      title: 'Scratch & SMS (Mobile Authentication Service - MAS)',
                      description:
                          'For anti-malarials and antibiotics, scratch the silver panel on the pack and SMS the PIN to the toll-free shortcode (e.g. 38353 or 2873).',
                    ),
                    const SizedBox(height: 12),
                    _buildTipItem(
                      number: '2',
                      title: 'Inspect Seals and Printing Quality',
                      description:
                          'Legitimate pharmaceutical packaging has crisp, embossed text, tamper-evident seals, and matching batch numbers across carton and blister foil.',
                    ),
                    const SizedBox(height: 12),
                    _buildTipItem(
                      number: '3',
                      title: 'Purchase from Licensed Community Pharmacies',
                      description:
                          'Avoid roadside drug vendors or open market hawkers. Always obtain prescription medications from registered premises under PCN oversight.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Legal Disclaimer Card
              const DisclaimerCard(),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerdictExplanationCard({
    required bool isGenuine,
    required String title,
    required String description,
  }) {
    final color = isGenuine ? AppColors.genuine : AppColors.suspicious;
    final surfaceColor = isGenuine ? AppColors.genuineSurface : AppColors.suspiciousSurface;
    final borderColor = isGenuine ? AppColors.genuineBorder : AppColors.suspiciousBorder;
    final icon = isGenuine ? Icons.check_circle_rounded : Icons.warning_rounded;
    final textColor = isGenuine ? const Color(0xFF065F46) : const Color(0xFF991B1B);

    return AppCard(
      borderColor: borderColor,
      backgroundColor: surfaceColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.title.copyWith(color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: AppTypography.bodySmall.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureExplanation({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.title.copyWith(fontSize: 14)),
              const SizedBox(height: 3),
              Text(description, style: AppTypography.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipItem({
    required String number,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.primarySurface,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: AppTypography.badge.copyWith(color: AppColors.primary, fontSize: 12),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.title.copyWith(fontSize: 14)),
              const SizedBox(height: 2),
              Text(description, style: AppTypography.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
