import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/ls_card.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/status_badge.dart';
import '../../sharing/presentation/share_draft_controller.dart';
import '../domain/transfer.dart';

enum _Tab { all, sent, received, failed }

/// Transfer history (PRD §8.10).
class TransfersScreen extends ConsumerStatefulWidget {
  const TransfersScreen({super.key});

  @override
  ConsumerState<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends ConsumerState<TransfersScreen> {
  _Tab _tab = _Tab.all;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final transfers = ref.watch(transfersProvider);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Transfers'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(shareActionsProvider).refresh(),
        child: transfers.when(
          loading: () => const Padding(
            padding:
                EdgeInsets.fromLTRB(Insets.gutter, Insets.lg, Insets.gutter, 0),
            child: LsSkeletonList(count: 5),
          ),
          error: (_, __) => ListView(children: const [
            SizedBox(height: 60),
            LsErrorState(message: 'Could not load your transfers.'),
          ]),
          data: (all) {
            final list = all.where((t) => switch (_tab) {
                  _Tab.all => true,
                  _Tab.sent => t.direction == TransferDirection.sent,
                  _Tab.received => t.direction == TransferDirection.received,
                  _Tab.failed =>
                    t.status == TransferStatus.failed ||
                        t.status == TransferStatus.cancelled,
                }).toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        Insets.gutter, 0, Insets.gutter, Insets.lg),
                    child: LsSegmented<_Tab>(
                      value: _tab,
                      options: _Tab.values,
                      labelBuilder: (v) => switch (v) {
                        _Tab.all => 'All',
                        _Tab.sent => 'Sent',
                        _Tab.received => 'Received',
                        _Tab.failed => 'Failed',
                      },
                      onChanged: (v) => setState(() => _tab = v),
                    ),
                  ),
                ),
                if (list.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: LsEmptyState(
                      icon: Icons.swap_vert_rounded,
                      title: all.isEmpty ? 'No transfers yet' : 'Nothing here',
                      message: all.isEmpty
                          ? 'Uploads and downloads you make will be listed here '
                              'with their outcome.'
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
                      itemBuilder: (context, i) =>
                          _TransferRow(transfer: list[i], now: now),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TransferRow extends StatelessWidget {
  const _TransferRow({required this.transfer, required this.now});

  final Transfer transfer;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final (Color color, IconData icon, String label) = switch (transfer.status) {
      TransferStatus.complete => (AppColors.success, Icons.check_rounded, 'Done'),
      TransferStatus.active => (AppColors.cyan, Icons.north_east_rounded, 'Sending'),
      TransferStatus.queued => (scheme.onSurfaceVariant, Icons.schedule_rounded, 'Queued'),
      TransferStatus.failed => (scheme.error, Icons.error_outline_rounded, 'Failed'),
      TransferStatus.cancelled => (scheme.onSurfaceVariant, Icons.remove_circle_outline_rounded, 'Cancelled'),
    };

    return LsCard(
      padding: const EdgeInsets.all(Insets.md),
      child: Row(
        children: [
          FileTypeChip(name: transfer.name, size: 40),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Fmt.ellipsizeMiddle(transfer.name, 28),
                  style: t.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${transfer.direction == TransferDirection.sent ? 'Sent' : 'Received'} · '
                  '${Fmt.bytes(transfer.sizeBytes)} · ${Fmt.ago(transfer.startedAt, now)}',
                  style: AppType.monoTiny.copyWith(color: scheme.onSurfaceVariant),
                ),
                if (transfer.status == TransferStatus.active) ...[
                  const SizedBox(height: Insets.sm),
                  LsProgressBar(value: transfer.progress, height: 4),
                ],
                if (transfer.failureReason != null) ...[
                  const SizedBox(height: Insets.xs),
                  Text(
                    transfer.failureReason!,
                    style: t.caption.copyWith(color: scheme.error),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: Insets.sm),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppType.monoTiny.copyWith(color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}