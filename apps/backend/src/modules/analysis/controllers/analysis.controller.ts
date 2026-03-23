import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import type { User } from '@prisma/client';
import { FirebaseAuthGuard } from '@modules/auth/guards/firebase-auth.guard';
import { CurrentUser } from '@modules/auth/decorators/current-user.decorator';
import { GoalsService } from '@modules/goals/services/goals.service';
import { AnalysisService } from '../services/analysis.service';
import { AnalyseJournalDto } from '../dto/analyse-journal.dto';

@Controller('analysis')
export class AnalysisController {
  constructor(
    private readonly analysisService: AnalysisService,
    private readonly goalsService: GoalsService,
  ) {}

  @Get('health')
  getHealth() {
    return { status: 'ok' };
  }

  @Post('journal')
  @UseGuards(FirebaseAuthGuard)
  async analyseJournal(@CurrentUser() user: User, @Body() dto: AnalyseJournalDto) {
    const goals = await this.goalsService.findActive(user.id);
    return this.analysisService.analyseJournal(dto.transcript, goals);
  }
}
