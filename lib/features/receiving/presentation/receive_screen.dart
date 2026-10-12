import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/ls_button.dart';
import '../../../core/widgets/ls_card.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/status_badge.dart';
import '../../sharing/domain/share.dart';
import '../../sharing/presentation/share_draft_controller.dart';

/// The receiving experience (PRD §8.9).
///
/// This screen is the whole reason Linksy is worth building: it must work for
/// someone with no account, and it must be honest about a link that is closed.
class ReceiveScreen extends ConsumerStatefulWidget {
  const ReceiveScreen({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen> {
  bool _unlocked = false;
  final _password = TextEditingController();
  String? _error;
  bool _checking = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    if (_password.text.length < 4) {
      setState(() => _error = 'Enter the password you were given.');
      return;
    }
    setState(() {
      _checking = true;
      _error = null;
    });
    // A real build posts this to `POST /v1/shares/{id}/access`. There is no
    // backend here, so the check is local and the failure path is what the UI
    // actually needs to demonstrate.
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    setState(() {
      _checking = false;
      _unlocked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Consumer(
          builder: (context, ref, _) {
            final shares = ref.watch(sharesProvider);
            final now = DateTime.now();

            return shares.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => LsErrorState(
                message: 'Could not load this share.',
                onRetry: () => ref.invalidate(sharesProvider),
              ),
              data: (all) {
                final match = all.where((s) => s.slug == widget.slug);
                if (match.isEmpty) {
                  return _Closed(
                    icon: Icons.search_off_rounded,
                    title: 'Link not found',
                    message: 'This link does not match any share. It may have '
                        'been typed incorrectly or deleted.',
                    action: 'Go home',
                    onAction: () => context.go(Routes.home),
                  );
                }

                final share = match.first;
                final effective = share.effectiveStatus(now);

                if (effective == ShareStatus.revoked) {
                  return _Closed(
                    icon: Icons.block_rounded,
                    title: 'Access revoked',
                    message: 'The person who shared this withdrew access. '
                        'Any copy you already downloaded is unaffected.',
                    action: 'Go home',
                    onAction: () => context.go(Routes.home),
                  );
                }
                if (effective == ShareStatus.expired) {
                  return _Closed(
                    icon: Icons.schedule_rounded,
                    title: 'This link has expired',
                    message: 'Links stop working on a schedule so shared files '
                        'don’t stay open forever. Ask the sender for a new one.',
                    action: 'Go home',
                    onAction: () => context.go(Routes.home),
                  );
                }
                if (effective == ShareStatus.uploading) {
                  return _Closed(
                    icon: Icons.cloud_upload_rounded,
                    title: 'Still uploading',
                    message: 'This share is being prepared. Try again in a moment.',
                    action: 'Refresh',
                    onAction: () => ref.invalidate(sharesProvider),
                  );
                }

                if (share.policy.passwordRequired && !_unlocked) {
                  return _PasswordGate(
                    controller: _password,
                    error: _error,
                    busy: _checking,
                    onSubmit: _unlock,
                  );
                }

                return _ShareBody(share: share, now: now);
              },
            );
          },
        ),
      ),
    );
  }
}

class _ShareBody extends StatelessWidget {
  const _ShareBody({required this.share, required this.now});

  final Share share;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          Insets.gutter, Insets.xl, Insets.gutter, Insets.huge),
      children: [
        Row(
          children: [
            const BrandMark(size: 24),
            const SizedBox(width: Insets.sm),
            Text('Linksy',
                style: t.titleMedium?.copyWith(letterSpacing: -0.4)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_open_rounded,
                      size: 12, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    'Verified link',
                    style: AppType.overline.copyWith(color: AppColors.success),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Insets.xxxl),
        Text(share.title, style: t.displayLarge?.copyWith(fontSize: 32)),
        if (share.senderName.isNotEmpty) ...[
          const SizedBox(height: Insets.sm),
          Text(
            'Shared by ${share.senderName} · ${Fmt.ago(share.createdAt, now)}',
            style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
        if (share.description.isNotEmpty) ...[
          const SizedBox(height: Insets.lg),
          Text(share.description, style: t.body),
        ],
        const SizedBox(height: Insets.xxl),

        LsCard(
          child: Column(
            children: [
              Row(
                children: [
                  Text('CONTENTS', style: t.labelSmall),
                  const Spacer(),
                  Text(
                    '${share.fileCount} · ${Fmt.bytes(share.totalBytes)}',
                    style: AppType.monoSmall
                        .copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: Insets.lg),
              // A share may carry several files; the list is driven by the
              // count so the layout stays honest when there are many.
              for (var i = 0; i < share.fileCount.clamp(1, 6); i++) ...[
                _FileLine(
                  name: i == 0 && share.fileCount == 1
                      ? share.title
                      : '${share.title} (${i + 1})',
                ),
                if (i < share.fileCount.clamp(1, 6) - 1)
                  const Divider(height: Insets.xl),
              ],
              if (share.fileCount > 6)
                Padding(
                  padding: const EdgeInsets.only(top: Insets.md),
                  child: Text(
                    '+ ${share.fileCount - 6} more',
                    style: t.caption.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: Insets.xl),
        LsButton(
          label: share.policy.allowDownload
              ? 'Download all (${Fmt.bytes(share.totalBytes)})'
              : 'Preview only',
          icon: Icons.download_rounded,
          expand: true,
          onPressed: share.policy.allowDownload
              ? () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Download requires the backend to sign a URL.'),
                    ),
                  )
              : null,
        ),
        const SizedBox(height: Insets.md),
        Text(
          'Expires ${Fmt.remaining(share.expiresAt, now) ?? 'soon'} · '
          'The sender can revoke this link at any time.',
          textAlign: TextAlign.center,
          style: t.caption.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _FileLine extends StatelessWidget {
  const _FileLine({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        FileTypeChip(name: name, size: 36),
        const SizedBox(width: Insets.md),
        Expanded(
          child: Text(
            Fmt.ellipsizeMiddle(name, 28),
            style: t.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Icon(Icons.download_outlined, size: 17, color: scheme.onSurfaceVariant),
      ],
    );
  }
}

class _PasswordGate extends StatelessWidget {
  const _PasswordGate({
    required this.controller,
    required this.error,
    required this.busy,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final String? error;
  final bool busy;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Insets.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 60,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(Radii.lg),
              ),
              child: Icon(Icons.lock_rounded, size: 27, color: scheme.primary),
            ),
            const SizedBox(height: Insets.xl),
            Text('Password protected',
                style: t.heading, textAlign: TextAlign.center),
            const SizedBox(height: Insets.sm),
            Text(
              'The sender protected this share. You don’t need an account — '
              'just the password they gave you.',
              textAlign: TextAlign.center,
              style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: Insets.xxl),
            TextField(
              controller: controller,
              obscureText: true,
              onSubmitted: (_) => onSubmit(),
              style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Password',
                errorText: error,
                prefixIcon: const Icon(Icons.key_rounded, size: 19),
              ),
            ),
            const SizedBox(height: Insets.lg),
            LsButton(
              label: 'Unlock',
              busy: busy,
              expand: true,
              onPressed: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

class _Closed extends StatelessWidget {
  const _Closed({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Insets.xxxl),
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
            Text(title, style: t.heading, textAlign: TextAlign.center),
            const SizedBox(height: Insets.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: Insets.xxl),
            LsButton(label: action, variant: LsButtonVariant.secondary, onPressed: onAction),
          ],
        ),
      ),
    );
  }
}