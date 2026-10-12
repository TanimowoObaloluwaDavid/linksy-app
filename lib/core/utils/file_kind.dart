import 'package:flutter/material.dart';

import '../theme/tokens.dart';

enum FileKind { image, video, audio, pdf, document, spreadsheet, image2d, archive, code, text, other }

/// Maps a file to a visual identity.
///
/// File-type colour is *semantic*, not categorical decoration: images and video
/// share a warm family, documents a neutral family, archives a cool one. That
/// means a list of mixed files stays readable as groups instead of turning
/// into confetti.
@immutable
class FileKindStyle {
  const FileKindStyle({
    required this.kind,
    required this.label,
    required this.tint,
    required this.ink,
  });

  final FileKind kind;
  final String label;
  final Color tint;
  final Color ink;
}

class FileKindResolver {
  const FileKindResolver._();

  static FileKind fromName(String name, {String? mime}) {
    final ext = _ext(name).toLowerCase();
    switch (ext) {
      case 'jpg': case 'jpeg': case 'png': case 'gif': case 'webp':
      case 'heic': case 'heif': case 'bmp': case 'avif':
        return FileKind.image;
      case 'mp4': case 'mov': case 'mkv': case 'avi': case 'webm':
      case 'm4v': case '3gp':
        return FileKind.video;
      case 'mp3': case 'wav': case 'aac': case 'flac': case 'ogg':
      case 'm4a':
        return FileKind.audio;
      case 'pdf':
        return FileKind.pdf;
      case 'doc': case 'docx': case 'odt': case 'rtf':
        return FileKind.document;
      case 'xls': case 'xlsx': case 'csv': case 'ods': case 'tsv':
        return FileKind.spreadsheet;
      case 'ppt': case 'pptx': case 'odp': case 'key':
        return FileKind.image2d;
      case 'zip': case 'rar': case '7z': case 'tar': case 'gz': case 'bz2':
      case 'xz': case 'zst':
        return FileKind.archive;
      case 'dart': case 'js': case 'ts': case 'tsx': case 'jsx': case 'py':
      case 'rb': case 'go': case 'rs': case 'java': case 'kt': case 'swift':
      case 'c': case 'h': case 'cpp': case 'cs': case 'php': case 'sh':
      case 'json': case 'yaml': case 'yml': case 'toml': case 'html':
      case 'css': case 'sql':
        return FileKind.code;
      case 'txt': case 'md': case 'log': case 'rtf.md':
        return FileKind.text;
    }
    if (mime != null) {
      final m = mime.toLowerCase();
      if (m.startsWith('image/')) return FileKind.image;
      if (m.startsWith('video/')) return FileKind.video;
      if (m.startsWith('audio/')) return FileKind.audio;
      if (m == 'application/pdf') return FileKind.pdf;
    }
    return FileKind.other;
  }

  static String _ext(String name) {
    final dot = name.lastIndexOf('.');
    return dot <= 0 ? '' : name.substring(dot + 1);
  }

  static FileKindStyle style(FileKind kind) {
    switch (kind) {
      case FileKind.image:
        return const FileKindStyle(
          kind: FileKind.image,
          label: 'Image',
          tint: Color(0x1AF5B544),
          ink: AppColors.warning,
        );
      case FileKind.video:
        return const FileKindStyle(
          kind: FileKind.video,
          label: 'Video',
          tint: Color(0x1AF06464),
          ink: AppColors.error,
        );
      case FileKind.audio:
        return const FileKindStyle(
          kind: FileKind.audio,
          label: 'Audio',
          tint: Color(0x1A9B7BFF),
          ink: Color(0xFF9B7BFF),
        );
      case FileKind.pdf:
        return const FileKindStyle(
          kind: FileKind.pdf,
          label: 'PDF',
          tint: Color(0x1A35C98A),
          ink: AppColors.success,
        );
      case FileKind.document:
        return const FileKindStyle(
          kind: FileKind.document,
          label: 'Document',
          tint: Color(0x1A7AA2F7),
          ink: AppColors.info,
        );
      case FileKind.spreadsheet:
        return const FileKindStyle(
          kind: FileKind.spreadsheet,
          label: 'Sheet',
          tint: Color(0x1A35C98A),
          ink: AppColors.success,
        );
      case FileKind.image2d:
        return const FileKindStyle(
          kind: FileKind.image2d,
          label: 'Slides',
          tint: Color(0x1AF5B544),
          ink: AppColors.warning,
        );
      case FileKind.archive:
        return const FileKindStyle(
          kind: FileKind.archive,
          label: 'Archive',
          tint: Color(0x1A39D5FF),
          ink: AppColors.cyan,
        );
      case FileKind.code:
        return const FileKindStyle(
          kind: FileKind.code,
          label: 'Source',
          tint: Color(0x1A7C5CFC),
          ink: AppColors.violet,
        );
      case FileKind.text:
        return const FileKindStyle(
          kind: FileKind.text,
          label: 'Text',
          tint: Color(0x1A969EAE),
          ink: AppColors.textMuted,
        );
      case FileKind.other:
        return const FileKindStyle(
          kind: FileKind.other,
          label: 'File',
          tint: Color(0x1A969EAE),
          ink: AppColors.textMuted,
        );
    }
  }
}