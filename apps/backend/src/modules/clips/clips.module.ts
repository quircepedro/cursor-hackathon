import { Module } from '@nestjs/common';
import { ClipsController } from './controllers/clips.controller';
import { ClipsService } from './services/clips.service';

@Module({
  imports: [],
  controllers: [ClipsController],
  providers: [ClipsService],
  exports: [],
})
export class ClipsModule {}
