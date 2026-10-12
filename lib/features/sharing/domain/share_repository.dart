import 'package:equatable/equatable.dart';

import '../../transfers/domain/transfer.dart';
import 'share.dart';
import 'shared_file.dart';

/// Progress report emitted while an upload runs (PRD §6.5).
class UploadProgress extends Equatable {
  const UploadProgress({required this.fileId, required this.bytesSent, required this.state});

  final String fileId;
  final int bytesSent;
  final FileUploadState state;

  @override
  List<Object?> get props => [fileId, bytesSent, state];
}

/// Contract for share persistence and transfer.
///
/// This is the seam the backend plugs into. The PRD specifies an HTTP API
/// (`POST /v1/shares`, `POST /v1/shares/{id}/uploads`, …); an `HttpShareRepository`
/// implementing this interface is the only production change required to go
/// live — no widget or notifier in the app imports a data source directly.
abstract interface class ShareRepository {
  /// PRD §6.4 step 3 — create the share draft and authorise uploads.
  Future<ShareDraft> createDraft({
    required String title,
    required String description,
    required Duration expiresIn,
    required AccessPolicy policy,
    required List<SharedFile> files,
  });

  /// PRD §6.5 — run the upload, reporting per-file progress.
  Stream<UploadProgress> upload({
    required ShareDraft draft,
    required List<SharedFile> files,
    Future<void> Function()? cancelSignal,
  });

  /// PRD §6.4 steps 5–7 — verify then publish. Must never be skipped because the
  /// client *thinks* the upload succeeded; the backend decides.
  Future<Share> finalize({required String draftId, required List<SharedFile> files});

  /// PRD §6.9 — list and mutate owned shares.
  Future<List<Share>> listShares();
  Future<Share?> getShare(String slug);
  Future<Share> revoke(String shareId);
  Future<Share> extend(String shareId, Duration extra);

  /// PRD §6.16 usage.
  Future<Usage> usage();

  /// PRD §6.10 history.
  Future<List<Transfer>> history();
}

/// A share that exists but is not yet published to recipients.
class ShareDraft extends Equatable {
  const ShareDraft({required this.id, required this.slug, required this.createdAt});

  final String id;
  final String slug;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, slug, createdAt];
}

class Usage extends Equatable {
  const Usage({
    required this.usedBytes,
    required this.quotaBytes,
    required this.activeShares,
    required this.shareLimit,
    required this.maxFileBytes,
  });

  final int usedBytes;
  final int quotaBytes;
  final int activeShares;
  final int shareLimit;
  final int maxFileBytes;

  double get fraction => quotaBytes <= 0 ? 0 : (usedBytes / quotaBytes).clamp(0.0, 1.0);

  @override
  List<Object?> get props => [usedBytes, quotaBytes, activeShares, shareLimit, maxFileBytes];
}