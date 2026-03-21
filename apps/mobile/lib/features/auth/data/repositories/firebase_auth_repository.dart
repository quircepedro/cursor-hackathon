import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Stream<({
    String uid,
    String? email,
    String? displayName,
    String? avatarUrl,
    bool emailVerified,
  })?>
      authStateChanges() {
    return _auth.authStateChanges().map((user) {
      if (user == null) return null;
      return (
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        avatarUrl: user.photoURL,
        emailVerified: user.emailVerified,
      );
    });
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> registerWithEmail({
    required String email,
    required String password,
  }) async {
    await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> signInWithGoogle() async {
    final account = await GoogleSignIn.instance.authenticate();
    final credential = GoogleAuthProvider.credential(
      idToken: account.authentication.idToken,
    );
    await _auth.signInWithCredential(credential);
  }

  @override
  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }

  @override
  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  @override
  Future<bool> reloadAndCheckEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
