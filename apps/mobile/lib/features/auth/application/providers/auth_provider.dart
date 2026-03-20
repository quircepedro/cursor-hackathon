import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/storage_service.dart';

// ─── State ───────────────────────────────────────────────────────────────────

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.userId,
    this.accessToken,
    this.error,
  });

  final AuthStatus status;
  final String? userId;
  final String? accessToken;
  final String? error;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    String? userId,
    String? accessToken,
    String? error,
  }) =>
      AuthState(
        status: status ?? this.status,
        userId: userId ?? this.userId,
        accessToken: accessToken ?? this.accessToken,
        error: error,
      );
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    return _checkSession();
  }

  Future<AuthState> _checkSession() async {
    final token = await StorageService.instance.getAccessToken();
    final userId = await StorageService.instance.getUserId();
    if (token != null && userId != null) {
      return AuthState(
        status: AuthStatus.authenticated,
        userId: userId,
        accessToken: token,
      );
    }
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Sign in with email and password.
  /// TODO: wire to AuthRepository once implemented.
  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      // Placeholder — real implementation will call AuthRepository
      await Future<void>.delayed(const Duration(milliseconds: 800));
      await StorageService.instance.setAccessToken('placeholder_token');
      await StorageService.instance.setUserId('placeholder_user_id');
      state = const AsyncValue.data(
        AuthState(
          status: AuthStatus.authenticated,
          userId: 'placeholder_user_id',
          accessToken: 'placeholder_token',
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    await StorageService.instance.clearTokens();
    state = const AsyncValue.data(AuthState(status: AuthStatus.unauthenticated));
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
