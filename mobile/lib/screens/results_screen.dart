import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/drug_check_result.dart';

/// Results screen — displays verdict, confidence gauge, explanations, and recommendation.
class ResultsScreen extends StatefulWidget {
  final DrugCheckResult result;

  const ResultsScreen({super.key, required this.result});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _gaugeController;
  late AnimationController _fadeController;
  late Animation<double> _gaugeAnim;

  @override
  void initState() {
    super.initState();

    _gaugeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _gaugeAnim = Tween<double>(begin: 0, end: widget.result.confidence).animate(
      CurvedAnimation(parent: _gaugeController, curve: Curves.easeOutCubic),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Stagger animations
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _fadeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _gaugeController.forward();
    });
  }

  @override
  void dispose() {
    _gaugeController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Color get _verdictColor => widget.result.isGenuine
      ? const Color(0xFF00E676)
      : const Color(0xFFFF1744);

  Color get _verdictGlow => widget.result.isGenuine
      ? const Color(0xFF00E676).withValues(alpha: 0.3)
      : const Color(0xFFFF1744).withValues(alpha: 0.3);

  IconData get _verdictIcon => widget.result.isGenuine
      ? Icons.verified_rounded
      : Icons.warning_rounded;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D2137), Color(0xFF0A1628)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              // Verdict Card
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _fadeController,
                  curve: Curves.easeOut,
                ),
                child: _buildVerdictCard(),
              ),
              const SizedBox(height: 24),

              // Confidence Gauge
              _buildConfidenceGauge(),
              const SizedBox(height: 28),

              // Explanation Section
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _fadeController,
                  curve: const Interval(0.3, 1, curve: Curves.easeOut),
                ),
                child: _buildExplanationSection(),
              ),
              const SizedBox(height: 20),

              // Recommendation
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _fadeController,
                  curve: const Interval(0.5, 1, curve: Curves.easeOut),
                ),
                child: _buildRecommendation(),
              ),
              const SizedBox(height: 20),

              // Input summary
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _fadeController,
                  curve: const Interval(0.6, 1, curve: Curves.easeOut),
                ),
                child: _buildInputSummary(),
              ),
              const SizedBox(height: 24),

              // Check another button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Check Another Drug',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
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

  Widget _buildVerdictCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _verdictColor.withValues(alpha: 0.15),
            _verdictColor.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: _verdictColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: _verdictGlow,
            blurRadius: 40,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _verdictColor.withValues(alpha: 0.15),
            ),
            child: Icon(_verdictIcon, color: _verdictColor, size: 40),
          ),
          const SizedBox(height: 16),

          // Verdict text
          Text(
            widget.result.prediction.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _verdictColor,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.result.isGenuine
                ? 'This drug appears to be authentic'
                : 'This drug shows suspicious indicators',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceGauge() {
    return AnimatedBuilder(
      animation: _gaugeAnim,
      builder: (context, child) {
        return Column(
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: CustomPaint(
                painter: _GaugePainter(
                  progress: _gaugeAnim.value,
                  color: _verdictColor,
                ),
                child: Center(
                  child: Text(
                    '${(_gaugeAnim.value * 100).toInt()}%',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Confidence Score',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white54,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExplanationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analysis Details',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        ...widget.result.explanation.map((exp) => _buildExplanationTile(exp)),
      ],
    );
  }

  Widget _buildExplanationTile(String text) {
    final isPositive = text.startsWith('✅');
    final isWarning = text.startsWith('⚠️') || text.startsWith('🚩');
    final isInfo = text.startsWith('🔍');

    Color tileColor;
    if (isPositive) {
      tileColor = const Color(0xFF00E676);
    } else if (isWarning) {
      tileColor = const Color(0xFFFF9100);
    } else if (isInfo) {
      tileColor = const Color(0xFF448AFF);
    } else {
      tileColor = Colors.white54;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: tileColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tileColor.withValues(alpha: 0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 6, right: 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tileColor,
                  ),
                ),
                Expanded(
                  child: Text(
                    text,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF448AFF).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF448AFF).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_rounded,
                  color: Color(0xFF448AFF), size: 18),
              const SizedBox(width: 8),
              Text(
                'Recommendation',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF448AFF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.result.recommendation,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white70,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSummary() {
    if (widget.result.inputData.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Input Summary',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 12),
          ...widget.result.inputData.entries.map((entry) {
            if (entry.value.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      entry.key,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white38,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// =============================================================================
// Animated circular gauge painter
// =============================================================================

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color color;

  _GaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Background arc
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi * 0.75,
      pi * 1.5,
      false,
      bgPaint,
    );

    // Progress arc
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -pi * 0.75,
        endAngle: pi * 0.75,
        colors: [color.withValues(alpha: 0.3), color],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi * 0.75,
      pi * 1.5 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
