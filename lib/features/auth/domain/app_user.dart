import 'package:equatable/equatable.dart';

/// PRD §6.1 / §13 `User`.
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.plan = 'free',
    required this.createdAt,
  });

  final String id;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String plan;
  final DateTime createdAt;

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters2;
    return '${parts.first.characters2}${parts.last.characters2}';
  }

  @override
  List<Object?> get props => [id, displayName, email, photoUrl, plan, createdAt];
}

extension on String {
  /// First character, upper-cased — safe for emoji-free display names.
  String get characters2 =>
      isEmpty ? '' : substring(0, 1).toUpperCase();
}