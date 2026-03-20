import { Controller, Get } from '@nestjs/common';
import { ClipsService } from '../services/clips.service';

@Controller('clips')
export class ClipsController {
  constructor(private readonly clipsService: ClipsService) {}

  @Get('health')
  getHealth() {
    return this.clipsService.getHealth();
  }
}
