import { Module } from '@nestjs/common';
import { PrismaModule } from '@database/prisma.module';
import { FirebaseModule } from '@modules/firebase/firebase.module';
import { UsersModule } from '@modules/users/users.module';
import { AnalysisModule } from '@modules/analysis/analysis.module';
import { GoalsModule } from '@modules/goals/goals.module';
import { StorageModule } from '@modules/storage/storage.module';
import { AudioController } from './controllers/audio.controller';
import { AudioService } from './services/audio.service';

@Module({
  imports: [PrismaModule, FirebaseModule, UsersModule, AnalysisModule, GoalsModule, StorageModule],
  controllers: [AudioController],
  providers: [AudioService],
  exports: [AudioService],
})
export class AudioModule {}
