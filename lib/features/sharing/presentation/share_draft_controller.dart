import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../transfers/domain/transfer.dart';
import '../data/in_memory_share_repository.dart';
import '../domain/share.dart';
import '../domain/share_repository.dart';
import '../domain/shared_file.dart';

/// Where the create-share workflow currently is.
enum UploadPhase { idle, uploading, verifying, publishing, done, failed, cancelled }

/// Immutable snapshot of the whole create-share workflow.
///
/// Kept as one value (rather than a set of unrelated providers) because the
/// file list, the total progress and the phase must always agree with one
/// another — splitting them invites states the backend would reject.
class ShareDraftState extends Equatable {
  const ShareDraftState({
    this.files = const [],
    this.title = '',
    this.description = '',
    this.expiry = Expiry.oneWeek,
    this.policy = const AccessPolicy(),
    this.phase = UploadPhase.idle,
    this.share,
    this.errorMessage,
  });

  final List<SharedFile> files;
  final String title;
  final String description;
  final Expiry expiry;
  final AccessPolicy policy;
  final UploadPhase phase;
  final Share? share;
  final String? errorMessage;

  int get totalBytes => files.fold(0, (a, f) => a + f.sizeBytes);

  int get sentBytes => files.fold(0, (a, f) => a + f.bytesSent);

  /// 0..1 across the whole selection.
  double get progress =>
      totalBytes <= 0 ? 0 : (sentBytes / totalBytes).clamp(0.0, 1.0);

  bool get isBusy =>
      phase == UploadPhase.uploading ||
      phase == UploadPhase.verifying ||
      phase == UploadPhase.publishing;

  bool get canSubmit =>
      files.isNotEmpty && title.trim().isNotEmpty && !isBusy;

  int get readyCount =>
      files.where((f) => f.state == FileUploadState.ready).length;

  bool get allReady => files.isNotEmpty && readyCount == files.length;

  ShareDraftState copyWith({
    List<SharedFile>? files,
    String? title,
    String? description,
    Expiry? expiry,
    AccessPolicy? policy,
    UploadPhase? phase,
    Share? share,
    String? errorMessage,
    bool clearError = false,
    bool clearShare = false,
  }) =>
      ShareDraftState(
        files: files ?? this.files,
        title: title ?? this.title,
        description: description ?? this.description,
        expiry: expiry ?? this.expiry,
        policy: policy ?? this.policy,
        phase: phase ?? this.phase,
        share: clearShare ? null : (share ?? this.share),
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props =>
      [files, title, description, expiry, policy, phase, share, errorMessage];
}

/// Orchestrates selection → upload → verify → publish.
///
/// Deliberately **not** auto-dispose: PRD §6.5 requires the workflow to keep
/// running coherently when the user navigates away mid-upload, so this state
/// has to outlive the screen that started it.
class ShareDraftController extends Notifier<ShareDraftState> {
  StreamSubscription<UploadProgress>? _sub;
  ShareDraft? _draft;

  @override
  ShareDraftState build() {
    ref.onDispose(() => _sub?.cancel());
    return const ShareDraftState();
  }

  ShareRepository get _repo => ref.read(shareRepositoryProvider);

  // ----------------------------------------------------------- selection

  void addFiles(Iterable<SharedFile> incoming) {
    // PRD §6.3: duplicate filenames must not silently overwrite.
    final existing = state.files.map((f) => f.name).toSet();
    final accepted = <SharedFile>[];
    for (final f in incoming) {
      var candidate = f;
      if (existing.contains(f.name)) {
        candidate = _dedupe(f, existing);
        existing.add(candidate.name);
      } else {
        existing.add(f.name);
      }
      accepted.add(candidate);
    }
    state = state.copyWith(files: [...state.files, ...accepted], clearError: true);
  }

  SharedFile _dedupe(SharedFile f, Set<String> taken) {
    final dot = f.name.lastIndexOf('.');
    final stem = dot > 0 ? f.name.substring(0, dot) : f.name;
    final ext = dot > 0 ? f.name.substring(dot) : '';
    var n = 2;
    var name = '$stem ($n)$ext';
    while (taken.contains(name)) {
      n++;
      name = '$stem ($n)$ext';
    }
    return SharedFile(
      id: '${f.id}_$n',
      name: name,
      sizeBytes: f.sizeBytes,
      mime: f.mime,
      localPath: f.localPath,
      state: f.state,
    );
  }

  void removeFile(String id) {
    state = state.copyWith(
      files: state.files.where((f) => f.id != id).toList(),
    );
  }

  void clearFiles() => state = state.copyWith(files: const [], clearShare: true);

  void setTitle(String v) => state = state.copyWith(title: v);

  void setDescription(String v) => state = state.copyWith(description: v);

  void setExpiry(Expiry v) => state = state.copyWith(expiry: v);

  void setPolicy(AccessPolicy v) => state = state.copyWith(policy: v);

  void reset() {
    _sub?.cancel();
    _sub = null;
    _draft = null;
    state = const ShareDraftState();
  }

  // ------------------------------------------------------------- upload

  Future<void> submit() async {
    if (!state.canSubmit) return;

    state = state.copyWith(phase: UploadPhase.uploading, clearError: true);

    try {
      _draft = await _repo.createDraft(
        title: state.title.trim(),
        description: state.description.trim(),
        expiresIn: state.expiry.duration,
        policy: state.policy,
        files: state.files,
      );

      _sub = _repo
          .upload(draft: _draft!, files: state.files)
          .listen(_onProgress, onError: _onError, onDone: _onComplete);
    } catch (e) {
      state = state.copyWith(phase: UploadPhase.failed, errorMessage: '$e');
    }
  }

  void _onProgress(UploadProgress p) {
    final files = state.files.map((f) {
      if (f.id != p.fileId) return f;
      // `verifying` is momentary: once the backend confirms, the file is ready.
      final next = p.state == FileUploadState.verifying
          ? FileUploadState.ready
          : p.state;
      return f.copyWith(state: next, bytesSent: p.bytesSent, clearError: true);
    }).toList();

    state = state.copyWith(files: files);
  }

  void _onError(Object e) {
    state = state.copyWith(phase: UploadPhase.failed, errorMessage: '$e');
  }

  Future<void> _onComplete() async {
    if (state.phase == UploadPhase.cancelled) return;

    state = state.copyWith(phase: UploadPhase.publishing);
    try {
      // PRD §6.4: the client never decides a share is publishable. Even this
      // stub enforces the same precondition the backend will.
      final share = await _repo.finalize(draftId: _draft!.id, files: state.files);
      state = state.copyWith(phase: UploadPhase.done, share: share);
    } catch (e) {
      state = state.copyWith(phase: UploadPhase.failed, errorMessage: '$e');
    }
  }

  void cancel() {
    _sub?.cancel();
    _sub = null;
    state = state.copyWith(
      phase: UploadPhase.cancelled,
      files: state.files
          .map((f) => f.state == FileUploadState.ready
              ? f
              : f.copyWith(state: FileUploadState.cancelled))
          .toList(),
    );
  }

  /// PRD §6.5 / Journey D — resume rather than restart. Files already `ready`
  /// are kept; everything else goes back to `queued`.
  Future<void> retry() async {
    final files = state.files
        .map((f) => f.state == FileUploadState.ready
            ? f
            : f.copyWith(state: FileUploadState.queued, bytesSent: 0, clearError: true))
        .toList();
    state = state.copyWith(files: files, phase: UploadPhase.idle, clearError: true);
    await submit();
  }

  /// PRD §6.5 — a single file can be retried without touching the others.
  void retryFile(String id) {
    state = state.copyWith(
      files: state.files
          .map((f) => f.id == id
              ? f.copyWith(state: FileUploadState.queued, bytesSent: 0, clearError: true)
              : f)
          .toList(),
      clearError: true,
    );
  }
}

final shareRepositoryProvider = Provider<ShareRepository>((ref) {
  return InMemoryShareRepository();
});

final shareDraftProvider =
    NotifierProvider<ShareDraftController, ShareDraftState>(
  ShareDraftController.new,
);

/// Owned shares (PRD §6.9).
final sharesProvider = FutureProvider<List<Share>>((ref) async {
  return ref.watch(shareRepositoryProvider).listShares();
});

final usageProvider = FutureProvider<Usage>((ref) async {
  return ref.watch(shareRepositoryProvider).usage();
});

final transfersProvider = FutureProvider<List<Transfer>>((ref) async {
  return ref.watch(shareRepositoryProvider).history();
});

class ShareActions {
  const ShareActions(this._ref);
  final Ref _ref;

  ShareRepository get _repo => _ref.read(shareRepositoryProvider);

  Future<void> revoke(String id) async {
    await _repo.revoke(id);
    _ref.invalidate(sharesProvider);
    _ref.invalidate(usageProvider);
  }

  Future<void> extend(String id) async {
    await _repo.extend(id, const Duration(days: 7));
    _ref.invalidate(sharesProvider);
  }

  Future<void> refresh() async {
    _ref.invalidate(sharesProvider);
    _ref.invalidate(usageProvider);
    _ref.invalidate(transfersProvider);
  }
}

final shareActionsProvider = Provider<ShareActions>(ShareActions.new);