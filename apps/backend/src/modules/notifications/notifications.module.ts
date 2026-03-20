import { Module } from '@nestjs/common';
import { NotificationsController } from './controllers/notifications.controller';
import { NotificationsService } from './services/notifications.service';

@Module({
  imports: [],
  controllers: [NotificationsController],
  providers: [NotificationsService],
  exports: [],
})
export class NotificationsModule {}
