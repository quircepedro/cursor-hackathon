import { Injectable, Logger } from '@nestjs/common';

@Injectable()
export class TranscriptionService {
  private readonly logger = new Logger(TranscriptionService.name);

  // Transcription is handled client-side (device speech recognition).
  // This service is kept as a stub in case server-side transcription is needed in the future.
  async transcribe(_audioFilePath: string): Promise<string> {
    this.logger.warn('Server-side transcription is disabled. Use client-side transcription.');
    return '';
  }
}
