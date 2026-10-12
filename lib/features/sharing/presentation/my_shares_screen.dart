import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/ls_button.dart';
import '../../../core/widgets/ls_card.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/status_badge.dart';
import '../domain/share.dart';
import 'share_draft_controller.dart';

enum _Filter { all, active, expired, revoked }

/// My Shares (PRD §8.11).
class MySharesScreen extends ConsumerStatefulWidget {
  const MySharesScreen({super.key});

  @override
  ConsumerState<MySharesScreen> createState() => _MySharesScreenState();
}

class _MySharesScreenState extends ConsumerState<MySharesScreen> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shares = ref.watch(sharesProvider);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('My Shares'),
        actions: [
          LsIconButton(
            icon: Icons.add_rounded,
            tooltip: 'New share',
            onPressed: () => context.go('${Routes.home}/send'),
          ),
          const SizedBox(width: Insets.sm),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(shareActionsProvider).refresh(),
        child: shares.when(
          loading: () => const Padding(
            padding: EdgeInsets.fromLTRB(
                Insets.gutter, Insets.lg, Insets.gutter, 0),
            child: LsSkeletonList(count: 5),
          ),
          error: (_, __) => ListView(
            children: [
              const SizedBox(height: 60),
              LsErrorState(
                message: 'Could not load your shares.',
                onRetry: () => ref.invalidate(sharesProvider),
              ),
            ],
          ),
          data: (all) {
            final list = all
                .where((s) => switch (_filter) {
                      _Filter.all => true,
                      _Filter.active =>
                        s.effectiveStatus(now) == ShareStatus.active,
                      _Filter.expired =>
                        s.effectiveStatus(now) == ShareStatus.expired,
                      _Filter.revoked =>
                        s.effectiveStatus(now) == ShareStatus.revoked,
                    })
                .toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        Insets.gutter, 0, Insets.gutter, Insets.lg),
                    child: LsSegmented<_Filter>(
                      value: _filter,
                      options: _Filter.values,
                      labelBuilder: (f) => switch (f) {
                        _Filter.all => 'All',
                        _Filter.active => 'Active',
                        _Filter.expired => 'Expired',
                        _Filter.revoked => 'Revoked',
                      },
                      onChanged: (f) => setState(() => _filter = f),
                    ),
                  ),
                ),
                if (list.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: LsEmptyState(
                      icon: Icons.link_rounded,
                      title: all.isEmpty
                          ? 'No shares yet'
                          : 'Nothing ${_filter.name}',
                      message: all.isEmpty
                          ? 'Create a share and it will appear here with its link, '
                              'QR code and expiry.'
                          : 'Try a different filter.',
                      actionLabel: all.isEmpty ? 'Send files' : null,
                      onAction: all.isEmpty
                          ? () => context.go('${Routes.home}/send')
                          : null,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        Insets.gutter, 0, Insets.gutter, Insets.huge),
                    sliver: SliverList.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: Insets.sm),
                      itemBuilder: (context, i) => _ShareCard(
                        share: list[i],
                        now: now,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('${Routes.home}/send'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New share'),
      ),
    );
  }
}

class _ShareCard extends ConsumerWidget {
  const _ShareCard({required this.share, required this.now});

  final Share share;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final effective = share.effectiveStatus(now);

    final (Color color, IconData icon) = switch (effective) {
      ShareStatus.active => (AppColors.success, Icons.check_circle_rounded),
      ShareStatus.uploading => (AppColors.cyan, Icons.cloud_upload_rounded),
      ShareStatus.expired => (scheme.onSurfaceVariant, Icons.schedule_rounded),
      ShareStatus.revoked => (scheme.error, Icons.block_rounded),
    };

    return LsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  share.title,
                  style: t.subheading,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: Insets.sm),
              StatusBadge(label: effective.label, color: color, icon: icon, dense: true),
            ],
          ),
          const SizedBox(height: Insets.xs),
          Text(
            share.url,
            style: AppType.monoSmall.copyWith(color: scheme.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: Insets.md),
          Row(
            children: [
              _Stat(
                label: 'files',
                value: '${share.fileCount}',
              ),
              const SizedBox(width: Insets.xl),
              _Stat(label: 'size', value: Fmt.bytes(share.totalBytes)),
              const SizedBox(width: Insets.xl),
              _Stat(label: 'opened', value: '${share.downloadCount}'),
              const Spacer(),
              Text(
                Fmt.remaining(share.expiresAt, now) ??
                    'closed ${Fmt.ago(share.expiresAt, now)}',
                style: AppType.monoTiny.copyWith(
                  color: effective.isAccessible
                      ? scheme.onSurfaceVariant
                      : scheme.error,
                ),
              ),
            ],
          ),
          if (effective == ShareStatus.active) ...[
            const SizedBox(height: Insets.md),
            const Divider(height: 1),
            const SizedBox(height: Insets.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push(Routes.receive(share.slug)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 42),
                    ),
                    child: const Text('Preview'),
                  ),
                ),
                const SizedBox(width: Insets.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmRevoke(context, ref),
                    icon: Icon(Icons.link_off_rounded, size: 17, color: scheme.error),
                    label: Text('Revoke', style: TextStyle(color: scheme.error)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 42),
                      side: BorderSide(color: scheme.error.withValues(alpha: 0.4)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmRevoke(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke access?'),
        content: Text(
          'The link stops working immediately. Anyone who already downloaded a '
          'copy still has it — that part cannot be undone.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Revoke',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(shareActionsProvider).revoke(share.id);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppType.monoValue.copyWith(color: scheme.onSurface),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            height: 1.3,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}