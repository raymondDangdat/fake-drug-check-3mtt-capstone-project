import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/history_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_dropdown.dart';
import '../widgets/app_text_field.dart';
import '../widgets/disclaimer_card.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/section_header.dart';
import 'barcode_scanner_sheet.dart';

/// Drug input verification form screen with 3 clinical sections & desktop split-view.
class DrugCheckScreen extends StatefulWidget {
  final Map<String, dynamic>? initialArgs;

  const DrugCheckScreen({super.key, this.initialArgs});

  @override
  State<DrugCheckScreen> createState() => _DrugCheckScreenState();
}

class _DrugCheckScreenState extends State<DrugCheckScreen> {
  final _formKey = GlobalKey<FormState>();

  final _drugNameController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _nafdacController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _batchController = TextEditingController();
  final _strengthController = TextEditingController();

  String _selectedDosageForm = 'Tablet';
  String _selectedCountry = 'Nigeria';
  bool _isLoading = false;

  static const _dosageForms = [
    'Tablet',
    'Capsule',
    'Syrup',
    'Suspension',
    'Injection',
    'Cream',
    'Ointment',
    'Drops',
    'Powder',
    'Sachet',
  ];

  static const _countries = [
    'Nigeria',
    'India',
    'China',
    'Ghana',
    'United Kingdom',
    'United States',
    'Pakistan',
    'South Africa',
    'Kenya',
    'Unknown',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialArguments();
    });
  }

  void _handleInitialArguments() {
    final args = widget.initialArgs ??
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      if (args['barcode'] != null) {
        setState(() {
          _barcodeController.text = args['barcode'] as String;
        });
      } else if (args['preset'] == 'genuine') {
        _loadGenuineSample();
      } else if (args['preset'] == 'suspicious') {
        _loadSuspiciousSample();
      }
    }
  }

  @override
  void dispose() {
    _drugNameController.dispose();
    _manufacturerController.dispose();
    _nafdacController.dispose();
    _barcodeController.dispose();
    _batchController.dispose();
    _strengthController.dispose();
    super.dispose();
  }

  void _loadGenuineSample() {
    setState(() {
      _drugNameController.text = 'Paracetamol';
      _manufacturerController.text = 'Emzor Pharmaceutical Industries';
      _nafdacController.text = 'A4-7823';
      _barcodeController.text = '6190012345670';
      _batchController.text = 'BN25-0042';
      _strengthController.text = '500mg';
      _selectedDosageForm = 'Tablet';
      _selectedCountry = 'Nigeria';
    });
  }

  void _loadSuspiciousSample() {
    setState(() {
      _drugNameController.text = 'Super Paracetmol Extra';
      _manufacturerController.text = 'QuickCure Labs International';
      _nafdacController.text = 'INVALID-999';
      _barcodeController.text = '12345678';
      _batchController.text = 'XYZ-UNKNOWN';
      _strengthController.text = '500mg';
      _selectedDosageForm = 'Tablet';
      _selectedCountry = 'China';
    });
  }

  void _clearForm() {
    setState(() {
      _drugNameController.clear();
      _manufacturerController.clear();
      _nafdacController.clear();
      _barcodeController.clear();
      _batchController.clear();
      _strengthController.clear();
      _selectedDosageForm = 'Tablet';
      _selectedCountry = 'Nigeria';
    });
  }

  Future<void> _openBarcodeScanner() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerSheet()),
    );

    if (scannedCode != null && scannedCode.isNotEmpty && mounted) {
      setState(() {
        _barcodeController.text = scannedCode;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Barcode detected: $scannedCode'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete the required medication fields.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final apiService = context.read<ApiService>();
    final historyService = context.read<HistoryService>();

    try {
      final result = await apiService.checkDrug(
        drugName: _drugNameController.text.trim(),
        manufacturer: _manufacturerController.text.trim(),
        nafdacNumber: _nafdacController.text.trim(),
        barcode: _barcodeController.text.trim(),
        batchNumber: _batchController.text.trim(),
        dosageForm: _selectedDosageForm,
        strength: _strengthController.text.trim(),
        country: _selectedCountry,
      );

      // Save to local history
      await historyService.saveResult(result);

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/results',
          arguments: result,
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.message);
      }
    } catch (_) {
      if (mounted) {
        _showErrorSnackBar('Verification timed out. Please check your internet connection.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.suspicious,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Medication Verification Form'),
        actions: [
          IconButton(
            onPressed: _clearForm,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset form',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: ResponsiveLayout.isDesktop(context)
            ? AppSpacing.screenPaddingDesktop
            : AppSpacing.screenPaddingMobile,
        child: MaxWidthContainer(
          child: ResponsiveLayout(
            mobile: _buildFormContent(),
            desktop: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: The 3-section Form
                Expanded(
                  flex: 6,
                  child: _buildFormContent(),
                ),
                const SizedBox(width: 32),

                // Right Column: Guidelines & Presets
                Expanded(
                  flex: 4,
                  child: _buildDesktopSidebar(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Sample Presets (Mobile View)
          if (ResponsiveLayout.isMobile(context)) ...[
            _buildSampleButtonsBar(),
            const SizedBox(height: 18),
          ],

          // Section 1: Medication Identity
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  stepNumber: '1',
                  title: 'Medication Identity',
                  subtitle: 'Active product name, form, and strength',
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _drugNameController,
                  label: 'Medication / Brand Name *',
                  hint: 'e.g. Paracetamol or Coartem',
                  prefixIcon: Icons.medication_rounded,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Medication name is required' : null,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: AppDropdown<String>(
                        label: 'Dosage Form',
                        value: _selectedDosageForm,
                        items: _dosageForms,
                        itemLabel: (f) => f,
                        prefixIcon: Icons.local_pharmacy_rounded,
                        onChanged: (v) => setState(() => _selectedDosageForm = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _strengthController,
                        label: 'Strength',
                        hint: 'e.g. 500mg',
                        prefixIcon: Icons.science_outlined,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section 2: Identifiers & Packaging
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  stepNumber: '2',
                  title: 'Packaging & Registration Identifiers',
                  subtitle: 'NAFDAC registration, barcode, and batch codes',
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _nafdacController,
                  label: 'NAFDAC Registration Number',
                  hint: 'e.g. A4-7823 or 04-1234',
                  helperText: 'Found printed on the outer carton or label',
                  prefixIcon: Icons.verified_outlined,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _barcodeController,
                  label: 'Product Barcode (EAN-13)',
                  hint: 'e.g. 6190012345670',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.qr_code_2_rounded,
                  suffix: IconButton(
                    onPressed: _openBarcodeScanner,
                    icon: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: AppColors.primary,
                    ),
                    tooltip: 'Scan Barcode with Camera',
                  ),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _batchController,
                  label: 'Batch / Lot Number',
                  hint: 'e.g. BN25-0042',
                  helperText: 'Found embossed on blister foil or carton flap',
                  prefixIcon: Icons.tag_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section 3: Manufacturer & Origin
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  stepNumber: '3',
                  title: 'Manufacturer & Country of Origin',
                  subtitle: 'Entity responsible for manufacturing and distribution',
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _manufacturerController,
                  label: 'Manufacturer Name *',
                  hint: 'e.g. Emzor Pharmaceutical Industries',
                  prefixIcon: Icons.business_outlined,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Manufacturer is required' : null,
                ),
                const SizedBox(height: 14),
                AppDropdown<String>(
                  label: 'Country of Origin',
                  value: _selectedCountry,
                  items: _countries,
                  itemLabel: (c) => c,
                  prefixIcon: Icons.public_rounded,
                  onChanged: (v) => setState(() => _selectedCountry = v!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Submit Action Button
          AppButton.primary(
            label: 'Run AI Verification Check',
            loadingLabel: 'Analyzing with AI Engine...',
            icon: Icons.search_rounded,
            height: 52,
            width: double.infinity,
            isLoading: _isLoading,
            onPressed: _submitVerification,
          ),
          const SizedBox(height: 24),

          // Disclaimer
          const DisclaimerCard(isCompact: true),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _buildSampleButtonsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, size: 16, color: AppColors.accent),
          const SizedBox(width: 6),
          Text(
            'Quick Test:',
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: _loadGenuineSample,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.genuineSurface,
                  borderRadius: AppRadius.sm,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Genuine Sample',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.genuine,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: _loadSuspiciousSample,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.suspiciousSurface,
                  borderRadius: AppRadius.sm,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Suspicious Sample',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.suspicious,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Presets Box
        AppCard(
          backgroundColor: AppColors.primarySurface,
          borderColor: AppColors.primaryBorder,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Demonstration Presets', style: AppTypography.title),
              const SizedBox(height: 4),
              Text(
                'Fill the form instantly with curated reference cases for your capstone presentation.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 14),
              AppButton.primary(
                label: 'Load Genuine Paracetamol',
                icon: Icons.check_circle_outline_rounded,
                width: double.infinity,
                onPressed: _loadGenuineSample,
              ),
              const SizedBox(height: 10),
              AppButton.danger(
                label: 'Load Suspicious Counterfeit',
                icon: Icons.warning_amber_rounded,
                width: double.infinity,
                onPressed: _loadSuspiciousSample,
              ),
              const SizedBox(height: 10),
              AppButton.outlined(
                label: 'Clear All Fields',
                icon: Icons.clear_all_rounded,
                width: double.infinity,
                onPressed: _clearForm,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Packaging Checklist Guide
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Physical Packaging Inspection', style: AppTypography.title),
              const SizedBox(height: 12),
              _buildSidebarTip(
                'NAFDAC Format',
                'Genuine numbers follow patterns such as A4-XXXX, 04-XXXX, or B4-XXXX.',
              ),
              const SizedBox(height: 10),
              _buildSidebarTip(
                'Matching Batch Numbers',
                'Verify that the batch number printed on the outer carton matches the blister foil.',
              ),
              const SizedBox(height: 10),
              _buildSidebarTip(
                'Scratch Panel (MAS)',
                'Anti-malarial products often include a scratch-and-SMS code for instant verification.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarTip(String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.label.copyWith(fontSize: 13)),
              const SizedBox(height: 2),
              Text(desc, style: AppTypography.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
