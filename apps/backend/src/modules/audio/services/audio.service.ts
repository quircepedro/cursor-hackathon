import { Injectable, Logger, NotFoundException, ForbiddenException } from '@nestjs/common';
import type { User } from '@prisma/client';
import { RecordingStatus } from '@prisma/client';
import { PrismaService } from '@database/prisma.service';
import { AnalysisService } from '@modules/analysis/services/analysis.service';
import { GoalsService } from '@modules/goals/services/goals.service';
import { StorageService } from '@modules/storage/storage.service';
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';

@Injectable()
export class AudioService {
  private readonly logger = new Logger(AudioService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly analysis: AnalysisService,
    private readonly goalsService: GoalsService,
    private readonly storage: StorageService,
  ) {}

  async upload(
    user: User,
    file: Express.Multer.File,
    clientTranscript?: string,
    tzOffsetMinutes?: number,
    referenceDate?: Date,
  ): Promise<{ id: string; status: string }> {
    const existingToday = await this.findTodayRecording(user.id, tzOffsetMinutes, referenceDate);
    if (
      existingToday &&
      existingToday.status !== RecordingStatus.FAILED
    ) {
      throw new ForbiddenException('You already recorded today');
    }

    const ext = path.extname(file.originalname) || '.m4a';
    const tmpPath = path.join(os.tmpdir(), `votio_${Date.now()}${ext}`);
    fs.writeFileSync(tmpPath, file.buffer);

    this.logger.log(`Audio saved to ${tmpPath} (${file.size} bytes)`);

    const recording = await this.prisma.recording.create({
      data: {
        userId: user.id,
        title: `Journal – ${new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}`,
        audioUrl: '',
        duration: 0,
        status: RecordingStatus.UPLOADING,
      },
    });

    void this.runPipeline(recording.id, tmpPath, user.id, ext, clientTranscript ?? '');

    return { id: recording.id, status: recording.status };
  }

  async getAll(userId: string) {
    const recordings = await this.prisma.recording.findMany({
      where: { userId, status: RecordingStatus.COMPLETE },
      orderBy: { createdAt: 'desc' },
      include: {
        insight: {
          include: {
            goalAlignments: {
              include: { goal: { select: { id: true, title: true } } },
            },
          },
        },
      },
    });

    return Promise.all(
      recordings.map(async (r) => ({
        id: r.id,
        title: r.title,
        createdAt: r.createdAt,
        status: r.status,
        audioStreamUrl: r.audioUrl ? await this.storage.getSignedUrl(r.audioUrl) : null,
        insight: r.insight,
      })),
    );
  }

  async getById(userId: string, recordingId: string) {
    const recording = await this.prisma.recording.findUnique({
      where: { id: recordingId },
      include: {
        transcription: true,
        insight: {
          include: {
            goalAlignments: {
              include: { goal: { select: { id: true, title: true } } },
            },
          },
        },
      },
    });

    if (!recording) throw new NotFoundException('Recording not found');
    if (recording.userId !== userId) throw new ForbiddenException();

    return recording;
  }

  async getToday(userId: string, tzOffsetMinutes?: number, referenceDate?: Date) {
    const recording = await this.findTodayRecording(userId, tzOffsetMinutes, referenceDate);
    if (!recording || recording.status === RecordingStatus.FAILED) {
      return null;
    }

    const isComplete = recording.status === RecordingStatus.COMPLETE;
    return {
      id: recording.id,
      title: recording.title,
      createdAt: recording.createdAt,
      status: recording.status,
      audioStreamUrl:
        isComplete && recording.audioUrl
          ? await this.storage.getSignedUrl(recording.audioUrl)
          : null,
      insight: isComplete ? recording.insight : null,
    };
  }

  // ─── Pipeline ────────────────────────────────────────────────────────────────

  private async runPipeline(
    recordingId: string,
    audioPath: string,
    userId: string,
    ext: string,
    transcript: string,
  ): Promise<void> {
    try {
      // Step 1: Upload to R2
      const s3Key = `audio/${userId}/${recordingId}${ext}`;
      await this.storage.uploadFile(audioPath, s3Key);
      await this.prisma.recording.update({
        where: { id: recordingId },
        data: { audioUrl: s3Key },
      });
      this.logger.log(`Audio uploaded to R2: ${s3Key}`);

      // Step 2: Save transcription
      await this.setStatus(recordingId, RecordingStatus.TRANSCRIBING);
      await this.prisma.transcription.create({
        data: { recordingId, text: transcript, language: 'auto' },
      });

      // Step 3: Fetch user's goals
      const goals = await this.goalsService.findActive(userId);

      // Step 4: Analyse with Gemini (uses client transcript)
      await this.setStatus(recordingId, RecordingStatus.ANALYZING);
      const result = await this.analysis.analyseJournal(transcript, goals);

      // Step 5: Save Insight
      const insight = await this.prisma.insight.create({
        data: {
          recordingId,
          summary: result.emotion.summary,
          dailySummary: result.emotion.dailySummary ?? null,
          emotionScores: result.emotion.emotionScores,
          keyThemes: result.emotion.keyThemes,
          sentiment: result.emotion.sentiment,
          overallAlignment: result.goalAlignment.overallScore,
        },
      });

      // Step 6: Save GoalAlignment records
      if (goals.length > 0 && result.goalAlignment.goals.length > 0) {
        const alignmentData = result.goalAlignment.goals
          .filter((g) => g.goalIndex >= 0 && g.goalIndex < goals.length)
          .map((g) => ({
            insightId: insight.id,
            goalId: goals[g.goalIndex].id,
            score: g.score,
            level: g.level as any,
            reason: g.reason,
          }));
        await this.prisma.goalAlignment.createMany({ data: alignmentData });
      }

      await this.setStatus(recordingId, RecordingStatus.COMPLETE);
      this.logger.log(`Pipeline complete for recording ${recordingId}`);
    } catch (err) {
      this.logger.error(`Pipeline failed for recording ${recordingId}`, err);
      await this.setStatus(recordingId, RecordingStatus.FAILED).catch(() => null);
    } finally {
      fs.unlink(audioPath, () => null);
    }
  }

  private async setStatus(id: string, status: RecordingStatus): Promise<void> {
    await this.prisma.recording.update({ where: { id }, data: { status } });
  }

  private getTodayRangeUtc(
    tzOffsetMinutes = 0,
    date: Date = new Date(),
  ): { start: Date; end: Date } {
    // Shift UTC "now" → local "now" by adding the offset
    const localNowMs = date.getTime() + tzOffsetMinutes * 60 * 1000;
    const localNow = new Date(localNowMs);

    // Extract the local date (midnight in local representation)
    const midnightLocalMs = Date.UTC(
      localNow.getUTCFullYear(),
      localNow.getUTCMonth(),
      localNow.getUTCDate(),
    );

    // Convert local midnight back to UTC by subtracting the offset
    const start = new Date(midnightLocalMs - tzOffsetMinutes * 60 * 1000);
    const end = new Date(start.getTime() + 24 * 60 * 60 * 1000);
    return { start, end };
  }

  private async findTodayRecording(userId: string, tzOffsetMinutes?: number, referenceDate?: Date) {
    const { start, end } = this.getTodayRangeUtc(tzOffsetMinutes ?? 0, referenceDate ?? new Date());
    return this.prisma.recording.findFirst({
      where: {
        userId,
        createdAt: {
          gte: start,
          lt: end,
        },
      },
      orderBy: { createdAt: 'desc' },
      include: {
        insight: {
          include: {
            goalAlignments: {
              include: { goal: { select: { id: true, title: true } } },
            },
          },
        },
      },
    });
  }
}
