import { Injectable } from '@nestjs/common';

@Injectable()
export class SubscriptionsService {
  getHealth() {
    return { status: 'ok' };
  }
}
