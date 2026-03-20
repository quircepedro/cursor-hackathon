import { Module } from '@nestjs/common';
import { SubscriptionsController } from './controllers/subscriptions.controller';
import { SubscriptionsService } from './services/subscriptions.service';

@Module({
  imports: [],
  controllers: [SubscriptionsController],
  providers: [SubscriptionsService],
  exports: [],
})
export class SubscriptionsModule {}
