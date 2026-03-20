import { Injectable } from '@nestjs/common';

@Injectable()
export class ClipsService {
  getHealth() {
    return { status: 'ok' };
  }
}
