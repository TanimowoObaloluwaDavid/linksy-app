import 'package:equatable/equatable.dart';

/// Per-file upload states. PRD §6.5 requires the UI to distinguish all seven of
/// these, and that they never be collapsed into a single "busy" flag.
///
/// This enum is deliberately free of icons and colours: those are presentation
/// concerns and live in `core/widgets/status_badge.dart`. Keeping them out is
/// what lets this stay pure Dart.
enum FileUploadState {
  queued('Waiting'),
  uploading('Uploading'),
  interrupted('Interrupted'),
  verifying('Verifying'),
  ready('Ready'),
  failed('Failed'),
  cancelled('Cancelled');

  const FileUploadState(this.label);
  final String label;

  bool get isTerminal =>
      this == FileUploadState.ready ||
      this == FileUploadState.failed ||
      this == FileUploadState.cancelled;

  bool get isRetriable =>
      this == FileUploadState.failed || this == FileUploadState.interrupted;
}

/// A file the sender has staged, and its progress. `localPath` is null for
/// items that came from a cloud document provider where no local file exists
/// (PRD §6.3) — callers must not assume a readable path.
class SharedFile extends Equatable {
  const SharedFile({
    required this.id,
    required this.name,
    required this.sizeBytes,
    required this.state,
    this.mime,
    this.localPath,
    this.bytesSent = 0,
    this.error,
  });

  final String id;
  final String name;
  final int sizeBytes;
  final String? mime;
  final String? localPath;
  final FileUploadState state;
  final int bytesSent;
  final String? error;

  double get progress => sizeBytes <= 0 ? 0 : (bytesSent / sizeBytes).clamp(0.0, 1.0);

  SharedFile copyWith({
    FileUploadState? state,
    int? bytesSent,
    String? error,
    bool clearError = false,
  }) =>
      SharedFile(
        id: id,
        name: name,
        sizeBytes: sizeBytes,
        mime: mime,
        localPath: localPath,
        state: state ?? this.state,
        bytesSent: bytesSent ?? this.bytesSent,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props =>
      [id, name, sizeBytes, mime, localPath, state, bytesSent, error];
}