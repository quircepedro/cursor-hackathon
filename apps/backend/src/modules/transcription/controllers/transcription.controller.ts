import { Controller, Get } from '@nestjs/common';
import { TranscriptionService } from '../services/transcription.service';

@Controller('transcription')
export class TranscriptionController {
  constructor(private readonly transcriptionService: TranscriptionService) {}

  @Get('health')
  getHealth() {
    return this.transcriptionService.getHealth();
  }
}
