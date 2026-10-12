import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/ls_button.dart';

/// QR scanner (PRD §8.8).
///
/// Camera permission is requested only when the screen opens, and manual entry
/// is always available — a shared link should never be unreachable because a
/// camera is blocked or broken.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );

  bool _handled = false;
  String? _cameraError;
  final _manual = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _manual.dispose();
    super.dispose();
  }

  /// PRD §8.8 — validate before navigating. Only Linksy share links (and plain
  /// https URLs) are accepted; anything else is refused rather than launched.
  void _handle(String raw) {
    if (_handled) return;
    final value = raw.trim();
    if (value.isEmpty) return;

    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) {
      _reject('That is not a valid link.');
      return;
    }
    const allowed = {'https', 'http', 'linksy'};
    if (!allowed.contains(uri.scheme.toLowerCase())) {
      _reject('Linksy can only open web links.');
      return;
    }
    _handled = true;
    context.go(Routes.receive(_slugOf(uri)));
  }

  static String _slugOf(Uri uri) {
    final segments = uri.pathSegments;
    for (var i = 0; i < segments.length; i++) {
      if (segments[i] == 's' && i + 1 < segments.length) {
        return segments[i + 1];
      }
    }
    return segments.isEmpty ? uri.host : segments.last;
  }

  void _reject(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    // Let the same code be scanned again after a brief cooldown.
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _handled = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Scan a code'),
        actions: [
          LsIconButton(
            icon: Icons.flashlight_on_rounded,
            tooltip: 'Toggle torch',
            foreground: Colors.white,
            onPressed: _controller.toggleTorch,
          ),
          const SizedBox(width: Insets.sm),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _cameraError != null
                ? _CameraUnavailable(message: _cameraError!)
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      MobileScanner(
                        controller: _controller,
                        onDetect: (capture) {
                          final code = capture.barcodes.firstOrNull?.rawValue;
                          if (code != null) _handle(code);
                        },
                        errorBuilder: (context, error) => _CameraUnavailable(
                          message: switch (error.errorCode) {
                            MobileScannerErrorCode.permissionDenied =>
                              'Camera access was denied.',
                            _ => 'The camera could not be started.',
                          },
                        ),
                      ),
                      const _ScannerOverlay(),
                    ],
                  ),
          ),

          // Manual entry — always present (PRD §8.8).
          Container(
            padding: const EdgeInsets.fromLTRB(
                Insets.gutter, Insets.xl, Insets.gutter, Insets.xxl),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(Radii.xl)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Text(
                    'Or paste a link',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Insets.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manual,
                          keyboardType: TextInputType.url,
                          onSubmitted: _handle,
                          style: const TextStyle(
                              fontFamily: 'JetBrainsMono', fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'linksy.app/s/…',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: Insets.lg, vertical: Insets.md),
                          ),
                        ),
                      ),
                      const SizedBox(width: Insets.md),
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: LsButton(
                          label: 'Open',
                          expand: true,
                          onPressed: () => _handle(_manual.text),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 230,
          height: 230,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.xl),
            border: Border.all(color: AppColors.cyan, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 0,
                spreadRadius: 1000,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraUnavailable extends StatelessWidget {
  const _CameraUnavailable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Insets.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined,
                size: 40, color: Colors.white54),
            const SizedBox(height: Insets.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                height: 1.5,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: Insets.sm),
            const Text(
              'Use the link box below to open it instead.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}