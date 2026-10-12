import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

enum LsButtonVariant { primary, secondary, ghost, danger }

/// Linksy's button.
///
/// One widget rather than three Material buttons so padding, radius, minimum
/// height (52 — comfortably above the 48dp accessibility floor) and press
/// feedback stay identical everywhere.
class LsButton extends StatefulWidget {
  const LsButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = LsButtonVariant.primary,
    this.icon,
    this.trailingIcon,
    this.expand = false,
    this.busy = false,
    this.tooltip,
  });

  final String label;
  final VoidCallback? onPressed;
  final LsButtonVariant variant;
  final IconData? icon;
  final IconData? trailingIcon;

  /// Stretch to the full width of the parent.
  final bool expand;

  /// Shows a spinner and blocks input while work is in flight.
  final bool busy;

  final String? tooltip;

  bool get _enabled => onPressed != null && !busy;

  @override
  State<LsButton> createState() => _LsButtonState();
}

class _LsButtonState extends State<LsButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final (Color bg, Color fg, Color? border, Gradient? gradient) =
        switch (widget.variant) {
      LsButtonVariant.primary => (
          scheme.primary,
          scheme.onPrimary,
          null,
          AppTheme.brandGradient,
        ),
      LsButtonVariant.secondary => (
          Colors.transparent,
          scheme.onSurface,
          scheme.outline,
          null,
        ),
      LsButtonVariant.ghost => (
          Colors.transparent,
          scheme.primary,
          null,
          null,
        ),
      LsButtonVariant.danger => (
          scheme.error.withValues(alpha: 0.12),
          scheme.error,
          scheme.error.withValues(alpha: 0.4),
          null,
        ),
    };

    final child = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.busy)
          SizedBox.square(
            dimension: 17,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: fg,
            ),
          )
        else if (widget.icon != null)
          Icon(widget.icon, size: 19, color: fg),
        if (widget.icon != null || widget.busy) const SizedBox(width: Insets.sm),
        Flexible(
          child: Text(
            widget.label,
            style: t.titleMedium?.copyWith(color: fg),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        if (widget.trailingIcon != null) ...[
          const SizedBox(width: Insets.sm),
          Icon(widget.trailingIcon, size: 19, color: fg),
        ],
      ],
    );

    final button = Semantics(
      button: true,
      enabled: widget._enabled,
      label: widget.tooltip ?? widget.label,
      child: GestureDetector(
        onTapDown: widget._enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: widget._enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: widget._enabled ? () => setState(() => _down = false) : null,
        child: AnimatedScale(
          scale: _down ? 0.975 : 1,
          duration: Motion.fast,
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: widget._enabled ? 1 : 0.42,
            duration: Motion.fast,
            child: Container(
              height: 52,
              padding: EdgeInsets.symmetric(horizontal: widget.expand ? Insets.lg : Insets.xxl),
              decoration: BoxDecoration(
                color: widget._enabled ? bg : scheme.surfaceContainerHigh,
                gradient: widget._enabled ? gradient : null,
                borderRadius: BorderRadius.circular(Radii.md),
                border: border != null && widget._enabled
                    ? Border.all(color: border)
                    : null,
              ),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );

    return widget.expand
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}

/// Square icon button used in app bars and dense rows. Always carries a
/// tooltip because there is no visible label.
class LsIconButton extends StatelessWidget {
  const LsIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.foreground,
    this.background,
    this.size = 40,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? foreground;
  final Color? background;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: background ?? Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(Radii.sm),
            child: SizedBox.square(
              dimension: size,
              child: Icon(
                icon,
                size: size * 0.5,
                color: foreground ?? scheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}