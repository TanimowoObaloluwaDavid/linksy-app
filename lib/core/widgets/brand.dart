import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The Linksy mark.
///
/// Drawn rather than imported so it stays crisp from 16px in the app bar to a
/// 512px store icon, and so it can carry the product's one idea: two chain
/// arcs (two parties) with a packet travelling between them.
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 36,
    this.showPacket = true,
  });

  final double size;
  final bool showPacket;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _BrandPainter(showPacket: showPacket),
      ),
    );
  }
}

class _BrandPainter extends CustomPainter {
  const _BrandPainter({required this.showPacket});

  final bool showPacket;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final inset = w * 0.17;
    final r = Rect.fromLTWH(inset, inset, w - inset * 2, h - inset * 2);
    final rad = Radius.circular(w * 0.30);

    // Rounded-square container so the mark reads on any background.
    final plate = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.violet, AppColors.violetDeep],
      ).createShader(r);
    canvas.drawRRect(RRect.fromRectAndRadius(r, rad), plate);

    // A single continuous stroke: an open link with a tail, suggesting a path
    // from one party to another.
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.105
      ..strokeCap = StrokeCap.round;

    final cx = w / 2;
    final cy = h / 2;
    final unit = w * 0.21;

    final arcR = unit * 0.82;
    final path = Path()
      // left arc, open to the right
      ..addArc(
        Rect.fromCircle(center: Offset(cx - unit * 0.48, cy), radius: arcR),
        math.pi * 0.42,
        math.pi * 1.16,
      )
      // right arc, open to the left
      ..addArc(
        Rect.fromCircle(center: Offset(cx + unit * 0.48, cy), radius: arcR),
        math.pi * 1.42,
        math.pi * 1.16,
      )
      // connecting tail
      ..moveTo(cx - unit * 0.9, cy + unit * 0.34)
      ..lineTo(cx + unit * 0.9, cy - unit * 0.34);

    canvas.drawPath(path, stroke);

    // Packet: the cyan dot that represents content in motion.
    if (showPacket) {
      const t = 0.34;
      final p = Offset(
        cx - unit * 0.9 + (unit * 1.8) * t,
        cy + unit * 0.34 - (unit * 0.68) * t,
      );
      canvas.drawCircle(p, w * 0.075, Paint()..color = AppColors.cyan);
      canvas.drawCircle(
        p,
        w * 0.13,
        Paint()..color = AppColors.cyan.withValues(alpha: 0.28),
      );
    }
  }

  @override
  bool shouldRepaint(_BrandPainter old) =>
      old.showPacket != showPacket;
}

/// Wordmark: mark + name, locked up so it never reflows awkwardly.
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, this.markSize = 30, this.showText = true});

  final double markSize;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: markSize),
        if (showText) ...[
          const SizedBox(width: Insets.md),
          Text(
            'Linksy',
            style: t.titleLarge?.copyWith(letterSpacing: -0.6),
          ),
        ],
      ],
    );
  }
}