import { Module } from '@nestjs/common';
import { TranscriptionController } from './controllers/transcription.controller';
import { TranscriptionService } from './services/transcription.service';

@Module({
  imports: [],
  controllers: [TranscriptionController],
  providers: [TranscriptionService],
  exports: [],
})
export class TranscriptionModule {}
