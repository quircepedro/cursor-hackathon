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
    const fromClient =
      dto.goals?.map((g) => g.title.trim()).filter((t) => t.length > 0) ?? [];
    const goalsForPrompt =
      fromClient.length > 0
        ? fromClient.map((title) => ({ title }))
        : (await this.goalsService.findActive(user.id)).map((g) => ({
            title: g.title,
          }));
    return this.analysisService.analyseJournal(dto.transcript, goalsForPrompt);
  }
}
