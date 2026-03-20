import { Injectable } from '@nestjs/common';

@Injectable()
export class HistoryService {
  getHealth() {
    return { status: 'ok' };
  }
}
