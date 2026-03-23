import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../recording/application/providers/recording_provider.dart';

// ─── Repository provider ──────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(),
);

// ─── State ───────────────────────────────────────────────────────────────────

enum AuthStatus { unknown, authenticated, pendingVerification, unauthenticated }

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
  bool get isPendingVerification => status == AuthStatus.pendingVerification;

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
  String? _lastUserId;

  @override
  Stream<AuthState> build() {
    return ref.watch(authRepositoryProvider).authStateChanges().map((firebaseUser) {
      final nextUserId = firebaseUser?.uid;
      if (_lastUserId != nextUserId) {
        _lastUserId = nextUserId;
        // Ensure account-scoped recording state is cleared when switching users.
        ref.invalidate(todayRecordingProvider);
        ref.read(recordingProvider.notifier).reset();
      }

      if (firebaseUser == null) {
        return const AuthState(status: AuthStatus.unauthenticated);
      }
      final user = UserEntity(
        id: firebaseUser.uid,
        email: firebaseUser.email,
        displayName: firebaseUser.displayName,
        avatarUrl: firebaseUser.avatarUrl,
        emailVerified: firebaseUser.emailVerified,
      );
      final status = firebaseUser.emailVerified
          ? AuthStatus.authenticated
          : AuthStatus.pendingVerification;
      return AuthState(status: status, userId: firebaseUser.uid, user: user);
    });
  }

  Future<void> signIn({required String email, required String password}) async {
    await ref.read(authRepositoryProvider).signInWithEmail(
          email: email,
          password: password,
        );
  }

  Future<void> register({required String email, required String password}) async {
    await ref.read(authRepositoryProvider).registerWithEmail(
          email: email,
          password: password,
        );
    // Send verification email immediately after account creation
    await ref.read(authRepositoryProvider).sendEmailVerification();
  }

  Future<void> signInWithGoogle() async {
    await ref.read(authRepositoryProvider).signInWithGoogle();
  }

  Future<void> signOut() async {
    ref.invalidate(todayRecordingProvider);
    ref.read(recordingProvider.notifier).reset();
    await ref.read(authRepositoryProvider).signOut();
  }

  Future<void> sendEmailVerification() async {
    await ref.read(authRepositoryProvider).sendEmailVerification();
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    await ref.read(authRepositoryProvider).sendPasswordResetEmail(email: email);
  }

  /// Reloads the Firebase user and updates state if now verified.
  /// Returns true if the user is now verified.
  Future<bool> reloadAndCheckEmailVerified() async {
    final verified = await ref.read(authRepositoryProvider).reloadAndCheckEmailVerified();
    if (verified && state.value != null) {
      state = AsyncValue.data(
        state.value!.copyWith(
          status: AuthStatus.authenticated,
          user: state.value!.user?.emailVerified == false
              ? UserEntity(
                  id: state.value!.user!.id,
                  email: state.value!.user!.email,
                  displayName: state.value!.user!.displayName,
                  avatarUrl: state.value!.user!.avatarUrl,
                  emailVerified: true,
                )
              : state.value!.user,
        ),
      );
      // Force the stream to re-emit the updated state
      state = AsyncValue.data(state.value!);
    }
    return verified;
  }
}

final authProvider = StreamNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
