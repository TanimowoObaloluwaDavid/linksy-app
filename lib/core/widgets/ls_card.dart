import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// A surface container with a hairline border. Depth comes from surface tone,
/// not shadow, so a long list of these stays calm.
class LsCard extends StatelessWidget {
  const LsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Insets.xl),
    this.onTap,
    this.accent,
    this.elevated = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// When set, tints the border — used to mark the one card that matters.
  final Color? accent;

  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(Radii.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.lg),
        splashColor: (accent ?? scheme.primary).withValues(alpha: 0.06),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.lg),
            border: Border.all(
              color: accent?.withValues(alpha: 0.42) ?? scheme.outlineVariant,
              width: accent != null ? 1.4 : 1,
            ),
            boxShadow: elevated ? Elev.low : Elev.none,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Small all-caps eyebrow that introduces a group of content.
class LsSectionHeader extends StatelessWidget {
  const LsSectionHeader({
    super.key,
    required this.label,
    this.trailing,
    this.padding = const EdgeInsets.only(bottom: Insets.md),
  });

  final String label;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Grouping wrapper that applies the standard page gutter and rhythm.
class LsSection extends StatelessWidget {
  const LsSection({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.gap = Insets.lg,
  });

  final Widget child;
  final String? title;
  final Widget? trailing;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Insets.gutter,
        Insets.xxl,
        Insets.gutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            LsSectionHeader(label: title!, trailing: trailing),
            SizedBox(height: gap),
          ],
          child,
        ],
      ),
    );
  }
}

/// Thin meter used for upload progress.
class LsProgressBar extends StatelessWidget {
  const LsProgressBar({
    super.key,
    required this.value,
    this.height = 6,
    this.color,
    this.background,
  });

  /// 0..1
  final double value;
  final double height;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Container(color: background ?? scheme.surfaceContainerHigh),
            LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth * value.clamp(0.0, 1.0);
                return AnimatedContainer(
                  duration: Motion.base,
                  curve: Curves.easeOut,
                  width: w,
                  decoration: BoxDecoration(
                    gradient: color != null
                        ? null
                        : const LinearGradient(
                            colors: [AppColors.violet, AppColors.cyan],
                          ),
                    color: color,
                    borderRadius: BorderRadius.circular(height),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Segmented control used for share-expiry choices.
class LsSegmented<T> extends StatelessWidget {
  const LsSegmented({
    super.key,
    required this.value,
    required this.options,
    required this.labelBuilder,
    required this.onChanged,
  });

  final T value;
  final List<T> options;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: options.map((o) {
          final selected = o == value;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(o),
              child: Semantics(
                selected: selected,
                button: true,
                child: AnimatedContainer(
                  duration: Motion.fast,
                  curve: Curves.easeOut,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? scheme.surfaceContainerLowest : Colors.transparent,
                    borderRadius: BorderRadius.circular(Radii.sm),
                    boxShadow: selected ? Elev.low : Elev.none,
                  ),
                  child: Text(
                    labelBuilder(o),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}