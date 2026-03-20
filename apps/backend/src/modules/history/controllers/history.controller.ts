import { Controller, Get } from '@nestjs/common';
import { HistoryService } from '../services/history.service';

@Controller('history')
export class HistoryController {
  constructor(private readonly historyService: HistoryService) {}

  @Get('health')
  getHealth() {
    return this.historyService.getHealth();
  }
}
