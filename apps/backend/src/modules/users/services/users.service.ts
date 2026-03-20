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
      // update: use ?? undefined so Prisma ignores missing fields (prevents erasing stored email)
      update: {
        email: decoded.email ?? undefined,
        emailVerified: decoded.email_verified ?? false,
        displayName: decoded.name ?? undefined,
        profilePicture: decoded.picture ?? undefined,
      },
      // create: use ?? null for explicit nulls on new records
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
