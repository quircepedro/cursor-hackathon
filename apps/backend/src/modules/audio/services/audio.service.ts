import { Injectable, Logger, NotFoundException, ForbiddenException } from '@nestjs/common';
import type { User } from '@prisma/client';
import { RecordingStatus } from '@prisma/client';
import { PrismaService } from '@database/prisma.service';
import { TranscriptionService } from '@modules/transcription/services/transcription.service';
import { AnalysisService } from '@modules/analysis/services/analysis.service';
import { GoalsService } from '@modules/goals/services/goals.service';
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
  ) {}

  async upload(
    user: User,
    file: Express.Multer.File,
  ): Promise<{ id: string; status: string }> {
    // Persist the buffer to a temp file so Whisper can stream it
    const ext = path.extname(file.originalname) || '.m4a';
    const tmpPath = path.join(os.tmpdir(), `votio_${Date.now()}${ext}`);
    fs.writeFileSync(tmpPath, file.buffer);

    this.logger.log(`Audio saved to ${tmpPath} (${file.size} bytes)`);

    const recording = await this.prisma.recording.create({
      data: {
        userId: user.id,
        title: `Journal – ${new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}`,
        audioUrl: tmpPath,
        duration: 0,
        status: RecordingStatus.UPLOADING,
      },
    });

    // Kick off pipeline without blocking the HTTP response
    void this.runPipeline(recording.id, tmpPath);

    return { id: recording.id, status: recording.status };
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

  private async runPipeline(recordingId: string, audioPath: string): Promise<void> {
    try {
      // Step 1: Transcribe
      await this.setStatus(recordingId, RecordingStatus.TRANSCRIBING);
      const text = await this.transcription.transcribe(audioPath);
      await this.prisma.transcription.create({
        data: { recordingId, text, language: 'auto' },
      });

      // Step 2: Fetch user's goals
      const recording = await this.prisma.recording.findUnique({
        where: { id: recordingId },
        select: { userId: true },
      });
      const goals = await this.goalsService.findActive(recording!.userId);

      // Step 3: Analyse with Gemini (emotion + goal alignment)
      await this.setStatus(recordingId, RecordingStatus.ANALYZING);
      const result = await this.analysis.analyseJournal(text, goals);

      // Step 4: Save Insight with all parsed fields
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

      // Step 5: Save GoalAlignment records
      if (goals.length > 0 && result.goalAlignment.goals.length > 0) {
        const alignmentData = result.goalAlignment.goals
          .filter((g) => g.goalIndex >= 0 && g.goalIndex < goals.length)
          .map((g) => ({
            insightId: insight.id,
            goalId: goals[g.goalIndex].id,
            score: g.score,
            level: g.level as any, // AlignmentLevel enum
            reason: g.reason,
          }));

        await this.prisma.goalAlignment.createMany({ data: alignmentData });
      }

      // Done
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
