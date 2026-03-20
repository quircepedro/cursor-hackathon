import { Controller, Get } from '@nestjs/common';
import { AnalysisService } from '../services/analysis.service';

@Controller('analysis')
export class AnalysisController {
  constructor(private readonly analysisService: AnalysisService) {}

  @Get('health')
  getHealth() {
    return this.analysisService.getHealth();
  }
}
