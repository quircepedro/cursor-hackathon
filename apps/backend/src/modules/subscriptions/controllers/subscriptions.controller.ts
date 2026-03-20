import { Controller, Get } from '@nestjs/common';
import { SubscriptionsService } from '../services/subscriptions.service';

@Controller('subscriptions')
export class SubscriptionsController {
  constructor(private readonly subscriptionsService: SubscriptionsService) {}

  @Get('health')
  getHealth() {
    return this.subscriptionsService.getHealth();
  }
}
