/// Contract for authentication operations.
/// AuthNotifier depends on this interface — inject a mock in tests.
abstract class AuthRepository {
  /// Emits the current Firebase user on auth state changes.
  /// Emits null when signed out.
  Stream<({String uid, String? email, String? displayName, String? avatarUrl})?> authStateChanges();

  Future<void> signInWithEmail({required String email, required String password});
  Future<void> registerWithEmail({required String email, required String password});
  Future<void> signInWithGoogle();
  Future<void> signOut();
}
