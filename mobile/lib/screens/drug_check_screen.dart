import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../services/history_service.dart';

/// Drug check form screen with input fields and barcode scanner.
class DrugCheckScreen extends StatefulWidget {
  const DrugCheckScreen({super.key});

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
    'Tablet', 'Capsule', 'Syrup', 'Suspension', 'Injection',
    'Cream', 'Ointment', 'Drops', 'Powder', 'Sachet',
  ];

  static const _countries = [
    'Nigeria', 'China', 'India', 'Ghana', 'Pakistan',
    'South Africa', 'Kenya', 'United Kingdom', 'United States', 'Unknown',
  ];

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
    _drugNameController.text = 'Paracetamol';
    _manufacturerController.text = 'Emzor Pharmaceutical Industries';
    _nafdacController.text = 'A4-7823';
    _barcodeController.text = '6190012345670';
    _batchController.text = 'BN25-0042';
    _strengthController.text = '500mg';
    setState(() {
      _selectedDosageForm = 'Tablet';
      _selectedCountry = 'Nigeria';
    });
  }

  void _loadSuspiciousSample() {
    _drugNameController.text = 'Super Paracetmol';
    _manufacturerController.text = 'QuickCure Labs';
    _nafdacController.text = 'INVALID123';
    _barcodeController.text = '12345';
    _batchController.text = '???';
    _strengthController.text = '500mg';
    setState(() {
      _selectedDosageForm = 'Tablet';
      _selectedCountry = 'China';
    });
  }

  void _clearForm() {
    _drugNameController.clear();
    _manufacturerController.clear();
    _nafdacController.clear();
    _barcodeController.clear();
    _batchController.clear();
    _strengthController.clear();
    setState(() {
      _selectedDosageForm = 'Tablet';
      _selectedCountry = 'Nigeria';
    });
  }

  Future<void> _openBarcodeScanner() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const _BarcodeScannerPage(),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _barcodeController.text = result;
      });
    }
  }

  Future<void> _submitCheck() async {
    if (!_formKey.currentState!.validate()) return;

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

      // Save to history
      await historyService.saveResult(result);

      if (mounted) {
        Navigator.pushNamed(context, '/results', arguments: result);
      }
    } on ApiException catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.message);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('An unexpected error occurred. Please try again.');
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
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: GoogleFonts.inter(fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFF1744),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check Drug'),
        actions: [
          IconButton(
            onPressed: _clearForm,
            icon: const Icon(Icons.clear_all_rounded, size: 22),
            tooltip: 'Clear form',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D2137), Color(0xFF0A1628)],
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: [
              // Quick fill buttons
              Row(
                children: [
                  Expanded(
                    child: _SampleButton(
                      label: '✅ Genuine Sample',
                      color: const Color(0xFF00E676),
                      onTap: _loadGenuineSample,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SampleButton(
                      label: '⚠️ Suspicious Sample',
                      color: const Color(0xFFFF9100),
                      onTap: _loadSuspiciousSample,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Drug Name
              _buildTextField(
                controller: _drugNameController,
                label: 'Drug Name',
                hint: 'e.g. Paracetamol',
                icon: Icons.medication_rounded,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              // Manufacturer
              _buildTextField(
                controller: _manufacturerController,
                label: 'Manufacturer',
                hint: 'e.g. Emzor Pharmaceutical Industries',
                icon: Icons.business_rounded,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              // NAFDAC Number
              _buildTextField(
                controller: _nafdacController,
                label: 'NAFDAC Number',
                hint: 'e.g. A4-7823',
                icon: Icons.verified_rounded,
              ),
              const SizedBox(height: 14),

              // Barcode with scanner button
              _buildTextField(
                controller: _barcodeController,
                label: 'Barcode',
                hint: 'e.g. 6190012345670',
                icon: Icons.qr_code_rounded,
                keyboardType: TextInputType.number,
                suffixIcon: IconButton(
                  onPressed: _openBarcodeScanner,
                  icon: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Color(0xFF448AFF),
                  ),
                  tooltip: 'Scan barcode',
                ),
              ),
              const SizedBox(height: 14),

              // Batch Number
              _buildTextField(
                controller: _batchController,
                label: 'Batch Number',
                hint: 'e.g. BN25-0042',
                icon: Icons.tag_rounded,
              ),
              const SizedBox(height: 14),

              // Dosage Form dropdown
              _buildDropdown(
                label: 'Dosage Form',
                value: _selectedDosageForm,
                items: _dosageForms,
                icon: Icons.local_pharmacy_rounded,
                onChanged: (v) => setState(() => _selectedDosageForm = v!),
              ),
              const SizedBox(height: 14),

              // Strength
              _buildTextField(
                controller: _strengthController,
                label: 'Strength',
                hint: 'e.g. 500mg',
                icon: Icons.science_rounded,
              ),
              const SizedBox(height: 14),

              // Country dropdown
              _buildDropdown(
                label: 'Country of Origin',
                value: _selectedCountry,
                items: _countries,
                icon: Icons.flag_rounded,
                onChanged: (v) => setState(() => _selectedCountry = v!),
              ),
              const SizedBox(height: 28),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitCheck,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF448AFF),
                    disabledBackgroundColor: const Color(0xFF448AFF).withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 8,
                    shadowColor: const Color(0xFF448AFF).withValues(alpha: 0.4),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_rounded, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Check Drug',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
      dropdownColor: const Color(0xFF1A2E4A),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
    );
  }
}

// =============================================================================
// Sample fill button widget
// =============================================================================

class _SampleButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SampleButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Barcode scanner page (using mobile_scanner)
// =============================================================================

class _BarcodeScannerPage extends StatefulWidget {
  const _BarcodeScannerPage();

  @override
  State<_BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<_BarcodeScannerPage> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _hasScanned = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: () => _scannerController.toggleTorch(),
            icon: const Icon(Icons.flash_on_rounded),
            tooltip: 'Toggle flashlight',
          ),
          IconButton(
            onPressed: () => _scannerController.switchCamera(),
            icon: const Icon(Icons.cameraswitch_rounded),
            tooltip: 'Switch camera',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              if (_hasScanned) return;
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                _hasScanned = true;
                Navigator.pop(context, barcodes.first.rawValue);
              }
            },
          ),
          // Scan overlay
          Center(
            child: Container(
              width: 260,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF448AFF), width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          // Instruction text
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Point camera at the barcode',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
