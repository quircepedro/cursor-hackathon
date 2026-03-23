import { Injectable, Logger, NotFoundException, ForbiddenException } from '@nestjs/common';
import type { User } from '@prisma/client';
import { RecordingStatus } from '@prisma/client';
import { PrismaService } from '@database/prisma.service';
import { TranscriptionService } from '@modules/transcription/services/transcription.service';
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
    private readonly transcription: TranscriptionService,
    private readonly analysis: AnalysisService,
    private readonly goalsService: GoalsService,
    private readonly storage: StorageService,
  ) {}

  async upload(
    user: User,
    file: Express.Multer.File,
  ): Promise<{ id: string; status: string }> {
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

    void this.runPipeline(recording.id, tmpPath, user.id, ext);

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

  // ─── Pipeline ────────────────────────────────────────────────────────────────

  private async runPipeline(
    recordingId: string,
    audioPath: string,
    userId: string,
    ext: string,
  ): Promise<void> {
    try {
      // Step 1: Upload to R2
      const s3Key = `audio/${userId}/${recordingId}${ext}`;
      await this.storage.uploadFile(audioPath, s3Key);
      await this.prisma.recording.update({
        where: { id: recordingId },
        data: { audioUrl: s3Key },
      });

      // Step 2: Transcribe (client-side — returns empty string)
      await this.setStatus(recordingId, RecordingStatus.TRANSCRIBING);
      const text = await this.transcription.transcribe(audioPath);
      await this.prisma.transcription.create({
        data: { recordingId, text, language: 'auto' },
      });

      // Step 3: Fetch user's goals
      const goals = await this.goalsService.findActive(userId);

      // Step 4: Analyse with Gemini (emotion + goal alignment)
      await this.setStatus(recordingId, RecordingStatus.ANALYZING);
      const result = await this.analysis.analyseJournal(text, goals);

      // Step 5: Save Insight
      const insight = await this.prisma.insight.create({
        data: {
          recordingId,
          summary: result.emotion.summary,
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
}
