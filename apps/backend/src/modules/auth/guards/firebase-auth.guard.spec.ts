import { Test, TestingModule } from '@nestjs/testing';
import { ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { FirebaseAuthGuard } from './firebase-auth.guard';
import { FirebaseService } from '../../firebase/firebase.service';
import { UsersService } from '../../users/services/users.service';

const mockDecoded = { uid: 'uid-abc', email: 'a@b.com', email_verified: true, name: 'Alice' };
const mockUser = { id: 'cuid1', providerUid: 'uid-abc' };

function makeContext(authHeader?: string): ExecutionContext {
  const req = { headers: { authorization: authHeader }, user: undefined as any };
  return {
    switchToHttp: () => ({
      getRequest: () => req,
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
