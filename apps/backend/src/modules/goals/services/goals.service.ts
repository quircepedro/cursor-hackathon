import { Injectable, BadRequestException, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '@database/prisma.service';

const MAX_ACTIVE_GOALS = 4;

@Injectable()
export class GoalsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(userId: string, title: string) {
    const activeCount = await this.prisma.goal.count({
      where: { userId, active: true },
    });
    if (activeCount >= MAX_ACTIVE_GOALS) {
      throw new BadRequestException(`Maximum ${MAX_ACTIVE_GOALS} active goals allowed`);
    }
    return this.prisma.goal.create({
      data: { userId, title },
    });
  }

  async findActive(userId: string) {
    return this.prisma.goal.findMany({
      where: { userId, active: true },
      orderBy: { createdAt: 'asc' },
    });
  }

  async update(userId: string, goalId: string, title: string) {
    const goal = await this.prisma.goal.findUnique({ where: { id: goalId } });
    if (!goal) throw new NotFoundException('Goal not found');
    if (goal.userId !== userId) throw new ForbiddenException();
    return this.prisma.goal.update({
      where: { id: goalId },
      data: { title },
    });
  }

  async remove(userId: string, goalId: string) {
    const goal = await this.prisma.goal.findUnique({ where: { id: goalId } });
    if (!goal) throw new NotFoundException('Goal not found');
    if (goal.userId !== userId) throw new ForbiddenException();
    return this.prisma.goal.update({
      where: { id: goalId },
      data: { active: false },
    });
  }

  async getAlignmentHistory(userId: string, days: number) {
    const since = new Date();
    since.setDate(since.getDate() - days);

    const alignments = await this.prisma.goalAlignment.findMany({
      where: {
        goal: { userId },
        createdAt: { gte: since },
      },
      include: {
        goal: { select: { id: true, title: true } },
        insight: { select: { createdAt: true, overallAlignment: true } },
      },
      orderBy: { createdAt: 'asc' },
    });

    const grouped = new Map<string, { overallScore: number; goals: Array<{ goalId: string; title: string; score: number }> }>();

    for (const a of alignments) {
      const dateKey = a.insight.createdAt.toISOString().split('T')[0];
      if (!grouped.has(dateKey)) {
        grouped.set(dateKey, {
          overallScore: a.insight.overallAlignment ?? 0,
          goals: [],
        });
      }
      grouped.get(dateKey)!.goals.push({
        goalId: a.goal.id,
        title: a.goal.title,
        score: a.score,
      });
    }

    return Array.from(grouped.entries()).map(([date, data]) => ({
      date,
      ...data,
    }));
  }
}
