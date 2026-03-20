# Firebase Auth Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement end-to-end Firebase Auth (email/password + Google Sign-In) across NestJS backend and Flutter frontend, with Firebase as the sole identity provider.

**Architecture:** The backend installs `firebase-admin`, exposes a `FirebaseAuthGuard` that verifies Firebase ID tokens and upserts internal Users by `providerUid`. The Flutter app uses `StreamNotifier<AuthState>` driven by `AuthRepository.authStateChanges()` (backed by `FirebaseAuth.authStateChanges()`), with `AuthInterceptor` fetching fresh ID tokens from the Firebase SDK on each request.

**Tech Stack:** NestJS + Prisma + PostgreSQL (backend); Flutter + Riverpod v2 + GoRouter + Dio (frontend); firebase-admin (Node); firebase_core, firebase_auth, google_sign_in (Flutter)

---

## File Map

### Backend — new files

| Path                                                                 | Responsibility                                                  |
| -------------------------------------------------------------------- | --------------------------------------------------------------- |
| `apps/backend/src/config/firebase.config.ts`                         | Validate + export Firebase env vars                             |
| `apps/backend/src/modules/firebase/firebase.module.ts`               | Global NestJS module; initialize firebase-admin                 |
| `apps/backend/src/modules/firebase/firebase.service.ts`              | `verifyIdToken()` wrapper around admin SDK                      |
| `apps/backend/src/modules/firebase/firebase.service.spec.ts`         | Unit test for FirebaseService                                   |
| `apps/backend/src/modules/auth/guards/firebase-auth.guard.ts`        | Extract Bearer token → verify → upsert user → attach to request |
| `apps/backend/src/modules/auth/guards/firebase-auth.guard.spec.ts`   | Unit test for guard                                             |
| `apps/backend/src/modules/auth/decorators/current-user.decorator.ts` | `@CurrentUser()` param decorator                                |

### Backend — modified files

| Path                                                            | Change                                                                                                |
| --------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| `apps/backend/prisma/schema.prisma`                             | Remove `password`, `RefreshToken`; add `providerUid`, `emailVerified`                                 |
| `apps/backend/src/config/jwt.config.ts`                         | **Delete**                                                                                            |
| `apps/backend/src/config/configuration.ts`                      | Remove jwtConfig import and `jwt` key                                                                 |
| `apps/backend/src/modules/users/services/users.service.ts`      | Add `findOrCreateFromFirebase()` with PrismaService injection                                         |
| `apps/backend/src/modules/users/services/users.service.spec.ts` | Tests for `findOrCreateFromFirebase()`                                                                |
| `apps/backend/src/modules/users/users.module.ts`                | Import PrismaModule; export UsersService                                                              |
| `apps/backend/src/modules/auth/auth.module.ts`                  | Import UsersModule; export FirebaseAuthGuard (FirebaseModule is @Global — no need to import it again) |
| `apps/backend/src/app.module.ts`                                | Import FirebaseModule                                                                                 |
| `apps/backend/.env.example`                                     | Remove JWT vars; add Firebase Admin vars                                                              |
| `apps/backend/package.json`                                     | Remove passport/jwt packages; add firebase-admin                                                      |

### Flutter — new files

| Path                                                                            | Responsibility                                         |
| ------------------------------------------------------------------------------- | ------------------------------------------------------ |
| `apps/mobile/lib/firebase_options.dart.example`                                 | Template with placeholder values (committed)           |
| `apps/mobile/lib/features/auth/domain/repositories/auth_repository.dart`        | Abstract contract: `authStateChanges()` + auth actions |
| `apps/mobile/lib/features/auth/data/repositories/firebase_auth_repository.dart` | Firebase implementation                                |

### Flutter — modified files

| Path                                                                      | Change                                                                                            |
| ------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| `apps/mobile/pubspec.yaml`                                                | Add firebase_core, firebase_auth, google_sign_in                                                  |
| `apps/mobile/.gitignore`                                                  | Add `lib/firebase_options.dart`                                                                   |
| `apps/mobile/lib/bootstrap.dart`                                          | `Firebase.initializeApp()` before `runApp()`                                                      |
| `apps/mobile/lib/features/auth/domain/entities/user_entity.dart`          | `email` → `String?`                                                                               |
| `apps/mobile/lib/features/auth/application/providers/auth_provider.dart`  | Rewrite: `StreamNotifier<AuthState>`, use `AuthRepository`, remove `accessToken` from `AuthState` |
| `apps/mobile/lib/features/auth/presentation/screens/login_screen.dart`    | Wire to `AuthNotifier`; add Google Sign-In button                                                 |
| `apps/mobile/lib/features/auth/presentation/screens/register_screen.dart` | Wire to `AuthNotifier`                                                                            |
| `apps/mobile/lib/app/router/app_router.dart`                              | `ref.watch(authProvider)` + `redirect` guard                                                      |
| `apps/mobile/lib/core/network/interceptors/auth_interceptor.dart`         | Remove `StorageService`; inject `Dio`; `getIdToken()` + 401 retry                                 |
| `apps/mobile/lib/core/network/api_client.dart`                            | `AuthInterceptor(dio)` constructor call                                                           |
| `apps/mobile/test/unit/features/auth/auth_provider_test.dart`             | Update tests for new `AuthState` shape                                                            |
| `apps/mobile/test/helpers/mock_providers.dart`                            | Add `MockAuthRepository`, `authRepositoryProvider` override                                       |

---

## PART A — Backend

---

### Task 1: Remove JWT/Passport infrastructure

**Files:**

- Delete: `apps/backend/src/config/jwt.config.ts`
- Modify: `apps/backend/src/config/configuration.ts`
- Modify: `apps/backend/package.json`

- [ ] **Step 1: Delete jwt.config.ts**

```bash
rm apps/backend/src/config/jwt.config.ts
```

- [ ] **Step 2: Update configuration.ts**

Open `apps/backend/src/config/configuration.ts`. Remove line 3 (`import jwtConfig from './jwt.config';`) and remove `jwt: jwtConfig()` from the returned object:

```typescript
import { registerAs } from '@nestjs/config';
import appConfig from './app.config';
import databaseConfig from './database.config';
import queueConfig from './queue.config';
import storageConfig from './storage.config';

export default registerAs('config', () => ({
  app: appConfig(),
  database: databaseConfig(),
  queue: queueConfig(),
  storage: storageConfig(),
}));
```

- [ ] **Step 3: Uninstall passport/JWT packages**

```bash
cd apps/backend && npm uninstall @nestjs/jwt @nestjs/passport passport passport-jwt @types/passport-jwt
```

- [ ] **Step 4: Verify build**

```bash
cd apps/backend && npm run build
```

Expected: `Found 0 errors. Watching for file changes.` (or clean exit). Fix any remaining JWT import errors.

- [ ] **Step 5: Run existing tests**

```bash
cd apps/backend && npm test
```

Expected: All existing tests pass.

- [ ] **Step 6: Commit**

```bash
cd /Users/usuario/Desktop/votio
# git add on the config dir stages both the deletion of jwt.config.ts and the modification of configuration.ts
git add apps/backend/src/config/ apps/backend/package.json apps/backend/package-lock.json
git commit -m "chore(backend): remove jwt/passport — firebase auth replaces them"
```

---

### Task 2: Update Prisma schema

**Files:**

- Modify: `apps/backend/prisma/schema.prisma`

- [ ] **Step 1: Update the User model**

Replace the full `User` model and delete `RefreshToken`. The schema diff:

- Remove: `password String`
- Remove: `refreshTokens RefreshToken[]` relation on User
- Add: `providerUid String @unique`
- Add: `emailVerified Boolean @default(false)`
- Add: `authProvider String @default("firebase")`
- Change `email String @unique` → `email String?` (optional, no longer unique — identity key is providerUid)
- Remove: `@@index([email])` on User
- Keep: `@@index([createdAt])` on User
- Delete the entire `RefreshToken` model

Final User model in `apps/backend/prisma/schema.prisma`:

```prisma
model User {
  id             String   @id @default(cuid())
  providerUid    String   @unique
  authProvider   String   @default("firebase")
  email          String?
  emailVerified  Boolean  @default(false)
  displayName    String?
  profilePicture String?
  bio            String?
  createdAt      DateTime @default(now())
  updatedAt      DateTime @updatedAt

  recordings    Recording[]
  notifications Notification[]

  @@index([createdAt])
}
```

Also remove `refreshTokens RefreshToken[]` from the User model and delete the entire `RefreshToken` model block.

- [ ] **Step 2: Run migration**

```bash
cd apps/backend && npx prisma migrate dev --name remove-jwt-add-firebase-identity
```

Expected: Migration created and applied. If Prisma complains about data loss (password is NOT NULL), confirm with `y` — this is a dev environment.

- [ ] **Step 3: Regenerate Prisma client**

```bash
cd apps/backend && npx prisma generate
```

Expected: `Generated Prisma Client`.

- [ ] **Step 4: Verify build still passes**

```bash
cd apps/backend && npm run build
```

Fix any TypeScript errors referencing `password` or `refreshTokens`.

- [ ] **Step 5: Commit**

```bash
cd /Users/usuario/Desktop/votio
git add apps/backend/prisma/ apps/backend/src/
git commit -m "feat(backend): update prisma schema for firebase auth identity"
```

---

### Task 3: Install firebase-admin and create FirebaseModule

**Files:**

- Create: `apps/backend/src/config/firebase.config.ts`
- Create: `apps/backend/src/modules/firebase/firebase.module.ts`
- Create: `apps/backend/src/modules/firebase/firebase.service.ts`
- Create: `apps/backend/src/modules/firebase/firebase.service.spec.ts`

- [ ] **Step 1: Install firebase-admin**

```bash
cd apps/backend && npm install firebase-admin
```

- [ ] **Step 2: Create firebase.config.ts**

```typescript
// apps/backend/src/config/firebase.config.ts
import { registerAs } from '@nestjs/config';

export default registerAs('firebase', () => ({
  projectId: process.env.FIREBASE_PROJECT_ID,
  clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
  privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
}));
```

- [ ] **Step 3: Write the failing FirebaseService test**

```typescript
// apps/backend/src/modules/firebase/firebase.service.spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { UnauthorizedException } from '@nestjs/common';
import { FirebaseService } from './firebase.service';

describe('FirebaseService', () => {
  let service: FirebaseService;
  let mockVerifyIdToken: jest.Mock;

  beforeEach(async () => {
    mockVerifyIdToken = jest.fn();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        FirebaseService,
        {
          provide: ConfigService,
          useValue: {
            get: jest.fn().mockReturnValue({
              projectId: 'test-project',
              clientEmail: 'test@test.iam.gserviceaccount.com',
              privateKey: 'test-key',
            }),
          },
        },
      ],
    }).compile();

    service = module.get<FirebaseService>(FirebaseService);
    // Inject mock into the internal admin app
    (service as any).adminAuth = { verifyIdToken: mockVerifyIdToken };
  });

  describe('verifyIdToken', () => {
    it('returns decoded token for valid token', async () => {
      const decoded = { uid: 'user123', email: 'a@b.com', email_verified: true };
      mockVerifyIdToken.mockResolvedValue(decoded);

      const result = await service.verifyIdToken('valid-token');

      expect(mockVerifyIdToken).toHaveBeenCalledWith('valid-token');
      expect(result).toEqual(decoded);
    });

    it('throws UnauthorizedException for invalid token', async () => {
      mockVerifyIdToken.mockRejectedValue(new Error('invalid token'));

      await expect(service.verifyIdToken('bad-token')).rejects.toThrow(UnauthorizedException);
    });
  });
});
```

- [ ] **Step 4: Run test to confirm it fails**

```bash
cd apps/backend && npm test -- --testPathPattern=firebase.service.spec
```

Expected: FAIL — `Cannot find module './firebase.service'`

- [ ] **Step 5: Create FirebaseService**

```typescript
// apps/backend/src/modules/firebase/firebase.service.ts
import { Injectable, OnModuleInit, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';

@Injectable()
export class FirebaseService implements OnModuleInit {
  private adminAuth!: admin.auth.Auth;

  constructor(private readonly configService: ConfigService) {}

  onModuleInit(): void {
    const firebaseConfig = this.configService.get<{
      projectId: string;
      clientEmail: string;
      privateKey: string;
    }>('firebase');

    if (!admin.apps.length) {
      const app = admin.initializeApp({
        credential: admin.credential.cert({
          projectId: firebaseConfig!.projectId,
          clientEmail: firebaseConfig!.clientEmail,
          privateKey: firebaseConfig!.privateKey,
        }),
      });
      this.adminAuth = app.auth();
    } else {
      this.adminAuth = admin.app().auth();
    }
  }

  async verifyIdToken(token: string): Promise<admin.auth.DecodedIdToken> {
    try {
      return await this.adminAuth.verifyIdToken(token);
    } catch {
      throw new UnauthorizedException('Invalid or expired Firebase token');
    }
  }
}
```

- [ ] **Step 6: Create FirebaseModule**

```typescript
// apps/backend/src/modules/firebase/firebase.module.ts
import { Global, Module } from '@nestjs/common';
import { FirebaseService } from './firebase.service';

@Global()
@Module({
  providers: [FirebaseService],
  exports: [FirebaseService],
})
export class FirebaseModule {}
```

- [ ] **Step 7: Run test to confirm it passes**

```bash
cd apps/backend && npm test -- --testPathPattern=firebase.service.spec
```

Expected: PASS

- [ ] **Step 8: Register firebase.config.ts in app.module.ts**

Open `apps/backend/src/app.module.ts`. Add:

1. `import firebaseConfig from '@config/firebase.config';` — add to the configFactory `load` array
2. `import { FirebaseModule } from '@modules/firebase/firebase.module';` — add to imports

In `ConfigModule.forRoot`:

```typescript
ConfigModule.forRoot({
  isGlobal: true,
  load: [configFactory, firebaseConfig],   // add firebaseConfig here
}),
```

And add `FirebaseModule` to the `imports` array.

- [ ] **Step 9: Build to check**

```bash
cd apps/backend && npm run build
```

Expected: No errors.

- [ ] **Step 10: Commit**

```bash
cd /Users/usuario/Desktop/votio
git add apps/backend/src/ apps/backend/package.json apps/backend/package-lock.json
git commit -m "feat(backend): add firebase-admin module and service"
```

---

### Task 4: Update UsersService with findOrCreateFromFirebase

**Files:**

- Modify: `apps/backend/src/modules/users/services/users.service.ts`
- Create: `apps/backend/src/modules/users/services/users.service.spec.ts`
- Modify: `apps/backend/src/modules/users/users.module.ts`

- [ ] **Step 1: Write the failing test**

```typescript
// apps/backend/src/modules/users/services/users.service.spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { UsersService } from './users.service';
import { PrismaService } from '@database/prisma.service';

const mockUser = {
  id: 'cuid1',
  providerUid: 'firebase-uid-123',
  authProvider: 'firebase',
  email: 'test@example.com',
  emailVerified: true,
  displayName: 'Test User',
  profilePicture: null,
  bio: null,
  createdAt: new Date(),
  updatedAt: new Date(),
};

const mockDecodedToken = {
  uid: 'firebase-uid-123',
  email: 'test@example.com',
  email_verified: true,
  name: 'Test User',
  picture: null,
} as any;

describe('UsersService', () => {
  let service: UsersService;
  let prisma: { user: { upsert: jest.Mock } };

  beforeEach(async () => {
    prisma = { user: { upsert: jest.fn() } };

    const module: TestingModule = await Test.createTestingModule({
      providers: [UsersService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = module.get<UsersService>(UsersService);
  });

  describe('findOrCreateFromFirebase', () => {
    it('upserts user by providerUid and returns the user', async () => {
      prisma.user.upsert.mockResolvedValue(mockUser);

      const result = await service.findOrCreateFromFirebase(mockDecodedToken);

      expect(prisma.user.upsert).toHaveBeenCalledWith({
        where: { providerUid: 'firebase-uid-123' },
        // update uses `?? undefined` so missing fields are ignored by Prisma
        // (passing null would erase previously stored values)
        update: {
          email: 'test@example.com',
          emailVerified: true,
          displayName: 'Test User',
          profilePicture: undefined,
        },
        create: {
          providerUid: 'firebase-uid-123',
          authProvider: 'firebase',
          email: 'test@example.com',
          emailVerified: true,
          displayName: 'Test User',
          profilePicture: null,
        },
      });
      expect(result).toEqual(mockUser);
    });

    it('handles missing optional fields from Firebase token', async () => {
      const tokenWithoutOptionals = { uid: 'uid-456' } as any;
      prisma.user.upsert.mockResolvedValue({ ...mockUser, email: null, displayName: null });

      await service.findOrCreateFromFirebase(tokenWithoutOptionals);

      expect(prisma.user.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { providerUid: 'uid-456' },
          update: expect.objectContaining({
            email: undefined,
            emailVerified: false,
            displayName: undefined,
            profilePicture: undefined,
          }),
          create: expect.objectContaining({
            email: null,
            emailVerified: false,
            displayName: null,
            profilePicture: null,
          }),
        })
      );
    });
  });
});
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd apps/backend && npm test -- --testPathPattern=users.service.spec
```

Expected: FAIL — `UsersService has no method findOrCreateFromFirebase` or similar.

- [ ] **Step 3: Implement UsersService**

```typescript
// apps/backend/src/modules/users/services/users.service.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '@database/prisma.service';
import type { User } from '@prisma/client';
import type { DecodedIdToken } from 'firebase-admin/auth';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async findOrCreateFromFirebase(decoded: DecodedIdToken): Promise<User> {
    return this.prisma.user.upsert({
      where: { providerUid: decoded.uid },
      // update: use `?? undefined` so Prisma ignores missing fields rather than
      // overwriting stored values with null (e.g. preserves a stored email when
      // the Firebase token doesn't include one).
      update: {
        email: decoded.email ?? undefined,
        emailVerified: decoded.email_verified ?? false,
        displayName: decoded.name ?? undefined,
        profilePicture: decoded.picture ?? undefined,
      },
      // create: use `?? null` to store explicit nulls for new records.
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
}
```

- [ ] **Step 4: Run test to confirm it passes**

```bash
cd apps/backend && npm test -- --testPathPattern=users.service.spec
```

Expected: PASS — 2 tests pass.

- [ ] **Step 5: Update UsersModule to import PrismaModule and export UsersService**

```typescript
// apps/backend/src/modules/users/users.module.ts
import { Module } from '@nestjs/common';
import { UsersController } from './controllers/users.controller';
import { UsersService } from './services/users.service';
import { PrismaModule } from '@database/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [UsersController],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}
```

- [ ] **Step 6: Commit**

```bash
cd /Users/usuario/Desktop/votio
git add apps/backend/src/modules/users/
git commit -m "feat(backend): add findOrCreateFromFirebase to users service"
```

---

### Task 5: Create FirebaseAuthGuard and @CurrentUser() decorator

**Files:**

- Create: `apps/backend/src/modules/auth/guards/firebase-auth.guard.ts`
- Create: `apps/backend/src/modules/auth/guards/firebase-auth.guard.spec.ts`
- Create: `apps/backend/src/modules/auth/decorators/current-user.decorator.ts`

- [ ] **Step 1: Write the failing guard test**

```typescript
// apps/backend/src/modules/auth/guards/firebase-auth.guard.spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { FirebaseAuthGuard } from './firebase-auth.guard';
import { FirebaseService } from '../../firebase/firebase.service';
import { UsersService } from '../../users/services/users.service';

const mockDecoded = {
  uid: 'uid-abc',
  email: 'a@b.com',
  email_verified: true,
  name: 'Alice',
};

const mockUser = { id: 'cuid1', providerUid: 'uid-abc' };

function makeContext(authHeader?: string): ExecutionContext {
  return {
    switchToHttp: () => ({
      getRequest: () => ({ headers: { authorization: authHeader }, user: undefined }),
    }),
  } as unknown as ExecutionContext;
}

describe('FirebaseAuthGuard', () => {
  let guard: FirebaseAuthGuard;
  let firebaseService: { verifyIdToken: jest.Mock };
  let usersService: { findOrCreateFromFirebase: jest.Mock };

  beforeEach(async () => {
    firebaseService = { verifyIdToken: jest.fn().mockResolvedValue(mockDecoded) };
    usersService = { findOrCreateFromFirebase: jest.fn().mockResolvedValue(mockUser) };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        FirebaseAuthGuard,
        { provide: FirebaseService, useValue: firebaseService },
        { provide: UsersService, useValue: usersService },
      ],
    }).compile();

    guard = module.get<FirebaseAuthGuard>(FirebaseAuthGuard);
  });

  it('returns true and attaches user when token is valid', async () => {
    const ctx = makeContext('Bearer valid-token');
    const req = ctx.switchToHttp().getRequest();

    const result = await guard.canActivate(ctx);

    expect(result).toBe(true);
    expect(firebaseService.verifyIdToken).toHaveBeenCalledWith('valid-token');
    expect(usersService.findOrCreateFromFirebase).toHaveBeenCalledWith(mockDecoded);
    expect(req.user).toEqual(mockUser);
  });

  it('throws UnauthorizedException when Authorization header is missing', async () => {
    const ctx = makeContext(undefined);
    await expect(guard.canActivate(ctx)).rejects.toThrow(UnauthorizedException);
  });

  it('throws UnauthorizedException when header is not Bearer format', async () => {
    const ctx = makeContext('Basic sometoken');
    await expect(guard.canActivate(ctx)).rejects.toThrow(UnauthorizedException);
  });

  it('throws UnauthorizedException when FirebaseService throws', async () => {
    firebaseService.verifyIdToken.mockRejectedValue(new UnauthorizedException());
    const ctx = makeContext('Bearer bad-token');
    await expect(guard.canActivate(ctx)).rejects.toThrow(UnauthorizedException);
  });
});
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd apps/backend && npm test -- --testPathPattern=firebase-auth.guard.spec
```

Expected: FAIL — cannot find module.

- [ ] **Step 3: Implement FirebaseAuthGuard**

```typescript
// apps/backend/src/modules/auth/guards/firebase-auth.guard.ts
import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import type { Request } from 'express';
import { FirebaseService } from '../../firebase/firebase.service';
import { UsersService } from '../../users/services/users.service';

@Injectable()
export class FirebaseAuthGuard implements CanActivate {
  constructor(
    private readonly firebaseService: FirebaseService,
    private readonly usersService: UsersService
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<Request>();
    const token = this.extractBearerToken(request);

    const decoded = await this.firebaseService.verifyIdToken(token);
    const user = await this.usersService.findOrCreateFromFirebase(decoded);
    (request as any).user = user;

    return true;
  }

  private extractBearerToken(request: Request): string {
    const auth = request.headers['authorization'];
    if (!auth || !auth.startsWith('Bearer ')) {
      throw new UnauthorizedException('Missing or malformed Authorization header');
    }
    return auth.slice(7);
  }
}
```

- [ ] **Step 4: Create @CurrentUser() decorator**

```typescript
// apps/backend/src/modules/auth/decorators/current-user.decorator.ts
import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import type { Request } from 'express';
import type { User } from '@prisma/client';

export const CurrentUser = createParamDecorator((_data: unknown, ctx: ExecutionContext): User => {
  const request = ctx.switchToHttp().getRequest<Request>();
  return (request as any).user as User;
});
```

- [ ] **Step 5: Run test to confirm guard tests pass**

```bash
cd apps/backend && npm test -- --testPathPattern=firebase-auth.guard.spec
```

Expected: PASS — 4 tests pass.

- [ ] **Step 6: Commit**

```bash
cd /Users/usuario/Desktop/votio
git add apps/backend/src/modules/auth/
git commit -m "feat(backend): add firebase auth guard and current-user decorator"
```

---

### Task 6: Wire AuthModule + update .env.example

**Files:**

- Modify: `apps/backend/src/modules/auth/auth.module.ts`
- Modify: `apps/backend/.env.example`

- [ ] **Step 1: Update AuthModule**

```typescript
// apps/backend/src/modules/auth/auth.module.ts
// FirebaseModule is @Global() and imported in AppModule — do NOT re-import it here.
// FirebaseService is available application-wide via the global module.
// UsersModule must be imported explicitly to make UsersService available to FirebaseAuthGuard.
import { Module } from '@nestjs/common';
import { UsersModule } from '../users/users.module';
import { AuthController } from './controllers/auth.controller';
import { AuthService } from './services/auth.service';
import { FirebaseAuthGuard } from './guards/firebase-auth.guard';

@Module({
  imports: [UsersModule],
  controllers: [AuthController],
  providers: [AuthService, FirebaseAuthGuard],
  exports: [FirebaseAuthGuard],
})
export class AuthModule {}
```

- [ ] **Step 2: Update .env.example**

Remove the JWT section and add Firebase Admin section:

```bash
# Remove these lines from apps/backend/.env.example:
# JWT_SECRET=...
# JWT_EXPIRY=1h
# JWT_REFRESH_SECRET=...
# JWT_REFRESH_EXPIRY=7d
```

Add after the `# Database` section:

```
# Firebase Admin SDK
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYOUR_KEY_HERE\n-----END PRIVATE KEY-----\n"
```

- [ ] **Step 3: Run full backend test suite**

```bash
cd apps/backend && npm test
```

Expected: All tests pass. Fix any import errors.

- [ ] **Step 4: Build**

```bash
cd apps/backend && npm run build
```

Expected: No errors.

- [ ] **Step 5: Commit**

```bash
cd /Users/usuario/Desktop/votio
git add apps/backend/src/modules/auth/ apps/backend/.env.example
git commit -m "feat(backend): wire firebase auth module and update env example"
```

---

## PART B — Flutter

---

### Task 7: Firebase dependencies, firebase_options template, gitignore, bootstrap

**Files:**

- Modify: `apps/mobile/pubspec.yaml`
- Create: `apps/mobile/lib/firebase_options.dart.example`
- Modify: `apps/mobile/.gitignore`
- Modify: `apps/mobile/lib/bootstrap.dart`

- [ ] **Step 1: Add Firebase packages**

```bash
cd apps/mobile && flutter pub add firebase_core firebase_auth google_sign_in
```

Expected: `pubspec.yaml` updated, `flutter pub get` runs successfully.

- [ ] **Step 2: Create firebase_options.dart.example template**

Create `apps/mobile/lib/firebase_options.dart.example`:

```dart
// TEMPLATE — copy to lib/firebase_options.dart and fill in your values.
// Run `flutterfire configure` in apps/mobile/ to generate this file automatically.
// DO NOT commit the real firebase_options.dart — it contains API keys.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('DefaultFirebaseOptions not configured for this platform.');
    }
  }

  // Replace ALL placeholder values below with your Firebase project values.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_WITH_WEB_API_KEY',
    appId: 'REPLACE_WITH_WEB_APP_ID',
    messagingSenderId: 'REPLACE_WITH_SENDER_ID',
    projectId: 'REPLACE_WITH_PROJECT_ID',
    authDomain: 'REPLACE_WITH_PROJECT_ID.firebaseapp.com',
    storageBucket: 'REPLACE_WITH_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_ANDROID_API_KEY',
    appId: 'REPLACE_WITH_ANDROID_APP_ID',
    messagingSenderId: 'REPLACE_WITH_SENDER_ID',
    projectId: 'REPLACE_WITH_PROJECT_ID',
    storageBucket: 'REPLACE_WITH_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_IOS_API_KEY',
    appId: 'REPLACE_WITH_IOS_APP_ID',
    messagingSenderId: 'REPLACE_WITH_SENDER_ID',
    projectId: 'REPLACE_WITH_PROJECT_ID',
    storageBucket: 'REPLACE_WITH_PROJECT_ID.appspot.com',
    iosClientId: 'REPLACE_WITH_IOS_CLIENT_ID',
    iosBundleId: 'REPLACE_WITH_IOS_BUNDLE_ID',
  );
}
```

- [ ] **Step 3: Add firebase_options.dart to .gitignore**

Append to `apps/mobile/.gitignore`:

```
# Firebase — contains API keys, do not commit
lib/firebase_options.dart
```

- [ ] **Step 4: Update bootstrap.dart**

Add `Firebase.initializeApp()` call. The file must import `firebase_core` and `firebase_options`. Note: `firebase_options.dart` won't exist until the user configures Firebase — the build will fail until then. This is expected. We provide the `.example` file and document the setup step.

```dart
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/services/logger_service.dart';
import 'firebase_options.dart';

Future<void> bootstrap({required AppConfig config}) async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: config.envFileName);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  LoggerService.init(config: config);

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
      ],
      child: const VotioApp(),
    ),
  );
}
```

- [ ] **Step 5: Create firebase_options.dart from example for CI/dev (if not already present)**

Only copy if the real file doesn't exist yet — avoids overwriting a real configured file:

```bash
[ -f apps/mobile/lib/firebase_options.dart ] || cp apps/mobile/lib/firebase_options.dart.example apps/mobile/lib/firebase_options.dart
```

Note: This placeholder file compiles but Firebase will fail at runtime. The user must run `flutterfire configure` to generate real values before the app can authenticate.

- [ ] **Step 6: Verify the project compiles**

```bash
cd apps/mobile && flutter pub get && flutter analyze
```

Expected: Only the pre-existing 3 info-level notes, no new errors.

- [ ] **Step 7: Commit**

```bash
cd /Users/usuario/Desktop/votio
git add apps/mobile/pubspec.yaml apps/mobile/pubspec.lock apps/mobile/.gitignore apps/mobile/lib/bootstrap.dart apps/mobile/lib/firebase_options.dart.example
# Do NOT add apps/mobile/lib/firebase_options.dart (it's in .gitignore)
git commit -m "feat(mobile): add firebase dependencies and bootstrap initialization"
```

---

### Task 8: Update UserEntity — email optional

**Files:**

- Modify: `apps/mobile/lib/features/auth/domain/entities/user_entity.dart`

- [ ] **Step 1: Update the entity**

```dart
// apps/mobile/lib/features/auth/domain/entities/user_entity.dart
import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    this.email,
    this.displayName,
    this.avatarUrl,
  });

  final String id;
  final String? email;
  final String? displayName;
  final String? avatarUrl;

  @override
  List<Object?> get props => [id, email, displayName, avatarUrl];
}
```

- [ ] **Step 2: Analyze for breakage**

```bash
cd apps/mobile && flutter analyze
```

Expected: No new errors — `email` was already nullable-accessed in existing code. Fix any compilation errors if needed.

- [ ] **Step 3: Run tests**

```bash
cd apps/mobile && flutter test
```

Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
cd /Users/usuario/Desktop/votio
git add apps/mobile/lib/features/auth/domain/entities/user_entity.dart
git commit -m "feat(mobile): make user entity email optional — identity is uid"
```

---

### Task 9: Create AuthRepository interface and FirebaseAuthRepository

**Files:**

- Create: `apps/mobile/lib/features/auth/domain/repositories/auth_repository.dart`
- Create: `apps/mobile/lib/features/auth/data/repositories/firebase_auth_repository.dart`

- [ ] **Step 1: Create the abstract AuthRepository**

```dart
// apps/mobile/lib/features/auth/domain/repositories/auth_repository.dart

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
```

- [ ] **Step 2: Create FirebaseAuthRepository**

```dart
// apps/mobile/lib/features/auth/data/repositories/firebase_auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository()
      : _auth = FirebaseAuth.instance,
        _googleSignIn = GoogleSignIn(scopes: ['email']);

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  @override
  Stream<({String uid, String? email, String? displayName, String? avatarUrl})?> authStateChanges() {
    return _auth.authStateChanges().map((user) {
      if (user == null) return null;
      return (
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        avatarUrl: user.photoURL,
      );
    });
  }

  @override
  Future<void> signInWithEmail({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> registerWithEmail({required String email, required String password}) async {
    await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return; // user cancelled
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await _auth.signInWithCredential(credential);
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut(); // no-op if not signed in via Google
    await _auth.signOut();
  }
}
```

- [ ] **Step 3: Analyze**

```bash
cd apps/mobile && flutter analyze
```

Expected: No errors.

- [ ] **Step 4: Commit**

```bash
cd /Users/usuario/Desktop/votio
git add apps/mobile/lib/features/auth/
git commit -m "feat(mobile): add auth repository interface and firebase implementation"
```

---

### Task 10: Rewrite AuthNotifier as StreamNotifier

**Files:**

- Modify: `apps/mobile/lib/features/auth/application/providers/auth_provider.dart`
- Modify: `apps/mobile/test/unit/features/auth/auth_provider_test.dart`
- Modify: `apps/mobile/test/helpers/mock_providers.dart`

- [ ] **Step 1: Update the tests first**

```dart
// apps/mobile/test/unit/features/auth/auth_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:votio_mobile/features/auth/application/providers/auth_provider.dart';
import 'package:votio_mobile/features/auth/domain/entities/user_entity.dart';

import 'package:votio_mobile/features/auth/domain/repositories/auth_repository.dart';
// Import MockAuthRepository from shared test helpers — do NOT redeclare it here
// to avoid a compile conflict when both files are transitively imported.
import '../../../helpers/mock_providers.dart' show MockAuthRepository;

// Helper to create a ProviderContainer with a mock auth repository
ProviderContainer makeContainer(AuthRepository repo) {
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(repo),
    ],
  );
}

void main() {
  group('AuthState', () {
    test('default status is unknown', () {
      const state = AuthState();
      expect(state.status, AuthStatus.unknown);
      expect(state.isAuthenticated, isFalse);
    });

    test('copyWith updates fields', () {
      const state = AuthState();
      final user = UserEntity(id: 'u1', email: 'a@b.com');
      final updated = state.copyWith(
        status: AuthStatus.authenticated,
        userId: 'u1',
        user: user,
      );
      expect(updated.status, AuthStatus.authenticated);
      expect(updated.userId, 'u1');
      expect(updated.user, user);
      expect(updated.isAuthenticated, isTrue);
    });

    test('does not have accessToken field', () {
      // Ensure accessToken was removed — this test documents the contract
      const state = AuthState(status: AuthStatus.authenticated, userId: 'x');
      expect(state.isAuthenticated, isTrue);
      // If accessToken were present, this would be a compile error below
      // (intentionally no accessToken field access here)
    });
  });

  group('AuthNotifier stream', () {
    test('emits unauthenticated when repository stream emits null', () async {
      final repo = MockAuthRepository();
      when(() => repo.authStateChanges()).thenAnswer((_) => Stream.value(null));

      final container = makeContainer(repo);
      addTearDown(container.dispose);

      await container.read(authProvider.future);
      final state = container.read(authProvider).value!;
      expect(state.status, AuthStatus.unauthenticated);
    });

    test('emits authenticated with UserEntity when repository stream emits user', () async {
      final repo = MockAuthRepository();
      final fakeUser = (
        uid: 'uid-abc',
        email: 'a@b.com',
        displayName: 'Alice',
        avatarUrl: null,
      );
      when(() => repo.authStateChanges()).thenAnswer((_) => Stream.value(fakeUser));

      final container = makeContainer(repo);
      addTearDown(container.dispose);

      await container.read(authProvider.future);
      final state = container.read(authProvider).value!;
      expect(state.status, AuthStatus.authenticated);
      expect(state.userId, 'uid-abc');
      expect(state.user?.email, 'a@b.com');
    });
  });
}
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
cd apps/mobile && flutter test test/unit/features/auth/auth_provider_test.dart
```

Expected: FAIL — `authRepositoryProvider` not found, `AuthState` has wrong shape.

- [ ] **Step 3: Rewrite auth_provider.dart**

```dart
// apps/mobile/lib/features/auth/application/providers/auth_provider.dart
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

final authProvider =
    StreamNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
```

- [ ] **Step 4: Update mock_providers.dart**

```dart
// apps/mobile/test/helpers/mock_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:votio_mobile/core/config/app_config.dart';
import 'package:votio_mobile/features/auth/application/providers/auth_provider.dart';
import 'package:votio_mobile/features/auth/domain/repositories/auth_repository.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────

class MockAuthNotifier extends Mock implements AuthNotifier {}
class MockAuthRepository extends Mock implements AuthRepository {}

// ─── Provider overrides ───────────────────────────────────────────────────────

List<Override> get testOverrides => [
      appConfigProvider.overrideWithValue(AppConfig.development()),
    ];

List<Override> authOverrides(AuthRepository repo) => [
      authRepositoryProvider.overrideWithValue(repo),
    ];
```

- [ ] **Step 5: Run the auth tests**

```bash
cd apps/mobile && flutter test test/unit/features/auth/auth_provider_test.dart
```

Expected: PASS — all tests pass.

- [ ] **Step 6: Run full test suite**

```bash
cd apps/mobile && flutter test
```

Expected: All 16+ tests pass. Fix any tests that used the old `accessToken` field.

- [ ] **Step 7: Commit**

```bash
cd /Users/usuario/Desktop/votio
git add apps/mobile/lib/features/auth/application/ apps/mobile/test/
git commit -m "feat(mobile): rewrite auth notifier as stream notifier with auth repository"
```

---

### Task 11: Update AuthInterceptor and ApiClient

**Files:**

- Modify: `apps/mobile/lib/core/network/interceptors/auth_interceptor.dart`
- Modify: `apps/mobile/lib/core/network/api_client.dart`

- [ ] **Step 1: Rewrite AuthInterceptor**

```dart
// apps/mobile/lib/core/network/interceptors/auth_interceptor.dart
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Attaches a fresh Firebase ID token to each outbound request.
/// On 401, force-refreshes the token and retries once using the same
/// configured Dio instance (so all interceptors and base options are preserved).
class AuthInterceptor extends Interceptor {
  // The app's configured Dio instance is injected to avoid creating a bare
  // Dio() for retries, which would bypass all other interceptors.
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
      final token =
          await FirebaseAuth.instance.currentUser?.getIdToken(true);
      if (token != null) {
        final retryOptions = err.requestOptions
          ..headers['Authorization'] = 'Bearer $token';
        try {
          final response = await _dio.fetch<dynamic>(retryOptions);
          return handler.resolve(response);
        } catch (_) {
          // fall through — propagate original error
        }
      }
    }
    handler.next(err);
  }
}
```

- [ ] **Step 2: Update api_client.dart to pass dio to AuthInterceptor**

Only change line 28 — `AuthInterceptor()` → `AuthInterceptor(dio)`:

```dart
  dio.interceptors.add(AuthInterceptor(dio));
```

The full updated `buildDio` function in `apps/mobile/lib/core/network/api_client.dart`:

```dart
Dio buildDio(AppConfig config) {
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: Duration(milliseconds: config.apiTimeoutMs),
      receiveTimeout: Duration(milliseconds: config.apiTimeoutMs),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  if (config.isDevelopment) {
    dio.interceptors.add(LoggingInterceptor(LoggerService.instance));
  }
  dio.interceptors.add(AuthInterceptor(dio));
  dio.interceptors.add(ErrorInterceptor());

  return dio;
}
```

- [ ] **Step 3: Analyze**

```bash
cd apps/mobile && flutter analyze
```

Expected: No errors.

- [ ] **Step 4: Commit**

```bash
cd /Users/usuario/Desktop/votio
git add apps/mobile/lib/core/network/
git commit -m "feat(mobile): update auth interceptor to use firebase id tokens"
```

---

### Task 12: Wire LoginScreen to AuthNotifier

**Files:**

- Modify: `apps/mobile/lib/features/auth/presentation/screens/login_screen.dart`

- [ ] **Step 1: Rewrite LoginScreen**

Convert from `StatelessWidget` to `ConsumerStatefulWidget` to manage form controllers:

```dart
// apps/mobile/lib/features/auth/presentation/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../application/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authProvider.notifier).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      // Router redirect will navigate to /home once authProvider emits authenticated
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authProvider.notifier).signInWithGoogle();
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: !_loading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                enabled: !_loading,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 32),
              PrimaryButton(
                label: _loading ? 'Signing in...' : 'Sign in',
                onPressed: _loading ? null : _signIn,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _loading ? null : _signInWithGoogle,
                icon: const Icon(Icons.login),
                label: const Text('Continue with Google'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.push(RouteNames.register),
                child: const Text("Don't have an account? Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze**

```bash
cd apps/mobile && flutter analyze
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
cd /Users/usuario/Desktop/votio
git add apps/mobile/lib/features/auth/presentation/screens/login_screen.dart
git commit -m "feat(mobile): wire login screen to firebase auth notifier"
```

---

### Task 13: Wire RegisterScreen to AuthNotifier

**Files:**

- Modify: `apps/mobile/lib/features/auth/presentation/screens/register_screen.dart`

- [ ] **Step 1: Rewrite RegisterScreen**

```dart
// apps/mobile/lib/features/auth/presentation/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../application/providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authProvider.notifier).register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      // Router redirect will navigate to /home once authProvider emits authenticated
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                enabled: !_loading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                enabled: !_loading,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 32),
              PrimaryButton(
                label: _loading ? 'Creating account...' : 'Create account',
                onPressed: _loading ? null : _register,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze + commit**

```bash
cd apps/mobile && flutter analyze
```

```bash
cd /Users/usuario/Desktop/votio
git add apps/mobile/lib/features/auth/presentation/screens/register_screen.dart
git commit -m "feat(mobile): wire register screen to firebase auth notifier"
```

---

### Task 14: Add router redirect guard

**Files:**

- Modify: `apps/mobile/lib/app/router/app_router.dart`

- [ ] **Step 1: Rewrite app_router.dart with redirect guard**

```dart
// apps/mobile/lib/app/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/history/presentation/screens/history_detail_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/paywall/presentation/screens/paywall_screen.dart';
import '../../features/recording/presentation/screens/processing_screen.dart';
import '../../features/recording/presentation/screens/recording_screen.dart';
import '../../features/recording/presentation/screens/result_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import 'route_names.dart';

const _publicRoutes = {
  RouteNames.splash,
  RouteNames.onboarding,
  RouteNames.login,
  RouteNames.register,
};

final routerProvider = Provider<GoRouter>((ref) {
  // Watching authProvider causes routerProvider to rebuild — and GoRouter to
  // re-evaluate redirect — whenever auth state changes.
  ref.watch(authProvider);

  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // ref.read is intentional: the outer ref.watch above is the reactive
      // trigger. Using ref.watch here would cause an infinite rebuild loop.
      final authStatus = ref.read(authProvider).valueOrNull?.status;
      final isPublic = _publicRoutes.contains(state.matchedLocation);

      if (authStatus == null || authStatus == AuthStatus.unknown) return null;
      if (authStatus == AuthStatus.unauthenticated && !isPublic) {
        return RouteNames.login;
      }
      if (authStatus == AuthStatus.authenticated && isPublic) {
        return RouteNames.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteNames.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RouteNames.recording,
        name: 'recording',
        builder: (context, state) => const RecordingScreen(),
      ),
      GoRoute(
        path: RouteNames.processing,
        name: 'processing',
        builder: (context, state) => const ProcessingScreen(),
      ),
      GoRoute(
        path: RouteNames.result,
        name: 'result',
        builder: (context, state) => const ResultScreen(),
      ),
      GoRoute(
        path: RouteNames.history,
        name: 'history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: RouteNames.historyDetail,
        name: 'historyDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return HistoryDetailScreen(entryId: id);
        },
      ),
      GoRoute(
        path: RouteNames.paywall,
        name: 'paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: RouteNames.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});
```

- [ ] **Step 2: Analyze**

```bash
cd apps/mobile && flutter analyze
```

Expected: No errors.

- [ ] **Step 3: Run all tests**

```bash
cd apps/mobile && flutter test
```

Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
cd /Users/usuario/Desktop/votio
git add apps/mobile/lib/app/router/app_router.dart
git commit -m "feat(mobile): add firebase auth redirect guard to router"
```

---

## Final Verification

- [ ] **Step 1: Backend — full test suite**

```bash
cd apps/backend && npm test
```

Expected: All tests pass, no failures.

- [ ] **Step 2: Backend — build**

```bash
cd apps/backend && npm run build
```

Expected: No TypeScript errors.

- [ ] **Step 3: Flutter — analyze**

```bash
cd apps/mobile && flutter analyze
```

Expected: 0 errors, 0 warnings (up to the pre-existing 3 info notes is fine).

- [ ] **Step 4: Flutter — full test suite**

```bash
cd apps/mobile && flutter test
```

Expected: All tests pass.

- [ ] **Step 5: Final commit if any loose ends**

```bash
cd /Users/usuario/Desktop/votio && git status
```

If clean: done. If not: commit remaining changes.

---

## User Setup Required (post-implementation)

Before the app can authenticate at runtime, the user must:

1. Create a Firebase project at console.firebase.google.com
2. Enable **Email/Password** and **Google** providers under Authentication → Sign-in method
3. Register iOS app → download `GoogleService-Info.plist` → place in `apps/mobile/ios/Runner/`
4. Register Android app → download `google-services.json` → place in `apps/mobile/android/app/`
5. Run `cd apps/mobile && flutterfire configure` → generates `lib/firebase_options.dart`
6. Go to Project Settings → Service Accounts → Generate new private key → extract values into `apps/backend/.env`:
   ```
   FIREBASE_PROJECT_ID=your-project-id
   FIREBASE_CLIENT_EMAIL=firebase-adminsdk@your-project.iam.gserviceaccount.com
   FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
   ```
