import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app.dart';
import '../../../app/router.dart';
import '../../../core/painters/transfer_rail.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/ls_button.dart';
import '../../../core/widgets/ls_card.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/status_badge.dart';
import '../domain/shared_file.dart';
import 'share_draft_controller.dart';

/// Upload progress (PRD §8.6).
///
/// The rail on the right is the transfer pipeline drawn as a spine; every file
/// aligns to a stage, so a glance tells you where the whole job is.
class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // Watch the phase once; navigating from a build method would be unsafe.
    ref.listenManual<ShareDraftState>(
      shareDraftProvider,
      (previous, next) {
        if (next.phase == UploadPhase.done && !_navigated) {
          _navigated = true;
          context.pushReplacement(Routes.ready);
        }
      },
      fireImmediately: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(shareDraftProvider);
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    // Nothing staged: send the user back rather than showing a dead screen.
    if (draft.files.isEmpty) {
      return LsScaffold(
        title: 'Upload',
        body: LsEmptyState(
          icon: Icons.upload_file_rounded,
          title: 'Nothing to upload',
          message: 'Choose some files first and the upload will start here.',
          actionLabel: 'Choose files',
          onAction: () => context.go('${Routes.home}/send'),
        ),
      );
    }

    final stage = switch (draft.phase) {
      UploadPhase.uploading => RailStage.upload,
      UploadPhase.verifying => RailStage.link,
      UploadPhase.publishing => RailStage.done,
      UploadPhase.done => RailStage.done,
      _ => RailStage.select,
    };

    return PopScope(
      // Leaving mid-upload must not silently discard it — the workflow
      // continues in the controller and is visible on the dashboard.
      canPop: draft.isBusy,
      onPopInvokedWithResult: (didPop, _) {},
      child: LsScaffold(
        title: draft.isBusy ? 'Uploading' : 'Upload',
        showBack: !draft.isBusy,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- headline ----
            LsCard(
              accent: draft.isBusy ? AppColors.cyan : null,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Bounded rather than intrinsic: LayoutBuilder cannot resolve
                  // constraints during an IntrinsicHeight pass. 210 is sized to
                  // the content beside it so the card has no dead space.
                  SizedBox(
                    height: 210,
                    child: TransferRail(
                      stage: stage,
                      progress: draft.progress,
                      travellerVisible: draft.isBusy,
                    ),
                  ),
                  const SizedBox(width: Insets.xl),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          switch (draft.phase) {
                            UploadPhase.uploading =>
                              'Sending your files…',
                            UploadPhase.publishing => 'Verifying…',
                            UploadPhase.done => 'Ready to share',
                            UploadPhase.failed => 'Upload failed',
                            UploadPhase.cancelled => 'Upload cancelled',
                            _ => 'Preparing',
                          },
                          style: t.subheading,
                        ),
                        const SizedBox(height: Insets.xs),
                        Text(
                          '${draft.readyCount} of ${draft.files.length} verified',
                          style: AppType.monoSmall
                              .copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: Insets.lg),
                        Text(
                          '${(draft.progress * 100).toStringAsFixed(0)}%',
                          style: AppType.hero.copyWith(
                            fontSize: 34,
                            color: draft.phase == UploadPhase.failed
                                ? scheme.error
                                : scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: Insets.md),
                        LsProgressBar(
                          value: draft.progress,
                          color: draft.phase == UploadPhase.failed
                              ? scheme.error
                              : null,
                        ),
                        const SizedBox(height: Insets.md),
                        Text(
                          '${Fmt.bytes(draft.sentBytes)} of ${Fmt.bytes(draft.totalBytes)}',
                          style: t.caption
                              .copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Insets.xxl),

            if (draft.errorMessage != null) ...[
              LsErrorState(
                message: draft.errorMessage!,
                onRetry: draft.phase == UploadPhase.cancelled
                    ? null
                    : () => ref.read(shareDraftProvider.notifier).retry(),
                retryLabel: 'Resume upload',
              ),
              const SizedBox(height: Insets.lg),
            ],

            // ---- per-file ----
            const LsSectionHeader(label: 'Files'),
            for (final f in draft.files)
              Padding(
                padding: const EdgeInsets.only(bottom: Insets.sm),
                child: _FileProgressRow(
                  file: f,
                  onRetry: f.state.isRetriable
                      ? () =>
                          ref.read(shareDraftProvider.notifier).retryFile(f.id)
                      : null,
                ),
              ),

            const SizedBox(height: Insets.xl),
            if (draft.isBusy)
              LsButton(
                label: 'Cancel upload',
                variant: LsButtonVariant.danger,
                icon: Icons.close_rounded,
                expand: true,
                onPressed: () =>
                    ref.read(shareDraftProvider.notifier).cancel(),
              )
            else if (draft.phase == UploadPhase.done)
              LsButton(
                label: 'View share',
                icon: Icons.qr_code_2_rounded,
                expand: true,
                onPressed: () => context.pushReplacement(Routes.ready),
              )
            else
              LsButton(
                label: 'Resume',
                icon: Icons.refresh_rounded,
                expand: true,
                onPressed: () =>
                    ref.read(shareDraftProvider.notifier).retry(),
              ),
          ],
        ),
      ),
    );
  }
}

class _FileProgressRow extends StatelessWidget {
  const _FileProgressRow({required this.file, this.onRetry});

  final SharedFile file;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final color = file.state.color(scheme);
    final done = file.state == FileUploadState.ready;

    return LsCard(
      padding: const EdgeInsets.all(Insets.md),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: file.state == FileUploadState.uploading
                    ? CircularProgressIndicator(strokeWidth: 2, color: color)
                    : file.state == FileUploadState.verifying
                        ? CircularProgressIndicator(strokeWidth: 2, color: color)
                        : Icon(file.state.icon, size: 17, color: color),
              ),
              const SizedBox(width: Insets.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Fmt.ellipsizeMiddle(file.name, 30),
                      style: t.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        decoration: file.state == FileUploadState.cancelled
                            ? TextDecoration.lineThrough
                            : null,
                        color: file.state == FileUploadState.cancelled
                            ? scheme.onSurfaceVariant
                            : scheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${file.state.label} · ${Fmt.bytes(file.sizeBytes)}',
                      style: AppType.monoTiny.copyWith(color: color),
                    ),
                  ],
                ),
              ),
              if (onRetry != null)
                IconButton(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  tooltip: 'Retry ${file.name}',
                  color: scheme.onSurfaceVariant,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          if (!done &&
              (file.state == FileUploadState.uploading ||
                  file.state == FileUploadState.queued)) ...[
            const SizedBox(height: Insets.md),
            LsProgressBar(value: file.progress, height: 4),
          ],
          if (file.error != null) ...[
            const SizedBox(height: Insets.sm),
            Text(
              file.error!,
              style: t.caption.copyWith(color: scheme.error),
            ),
          ],
        ],
      ),
    );
  }
}