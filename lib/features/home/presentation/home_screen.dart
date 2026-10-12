import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app.dart';
import '../../../app/router.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/ls_button.dart';
import '../../../core/widgets/ls_card.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../sharing/domain/share.dart';
import '../../sharing/presentation/share_draft_controller.dart';

/// The workspace (PRD §8.3).
///
/// Deliberately action-first: the Send and Scan actions sit above the fold and
/// everything else is reporting on them, not competing with them.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final auth = ref.watch(authProvider);
    final now = DateTime.now();

    return LsScaffold(
      showBack: false,
      title: null,
      actions: [
        LsIconButton(
          icon: Icons.settings_outlined,
          tooltip: 'Settings',
          onPressed: () => context.push(Routes.settings),
        ),
        const SizedBox(width: Insets.sm),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Greeting(name: auth.user?.displayName ?? 'there', now: now),
          const SizedBox(height: Insets.xxl),

          // ------------------------------------------------ primary actions
          _SendHero(),
          const SizedBox(height: Insets.md),
          _ScanRow(),
          const SizedBox(height: Insets.xxxl),

          // ------------------------------------------------ storage
          const _UsageCard(),
          const SizedBox(height: Insets.xxxl),

          // ------------------------------------------------ active transfers
          const _ActiveTransfers(),
          const SizedBox(height: Insets.xxxl),

          // ------------------------------------------------ recent shares
          _RecentShares(now: now),

          const SizedBox(height: Insets.xl),
          Text(
            'Everything above stays private until you share it.',
            textAlign: TextAlign.center,
            style: t.caption.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: Insets.xxl),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name, required this.now});

  final String name;
  final DateTime now;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final first = name.split(' ').first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_days[now.weekday - 1]}, ${_months[now.month - 1]} ${now.day}',
          style: AppType.overline.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: Insets.sm),
        Text(
          _partOfDay(now) == 'morning' ? 'Good morning, $first' : 'Good ${_partOfDay(now)}, $first',
          style: t.headlineLarge,
        ),
      ],
    );
  }

  static String _partOfDay(DateTime d) {
    if (d.hour < 12) return 'morning';
    if (d.hour < 18) return 'afternoon';
    return 'evening';
  }
}

/// The hero action.
///
/// Not a floating action button and not a plain card: the primary thing a user
/// came to do gets a full-width, unmistakably-tappable surface, and the scan
/// action sits directly beneath it as the obvious counterpart.
class _SendHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Send files. Choose files and create a share link.',
      child: Material(
        borderRadius: BorderRadius.circular(Radii.xl),
        clipBehavior: Clip.antiAlias,
        color: scheme.primary,
        child: InkWell(
          onTap: () => context.go('${Routes.home}/send'),
          splashColor: Colors.white.withValues(alpha: 0.08),
          child: Ink(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.violet, AppColors.violetDeep],
              ),
            ),
            child: Stack(
              children: [
                // Decorative but structural: a soft arc echoing the brand mark,
                // anchored off the right edge so it reads as texture, not an icon.
                Positioned(
                  right: -46,
                  top: -34,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                        width: 22,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(Insets.xxl),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(Radii.lg),
                        ),
                        child: const Icon(
                          Icons.north_east_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: Insets.xl),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Send files',
                              style: TextStyle(
                                fontFamily: 'SpaceGrotesk',
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                                letterSpacing: -0.4,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Get a link or QR code',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13.5,
                                height: 1.3,
                                color: Colors.white.withValues(alpha: 0.78),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 22),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return LsCard(
      onTap: () => context.push(Routes.scan),
      padding: const EdgeInsets.all(Insets.lg),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: const Icon(Icons.qr_code_scanner_rounded,
                size: 21, color: AppColors.cyan),
          ),
          const SizedBox(width: Insets.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Receive', style: t.titleMedium),
                const SizedBox(height: 1),
                Text(
                  'Scan a QR code or open a link',
                  style: t.caption.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _UsageCard extends ConsumerWidget {
  const _UsageCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final usage = ref.watch(usageProvider);

    return usage.when(
      loading: () => const LsSkeleton(height: 108, radius: Radii.lg),
      error: (_, __) => const SizedBox.shrink(),
      data: (u) {
        final nearLimit = u.fraction > 0.8;
        return LsCard(
          onTap: () => context.push(Routes.settings),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('STORAGE', style: t.labelSmall),
                  ),
                  StatusBadge(
                    label: 'Free plan',
                    color: scheme.primary,
                    icon: Icons.star_rounded,
                    dense: true,
                  ),
                ],
              ),
              const SizedBox(height: Insets.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(Fmt.bytes(u.usedBytes), style: AppType.monoLarge),
                  const SizedBox(width: 6),
                  Text(
                    'of ${Fmt.bytes(u.quotaBytes)}',
                    style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  Text(
                    '${(u.fraction * 100).toStringAsFixed(0)}%',
                    style: AppType.monoValue.copyWith(
                      color: nearLimit ? scheme.error : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Insets.md),
              LsProgressBar(
                value: u.fraction,
                color: nearLimit ? scheme.error : null,
              ),
              const SizedBox(height: Insets.md),
              Text(
                '${Fmt.plural(u.activeShares, 'active share')} · '
                '${Fmt.plural(u.shareLimit - u.activeShares, 'slot')} remaining',
                style: t.caption.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActiveTransfers extends ConsumerWidget {
  const _ActiveTransfers();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(shareDraftProvider);

    // Only surface the workflow while it is actually running — a finished or
    // cancelled upload does not belong on the dashboard.
    final showDraft = draft.isBusy && draft.files.isNotEmpty;
    if (!showDraft) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LsSectionHeader(label: 'In progress'),
        LsCard(
          accent: AppColors.cyan,
          onTap: () => context.push(Routes.upload),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: Insets.md),
                  Expanded(
                    child: Text(
                      'Uploading ${Fmt.plural(draft.files.length, 'file')}',
                      style: t.titleMedium,
                    ),
                  ),
                  Text(
                    '${(draft.progress * 100).toStringAsFixed(0)}%',
                    style: AppType.monoValue,
                  ),
                ],
              ),
              const SizedBox(height: Insets.md),
              LsProgressBar(value: draft.progress),
              const SizedBox(height: Insets.md),
              Text(
                '${Fmt.bytes(draft.sentBytes)} of ${Fmt.bytes(draft.totalBytes)} · tap to manage',
                style: t.caption.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentShares extends ConsumerWidget {
  const _RecentShares({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final shares = ref.watch(sharesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LsSectionHeader(
          label: 'Recent shares',
          trailing: TextButton(
            onPressed: () => context.go(Routes.shares),
            child: const Text('See all'),
          ),
        ),
        shares.when(
          loading: () => const LsSkeletonList(count: 3),
          error: (_, __) => LsErrorState(
            message: 'Could not load your shares.',
            onRetry: () => ref.invalidate(sharesProvider),
          ),
          data: (list) {
            if (list.isEmpty) {
              return LsCard(
                padding: const EdgeInsets.all(Insets.xxl),
                child: Column(
                  children: [
                    Icon(Icons.inbox_rounded,
                        size: 26, color: scheme.onSurfaceVariant),
                    const SizedBox(height: Insets.md),
                    Text('Nothing shared yet', style: t.titleMedium),
                    const SizedBox(height: Insets.xs),
                    Text(
                      'Your first share is two taps away.',
                      style: t.caption.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: [
                for (final s in list.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: Insets.sm),
                    child: _ShareRow(share: s, now: now),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ShareRow extends ConsumerWidget {
  const _ShareRow({required this.share, required this.now});

  final Share share;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final effective = share.effectiveStatus(now);

    final (Color color, IconData icon) = switch (effective) {
      ShareStatus.active => (AppColors.success, Icons.check_rounded),
      ShareStatus.uploading => (AppColors.cyan, Icons.north_east_rounded),
      ShareStatus.expired => (scheme.onSurfaceVariant, Icons.schedule_rounded),
      ShareStatus.revoked => (scheme.error, Icons.block_rounded),
    };

    return LsCard(
      padding: const EdgeInsets.all(Insets.lg),
      onTap: () => context.go(Routes.shares),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Fmt.ellipsizeMiddle(share.title, 34),
                  style: t.bodyStrong,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${Fmt.plural(share.fileCount, 'file')} · ${Fmt.bytes(share.totalBytes)} · ${Fmt.ago(share.createdAt, now)}',
                  style: t.caption.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: Insets.sm),
          effective == ShareStatus.active && !share.isExpiredAt(now)
              ? Text(
                  Fmt.remaining(share.expiresAt, now) ?? '',
                  style: AppType.monoTiny.copyWith(color: scheme.onSurfaceVariant),
                )
              : StatusBadge(
                  label: effective.label,
                  color: color,
                  icon: icon,
                  dense: true,
                ),
        ],
      ),
    );
  }
}