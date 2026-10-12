import 'package:equatable/equatable.dart';

/// PRD §6.10 — transfer history entries.
enum TransferDirection { sent, received }

enum TransferStatus {
  queued,
  active,
  complete,
  failed,
  cancelled,
}

extension TransferStatusX on TransferStatus {
  String get label => switch (this) {
        TransferStatus.queued => 'Queued',
        TransferStatus.active => 'Transferring',
        TransferStatus.complete => 'Complete',
        TransferStatus.failed => 'Failed',
        TransferStatus.cancelled => 'Cancelled',
      };
}

class Transfer extends Equatable {
  const Transfer({
    required this.id,
    required this.name,
    required this.direction,
    required this.status,
    required this.startedAt,
    this.sizeBytes = 0,
    this.bytesTransferred = 0,
    this.failureReason,
    this.shareSlug,
  });

  final String id;
  final String name;
  final TransferDirection direction;
  final TransferStatus status;
  final DateTime startedAt;
  final int sizeBytes;
  final int bytesTransferred;
  final String? failureReason;
  final String? shareSlug;

  double get progress =>
      sizeBytes <= 0 ? 0 : (bytesTransferred / sizeBytes).clamp(0.0, 1.0);

  Transfer copyWith({
    TransferStatus? status,
    int? bytesTransferred,
    String? failureReason,
    bool clearFailure = false,
  }) =>
      Transfer(
        id: id,
        name: name,
        direction: direction,
        status: status ?? this.status,
        startedAt: startedAt,
        sizeBytes: sizeBytes,
        bytesTransferred: bytesTransferred ?? this.bytesTransferred,
        failureReason: clearFailure ? null : (failureReason ?? this.failureReason),
        shareSlug: shareSlug,
      );

  @override
  List<Object?> get props =>
      [id, name, direction, status, startedAt, sizeBytes, bytesTransferred, failureReason];
}

/// PRD §6.11 — the private Link Vault.
enum VaultKind { url, note, file }

class VaultItem extends Equatable {
  const VaultItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.content,
    required this.createdAt,
    this.tags = const [],
  });

  final String id;
  final VaultKind kind;
  final String title;
  final String content;
  final DateTime createdAt;
  final List<String> tags;

  VaultItem copyWith({
    String? title,
    String? content,
    List<String>? tags,
  }) =>
      VaultItem(
        id: id,
        kind: kind,
        title: title ?? this.title,
        content: content ?? this.content,
        createdAt: createdAt,
        tags: tags ?? this.tags,
      );

  @override
  List<Object?> get props => [id, kind, title, content, createdAt, tags];
}