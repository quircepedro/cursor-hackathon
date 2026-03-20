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

  @@index([providerUid])
}
```

### Removed

- `password String` field
- `RefreshToken` model and its `User` relation

### Identity logic

- **Lookup key:** `providerUid` always. Never match by email.
- **Email:** saved and updated on every auth if Firebase provides it. Never used as lookup.
- **emailVerified:** always mapped from the decoded Firebase token for product/audit use.

---

## 4. Backend — NestJS

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

| File                                      | Change                                                         |
| ----------------------------------------- | -------------------------------------------------------------- |
| `prisma/schema.prisma`                    | Remove password + RefreshToken; add providerUid, emailVerified |
| `modules/users/services/users.service.ts` | Add findOrCreateFromFirebase()                                 |
| `modules/users/users.module.ts`           | Export UsersService                                            |
| `modules/auth/auth.module.ts`             | Import FirebaseModule, UsersModule; register guard             |
| `app.module.ts`                           | Import FirebaseModule                                          |
| `.env.example`                            | Add Firebase Admin env vars                                    |

### FirebaseModule

Global NestJS module. Initializes `firebase-admin` once using a service account loaded from environment variables:

```
FIREBASE_PROJECT_ID
FIREBASE_CLIENT_EMAIL
FIREBASE_PRIVATE_KEY   (newline-encoded: "-----BEGIN PRIVATE KEY-----\n...")
```

`FirebaseService.verifyIdToken(token: string)` → returns `admin.auth.DecodedIdToken` or throws `UnauthorizedException`.

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

### Environment variables (new)

```env
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
google_sign_in: ^6.x
```

`flutter_secure_storage` is **not** added — Firebase SDK handles session persistence natively.

### New files

```
lib/
  firebase_options.dart                                    ← template; user fills values
  features/auth/
    domain/repositories/auth_repository.dart              ← abstract contract
    data/repositories/firebase_auth_repository.dart       ← Firebase implementation
```

### Modified files

| File                                                      | Change                                                                              |
| --------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| `bootstrap.dart`                                          | Add `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` |
| `features/auth/application/providers/auth_provider.dart`  | Replace stub with authStateChanges() stream; add signInWithGoogle(); add register() |
| `features/auth/presentation/screens/login_screen.dart`    | Wire to AuthNotifier; add Google Sign-In button                                     |
| `features/auth/presentation/screens/register_screen.dart` | Wire to AuthNotifier                                                                |
| `app/router/app_router.dart`                              | Add redirect guard                                                                  |
| `core/network/interceptors/auth_interceptor.dart`         | Get fresh ID token from FirebaseAuth                                                |

### AuthNotifier (new implementation)

**Source of truth:** `FirebaseAuth.instance.authStateChanges()` stream — no manual token storage.

```
build() → listen to authStateChanges()
  null  → AuthState(status: unauthenticated)
  User  → AuthState(status: authenticated, userId: user.uid, user: UserEntity(...))

signIn(email, password) → FirebaseAuth.signIn() → stream updates state
signInWithGoogle() → GoogleSignIn.signIn() → GoogleAuthProvider → FirebaseAuth.signIn()
register(email, password) → FirebaseAuth.createUser()
signOut() → FirebaseAuth.signOut() (+ GoogleSignIn.signOut() if Google session)
```

`AuthState` is updated reactively via stream — callers do not need to update state manually after sign-in.

### AuthInterceptor (updated)

On every outgoing request:

```dart
final token = await FirebaseAuth.instance.currentUser?.getIdToken();
if (token != null) {
  options.headers['Authorization'] = 'Bearer $token';
}
```

Firebase SDK handles token refresh automatically (tokens expire every 1h; `getIdToken()` returns a fresh one transparently).

### Router redirect guard

```dart
redirect: (context, state) {
  final authStatus = ref.read(authProvider).valueOrNull?.status;
  final isPublic = ['/login', '/register', '/onboarding', '/'].contains(state.matchedLocation);

  if (authStatus == AuthStatus.unknown) return null; // wait for splash
  if (authStatus == AuthStatus.unauthenticated && !isPublic) return '/login';
  if (authStatus == AuthStatus.authenticated && isPublic) return '/home';
  return null;
}
```

### firebase_options.dart

Delivered as a **template with placeholder values**. The user must:

1. Create a Firebase project
2. Register the iOS and Android apps
3. Run `flutterfire configure` or manually fill in the values

---

## 6. Data Flow — Token Lifecycle

```
1. User signs in via Firebase SDK (email/password or Google)
2. Firebase SDK stores session locally (platform-native secure storage)
3. authStateChanges() emits FirebaseUser → AuthNotifier updates state
4. App navigates to /home
5. API call triggered → AuthInterceptor calls getIdToken()
   - if token < 5min old: returns cached token
   - if token expired: Firebase SDK silently refreshes using refresh token
6. NestJS receives Bearer token → FirebaseAuthGuard verifies → upserts User
7. Endpoint executes with @CurrentUser()
8. On sign-out: FirebaseAuth.signOut() clears SDK session → authStateChanges() emits null
   → AuthNotifier → unauthenticated → router redirects to /login
```

---

## 7. What the User Must Do Manually

Firebase requires native platform configuration that cannot be automated:

1. **Create Firebase project** at console.firebase.google.com
2. **Enable Auth providers:** Email/Password + Google
3. **Register iOS app** → download `GoogleService-Info.plist` → place in `apps/mobile/ios/Runner/`
4. **Register Android app** → download `google-services.json` → place in `apps/mobile/android/app/`
5. **Generate service account key** (Project Settings → Service Accounts) → extract values into `.env`
6. **Run `flutterfire configure`** or manually populate `firebase_options.dart`

These steps are documented in `docs/firebase-setup.md` (to be created).

---

## 8. Out of Scope

- Email verification flow (send/check verification email)
- Password reset flow
- Anonymous auth
- Phone auth
- Multi-factor authentication
- JWT issued by our own backend
- Refresh token management (handled entirely by Firebase SDK)
