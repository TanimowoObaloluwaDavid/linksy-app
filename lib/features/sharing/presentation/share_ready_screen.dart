import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart' as share_plus;

import '../../../app/app.dart';
import '../../../app/router.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/ls_button.dart';
import '../../../core/widgets/ls_card.dart';
import '../../../core/widgets/states.dart';
import '../domain/share.dart';
import 'share_draft_controller.dart';

/// Share ready (PRD §8.7) — the emotional payoff of the whole flow.
///
/// The QR code is the product's hero moment: it materialises behind a sweeping
/// mask, because getting it to the other person is the thing the user actually
/// came to do.
class ShareReadyScreen extends ConsumerStatefulWidget {
  const ShareReadyScreen({super.key});

  @override
  ConsumerState<ShareReadyScreen> createState() => _ShareReadyScreenState();
}

class _ShareReadyScreenState extends ConsumerState<ShareReadyScreen> {
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    // Drive the reveal off a real timer rather than a build-time flag so it
    // survives a rebuild.
    Future<void>.delayed(const Duration(milliseconds: 220), () {
      if (mounted) setState(() => _revealed = true);
    });
  }

  Future<void> _copy(Share share) async {
    await Clipboard.setData(ClipboardData(text: share.url));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Link copied to clipboard')));
  }

  Future<void> _share(Share share) async {
    final box = context.findRenderObject() as RenderBox?;
    await share_plus.Share.share(
      '${share.title} — ${share.url}',
      subject: share.title,
      sharePositionOrigin:
          box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(shareDraftProvider);
    final share = draft.share;
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    if (share == null) {
      // Reached directly, or the controller was reset. Do not show a blank
      // success screen — send the user somewhere they can act.
      return LsScaffold(
        title: 'Share',
        showBack: false,
        body: LsEmptyState(
          icon: Icons.link_off_rounded,
          title: 'No share to show',
          message: 'The share that was open has finished. Start a new one.',
          actionLabel: 'Send files',
          onAction: () => context.go('${Routes.home}/send'),
        ),
      );
    }

    final now = DateTime.now();
    final effective = share.effectiveStatus(now);

    return LsScaffold(
      title: 'Share ready',
      showBack: false,
      actions: [
        LsIconButton(
          icon: Icons.close_rounded,
          tooltip: 'Done',
          onPressed: () {
            ref.read(shareDraftProvider.notifier).reset();
            context.go(Routes.home);
          },
        ),
        const SizedBox(width: Insets.sm),
      ],
      bottomBar: Row(
        children: [
          Expanded(
            child: LsButton(
              label: 'Copy link',
              icon: Icons.copy_rounded,
              variant: LsButtonVariant.secondary,
              expand: true,
              onPressed: () => _copy(share),
            ),
          ),
          const SizedBox(width: Insets.md),
          Expanded(
            child: LsButton(
              label: 'Share',
              icon: Icons.ios_share_rounded,
              expand: true,
              onPressed: () => _share(share),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- success header ----
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: const Icon(Icons.check_rounded,
                    size: 21, color: AppColors.success),
              ),
              const SizedBox(width: Insets.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      effective.isAccessible ? 'Link is live' : effective.label,
                      style: t.heading,
                    ),
                    Text(
                      effective.isAccessible
                          ? 'Anyone with it can open — no account needed.'
                          : effective.explanation,
                      style: t.caption
                          .copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: Motion.base + const Duration(milliseconds: 80))
              .slideY(begin: 0.15, end: 0, curve: Motion.enter),

          const SizedBox(height: Insets.xxl),

          // ---- QR: the hero moment ----
          Center(
            child: _QrCard(
              slug: share.slug,
              revealed: _revealed,
              title: share.title,
            ),
          ),

          const SizedBox(height: Insets.xxl),

          // ---- link field ----
          _LinkField(share: share),

          const SizedBox(height: Insets.xl),

          // ---- metadata ----
          LsCard(
            child: Column(
              children: [
                _MetaRow(
                  label: 'Contents',
                  value:
                      '${Fmt.plural(share.fileCount, 'file')} · ${Fmt.bytes(share.totalBytes)}',
                ),
                const Divider(height: Insets.xl),
                _MetaRow(
                  label: 'Expires',
                  value: Fmt.remaining(share.expiresAt, now) ?? 'expired',
                  valueColor: effective.isAccessible ? null : scheme.error,
                ),
                const Divider(height: Insets.xl),
                _MetaRow(
                  label: 'Downloads',
                  value: share.policy.maxDownloads == null
                      ? 'Unlimited'
                      : '${share.downloadCount} of ${share.policy.maxDownloads}',
                ),
                if (share.policy.passwordRequired) ...[
                  const Divider(height: Insets.xl),
                  const _MetaRow(
                    label: 'Access',
                    value: 'Password protected',
                    valueIcon: Icons.lock_rounded,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: Insets.xl),
          Center(
            child: TextButton.icon(
              onPressed: () {
                ref.read(shareDraftProvider.notifier).reset();
                ref.read(shareActionsProvider).refresh();
                context.go(Routes.shares);
              },
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: const Text('Manage this share'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QrCard extends StatelessWidget {
  const _QrCard({
    required this.slug,
    required this.revealed,
    required this.title,
  });

  final String slug;
  final bool revealed;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Print-friendly colours: pure black modules on white guarantees the code
    // scans under any camera and in any lighting.
    const qrInk = Color(0xFF0B0D12);

    return Container(
      width: 250,
      padding: const EdgeInsets.all(Insets.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Radii.xl),
        boxShadow: Elev.medium,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 194,
            width: 194,
            child: Stack(
              children: [
                // The code itself.
                QrImageView(
                  data: 'https://linksy.app/s/$slug',
                  version: QrVersions.auto,
                  size: 194,
                  padding: EdgeInsets.zero,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: qrInk,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: qrInk,
                  ),
                ),
                // Mask that lifts away once [revealed] flips.
                AnimatedContainer(
                  duration: Motion.deliberate,
                  curve: Motion.enter,
                  height: revealed ? 0 : 194,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        scheme.surfaceContainerHigh,
                        scheme.surfaceContainerHighest,
                        scheme.surfaceContainerHigh,
                      ],
                    ),
                  ),
                ),
                if (!revealed)
                  const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
          )
              .animate()
              .scale(begin: const Offset(0.92, 0.92), end: const Offset(1, 1))
              .fadeIn(duration: Motion.slow, curve: Motion.enter),
          const SizedBox(height: Insets.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppType.bodyStrong.copyWith(color: qrInk),
          ),
          const SizedBox(height: 2),
          const Text(
            'Scan to open',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: Motion.base + const Duration(milliseconds: 160))
        .slideY(begin: 0.1, end: 0, curve: Motion.enter);
  }
}

class _LinkField extends StatelessWidget {
  const _LinkField({required this.share});

  final Share share;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.md, Insets.sm, Insets.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              share.url,
              style: AppType.monoSmall.copyWith(color: scheme.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18),
            tooltip: 'Copy link',
            color: scheme.primary,
            visualDensity: VisualDensity.compact,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: share.url));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(content: Text('Link copied to clipboard')),
                );
            },
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueIcon,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final IconData? valueIcon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const Spacer(),
        if (valueIcon != null) ...[
          Icon(valueIcon, size: 13, color: valueColor ?? scheme.onSurface),
          const SizedBox(width: 5),
        ],
        Text(
          value,
          style: AppType.monoSmall.copyWith(color: valueColor ?? scheme.onSurface),
        ),
      ],
    );
  }
}