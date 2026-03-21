import { Module } from '@nestjs/common';
import { PrismaModule } from '@database/prisma.module';
import { FirebaseModule } from '@modules/firebase/firebase.module';
import { UsersModule } from '@modules/users/users.module';
import { GoalsController } from './controllers/goals.controller';
import { GoalsService } from './services/goals.service';

@Module({
  imports: [PrismaModule, FirebaseModule, UsersModule],
  controllers: [GoalsController],
  providers: [GoalsService],
  exports: [GoalsService],
})
export class GoalsModule {}
