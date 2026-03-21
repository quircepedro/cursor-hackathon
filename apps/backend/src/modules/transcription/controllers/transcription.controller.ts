import { Controller, Get } from '@nestjs/common';

@Controller('transcription')
export class TranscriptionController {
  @Get('health')
  getHealth() {
    return { status: 'ok' };
  }
}
