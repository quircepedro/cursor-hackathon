import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { FirebaseAuthGuard } from '@modules/auth/guards/firebase-auth.guard';
import { AnalysisService } from '../services/analysis.service';
import { AnalyseJournalDto } from '../dto/analyse-journal.dto';

@Controller('analysis')
export class AnalysisController {
  constructor(private readonly analysisService: AnalysisService) {}

  @Get('health')
  getHealth() {
    return { status: 'ok' };
  }

  @Post('journal')
  @UseGuards(FirebaseAuthGuard)
  async analyseJournal(@Body() dto: AnalyseJournalDto) {
    return this.analysisService.analyseJournal(dto.transcript, []);
  }
}
