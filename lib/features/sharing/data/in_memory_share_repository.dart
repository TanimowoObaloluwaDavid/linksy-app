import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../transfers/domain/transfer.dart';
import '../domain/share.dart';
import '../domain/share_repository.dart';
import '../domain/shared_file.dart';

/// DEVELOPMENT STUB — not production behaviour.
///
/// The PRD requires a Firebase/Cloud-Functions backend that verifies uploads
/// server-side. No Firebase project is configured for this build, so this
/// in-memory implementation stands in for it. It is intentionally explicit
/// about that: it simulates progress locally and holds shares in RAM.
///
/// It is **not** a silent substitution for real backend logic — it implements
/// the same interface the HTTP client will, so swapping it is a one-line
/// provider change and nothing in the presentation layer moves.
///
/// What this stub must never become: the thing that decides a share is
/// valid. [finalize] here is a local shortcut standing in for server
/// verification.
class InMemoryShareRepository implements ShareRepository {
  InMemoryShareRepository({@visibleForTesting Random? random})
      : _random = random ?? Random();

  final Random _random;

  final List<Share> _shares = <Share>[];
  final List<Transfer> _history = <Transfer>[];

  int _usedBytes = 0;
  int _activeCount = 0;

  /// Simulated throughput so progress looks like a real transfer rather than an
  /// instant jump — the UI must be exercised under moving values.
  @visibleForTesting
  int bytesPerTick = 220 * 1024;

  @visibleForTesting
  Duration tickInterval = const Duration(milliseconds: 55);

  /// Unpredictable public identifiers (PRD §6.6).
  String _slug() {
    const alphabet = 'abcdefghijkmnpqrstuvwxyz23456789';
    return List.generate(12, (_) => alphabet[_random.nextInt(alphabet.length)])
        .join();
  }

  @override
  Future<ShareDraft> createDraft({
    required String title,
    required String description,
    required Duration expiresIn,
    required AccessPolicy policy,
    required List<SharedFile> files,
  }) async {
    // PRD §6.3 / §6.4: reject invalid selections before anything is uploaded.
    if (files.isEmpty) {
      throw ArgumentError('A share needs at least one file.');
    }
    final now = DateTime.now();
    return ShareDraft(id: 'draft_${_random.nextInt(1 << 32)}', slug: _slug(), createdAt: now);
  }

  @override
  Stream<UploadProgress> upload({
    required ShareDraft draft,
    required List<SharedFile> files,
    Future<void> Function()? cancelSignal,
  }) {
    // Files are uploaded one at a time. Deterministic per-file ordering is what
    // makes the per-file progress list readable rather than a blur, and it is
    // what makes resumption (PRD §6.5) meaningful: completed files are skipped.
    late final StreamController<UploadProgress> controller;
    Timer? timer;
    var next = 0;
    var sent = 0;
    var stopped = false;

    void stop() {
      if (stopped) return;
      stopped = true;
      timer?.cancel();
      timer = null;
    }

    controller = StreamController<UploadProgress>(
      // Unsubscribing is the cancel path for this stub.
      onCancel: stop,
      onListen: () {
        timer = Timer.periodic(tickInterval, (_) {
          if (stopped) return;
          if (next >= files.length) {
            stop();
            unawaited(controller.close());
            return;
          }
          final file = files[next];
          sent += bytesPerTick;
          final done = sent >= file.sizeBytes;
          controller.add(UploadProgress(
            fileId: file.id,
            bytesSent: done ? file.sizeBytes : sent,
            state: done ? FileUploadState.verifying : FileUploadState.uploading,
          ));
          if (done) {
            next++;
            sent = 0;
          }
        });
      },
    );

    // `cancelSignal` is honoured by the real HTTP repository, which can abort
    // an in-flight request. A local timer has nothing to abort, so unsubscribing
    // is the equivalent action here.
    return controller.stream;
  }

  @override
  Future<Share> finalize({required String draftId, required List<SharedFile> files}) async {
    final now = DateTime.now();
    final total = files.fold<int>(0, (a, f) => a + f.sizeBytes);

    // Stand-in for server verification: refuse to publish unless every file
    // actually reached `ready`. A real build gets this from the backend.
    final notReady = files.where((f) => f.state != FileUploadState.ready);
    if (notReady.isNotEmpty) {
      throw StateError(
        'Cannot publish: ${notReady.length} file(s) not verified.',
      );
    }

    final share = Share(
      id: draftId,
      slug: _slug(),
      title: files.length == 1 ? files.first.name : '${files.length} files',
      status: ShareStatus.active,
      createdAt: now,
      expiresAt: now.add(const Duration(days: 7)),
      fileCount: files.length,
      totalBytes: total,
      policy: const AccessPolicy(),
      senderName: 'You',
    );

    _shares.insert(0, share);
    _usedBytes += total;
    _activeCount++;

    for (final f in files) {
      _history.insert(
        0,
        Transfer(
          id: 'tr_${_random.nextInt(1 << 32)}',
          name: f.name,
          direction: TransferDirection.sent,
          status: TransferStatus.complete,
          startedAt: now,
          sizeBytes: f.sizeBytes,
          bytesTransferred: f.sizeBytes,
          shareSlug: share.slug,
        ),
      );
    }
    return share;
  }

  @override
  Future<List<Share>> listShares() async => List.unmodifiable(_shares);

  @override
  Future<Share?> getShare(String slug) async {
    for (final s in _shares) {
      if (s.slug == slug) return s;
    }
    return null;
  }

  @override
  Future<Share> revoke(String shareId) async {
    final i = _shares.indexWhere((s) => s.id == shareId);
    if (i < 0) throw StateError('Share not found.');
    final updated = _shares[i].copyWith(status: ShareStatus.revoked);
    _shares[i] = updated;
    _activeCount = (_activeCount - 1).clamp(0, 1 << 30);
    return updated;
  }

  @override
  Future<Share> extend(String shareId, Duration extra) async {
    final i = _shares.indexWhere((s) => s.id == shareId);
    if (i < 0) throw StateError('Share not found.');
    final updated = _shares[i].copyWith(
      status: ShareStatus.active,
      expiresAt: _shares[i].expiresAt.add(extra),
    );
    _shares[i] = updated;
    return updated;
  }

  @override
  Future<Usage> usage() async => Usage(
        usedBytes: _usedBytes,
        quotaBytes: 2 * 1024 * 1024 * 1024,
        activeShares: _activeCount,
        shareLimit: 10,
        maxFileBytes: 500 * 1024 * 1024,
      );

  @override
  Future<List<Transfer>> history() async => List.unmodifiable(_history);

  /// Test seam: seed a share so screens can be exercised without an upload.
  @visibleForTesting
  void seed(Share share) => _shares.insert(0, share);
}