import {
  Controller,
  Get,
  Post,
  Param,
  UseGuards,
  UseInterceptors,
  UploadedFile,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import type { User } from '@prisma/client';
import { FirebaseAuthGuard } from '@modules/auth/guards/firebase-auth.guard';
import { CurrentUser } from '@modules/auth/decorators/current-user.decorator';
import { AudioService } from '../services/audio.service';

@Controller('audio')
@UseGuards(FirebaseAuthGuard)
export class AudioController {
  constructor(private readonly audioService: AudioService) {}

  /**
   * Upload an audio file and trigger the processing pipeline.
   * Returns immediately with the recording id and initial status.
   */
  @Post('upload')
  @UseInterceptors(FileInterceptor('audio', { limits: { fileSize: 100 * 1024 * 1024 } }))
  upload(
    @CurrentUser() user: User,
    @UploadedFile() file: Express.Multer.File,
  ) {
    return this.audioService.upload(user, file);
  }

  /**
   * Poll the status and result of a recording.
   */
  @Get(':id')
  getById(@CurrentUser() user: User, @Param('id') id: string) {
    return this.audioService.getById(user.id, id);
  }
}
