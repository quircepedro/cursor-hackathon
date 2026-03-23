import { Injectable, Logger, OnModuleInit, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';

@Injectable()
export class FirebaseService implements OnModuleInit {
  private readonly logger = new Logger(FirebaseService.name);
  private adminAuth!: admin.auth.Auth;

  constructor(private readonly configService: ConfigService) {}

  onModuleInit(): void {
    const firebaseConfig = this.configService.get<{
      projectId: string;
      clientEmail: string;
      privateKey: string;
    }>('firebase');

    try {
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
      this.logger.log('Firebase Admin SDK initialized successfully');
    } catch (error) {
      this.logger.error(`Firebase Admin SDK failed to initialize: ${error}`);
      this.logger.error('Auth endpoints will not work until FIREBASE_PRIVATE_KEY is fixed');
    }
  }

  async verifyIdToken(token: string): Promise<admin.auth.DecodedIdToken> {
    if (!this.adminAuth) {
      throw new UnauthorizedException('Firebase is not initialized — check FIREBASE_PRIVATE_KEY');
    }
    try {
      return await this.adminAuth.verifyIdToken(token);
    } catch {
      throw new UnauthorizedException('Invalid or expired Firebase token');
    }
  }
}
