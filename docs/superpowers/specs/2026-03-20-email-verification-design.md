# Email Verification Flow — Design Spec

**Date:** 2026-03-20
**Status:** Approved

## Goal

Enforce mandatory email verification for email/password registrations. Google Sign-In users bypass this step (Google accounts are pre-verified). Unverified users are held at a dedicated screen until they confirm their email.

---

## Architecture

### Layer map

| Layer         | File                                   | Change                                                                                                                |
| ------------- | -------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| Domain        | `auth_repository.dart`                 | Add `emailVerified` to record; add 2 new methods                                                                      |
| Data          | `firebase_auth_repository.dart`        | Implement new methods                                                                                                 |
| State         | `auth_provider.dart`                   | New `AuthStatus.pendingVerification`; update stream mapping; update `register()`; add `reloadAndCheckEmailVerified()` |
| Domain entity | `user_entity.dart`                     | Add `emailVerified` field                                                                                             |
| Router        | `app_router.dart` + `route_names.dart` | Add `/verify-email` route + redirect logic                                                                            |
| UI            | `verify_email_screen.dart`             | New screen                                                                                                            |
| Backend       | `users.service.ts`                     | Ensure `emailVerified` is written on upsert                                                                           |

---

## Domain Layer

### `AuthRepository` — new contract

```dart
abstract class AuthRepository {
  Stream<({
    String uid,
    String? email,
    String? displayName,
    String? avatarUrl,
    bool emailVerified,      // NEW
  })?> authStateChanges();

  Future<void> signInWithEmail({required String email, required String password});
  Future<void> registerWithEmail({required String email, required String password});
  Future<void> signInWithGoogle();
  Future<void> signOut();
  Future<void> sendEmailVerification();      // NEW
  Future<bool> reloadAndCheckEmailVerified(); // NEW — returns current emailVerified after reload
}
```

### `UserEntity` — new field

```dart
class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    this.email,
    this.displayName,
    this.avatarUrl,
    this.emailVerified = false,  // NEW
  });
  final bool emailVerified;
}
```

---

## State Layer

### `AuthStatus` enum

```dart
enum AuthStatus { unknown, authenticated, pendingVerification, unauthenticated }
```

`pendingVerification` means: Firebase user exists, signed in, but `emailVerified == false` and the provider is **not** Google.

### Stream mapping logic

```
firebaseUser == null         → AuthStatus.unauthenticated
firebaseUser.emailVerified   → AuthStatus.authenticated
!firebaseUser.emailVerified  → AuthStatus.pendingVerification
```

Google Sign-In always produces `emailVerified = true` at the Firebase level, so no special-casing needed — the boolean drives the status automatically.

### `AuthState`

```dart
class AuthState {
  final AuthStatus status;
  final String? userId;
  final UserEntity? user;
  final String? error;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isPendingVerification => status == AuthStatus.pendingVerification;
}
```

### `AuthNotifier` changes

- **`register()`** — after `registerWithEmail()` succeeds, calls `sendEmailVerification()`. The stream emits `pendingVerification` automatically because the new account has `emailVerified = false`.
- **`reloadAndCheckEmailVerified()`** — calls `repository.reloadAndCheckEmailVerified()`. If it returns `true`, manually sets `state = AsyncValue.data(state.value!.copyWith(status: AuthStatus.authenticated))` because `authStateChanges()` stream does not re-emit on reload.
- **`sendEmailVerification()`** — delegates to repository; throws on error so the UI can display feedback.

---

## Firebase Implementation

### `sendEmailVerification()`

```dart
await FirebaseAuth.instance.currentUser?.sendEmailVerification();
```

### `reloadAndCheckEmailVerified()`

```dart
await FirebaseAuth.instance.currentUser?.reload();
return FirebaseAuth.instance.currentUser?.emailVerified ?? false;
```

### `authStateChanges()` record

```dart
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
```

---

## Router

### New constant

```dart
// route_names.dart
static const verifyEmail = '/verify-email';
```

### Updated `_publicRoutes`

```dart
const _publicRoutes = {
  RouteNames.splash,
  RouteNames.onboarding,
  RouteNames.login,
  RouteNames.register,
  RouteNames.verifyEmail,   // NEW
};
```

### Redirect logic

```dart
redirect: (context, state) {
  final authStatus = ref.read(authProvider).valueOrNull?.status;
  final loc = state.matchedLocation;
  final isPublic = _publicRoutes.contains(loc);

  if (authStatus == null || authStatus == AuthStatus.unknown) return null;

  if (authStatus == AuthStatus.unauthenticated && !isPublic) {
    return RouteNames.login;
  }
  if (authStatus == AuthStatus.pendingVerification && loc != RouteNames.verifyEmail) {
    return RouteNames.verifyEmail;
  }
  if (authStatus == AuthStatus.authenticated && isPublic) {
    return RouteNames.home;
  }
  return null;
},
```

---

## `VerifyEmailScreen`

**Path:** `lib/features/auth/presentation/screens/verify_email_screen.dart`

**Type:** `ConsumerStatefulWidget`

**State managed locally:** `_resending` (bool), `_checking` (bool), `_message` (String?)

### UI structure

```
AppBar: "Verifica tu email"
Body:
  Icon (email outline, large)
  Title: "Revisa tu bandeja de entrada"
  Subtitle: "Hemos enviado un enlace a {user.email}. Pulsa el enlace y luego vuelve aquí."
  [if _message != null] → info/error text
  SizedBox
  PrimaryButton "Ya lo he verificado"   → _checkVerification()
  OutlinedButton "Reenviar correo"      → _resend()
  TextButton "Cerrar sesión"            → signOut()
```

### `_checkVerification()`

1. Set `_checking = true`
2. Call `ref.read(authProvider.notifier).reloadAndCheckEmailVerified()`
3. If returns `false`: set `_message = "Tu email todavía no está verificado. Revisa tu bandeja de entrada."`
4. Router redirect fires automatically when `authProvider` emits `authenticated`

### `_resend()`

1. Set `_resending = true`
2. Call `ref.read(authProvider.notifier).sendEmailVerification()`
3. On success: set `_message = "Correo reenviado."`
4. On error: set `_message = error.toString()`

---

## Backend

**File:** `apps/backend/src/modules/users/services/users.service.ts`

`findOrCreateFromFirebase()` already does an upsert from `decodedToken`. Add `emailVerified` to the upsert data:

```typescript
await this.prisma.user.upsert({
  where: { providerUid: decodedToken.uid },
  update: {
    displayName: decodedToken.name,
    email: decodedToken.email,
    emailVerified: decodedToken.email_verified ?? false,  // ENSURE THIS EXISTS
  },
  create: { ... emailVerified: decodedToken.email_verified ?? false ... },
});
```

---

## Files changed

### New

- `apps/mobile/lib/features/auth/presentation/screens/verify_email_screen.dart`

### Modified (Flutter)

- `apps/mobile/lib/features/auth/domain/repositories/auth_repository.dart`
- `apps/mobile/lib/features/auth/data/repositories/firebase_auth_repository.dart`
- `apps/mobile/lib/features/auth/domain/entities/user_entity.dart`
- `apps/mobile/lib/features/auth/application/providers/auth_provider.dart`
- `apps/mobile/lib/app/router/route_names.dart`
- `apps/mobile/lib/app/router/app_router.dart`
- `apps/mobile/test/unit/features/auth/auth_provider_test.dart`
- `apps/mobile/test/helpers/mock_providers.dart`

### Modified (Backend)

- `apps/backend/src/modules/users/services/users.service.ts`

---

## Test plan

- Unit: `AuthStatus.pendingVerification` emitted when stream returns `emailVerified: false`
- Unit: `AuthStatus.authenticated` emitted when stream returns `emailVerified: true`
- Unit: `reloadAndCheckEmailVerified()` forces state to `authenticated` when repository returns `true`
- Unit: `register()` calls `sendEmailVerification()` after account creation
- Manual: register → lands on `/verify-email` → click "Ya lo he verificado" without verifying → message shown → verify email → click again → redirected to `/home`
- Manual: Google Sign-In → goes directly to `/home` (no verify screen)
- Manual: Sign in with unverified account → lands on `/verify-email`
