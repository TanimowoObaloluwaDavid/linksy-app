import 'package:flutter/material.dart';

import '../../features/sharing/domain/shared_file.dart';
import '../theme/app_typography.dart';
import '../theme/tokens.dart';
import '../utils/file_kind.dart';

/// Presentation mapping for [FileUploadState].
///
/// Lives here rather than on the enum so the domain stays free of Flutter types.
extension FileUploadStateIcon on FileUploadState {
  IconData get icon => switch (this) {
        FileUploadState.queued => Icons.schedule_rounded,
        FileUploadState.uploading => Icons.north_east_rounded,
        FileUploadState.interrupted => Icons.wifi_off_rounded,
        FileUploadState.verifying => Icons.verified_outlined,
        FileUploadState.ready => Icons.check_rounded,
        FileUploadState.failed => Icons.error_outline_rounded,
        FileUploadState.cancelled => Icons.remove_circle_outline_rounded,
      };

  /// Colour carries meaning only alongside the icon and the word — never alone.
  Color color(ColorScheme scheme) => switch (this) {
        FileUploadState.ready => AppColors.success,
        FileUploadState.failed => scheme.error,
        FileUploadState.cancelled => scheme.onSurfaceVariant,
        FileUploadState.uploading ||
        FileUploadState.verifying =>
          AppColors.cyan,
        FileUploadState.interrupted => AppColors.warning,
        FileUploadState.queued => scheme.onSurfaceVariant,
      };
}

/// A compact status chip.
///
/// Per the accessibility requirements, state is never communicated by colour
/// alone: every badge carries an icon *and* a word.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
    this.dense = false,
  });

  final String label;
  final Color color;
  final IconData icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 7 : Insets.sm,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: dense ? 11 : 13, color: color),
          SizedBox(width: dense ? 4 : 5),
          Text(
            label.toUpperCase(),
            style: AppType.overline.copyWith(
              color: color,
              fontSize: dense ? 9 : 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// A file-type chip: colour plus a two/three-letter monogram.
///
/// The monogram is what actually carries the distinction, so it survives
/// greyscale, colour-blindness and low-contrast screens.
class FileTypeChip extends StatelessWidget {
  const FileTypeChip({
    super.key,
    required this.name,
    this.mime,
    this.size = 42,
  });

  final String name;
  final String? mime;
  final double size;

  static const _monograms = {
    FileKind.image: 'IMG',
    FileKind.video: 'VID',
    FileKind.audio: 'AUD',
    FileKind.pdf: 'PDF',
    FileKind.document: 'DOC',
    FileKind.spreadsheet: 'XLS',
    FileKind.image2d: 'PPT',
    FileKind.archive: 'ZIP',
    FileKind.code: '{}',
    FileKind.text: 'TXT',
    FileKind.other: 'BIN',
  };

  @override
  Widget build(BuildContext context) {
    final kind = FileKindResolver.fromName(name, mime: mime);
    final style = FileKindResolver.style(kind);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: style.tint,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: style.ink.withValues(alpha: 0.28)),
      ),
      child: Text(
        _monograms[kind]!,
        style: AppType.monoTiny.copyWith(
          color: style.ink,
          fontSize: size * 0.235,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}