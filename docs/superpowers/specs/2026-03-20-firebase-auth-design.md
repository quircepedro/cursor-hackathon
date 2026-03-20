# Firebase Auth — Design Spec

**Date:** 2026-03-20
**Status:** Approved
**Scope:** End-to-end authentication with Firebase Auth in Flutter + NestJS

---

## 1. Goals

Implement complete authentication using Firebase Auth as the single source of identity:

- Email/password sign-in and registration
- Google Sign-In
- Session persistence via Firebase SDK (not custom token storage)
- Backend verifies Firebase ID tokens, maintains an internal User record, and protects endpoints
- No passwords or refresh tokens stored in our database

---

## 2. Architecture

```
Flutter App
  │  FirebaseAuth SDK  ←── email/password + Google Sign-In
  │         │
  │    ID Token (short-lived JWT signed by Firebase)
  │         │
  ▼         ▼
  AuthRepository (abstract) ──► NestJS API
  FirebaseAuthRepository (impl)     │
                              FirebaseAuthGuard
                                    │  verifyIdToken() via Admin SDK
                                    ▼
                              UsersService.findOrCreateFromFirebase()
                                    │  upsert by providerUid
                                    ▼
                              User record in PostgreSQL
```

**Key constraint:** Firebase is the sole identity provider. The backend never stores passwords, never issues its own tokens, and never matches users by email.

---

## 3. Database — Prisma Schema Changes

### User model (final)

```prisma
model User {
  id             String   @id @default(cuid())
  providerUid    String   @unique          // Firebase UID — primary identity key
  authProvider   String   @default("firebase")
  email          String?                   // optional; updated when Firebase provides it
  emailVerified  Boolean  @default(false)  // mapped from decoded token
  displayName    String?
  profilePicture String?
  bio            String?
  createdAt      DateTime @default(now())
  updatedAt      DateTime @updatedAt

  recordings     Recording[]
  notifications  Notification[]

  @@index([createdAt])
}
```

Notes:

- `providerUid @unique` implicitly creates a Postgres B-tree index — no additional `@@index([providerUid])` needed
- `@@index([createdAt])` is retained for user listing/pagination queries
- `@@index([email])` is removed — email is not a lookup key

### Removed

- `password String` field
- `RefreshToken` model and its `User` relation

### Identity logic

- **Lookup key:** `providerUid` always. Never match by email.
- **Email:** saved and updated on every auth if Firebase provides it. Never used as lookup.
- **emailVerified:** always mapped from the decoded Firebase token for product/audit use.

---

## 4. Backend — NestJS

### New dependency

```bash
npm install firebase-admin --workspace=apps/backend
```

### New files

```
src/
  config/firebase.config.ts
  modules/firebase/
    firebase.module.ts            (global module)
    firebase.service.ts           (wraps admin.auth().verifyIdToken())
  modules/auth/
    guards/firebase-auth.guard.ts
    decorators/current-user.decorator.ts
```

### Modified files

| File                                          | Change                                                                                      |
| --------------------------------------------- | ------------------------------------------------------------------------------------------- |
| `prisma/schema.prisma`                        | Remove password + RefreshToken; update User model as above                                  |
| `config/jwt.config.ts`                        | **Delete entirely** — JWT is no longer issued by this backend                               |
| `config/configuration.ts`                     | Remove `import jwtConfig` and remove `jwt: jwtConfig()` from the aggregated config          |
| `package.json` (backend)                      | Remove `@nestjs/jwt`, `@nestjs/passport`, `passport`, `passport-jwt`, `@types/passport-jwt` |
| `modules/users/services/users.service.ts`     | Add `findOrCreateFromFirebase()`                                                            |
| `modules/users/users.module.ts`               | Export UsersService                                                                         |
| `modules/auth/auth.module.ts`                 | Import FirebaseModule, UsersModule; register FirebaseAuthGuard as exported guard            |
| `modules/auth/controllers/auth.controller.ts` | No change — keep existing health endpoint                                                   |
| `modules/auth/services/auth.service.ts`       | No change                                                                                   |
| `app.module.ts`                               | Import FirebaseModule                                                                       |
| `.env.example`                                | Remove JWT vars; add Firebase Admin vars                                                    |

### FirebaseModule

Global NestJS module. Initializes `firebase-admin` once at startup using a service account loaded from environment variables.

```
FIREBASE_PROJECT_ID
FIREBASE_CLIENT_EMAIL
FIREBASE_PRIVATE_KEY   (PEM key with literal "\n" sequences in the env var)
```

**Important:** The private key stored in `.env` uses `\n` as literal characters. The module must parse it:

```typescript
privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
```

`FirebaseService.verifyIdToken(token: string)` returns `admin.auth.DecodedIdToken` or throws `UnauthorizedException`.

### FirebaseAuthGuard

Applied per-endpoint with `@UseGuards(FirebaseAuthGuard)`.

1. Extract `Bearer <token>` from `Authorization` header → 401 if missing
2. Call `firebaseService.verifyIdToken(token)` → 401 if invalid/expired
3. Call `usersService.findOrCreateFromFirebase(decodedToken)` → upsert by `providerUid`
4. Attach result to `request.user`

### UsersService.findOrCreateFromFirebase()

```typescript
// Pseudocode
async findOrCreateFromFirebase(decoded: DecodedIdToken): Promise<User> {
  return prisma.user.upsert({
    where: { providerUid: decoded.uid },
    update: {
      email: decoded.email ?? undefined,
      emailVerified: decoded.email_verified ?? false,
      displayName: decoded.name ?? undefined,
      profilePicture: decoded.picture ?? undefined,
    },
    create: {
      providerUid: decoded.uid,
      authProvider: 'firebase',
      email: decoded.email ?? null,
      emailVerified: decoded.email_verified ?? false,
      displayName: decoded.name ?? null,
      profilePicture: decoded.picture ?? null,
    },
  });
}
```

### @CurrentUser() decorator

Parameter decorator that returns `request.user` (the internal `User` from Postgres). Usage: `@CurrentUser() user: User`.

### Environment variables

Remove from `.env.example`:

```
JWT_SECRET
JWT_EXPIRY
JWT_REFRESH_SECRET
JWT_REFRESH_EXPIRY
```

Add to `.env.example`:

```
FIREBASE_PROJECT_ID=
FIREBASE_CLIENT_EMAIL=
FIREBASE_PRIVATE_KEY=
```

---

## 5. Flutter

### New dependencies (pubspec.yaml)

```yaml
firebase_core: ^3.x
firebase_auth: ^5.x
google_sign_in: ^6.1.0 # minimum 6.1.0 for firebase_auth ^5.x compatibility
```

`flutter_secure_storage` is **not** added — Firebase SDK handles session persistence natively via platform-native secure storage.

### New files

```
lib/
  firebase_options.dart                                    ← generated by flutterfire configure
  features/auth/
    domain/repositories/auth_repository.dart              ← abstract contract
    data/repositories/firebase_auth_repository.dart       ← Firebase implementation
```

**`firebase_options.dart`:** Generated by running `flutterfire configure` with the Firebase project. This file contains platform API keys and must **always** be added to `.gitignore` regardless of repo visibility. Commit a `firebase_options.dart.example` template with placeholder values instead.

### New dependency

```bash
cd apps/mobile && flutter pub add firebase_core firebase_auth google_sign_in
```

### Modified files

| File                                                      | Change                                                                                                |
| --------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| `bootstrap.dart`                                          | Add `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` before `runApp()` |
| `features/auth/domain/entities/user_entity.dart`          | Make `email` optional: `final String? email`                                                          |
| `features/auth/application/providers/auth_provider.dart`  | Full rewrite — see AuthNotifier section below                                                         |
| `features/auth/presentation/screens/login_screen.dart`    | Wire to AuthNotifier; add Google Sign-In button                                                       |
| `features/auth/presentation/screens/register_screen.dart` | Wire to AuthNotifier                                                                                  |
| `app/router/app_router.dart`                              | Add redirect guard (see below)                                                                        |
| `core/network/interceptors/auth_interceptor.dart`         | Remove StorageService; inject Dio; get token from FirebaseAuth (see below)                            |
| `core/network/api_client.dart`                            | Pass `dio` instance to `AuthInterceptor(dio)` constructor                                             |
| `.gitignore` (mobile)                                     | Add `apps/mobile/lib/firebase_options.dart`                                                           |

### AuthState (updated)

Remove `accessToken` field — tokens are always fetched on demand from `FirebaseAuth.instance.currentUser?.getIdToken()`. Do not cache them in state.

```dart
class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.userId,
    this.user,       // UserEntity — populated when authenticated
    this.error,
  });

  final AuthStatus status;
  final String? userId;
  final UserEntity? user;
  final String? error;
}
```

### AuthNotifier — Riverpod pattern

Use `StreamNotifier<AuthState>` (available since Riverpod 2.1). `build()` returns a `Stream<AuthState>` derived from `FirebaseAuth.instance.authStateChanges()`. This is the correct pattern for maintaining a live subscription — `AsyncNotifier` with a `Future<AuthState> build()` cannot maintain a live stream.

```dart
class AuthNotifier extends StreamNotifier<AuthState> {
  @override
  Stream<AuthState> build() {
    return FirebaseAuth.instance.authStateChanges().map((firebaseUser) {
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
          avatarUrl: firebaseUser.photoURL,
        ),
      );
    });
  }

  Future<void> signIn({required String email, required String password}) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email, password: password,
    );
    // authStateChanges() stream updates state automatically — no manual setState
  }

  Future<void> register({required String email, required String password}) async {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email, password: password,
    );
    // stream updates state automatically
  }

  Future<void> signInWithGoogle() async {
    final googleUser = await GoogleSignIn(scopes: ['email']).signIn();
    if (googleUser == null) return; // user cancelled
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await FirebaseAuth.instance.signInWithCredential(credential);
    // stream updates state automatically
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut(); // no-op if not signed in via Google
    await FirebaseAuth.instance.signOut();
    // stream emits null → unauthenticated
  }
}

final authProvider = StreamNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
```

### AuthInterceptor (updated)

Remove `StorageService` dependency entirely. On each request, get a fresh token from the Firebase SDK (which handles caching and proactive refresh automatically — tokens are refreshed when within 5 minutes of their 60-minute expiry).

On 401, force-refresh the token and retry the request once. This handles edge cases like clock skew or server-side token revocation. If the retry also returns 401, propagate the error — `authStateChanges()` will handle the session if Firebase itself revokes the session.

```dart
class AuthInterceptor extends Interceptor {
  // Requires the app's configured Dio instance for retry (not a bare Dio())
  // so all interceptors, base URL, and timeouts are preserved on the retry request.
  AuthInterceptor(this._dio);
  final Dio _dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Force-refresh token and retry once via the configured Dio instance.
      // This handles edge cases like clock skew or server-side token revocation.
      final token = await FirebaseAuth.instance.currentUser?.getIdToken(true);
      if (token != null) {
        final retryOptions = err.requestOptions
          ..headers['Authorization'] = 'Bearer $token';
        try {
          final response = await _dio.fetch(retryOptions);
          return handler.resolve(response);
        } catch (_) {
          // fall through to propagate original error
        }
      }
    }
    handler.next(err);
  }
}
```

### Router redirect guard

```dart
redirect: (context, state) {
  // ref.read is correct here — redirect is re-evaluated every time the Provider
  // rebuilds, which is triggered by the ref.watch(authProvider) in routerProvider
  // below. Do NOT add ref.watch here; that would cause an infinite rebuild loop.
  final authStatus = ref.read(authProvider).valueOrNull?.status;
  final isPublic = {
    RouteNames.splash,
    RouteNames.login,
    RouteNames.register,
    RouteNames.onboarding,
  }.contains(state.matchedLocation);

  if (authStatus == null || authStatus == AuthStatus.unknown) return null; // wait
  if (authStatus == AuthStatus.unauthenticated && !isPublic) return RouteNames.login;
  if (authStatus == AuthStatus.authenticated && isPublic) return RouteNames.home;
  return null;
},
```

The `routerProvider` must `ref.watch(authProvider)` so it rebuilds (and re-evaluates the redirect) whenever auth state changes. The `redirect` callback above uses `ref.read` — this is intentional and correct:

```dart
final routerProvider = Provider<GoRouter>((ref) {
  ref.watch(authProvider); // causes routerProvider to rebuild on auth state change
  return GoRouter(
    redirect: (context, state) { /* ... uses ref.read, see above */ },
    routes: [...],
  );
});
```

---

## 6. Data Flow — Token Lifecycle

```
1. User signs in via Firebase SDK (email/password or Google)
2. Firebase SDK stores session locally (platform-native secure storage)
3. authStateChanges() emits FirebaseUser → AuthNotifier (StreamNotifier) updates state
4. Router redirect fires → navigates to /home
5. API call triggered → AuthInterceptor.onRequest() calls getIdToken()
   - Firebase SDK returns cached token if it will not expire within 5 minutes
   - Firebase SDK silently refreshes using platform refresh token if near expiry
6. NestJS receives Bearer token → FirebaseAuthGuard verifies → upserts User
7. Endpoint executes with @CurrentUser()
8. On sign-out: FirebaseAuth.signOut() clears SDK session → authStateChanges() emits null
   → StreamNotifier maps to unauthenticated → router redirects to /login
```

---

## 7. What the User Must Do Manually

Firebase requires native platform configuration that cannot be automated:

1. **Create Firebase project** at console.firebase.google.com
2. **Enable Auth providers:** Email/Password + Google
3. **Register iOS app** → download `GoogleService-Info.plist` → place in `apps/mobile/ios/Runner/`
4. **Register Android app** → download `google-services.json` → place in `apps/mobile/android/app/`
5. **Run `flutterfire configure`** in `apps/mobile/` → generates `lib/firebase_options.dart`
6. **Generate service account key** (Project Settings → Service Accounts) → extract values into `.env`

These steps are documented in `docs/firebase-setup.md` (to be created during implementation).

---

## 8. Out of Scope

- Email verification flow (send/check verification email)
- Password reset flow
- Anonymous auth
- Phone auth
- Multi-factor authentication
- JWT issued by our own backend
- Refresh token management (handled entirely by Firebase SDK)
