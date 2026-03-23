import {
  Controller,
  Get,
  Post,
  Param,
  Body,
  Query,
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

  @Post('upload')
  @UseInterceptors(FileInterceptor('audio', { limits: { fileSize: 100 * 1024 * 1024 } }))
  upload(
    @CurrentUser() user: User,
    @UploadedFile() file: Express.Multer.File,
    @Body('transcript') transcript?: string,
    @Body('tzOffsetMinutes') tzOffsetMinutes?: string,
  ) {
    const parsed =
      tzOffsetMinutes !== undefined ? Number.parseInt(tzOffsetMinutes, 10) : undefined;
    return this.audioService.upload(
      user,
      file,
      transcript,
      Number.isNaN(parsed) ? undefined : parsed,
    );
  }

  @Get()
  getAll(@CurrentUser() user: User) {
    return this.audioService.getAll(user.id);
  }

  @Get('today')
  getToday(
    @CurrentUser() user: User,
    @Query('tzOffsetMinutes') tzOffsetMinutes?: string,
  ) {
    const parsedOffset =
      tzOffsetMinutes !== undefined ? Number.parseInt(tzOffsetMinutes, 10) : undefined;
    return this.audioService.getToday(
      user.id,
      Number.isNaN(parsedOffset) ? undefined : parsedOffset,
    );
  }

  @Get(':id')
  getById(@CurrentUser() user: User, @Param('id') id: string) {
    return this.audioService.getById(user.id, id);
  }
}
