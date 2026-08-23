import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';
import '../widgets/app_button.dart';

/// Full-screen or modal barcode scanning experience with targeting frame.
class BarcodeScannerSheet extends StatefulWidget {
  const BarcodeScannerSheet({super.key});

  @override
  State<BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<BarcodeScannerSheet> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _hasScanned = false;
  bool _isTorchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final code = barcodes.first.rawValue!.trim();
      if (code.isNotEmpty) {
        _hasScanned = true;
        Navigator.pop(context, code);
      }
    }
  }

  void _showManualInputDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
        title: Text('Enter Barcode Manually', style: AppTypography.h3),
        content: TextField(
          controller: textController,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: AppTypography.body.copyWith(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'e.g. 6190012345670',
            labelText: 'Product Barcode (EAN-13)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          AppButton.primary(
            label: 'Use Barcode',
            onPressed: () {
              final val = textController.text.trim();
              if (val.isNotEmpty) {
                Navigator.pop(ctx);
                Navigator.pop(context, val);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'Scan Product Barcode',
          style: AppTypography.h3.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _controller.toggleTorch();
              setState(() => _isTorchOn = !_isTorchOn);
            },
            icon: Icon(
              _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: Colors.white,
            ),
            tooltip: 'Toggle Flashlight',
          ),
          IconButton(
            onPressed: () => _controller.switchCamera(),
            icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
            tooltip: 'Switch Camera',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Preview
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Dark Framing Overlay with Transparent Viewfinder
          Positioned.fill(
            child: CustomPaint(
              painter: _ScannerOverlayPainter(),
            ),
          ),

          // Central Frame Graphic
          Center(
            child: Container(
              width: 280,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: AppRadius.lg,
                border: Border.all(
                  color: AppColors.primaryLight,
                  width: 2.0,
                ),
              ),
              child: Stack(
                children: [
                  // Corner ticks
                  _buildCornerTick(Alignment.topLeft),
                  _buildCornerTick(Alignment.topRight),
                  _buildCornerTick(Alignment.bottomLeft),
                  _buildCornerTick(Alignment.bottomRight),

                  // Center Guidance
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: AppRadius.pill,
                      ),
                      child: Text(
                        'Align barcode inside box',
                        style: AppTypography.caption.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Bar & Manual Entry Fallback
          Positioned(
            bottom: 36,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Text(
                  'Locate the 13-digit EAN barcode on the packaging or blister pack.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                AppButton.outlined(
                  label: 'Enter Barcode Manually',
                  icon: Icons.keyboard_rounded,
                  onPressed: _showManualInputDialog,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerTick(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 20,
        height: 20,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border(
            top: alignment == Alignment.topLeft || alignment == Alignment.topRight
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
            bottom: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
            left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
            right: alignment == Alignment.topRight || alignment == Alignment.bottomRight
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);

    const cutoutWidth = 280.0;
    const cutoutHeight = 180.0;
    final cutoutLeft = (size.width - cutoutWidth) / 2;
    final cutoutTop = (size.height - cutoutHeight) / 2;

    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cutoutLeft, cutoutTop, cutoutWidth, cutoutHeight),
          const Radius.circular(14),
        ),
      );

    final combinedPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    canvas.drawPath(combinedPath, bgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
