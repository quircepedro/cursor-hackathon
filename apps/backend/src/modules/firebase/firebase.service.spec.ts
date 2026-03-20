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
