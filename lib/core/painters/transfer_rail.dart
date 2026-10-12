import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The four states a share moves through. Order matters: the rail paints
/// progress as a function of these.
enum RailStage { select, upload, link, done }

/// [TransferRail] is Linksy's identity element.
///
/// A file transfer is data physically moving from one device to another, so
/// the app shows that movement as a literal rail: nodes for each stage, a
/// filled track for what's finished, and a travelling packet for what is
/// happening right now. It is the product's state machine drawn, not
/// decoration laid over it.
class TransferRail extends StatefulWidget {
  const TransferRail({
    super.key,
    required this.stage,
    this.progress = 0,
    this.nodeSize = 34,
    this.travellerVisible = true,
    this.reducedMotion = false,
  });

  /// Which stage is currently reached.
  final RailStage stage;

  /// 0..1 completion of the *active* stage. Values above 1 are clamped.
  final double progress;

  final double nodeSize;

  /// Whether the travelling packet is drawn.
  final bool travellerVisible;

  final bool reducedMotion;

  @override
  State<TransferRail> createState() => _TransferRailState();
}

class _TransferRailState extends State<TransferRail>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  @override
  void initState() {
    super.initState();
    if (!widget.reducedMotion) _c.repeat();
  }

  @override
  void didUpdateWidget(TransferRail old) {
    super.didUpdateWidget(old);
    if (widget.reducedMotion && _c.isAnimating) {
      _c.stop();
    } else if (!widget.reducedMotion && !_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          // Fill whatever height the parent gives us so the rail reads as a
          // spine alongside the content rather than a fixed-size decoration.
          final h = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : widget.nodeSize * 1.62 * 3 + widget.nodeSize;
          return CustomPaint(
            painter: _RailPainter(
              stage: widget.stage,
              progress: widget.progress.clamp(0.0, 1.0),
              nodeSize: widget.nodeSize,
              phase: widget.reducedMotion ? 0.35 : _c.value,
              showTraveller: widget.travellerVisible,
              isDark: Theme.of(context).brightness == Brightness.dark,
              height: h,
            ),
            size: Size(widget.nodeSize, h),
          );
        },
      ),
    );
  }
}

class _RailPainter extends CustomPainter {
  _RailPainter({
    required this.stage,
    required this.progress,
    required this.nodeSize,
    required this.phase,
    required this.showTraveller,
    required this.isDark,
    required this.height,
  });

  final RailStage stage;
  final double progress;
  final double nodeSize;
  final double phase;
  final bool showTraveller;
  final bool isDark;
  final double height;

  static const _stages = RailStage.values;

  Color get _idle => isDark ? AppColors.hairlineStrong : AppColors.hairlineStrongLight;

  @override
  void paint(Canvas canvas, Size size) {
    final r = nodeSize / 2;
    final top = r;
    final bottom = height - r;
    final lastIndex = (_stages.length - 1).toDouble();
    // Spread the nodes evenly through whatever height we were given, so the
    // rail reads as a spine alongside the content instead of a fixed ornament.
    final step = lastIndex <= 0 ? 0.0 : (bottom - top) / lastIndex;
    final cx = size.width / 2;

    // How far the rail is "filled": completed stages fully, the active stage
    // partially according to progress.
    final activeIndex = _stages.indexOf(stage).toDouble();
    final fillFraction = activeIndex + progress;
    final fillY = top + step * fillFraction.clamp(0.0, _stages.length - 1.0);

    // ---- Track ----
    final track = Paint()
      ..color = _idle
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx, top), Offset(cx, bottom), track);

    // ---- Filled track: violet (intent) bleeding into cyan (in transit) ----
    if (fillY > top) {
      final fill = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.violet, AppColors.cyan],
        ).createShader(Rect.fromLTRB(cx - 2, top, cx + 2, bottom))
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(cx, top), Offset(cx, fillY), fill);
    }

    // ---- Travelling packet along the active segment ----
    if (showTraveller && stage != RailStage.done) {
      final startY = top + step * activeIndex;
      final endY = startY + step;
      final span = (endY - startY).clamp(0.0, double.infinity);
      // Ping-pong between the start of the active segment and the current
      // progress mark, so the packet always reads as "heading there".
      final reach = math.max(0.06, progress);
      final y = startY + span * (reach * (0.5 - 0.5 * math.cos(phase * 2 * math.pi)));
      final glow = Paint()..color = AppColors.cyan.withValues(alpha: 0.18);
      canvas.drawCircle(Offset(cx, y), 9, glow);
      final dot = Paint()..color = AppColors.cyan;
      canvas.drawCircle(Offset(cx, y), 3.2, dot);
    }

    // ---- Nodes ----
    for (var i = 0; i < _stages.length; i++) {
      final y = top + step * i;
      _paintNode(canvas, Offset(cx, y), r, i, activeIndex);
    }
  }

  void _paintNode(Canvas canvas, Offset c, double r, int index, double active) {
    final reached = index <= active;

    if (reached) {
      // Glow behind reached nodes — subtle, sells depth without a shadow.
      canvas.drawCircle(c, r + 7, Paint()..color = AppColors.violet.withValues(alpha: 0.13));
      final isCurrent = index == active;
      final core = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCurrent
              ? [AppColors.violet, AppColors.cyan]
              : [AppColors.violet, AppColors.violetDeep],
        ).createShader(Rect.fromCircle(center: c, radius: r));
      canvas.drawCircle(c, r - 3, core);
      _paintGlyph(canvas, c, r - 3, index, filled: true);
      return;
    }

    // Pending: hollow node with a faint ring.
    final ring = Paint()
      ..color = _idle
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(c, r - 4, ring);
    canvas.drawCircle(c, r - 11, Paint()..color = _idle.withValues(alpha: 0.35));
  }

  /// Drawn glyphs rather than emoji so the rail stays crisp at any size and
  /// matches the icon language used everywhere else.
  void _paintGlyph(Canvas canvas, Offset c, double radius, int index,
      {required bool filled}) {
    final p = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final f = Paint()..color = Colors.white;
    final u = radius * 0.42; // unit half-extent

    switch (_stages[index]) {
      case RailStage.select:
        // Document with a folded corner.
        final path = Path()
          ..moveTo(c.dx - u, c.dy - u)
          ..lineTo(c.dx + u * 0.35, c.dy - u)
          ..lineTo(c.dx + u, c.dy - u * 0.35)
          ..lineTo(c.dx + u, c.dy + u)
          ..lineTo(c.dx - u, c.dy + u)
          ..close();
        if (filled) {
          canvas.drawPath(path, f);
        } else {
          canvas.drawPath(path, p);
        }

      case RailStage.upload:
        // Upward arrow.
        final path = Path()
          ..moveTo(c.dx, c.dy + u * 0.6)
          ..lineTo(c.dx, c.dy - u * 0.7)
          ..moveTo(c.dx - u * 0.65, c.dy - u * 0.05)
          ..lineTo(c.dx, c.dy - u * 0.8)
          ..lineTo(c.dx + u * 0.65, c.dy - u * 0.05);
        canvas.drawPath(path, p);

      case RailStage.link:
        // Two interlocking link arcs.
        final path = Path()
          ..addArc(Rect.fromCircle(center: c.translate(-u * 0.45, 0), radius: u * 0.62),
              -math.pi / 2, math.pi)
          ..moveTo(c.dx + u * 0.45, c.dy - u * 0.62)
          ..addArc(Rect.fromCircle(center: c.translate(u * 0.45, 0), radius: u * 0.62),
              math.pi / 2, math.pi);
        canvas.drawPath(path, p);

      case RailStage.done:
        // Check.
        final path = Path()
          ..moveTo(c.dx - u * 0.7, c.dy)
          ..lineTo(c.dx - u * 0.15, c.dy + u * 0.55)
          ..lineTo(c.dx + u * 0.75, c.dy - u * 0.6);
        canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_RailPainter old) =>
      old.stage != stage ||
      old.progress != progress ||
      old.phase != phase ||
      old.showTraveller != showTraveller ||
      old.isDark != isDark;
}