import { Module } from '@nestjs/common';
import { PrismaModule } from '@database/prisma.module';
import { FirebaseModule } from '@modules/firebase/firebase.module';
import { UsersModule } from '@modules/users/users.module';
import { TranscriptionModule } from '@modules/transcription/transcription.module';
import { AnalysisModule } from '@modules/analysis/analysis.module';
import { GoalsModule } from '@modules/goals/goals.module';
import { AudioController } from './controllers/audio.controller';
import { AudioService } from './services/audio.service';

@Module({
  imports: [PrismaModule, FirebaseModule, UsersModule, TranscriptionModule, AnalysisModule, GoalsModule],
  controllers: [AudioController],
  providers: [AudioService],
  exports: [AudioService],
})
export class AudioModule {}
