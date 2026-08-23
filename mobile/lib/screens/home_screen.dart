import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';

/// Home screen — landing page with hero section and feature cards.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _apiHealthy = false;
  bool _checkingHealth = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animController.forward();
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

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D2137), Color(0xFF0A1628)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Header row
                _buildHeader(),
                const SizedBox(height: 32),

                // Hero Section
                _buildHeroCard(),
                const SizedBox(height: 24),

                // API status indicator
                _buildStatusIndicator(),
                const SizedBox(height: 28),

                // Feature cards
                Text(
                  'How It Works',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                _buildFeatureCard(
                  icon: Icons.edit_note_rounded,
                  title: 'Enter Drug Details',
                  description: 'Input the drug name, manufacturer, NAFDAC number, barcode, and other details.',
                  color: const Color(0xFF448AFF),
                ),
                const SizedBox(height: 12),
                _buildFeatureCard(
                  icon: Icons.qr_code_scanner_rounded,
                  title: 'Scan Barcode',
                  description: 'Use your camera to scan the barcode on the drug package for quick input.',
                  color: const Color(0xFF7C4DFF),
                ),
                const SizedBox(height: 12),
                _buildFeatureCard(
                  icon: Icons.analytics_rounded,
                  title: 'AI Analysis',
                  description: 'Our ML model analyzes patterns and flags suspicious drugs with detailed explanations.',
                  color: const Color(0xFF00E676),
                ),
                const SizedBox(height: 12),
                _buildFeatureCard(
                  icon: Icons.history_rounded,
                  title: 'Track History',
                  description: 'All your past drug checks are saved locally for quick reference.',
                  color: const Color(0xFFFF9100),
                ),

                const SizedBox(height: 32),

                // Disclaimer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.amber, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This tool is for educational and research purposes. '
                          'Always verify drugs with NAFDAC and consult a licensed pharmacist.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.amber.shade200,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF448AFF), Color(0xFF00E676)],
                ),
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'FakeDrugChecker',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: () => Navigator.pushNamed(context, '/history'),
          icon: const Icon(Icons.history_rounded, color: Colors.white70),
          tooltip: 'History',
        ),
      ],
    );
  }

  Widget _buildHeroCard() {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _animController, curve: Curves.easeOut),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A3A5C), Color(0xFF162240)],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF448AFF).withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF448AFF).withValues(alpha: 0.15),
              ),
              child: const Icon(
                Icons.medication_rounded,
                size: 40,
                color: Color(0xFF448AFF),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Verify Your Medicine',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check if a drug is genuine or suspicious using AI-powered analysis',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/check'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF448AFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 8,
                  shadowColor: const Color(0xFF448AFF).withValues(alpha: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_rounded, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Check a Drug',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    Color color;
    String text;
    IconData icon;

    if (_checkingHealth) {
      color = Colors.amber;
      text = 'Checking server...';
      icon = Icons.sync_rounded;
    } else if (_apiHealthy) {
      color = const Color(0xFF00E676);
      text = 'Server online — Model ready';
      icon = Icons.check_circle_rounded;
    } else {
      color = const Color(0xFFFF1744);
      text = 'Server offline — Check connection';
      icon = Icons.error_outline_rounded;
    }

    return GestureDetector(
      onTap: () {
        setState(() => _checkingHealth = true);
        _checkApiHealth();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_checkingHealth)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              )
            else
              Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white54,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
