import { Injectable } from '@nestjs/common';

@Injectable()
export class TranscriptionService {
  getHealth() {
    return { status: 'ok' };
  }
}
