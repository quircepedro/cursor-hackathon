import { Injectable } from '@nestjs/common';

@Injectable()
export class UsersService {
  getHealth() {
    return { status: 'ok' };
  }
}
