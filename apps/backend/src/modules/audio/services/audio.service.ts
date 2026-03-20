import { Injectable } from '@nestjs/common';

@Injectable()
export class AudioService {
  getHealth() {
    return { status: 'ok' };
  }
}
