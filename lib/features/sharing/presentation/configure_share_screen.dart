import 'dart:async';

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
import '../../sharing/domain/share.dart';
import '../../sharing/presentation/share_draft_controller.dart';

/// Share configuration (PRD §8.5).
///
/// Defaults are chosen so the common case — send something, let someone open
/// it for a week — needs no input at all. Every option is optional.
class ConfigureShareScreen extends ConsumerStatefulWidget {
  const ConfigureShareScreen({super.key});

  @override
  ConsumerState<ConfigureShareScreen> createState() => _ConfigureShareScreenState();
}

class _ConfigureShareScreenState extends ConsumerState<ConfigureShareScreen> {
  late final TextEditingController _title =
      TextEditingController(text: ref.read(shareDraftProvider).title);
  late final TextEditingController _description =
      TextEditingController(text: ref.read(shareDraftProvider).description);
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    // A single sensible title beats a blank field the user has to invent.
    final draft = ref.read(shareDraftProvider);
    if (draft.title.isEmpty && draft.files.length == 1) {
      _title.text = draft.files.first.name;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final c = ref.read(shareDraftProvider.notifier);
    c.setTitle(_title.text);
    c.setDescription(_description.text);
    await c.submit();
    if (!mounted) return;
    // Jump straight into the upload screen — the work has already started.
    // Not awaited: awaiting would block until the upload screen is popped,
    // which would prevent handing off to the share-ready screen below.
    unawaited(context.push(Routes.upload));
    if (!mounted) return;
    final phase = ref.read(shareDraftProvider).phase;
    if (phase == UploadPhase.done) {
      context.pushReplacement(Routes.ready);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(shareDraftProvider);
    final c = ref.read(shareDraftProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return LsScaffold(
      title: 'Configure share',
      bottomBar: LsButton(
        label: draft.isBusy ? 'Uploading…' : 'Create share',
        icon: Icons.cloud_upload_rounded,
        expand: true,
        onPressed: draft.canSubmit ? _start : null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Summary of what is being shared ----
          LsCard(
            child: Row(
              children: [
                _StackedChips(files: draft.files.length),
                const SizedBox(width: Insets.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Fmt.plural(draft.files.length, 'file'),
                        style: t.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Fmt.bytes(draft.totalBytes),
                        style: AppType.monoSmall
                            .copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.xxl),

          // ---- Title ----
          const LsSectionHeader(label: 'Title'),
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            onChanged: c.setTitle,
            decoration: const InputDecoration(
              hintText: 'What are you sharing?',
              prefixIcon: Icon(Icons.title_rounded, size: 19),
            ),
          ),
          const SizedBox(height: Insets.lg),

          // ---- Description ----
          const LsSectionHeader(label: 'Description (optional)'),
          TextField(
            controller: _description,
            maxLines: 3,
            minLines: 2,
            textCapitalization: TextCapitalization.sentences,
            onChanged: c.setDescription,
            decoration: const InputDecoration(
              hintText: 'Add a note for the recipient',
              prefixIcon: Icon(Icons.notes_rounded, size: 19),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: Insets.xxl),

          // ---- Expiry ----
          const LsSectionHeader(
            label: 'Expires after',
            trailing: _ExpiryHint(),
          ),
          LsSegmented<Expiry>(
            value: draft.expiry,
            options: Expiry.values,
            labelBuilder: (e) => switch (e) {
              Expiry.oneHour => '1h',
              Expiry.oneDay => '24h',
              Expiry.oneWeek => '7d',
              Expiry.thirtyDays => '30d',
            },
            onChanged: c.setExpiry,
          ),
          const SizedBox(height: Insets.xl),

          // ---- Access ----
          const LsSectionHeader(label: 'Access'),
          _ToggleRow(
            icon: Icons.password_rounded,
            title: 'Require a password',
            subtitle: 'The recipient enters it before downloading',
            value: draft.policy.passwordRequired,
            isPro: true,
            onChanged: (v) {
              c.setPolicy(draft.policy.copyWith(passwordRequired: v));
              if (!v) _password.clear();
            },
          ),
          if (draft.policy.passwordRequired) ...[
            const SizedBox(height: Insets.md),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Share password',
                hintText: 'At least 6 characters',
                prefixIcon: const Icon(Icons.key_rounded, size: 19),
                errorText: _password.text.isNotEmpty && _password.text.length < 6
                    ? 'Too short'
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: Insets.sm),
          _ToggleRow(
            icon: Icons.download_rounded,
            title: 'Allow downloads',
            subtitle: 'Turn off for a preview-only share',
            value: draft.policy.allowDownload,
            onChanged: (v) =>
                c.setPolicy(draft.policy.copyWith(allowDownload: v)),
          ),
          const SizedBox(height: Insets.lg),

          // ---- Honest copy about what Linksy cannot promise ----
          const _Notice(
            icon: Icons.lock_clock_rounded,
            text: 'Revoking stops new downloads. It cannot erase a copy '
                'someone has already saved.',
          ),
        ],
      ),
    );
  }
}

class _ExpiryHint extends StatelessWidget {
  const _ExpiryHint();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      'links stop working after this',
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}

class _StackedChips extends StatelessWidget {
  const _StackedChips({required this.files});

  final int files;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 52,
      height: 44,
      child: Stack(
        children: [
          for (var i = 0; i < (files > 2 ? 3 : files); i++)
            Positioned(
              left: i * 11,
              top: i * 5,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(Radii.sm),
                  border: Border.all(color: scheme.outlineVariant),
                ),
              ),
            ),
          if (files > 2)
            Positioned(
              left: 22,
              top: 10,
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: Text(
                  '$files',
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.isPro = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isPro;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.md, Insets.md, Insets.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: scheme.onSurfaceVariant),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(title, style: t.bodyStrong)),
                    if (isPro) ...[
                      const SizedBox(width: Insets.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(Radii.pill),
                        ),
                        child: Text(
                          'PRO',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: t.caption.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(Insets.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: scheme.onSurfaceVariant),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                height: 1.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}