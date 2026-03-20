import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

// ─── Repository provider ──────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(),
);

// ─── State ───────────────────────────────────────────────────────────────────

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.userId,
    this.user,
    this.error,
  });

  final AuthStatus status;
  final String? userId;
  final UserEntity? user;
  final String? error;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    String? userId,
    UserEntity? user,
    String? error,
  }) =>
      AuthState(
        status: status ?? this.status,
        userId: userId ?? this.userId,
        user: user ?? this.user,
        error: error,
      );
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class AuthNotifier extends StreamNotifier<AuthState> {
  @override
  Stream<AuthState> build() {
    return ref.watch(authRepositoryProvider).authStateChanges().map((firebaseUser) {
      if (firebaseUser == null) {
        return const AuthState(status: AuthStatus.unauthenticated);
      }
      return AuthState(
        status: AuthStatus.authenticated,
        userId: firebaseUser.uid,
        user: UserEntity(
          id: firebaseUser.uid,
          email: firebaseUser.email,
          displayName: firebaseUser.displayName,
          avatarUrl: firebaseUser.avatarUrl,
        ),
      );
    });
  }

  Future<void> signIn({required String email, required String password}) async {
    await ref.read(authRepositoryProvider).signInWithEmail(
          email: email,
          password: password,
        );
    // authStateChanges() stream updates state automatically
  }

  Future<void> register({required String email, required String password}) async {
    await ref.read(authRepositoryProvider).registerWithEmail(
          email: email,
          password: password,
        );
  }

  Future<void> signInWithGoogle() async {
    await ref.read(authRepositoryProvider).signInWithGoogle();
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
  }
}

final authProvider = StreamNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
