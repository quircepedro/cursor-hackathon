import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import OpenAI from 'openai';
import * as fs from 'fs';

@Injectable()
export class TranscriptionService {
  private readonly logger = new Logger(TranscriptionService.name);
  private readonly openai: OpenAI;

  constructor(private readonly config: ConfigService) {
    const apiKey = this.config.get<string>('OPENAI_API_KEY') ?? '';
    this.openai = new OpenAI({ apiKey });
  }

  async transcribe(audioFilePath: string): Promise<string> {
    this.logger.log(`Transcribing audio: ${audioFilePath}`);

    const audioStream = fs.createReadStream(audioFilePath);

    const response = await this.openai.audio.transcriptions.create({
      model: 'whisper-1',
      file: audioStream,
      response_format: 'text',
    });

    // whisper-1 with response_format: 'text' returns a plain string
    const text = typeof response === 'string' ? response : (response as any).text ?? '';
    this.logger.log(`Transcription done (${text.length} chars)`);
    return text;
  }
}
