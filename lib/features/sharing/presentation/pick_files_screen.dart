import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app.dart';
import '../../../app/router.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/file_kind.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/ls_button.dart';
import '../../../core/widgets/ls_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../sharing/domain/shared_file.dart';
import '../../sharing/presentation/share_draft_controller.dart';

/// File selection (PRD §8.4).
class PickFilesScreen extends ConsumerStatefulWidget {
  const PickFilesScreen({super.key});

  @override
  ConsumerState<PickFilesScreen> createState() => _PickFilesScreenState();
}

class _PickFilesScreenState extends ConsumerState<PickFilesScreen> {
  bool _picking = false;
  int _seq = 0;

  Future<void> _pick() async {
    setState(() => _picking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        // PRD §6.3 — cloud-backed providers and temporary file permissions are
        // normal; `withData: false` keeps large files off the Dart heap.
        withData: false,
      );
      if (result == null) return; // cancelled — return silently
      if (!mounted) return;

      final usage = ref.read(usageProvider).valueOrNull;
      final maxBytes = usage?.maxFileBytes ?? 500 * 1024 * 1024;

      final accepted = <SharedFile>[];
      final rejected = <String>[];
      for (final f in result.files) {
        final size = f.size;
        final path = f.path;
        if (size > maxBytes) {
          rejected.add('${f.name} — ${Fmt.bytes(size)} exceeds the ${Fmt.bytes(maxBytes)} limit');
          continue;
        }
        accepted.add(SharedFile(
          id: 'f${_seq++}',
          name: f.name,
          sizeBytes: size,
          mime: _mimeOf(path),
          // A null path is legitimate: the platform may have granted a
          // temporary URI rather than a readable file. Nothing may assume a
          // local file exists.
          localPath: path,
          state: FileUploadState.queued,
        ));
      }

      ref.read(shareDraftProvider.notifier).addFiles(accepted);
      if (!mounted) return;
      if (rejected.isNotEmpty) {
        _snack(rejected.first, isError: true);
      }
    } catch (e) {
      if (mounted) _snack('Could not open files: $e', isError: true);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  static String? _mimeOf(String? path) {
    if (path == null) return null;
    final dot = path.lastIndexOf('.');
    if (dot < 0) return null;
    final ext = path.substring(dot + 1).toLowerCase();
    const map = {
      'pdf': 'application/pdf', 'png': 'image/png', 'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg', 'webp': 'image/webp', 'gif': 'image/gif',
      'mp4': 'video/mp4', 'mov': 'video/quicktime', 'mp3': 'audio/mpeg',
      'zip': 'application/zip', 'txt': 'text/plain', 'csv': 'text/csv',
      'json': 'application/json', 'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    };
    return map[ext];
  }

  void _snack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    if (isError) return;
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(shareDraftProvider);
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final usage = ref.watch(usageProvider).valueOrNull;
    final maxBytes = usage?.maxFileBytes ?? 500 * 1024 * 1024;
    final overLimit = draft.totalBytes > maxBytes;

    return LsScaffold(
      title: 'Select files',
      actions: [
        if (draft.files.isNotEmpty)
          TextButton(
            onPressed: () => ref.read(shareDraftProvider.notifier).clearFiles(),
            child: const Text('Clear'),
          ),
        const SizedBox(width: Insets.sm),
      ],
      bottomBar: draft.files.isEmpty
          ? LsButton(
              label: 'Choose files',
              icon: Icons.attach_file_rounded,
              busy: _picking,
              expand: true,
              onPressed: _pick,
            )
          : LsButton(
              label: 'Next — configure share',
              icon: Icons.arrow_forward_rounded,
              expand: true,
              onPressed: overLimit ? null : () => context.push(Routes.configure),
            ),
      body: draft.files.isEmpty
          ? _PickerEmpty(onPick: _pick, busy: _picking)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Running total, always visible while selecting.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Insets.lg,
                    vertical: Insets.md,
                  ),
                  decoration: BoxDecoration(
                    color: overLimit
                        ? scheme.error.withValues(alpha: 0.10)
                        : scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(Radii.md),
                    border: Border.all(
                      color: overLimit
                          ? scheme.error.withValues(alpha: 0.4)
                          : scheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        overLimit
                            ? Icons.error_outline_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 17,
                        color: overLimit ? scheme.error : AppColors.success,
                      ),
                      const SizedBox(width: Insets.md),
                      Expanded(
                        child: Text(
                          '${Fmt.plural(draft.files.length, 'file')} · ${Fmt.bytes(draft.totalBytes)}',
                          style: t.bodySmall,
                        ),
                      ),
                      if (!overLimit)
                        Text(
                          'limit ${Fmt.bytes(maxBytes)}',
                          style: AppType.monoTiny
                              .copyWith(color: scheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: Insets.lg),
                for (final f in draft.files)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Insets.sm),
                    child: _PickRow(
                      file: f,
                      onRemove: () => ref
                          .read(shareDraftProvider.notifier)
                          .removeFile(f.id),
                    ),
                  ),
                const SizedBox(height: Insets.md),
                OutlinedButton.icon(
                  onPressed: _picking ? null : _pick,
                  icon: _picking
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_rounded, size: 19),
                  label: const Text('Add more'),
                ),
              ],
            ),
    );
  }
}

class _PickerEmpty extends StatelessWidget {
  const _PickerEmpty({required this.onPick, required this.busy});

  final VoidCallback onPick;
  final bool busy;

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
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(Radii.xl),
              ),
              child: Icon(Icons.note_add_rounded, size: 34, color: scheme.primary),
            ),
            const SizedBox(height: Insets.xl),
            Text('What are you sending?', style: t.heading, textAlign: TextAlign.center),
            const SizedBox(height: Insets.sm),
            Text(
              'Documents, photos, video, archives — pick as many as you need.',
              style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Insets.xxl),
            LsButton(
              label: 'Choose files',
              icon: Icons.folder_open_rounded,
              busy: busy,
              expand: true,
              onPressed: onPick,
            ),
          ],
        ),
      ),
    );
  }
}

class _PickRow extends StatelessWidget {
  const _PickRow({required this.file, required this.onRemove});

  final SharedFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final style = FileKindResolver.style(
      FileKindResolver.fromName(file.name, mime: file.mime),
    );

    return LsCard(
      padding: const EdgeInsets.all(Insets.md),
      child: Row(
        children: [
          FileTypeChip(name: file.name, mime: file.mime),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: t.bodyStrong,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${Fmt.bytes(file.sizeBytes)} · ${style.label}',
                  style: AppType.monoTiny.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 18),
            tooltip: 'Remove ${file.name}',
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}