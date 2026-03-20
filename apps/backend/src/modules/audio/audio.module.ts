import { Module } from '@nestjs/common';
import { AudioController } from './controllers/audio.controller';
import { AudioService } from './services/audio.service';

@Module({
  imports: [],
  controllers: [AudioController],
  providers: [AudioService],
  exports: [],
})
export class AudioModule {}
