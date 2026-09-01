import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_card.dart';
import '../widgets/disclaimer_card.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/status_badge.dart';
import 'barcode_scanner_sheet.dart';

/// Home verification portal screen with a fixed top header and borderless cards.
class HomeScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _apiHealthy = false;
  bool _checkingHealth = true;

  @override
  void initState() {
    super.initState();
    _checkApiHealth();
  }

  Future<void> _checkApiHealth() async {
    final apiService = context.read<ApiService>();
    final healthy = await apiService.isHealthy();
    if (mounted) {
      setState(() {
        _apiHealthy = healthy;
        _checkingHealth = false;
      });
    }
  }

  Future<void> _handleBarcodeScan() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerSheet()),
    );

    if (barcode != null && barcode.isNotEmpty && mounted) {
      Navigator.pushNamed(context, '/check', arguments: {'barcode': barcode});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      // Fixed sticky header on Mobile
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: AppColors.surface,
              elevation: 0,
              scrolledUnderElevation: 0.5,
              automaticallyImplyLeading: false,
              titleSpacing: 16,
              title: _buildMobileBrandHeader(),
            ),
      body: SingleChildScrollView(
        padding: isDesktop
            ? AppSpacing.screenPaddingDesktop
            : AppSpacing.screenPaddingMobile,
        child: MaxWidthContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // Hero Heading & Subtitle
              Text(
                'Verify Before You Trust',
                style: AppTypography.display,
              ),
              const SizedBox(height: 8),
              Text(
                'Check pharmaceutical packaging details, NAFDAC registration formats, and manufacturer records to detect counterfeit medication risks.',
                style: AppTypography.bodyLarge,
              ),
              const SizedBox(height: 24),

              // Two Primary Action Cards (Scan vs Form) - Borderless
              ResponsiveLayout(
                mobile: Column(
                  children: [
                    _buildPrimaryActionCard(
                      icon: Icons.qr_code_scanner_rounded,
                      badge: 'Fastest',
                      title: 'Scan Product Barcode',
                      description:
                          'Use your device camera to instantly scan the barcode on the carton or blister pack.',
                      actionLabel: 'Open Scanner',
                      isPrimary: true,
                      onTap: _handleBarcodeScan,
                    ),
                    const SizedBox(height: 12),
                    _buildPrimaryActionCard(
                      icon: Icons.edit_note_rounded,
                      badge: 'Manual Entry',
                      title: 'Enter Medication Details',
                      description:
                          'Input the drug name, NAFDAC registration number, batch number, and manufacturer.',
                      actionLabel: 'Open Form',
                      isPrimary: false,
                      onTap: () => Navigator.pushNamed(context, '/check'),
                    ),
                  ],
                ),
                desktop: Row(
                  children: [
                    Expanded(
                      child: _buildPrimaryActionCard(
                        icon: Icons.qr_code_scanner_rounded,
                        badge: 'Fastest Method',
                        title: 'Scan Product Barcode',
                        description:
                            'Use your camera to scan the 13-digit EAN barcode printed on the packaging.',
                        actionLabel: 'Scan Barcode',
                        isPrimary: true,
                        onTap: _handleBarcodeScan,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildPrimaryActionCard(
                        icon: Icons.edit_note_rounded,
                        badge: 'Detailed Check',
                        title: 'Enter Medication Details',
                        description:
                            'Fill in NAFDAC number, batch, dosage, and manufacturer for comprehensive AI analysis.',
                        actionLabel: 'Enter Details',
                        isPrimary: false,
                        onTap: () => Navigator.pushNamed(context, '/check'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Quick Sample Demo Section (Borderless)
              AppCard(
                backgroundColor: AppColors.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.science_outlined, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Test With Verification Presets',
                          style: AppTypography.title.copyWith(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select a demo medication profile to immediately test the AI classification engine.',
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildPresetChip(
                          label: 'Genuine Paracetamol Sample',
                          icon: Icons.check_circle_outline_rounded,
                          color: AppColors.genuine,
                          bgColor: AppColors.genuineSurface,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/check',
                              arguments: {'preset': 'genuine'},
                            );
                          },
                        ),
                        _buildPresetChip(
                          label: 'Counterfeit / Suspicious Sample',
                          icon: Icons.warning_amber_rounded,
                          color: AppColors.suspicious,
                          bgColor: AppColors.suspiciousSurface,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/check',
                              arguments: {'preset': 'suspicious'},
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // How It Works Section
              Text('How It Works', style: AppTypography.h2),
              const SizedBox(height: 4),
              Text(
                'Three simple steps to verify medication before consumption.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 16),

              ResponsiveLayout(
                mobile: Column(
                  children: [
                    _buildStepCard(
                      step: '1',
                      title: 'Capture or Enter Details',
                      description:
                          'Scan the product barcode or type in the drug name, NAFDAC number, and batch code.',
                      icon: Icons.camera_alt_outlined,
                    ),
                    const SizedBox(height: 10),
                    _buildStepCard(
                      step: '2',
                      title: 'AI Pattern Analysis',
                      description:
                          'The system checks formatting, regex validity, manufacturer legitimacy, and formulation consistency.',
                      icon: Icons.insights_outlined,
                    ),
                    const SizedBox(height: 10),
                    _buildStepCard(
                      step: '3',
                      title: 'Review Risk & Action',
                      description:
                          'Receive an interpretable risk assessment and clear guidance on physical packaging verification.',
                      icon: Icons.fact_check_outlined,
                    ),
                  ],
                ),
                desktop: Row(
                  children: [
                    Expanded(
                      child: _buildStepCard(
                        step: '1',
                        title: 'Capture or Enter Details',
                        description:
                          'Scan the product barcode or enter NAFDAC registration & batch details.',
                        icon: Icons.camera_alt_outlined,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildStepCard(
                        step: '2',
                        title: 'AI Pattern Analysis',
                        description:
                          'The model checks formatting, regex schemas, manufacturer legitimacy, and origin.',
                        icon: Icons.insights_outlined,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildStepCard(
                        step: '3',
                        title: 'Review Risk & Action',
                        description:
                          'Get a clear risk verdict with actionable advice on what to inspect next.',
                        icon: Icons.fact_check_outlined,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Regulatory & NAFDAC Notice Card
              const DisclaimerCard(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileBrandHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppRadius.md,
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'FakeDrugChecker',
              style: AppTypography.title.copyWith(fontSize: 16),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: AppRadius.sm,
              ),
              child: Text(
                'NG',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        _buildHealthStatusPill(),
      ],
    );
  }

  Widget _buildHealthStatusPill() {
    if (_checkingHealth) {
      return const StatusBadge(
        label: 'Connecting...',
        variant: StatusBadgeVariant.neutral,
        icon: Icons.sync_rounded,
        isCompact: true,
      );
    }
    if (_apiHealthy) {
      return const StatusBadge.genuine(
        label: 'Engine Ready',
        isCompact: true,
      );
    }
    return InkWell(
      onTap: () {
        setState(() => _checkingHealth = true);
        _checkApiHealth();
      },
      borderRadius: AppRadius.pill,
      child: const StatusBadge.suspicious(
        label: 'Offline (Tap to Retry)',
        isCompact: true,
      ),
    );
  }

  Widget _buildPrimaryActionCard({
    required IconData icon,
    required String badge,
    required String title,
    required String description,
    required String actionLabel,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isPrimary ? AppColors.primarySurface : AppColors.surface,
      borderRadius: AppRadius.lg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lg,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: AppRadius.lg,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isPrimary ? AppColors.primary : AppColors.surfaceMuted,
                      borderRadius: AppRadius.md,
                    ),
                    child: Icon(
                      icon,
                      color: isPrimary ? Colors.white : AppColors.textPrimary,
                      size: 22,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isPrimary
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : AppColors.surfaceMuted,
                      borderRadius: AppRadius.sm,
                    ),
                    child: Text(
                      badge,
                      style: AppTypography.caption.copyWith(
                        color: isPrimary ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(title, style: AppTypography.h3),
              const SizedBox(height: 4),
              Text(description, style: AppTypography.bodySmall),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    actionLabel,
                    style: AppTypography.button.copyWith(
                      color: isPrimary ? AppColors.primary : AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: isPrimary ? AppColors.primary : AppColors.textPrimary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip({
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bgColor,
      borderRadius: AppRadius.md,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.md,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: AppRadius.md,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.button.copyWith(
                  fontSize: 13,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required String step,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              step,
              style: AppTypography.badge.copyWith(
                color: AppColors.primary,
                fontSize: 13,
              ),
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
      ),
    );
  }
}
