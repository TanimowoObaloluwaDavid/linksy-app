import 'package:flutter/material.dart';

import '../theme/app_typography.dart';
import '../theme/tokens.dart';
import 'ls_button.dart';

/// Shown when a list has nothing in it. Always explains *why* it is empty and
/// offers the one action that fixes it — never a shrug.
class LsEmptyState extends StatelessWidget {
  const LsEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Insets.xxxl, vertical: Insets.huge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(Radii.xl),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Icon(icon, size: 28, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: Insets.xl),
            Text(title, style: t.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: Insets.sm),
            Text(
              message,
              style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: Insets.xxl),
              LsButton(
                label: actionLabel!,
                onPressed: onAction,
                icon: Icons.add_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Failure state with a retry. The message is human-readable on purpose — no
/// raw exception text reaches the user.
class LsErrorState extends StatelessWidget {
  const LsErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Try again',
  });

  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Insets.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: scheme.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cloud_off_rounded, size: 26, color: scheme.error),
            ),
            const SizedBox(height: Insets.lg),
            Text('Something went wrong', style: t.subheading, textAlign: TextAlign.center),
            const SizedBox(height: Insets.xs),
            Text(
              message,
              style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: Insets.xl),
              LsButton(
                label: retryLabel,
                onPressed: onRetry,
                icon: Icons.refresh_rounded,
                variant: LsButtonVariant.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading placeholder. A shimmer sweep rather than a blocking spinner, so the
/// page keeps its shape while data arrives (PRD §6.2).
class LsSkeleton extends StatefulWidget {
  const LsSkeleton({
    super.key,
    required this.height,
    this.width,
    this.radius = Radii.md,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  State<LsSkeleton> createState() => _LsSkeletonState();
}

class _LsSkeletonState extends State<LsSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1250),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 - 2 * (1 - _c.value), 0),
              end: Alignment(1 + 2 * _c.value, 0),
              colors: [
                scheme.surfaceContainerHigh,
                scheme.surfaceContainerHighest,
                scheme.surfaceContainerHigh,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton list used by the transfers and shares tabs.
class LsSkeletonList extends StatelessWidget {
  const LsSkeletonList({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: Insets.md),
            child: Row(
              children: [
                const LsSkeleton(height: 42, width: 42, radius: 12),
                const SizedBox(width: Insets.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LsSkeleton(height: 13, width: 180 + (i % 3) * 40),
                      const SizedBox(height: Insets.sm),
                      const LsSkeleton(height: 11, width: 96),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}