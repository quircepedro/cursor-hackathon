import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import type { Request } from 'express';
import { FirebaseService } from '../../firebase/firebase.service';
import { UsersService } from '../../users/services/users.service';

@Injectable()
export class FirebaseAuthGuard implements CanActivate {
  constructor(
    private readonly firebaseService: FirebaseService,
    private readonly usersService: UsersService,
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
