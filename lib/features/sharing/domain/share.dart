import 'package:equatable/equatable.dart';

/// Lifecycle of a share, as defined in PRD §6.4 / §8.11.
enum ShareStatus {
  /// Files selected, upload not yet finished. Not reachable by recipients.
  uploading,

  /// Backend has verified the upload and issued a link.
  active,

  /// Past its expiry window. Denied.
  expired,

  /// Sender withdrew access. Denied.
  revoked,
}

extension ShareStatusX on ShareStatus {
  bool get isAccessible => this == ShareStatus.active;

  String get label => switch (this) {
        ShareStatus.uploading => 'Uploading',
        ShareStatus.active => 'Active',
        ShareStatus.expired => 'Expired',
        ShareStatus.revoked => 'Revoked',
      };

  String get explanation => switch (this) {
        ShareStatus.uploading => 'Not available until the upload is verified.',
        ShareStatus.active => 'Anyone with the link can open this.',
        ShareStatus.expired => 'This link has passed its expiry and is closed.',
        ShareStatus.revoked => 'Access was withdrawn by the sender.',
      };
}

/// How long a share stays open. Mirrors the options in PRD §6.4 — sensible
/// defaults rather than an exhaustive configuration surface.
enum Expiry {
  oneHour('1 hour'),
  oneDay('24 hours'),
  oneWeek('7 days'),
  thirtyDays('30 days');

  const Expiry(this.label);
  final String label;

  Duration get duration => switch (this) {
        Expiry.oneHour => const Duration(hours: 1),
        Expiry.oneDay => const Duration(days: 1),
        Expiry.oneWeek => const Duration(days: 7),
        Expiry.thirtyDays => const Duration(days: 30),
      };

  static Expiry fromDuration(Duration d) {
    if (d.inHours <= 24) return Expiry.oneDay;
    if (d.inDays <= 7) return Expiry.oneWeek;
    return Expiry.thirtyDays;
  }
}

/// PRD §6.4 access configuration.
class AccessPolicy extends Equatable {
  const AccessPolicy({
    this.passwordRequired = false,
    this.allowDownload = true,
    this.maxDownloads,
  });

  final bool passwordRequired;
  final bool allowDownload;

  /// Null means unlimited.
  final int? maxDownloads;

  bool isDownloadExhausted(int current) =>
      maxDownloads != null && current >= maxDownloads!;

  AccessPolicy copyWith({
    bool? passwordRequired,
    bool? allowDownload,
    int? maxDownloads,
    bool clearMaxDownloads = false,
  }) =>
      AccessPolicy(
        passwordRequired: passwordRequired ?? this.passwordRequired,
        allowDownload: allowDownload ?? this.allowDownload,
        maxDownloads: clearMaxDownloads ? null : (maxDownloads ?? this.maxDownloads),
      );

  @override
  List<Object?> get props => [passwordRequired, allowDownload, maxDownloads];
}

/// An owned share. Fields mirror the `Share` collection in PRD §13.
class Share extends Equatable {
  const Share({
    required this.id,
    required this.slug,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.description = '',
    this.fileCount = 0,
    this.totalBytes = 0,
    this.downloadCount = 0,
    this.policy = const AccessPolicy(),
    this.senderName = '',
  });

  final String id;

  /// Unguessable public identifier embedded in the URL (PRD §6.6).
  final String slug;

  final String title;
  final String description;
  final ShareStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int fileCount;
  final int totalBytes;
  final int downloadCount;
  final AccessPolicy policy;
  final String senderName;

  bool isExpiredAt(DateTime now) => now.isAfter(expiresAt);

  /// Status resolved against the wall clock — an `active` share whose clock has
  /// run out must read as expired everywhere, not just in one screen.
  ShareStatus effectiveStatus(DateTime now) {
    if (status == ShareStatus.active && isExpiredAt(now)) return ShareStatus.expired;
    return status;
  }

  String get url => 'https://linksy.app/s/$slug';

  Share copyWith({
    String? title,
    String? description,
    ShareStatus? status,
    DateTime? expiresAt,
    int? downloadCount,
    AccessPolicy? policy,
  }) =>
      Share(
        id: id,
        slug: slug,
        title: title ?? this.title,
        description: description ?? this.description,
        status: status ?? this.status,
        createdAt: createdAt,
        expiresAt: expiresAt ?? this.expiresAt,
        fileCount: fileCount,
        totalBytes: totalBytes,
        downloadCount: downloadCount ?? this.downloadCount,
        policy: policy ?? this.policy,
        senderName: senderName,
      );

  @override
  List<Object?> get props => [
        id, slug, title, description, status,
        createdAt, expiresAt, fileCount, totalBytes,
        downloadCount, policy, senderName,
      ];
}