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
      providers: [
        UsersService,
        { provide: PrismaService, useValue: prisma },
      ],
    }).compile();
    service = module.get<UsersService>(UsersService);
  });

  describe('findOrCreateFromFirebase', () => {
    it('upserts user by providerUid and returns the user', async () => {
      prisma.user.upsert.mockResolvedValue(mockUser);
      const result = await service.findOrCreateFromFirebase(mockDecodedToken);
      expect(prisma.user.upsert).toHaveBeenCalledWith({
        where: { providerUid: 'firebase-uid-123' },
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
        }),
      );
    });
  });
});
