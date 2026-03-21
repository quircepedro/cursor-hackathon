import { Controller, Get, Post, Put, Delete, Param, Body, Query, UseGuards } from '@nestjs/common';
import type { User } from '@prisma/client';
import { FirebaseAuthGuard } from '@modules/auth/guards/firebase-auth.guard';
import { CurrentUser } from '@modules/auth/decorators/current-user.decorator';
import { GoalsService } from '../services/goals.service';
import { CreateGoalDto } from '../dto/create-goal.dto';
import { UpdateGoalDto } from '../dto/update-goal.dto';

@Controller('goals')
@UseGuards(FirebaseAuthGuard)
export class GoalsController {
  constructor(private readonly goalsService: GoalsService) {}

  @Post()
  create(@CurrentUser() user: User, @Body() dto: CreateGoalDto) {
    return this.goalsService.create(user.id, dto.title);
  }

  @Get()
  findActive(@CurrentUser() user: User) {
    return this.goalsService.findActive(user.id);
  }

  @Get('alignment/history')
  getAlignmentHistory(@CurrentUser() user: User, @Query('days') days?: string) {
    return this.goalsService.getAlignmentHistory(user.id, Number(days) || 30);
  }

  @Put(':id')
  update(@CurrentUser() user: User, @Param('id') id: string, @Body() dto: UpdateGoalDto) {
    return this.goalsService.update(user.id, id, dto.title);
  }

  @Delete(':id')
  remove(@CurrentUser() user: User, @Param('id') id: string) {
    return this.goalsService.remove(user.id, id);
  }
}
