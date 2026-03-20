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
