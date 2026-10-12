import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_user.dart';

/// Session state. `loading` exists so the router can hold the splash screen
/// while a stored session is restored, instead of flashing the welcome screen.
enum AuthStatus { loading, signedOut, signedIn }

class AuthState {
  const AuthState({required this.status, this.user});

  final AuthStatus status;
  final AppUser? user;

  bool get isSignedIn => status == AuthStatus.signedIn && user != null;

  AuthState copyWith({AuthStatus? status, AppUser? user}) =>
      AuthState(status: status ?? this.status, user: user ?? this.user);

  @override
  bool operator ==(Object other) =>
      other is AuthState && other.status == status && other.user == user;

  @override
  int get hashCode => Object.hash(status, user);
}

/// Contract for authentication (PRD §6.1). The concrete implementation will be
/// Firebase Auth; nothing in the UI depends on which.
abstract interface class AuthRepository {
  Future<AppUser?> restore();
  Future<AppUser> signIn({required String email, required String password});
  Future<AppUser> register({
    required String email,
    required String password,
    required String displayName,
  });
  Future<void> signOut();
  Future<void> deleteAccount();
}

/// DEVELOPMENT STUB — see the note on `InMemoryShareRepository`.
class LocalAuthRepository implements AuthRepository {
  AppUser? _user;

  @override
  Future<AppUser?> restore() async => _user;

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    if (email.trim().isEmpty || password.isEmpty) {
      throw const AuthFailure('Enter an email and password.');
    }
    if (!email.contains('@')) {
      throw const AuthFailure('That does not look like an email address.');
    }
    return _user = AppUser(
      id: 'local_${email.hashCode.abs()}',
      displayName: _nameFromEmail(email),
      email: email.trim(),
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<AppUser> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (displayName.trim().isEmpty) {
      throw const AuthFailure('Choose a display name.');
    }
    if (password.length < 8) {
      throw const AuthFailure('Use at least 8 characters.');
    }
    return _user = AppUser(
      id: 'local_${email.hashCode.abs()}',
      displayName: displayName.trim(),
      email: email.trim(),
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> signOut() async => _user = null;

  @override
  Future<void> deleteAccount() async => _user = null;

  String _nameFromEmail(String email) {
    final local = email.split('@').first.replaceAll(RegExp(r'[._-]+'), ' ').trim();
    if (local.isEmpty) return 'You';
    return local
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => LocalAuthRepository());

final authProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Restore any existing session; hold in `loading` until it resolves so the
    // router doesn't redirect before we know where to send the user.
    Future.microtask(_restore);
    return const AuthState(status: AuthStatus.loading);
  }

  Future<void> _restore() async {
    final user = await ref.read(authRepositoryProvider).restore();
    state = AuthState(
      status: user == null ? AuthStatus.signedOut : AuthStatus.signedIn,
      user: user,
    );
  }

  Future<void> signIn(String email, String password) async {
    final user = await ref.read(authRepositoryProvider)
        .signIn(email: email, password: password);
    state = AuthState(status: AuthStatus.signedIn, user: user);
  }

  Future<void> register(String email, String password, String name) async {
    final user = await ref.read(authRepositoryProvider)
        .register(email: email, password: password, displayName: name);
    state = AuthState(status: AuthStatus.signedIn, user: user);
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AuthState(status: AuthStatus.signedOut);
  }

  Future<void> deleteAccount() async {
    await ref.read(authRepositoryProvider).deleteAccount();
    state = const AuthState(status: AuthStatus.signedOut);
  }
}