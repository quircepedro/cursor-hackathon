# Goal Alignment System Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add goal-alignment productivity layer — users define 2-4 objectives during onboarding, AI analyzes daily journaling against those objectives, results displayed as charts.

**Architecture:** Single Gemini prompt returns JSON with both emotional analysis and goal alignment. New `Goal` and `GoalAlignment` Prisma models. New NestJS `goals` module for CRUD + history. Flutter gets goals onboarding screen, goals management, and `fl_chart` visualizations on result screen.

**Tech Stack:** NestJS, Prisma/PostgreSQL, Gemini 2.5 Flash, Flutter/Riverpod, fl_chart, GoRouter

**Spec:** `docs/superpowers/specs/2026-03-21-goal-alignment-design.md`

---

## File Structure

### Backend (NestJS)

| Action | File                                                             | Responsibility                                                                              |
| ------ | ---------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| Modify | `apps/backend/prisma/schema.prisma`                              | Add `AlignmentLevel` enum, `Goal` model, `GoalAlignment` model, modify `Insight` and `User` |
| Create | `apps/backend/src/modules/goals/goals.module.ts`                 | Module definition                                                                           |
| Create | `apps/backend/src/modules/goals/controllers/goals.controller.ts` | CRUD + history endpoints                                                                    |
| Create | `apps/backend/src/modules/goals/services/goals.service.ts`       | Business logic, validation                                                                  |
| Create | `apps/backend/src/modules/goals/dto/create-goal.dto.ts`          | Validation DTO                                                                              |
| Create | `apps/backend/src/modules/goals/dto/update-goal.dto.ts`          | Validation DTO                                                                              |
| Modify | `apps/backend/src/modules/analysis/services/analysis.service.ts` | New prompt, JSON response, goals parameter                                                  |
| Modify | `apps/backend/src/modules/audio/services/audio.service.ts`       | Fetch goals, pass to analysis, save GoalAlignment records                                   |
| Modify | `apps/backend/src/modules/audio/audio.module.ts`                 | Import GoalsModule                                                                          |
| Modify | `apps/backend/src/app.module.ts`                                 | Import GoalsModule                                                                          |

### Frontend (Flutter)

| Action | File                                                                               | Responsibility                    |
| ------ | ---------------------------------------------------------------------------------- | --------------------------------- |
| Create | `apps/mobile/lib/features/goals/domain/entities/goal_entity.dart`                  | Goal data model                   |
| Create | `apps/mobile/lib/features/goals/domain/entities/goal_alignment_entity.dart`        | Alignment data model              |
| Create | `apps/mobile/lib/features/goals/domain/entities/alignment_history_entity.dart`     | History data model                |
| Create | `apps/mobile/lib/features/goals/domain/repositories/goals_repository.dart`         | Abstract repository               |
| Create | `apps/mobile/lib/features/goals/data/repositories/api_goals_repository.dart`       | API implementation                |
| Create | `apps/mobile/lib/features/goals/application/providers/goals_provider.dart`         | State management                  |
| Create | `apps/mobile/lib/features/goals/presentation/screens/goals_onboarding_screen.dart` | Onboarding flow                   |
| Create | `apps/mobile/lib/features/goals/presentation/screens/goals_screen.dart`            | Manage goals from Home            |
| Create | `apps/mobile/lib/features/goals/presentation/widgets/alignment_bar_chart.dart`     | Horizontal bars                   |
| Create | `apps/mobile/lib/features/goals/presentation/widgets/alignment_radar_chart.dart`   | Radar/spider chart                |
| Create | `apps/mobile/lib/features/goals/presentation/widgets/alignment_trend_chart.dart`   | Historical trend lines            |
| Create | `apps/mobile/lib/features/goals/presentation/widgets/alignment_cards.dart`         | Qualitative level cards           |
| Modify | `apps/mobile/lib/features/recording/domain/entities/insight_entity.dart`           | Add alignment fields              |
| Modify | `apps/mobile/lib/features/recording/presentation/screens/result_screen.dart`       | Add alignment section with charts |
| Modify | `apps/mobile/lib/features/home/presentation/screens/home_screen.dart`              | Add "Mis Objetivos" card          |
| Modify | `apps/mobile/lib/app/router/app_router.dart`                                       | Add goals routes + redirect logic |
| Modify | `apps/mobile/lib/app/router/route_names.dart`                                      | Add route constants               |
| Modify | `apps/mobile/pubspec.yaml`                                                         | Add fl_chart dependency           |

---

## Task 1: Prisma Schema — Add Goal, GoalAlignment, AlignmentLevel

**Files:**

- Modify: `apps/backend/prisma/schema.prisma`

- [ ] **Step 1: Add enum and models to schema**

Add after the `SubscriptionTier` enum:

```prisma
enum AlignmentLevel {
  CLEAR_PROGRESS
  PARTIAL_PROGRESS
  NO_EVIDENCE
  DEVIATION
}
```

Add after the `User` model's relations (inside the User model block, after `notifications Notification[]`):

```prisma
  goals         Goal[]
```

Add `overallAlignment` and `goalAlignments` to the `Insight` model, after `sentiment`:

```prisma
  overallAlignment Float?
  goalAlignments   GoalAlignment[]
```

Add new models after the `Notification` model:

```prisma
model Goal {
  id        String   @id @default(cuid())
  userId    String
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)

  title     String
  active    Boolean  @default(true)

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  alignments GoalAlignment[]

  @@index([userId])
}

model GoalAlignment {
  id        String         @id @default(cuid())
  insightId String
  insight   Insight        @relation(fields: [insightId], references: [id], onDelete: Cascade)
  goalId    String
  goal      Goal           @relation(fields: [goalId], references: [id], onDelete: Cascade)

  score     Float
  level     AlignmentLevel
  reason    String

  createdAt DateTime @default(now())

  @@unique([insightId, goalId])
  @@index([insightId])
}
```

- [ ] **Step 2: Generate migration and apply**

Run:

```bash
cd apps/backend && npx prisma migrate dev --name add-goals-and-alignment
```

Expected: Migration created and applied successfully. Prisma Client regenerated.

- [ ] **Step 3: Verify Prisma Client types**

Run:

```bash
cd apps/backend && npx prisma generate
```

Expected: Prisma Client generated with `Goal`, `GoalAlignment`, and `AlignmentLevel` types.

- [ ] **Step 4: Commit**

```bash
git add apps/backend/prisma/
git commit -m "feat(db): add Goal, GoalAlignment models and AlignmentLevel enum"
```

---

## Task 2: Backend — Goals Module (CRUD)

**Files:**

- Create: `apps/backend/src/modules/goals/dto/create-goal.dto.ts`
- Create: `apps/backend/src/modules/goals/dto/update-goal.dto.ts`
- Create: `apps/backend/src/modules/goals/services/goals.service.ts`
- Create: `apps/backend/src/modules/goals/controllers/goals.controller.ts`
- Create: `apps/backend/src/modules/goals/goals.module.ts`
- Modify: `apps/backend/src/app.module.ts`

- [ ] **Step 1: Create DTOs**

`apps/backend/src/modules/goals/dto/create-goal.dto.ts`:

```typescript
import { IsString, MinLength, MaxLength } from 'class-validator';

export class CreateGoalDto {
  @IsString()
  @MinLength(1, { message: 'Title must not be empty' })
  @MaxLength(100, { message: 'Title must be at most 100 characters' })
  title!: string;
}
```

`apps/backend/src/modules/goals/dto/update-goal.dto.ts`:

```typescript
import { IsString, MinLength, MaxLength } from 'class-validator';

export class UpdateGoalDto {
  @IsString()
  @MinLength(1, { message: 'Title must not be empty' })
  @MaxLength(100, { message: 'Title must be at most 100 characters' })
  title!: string;
}
```

- [ ] **Step 2: Create GoalsService**

`apps/backend/src/modules/goals/services/goals.service.ts`:

```typescript
import {
  Injectable,
  BadRequestException,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
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

    // Group by date
    const grouped = new Map<
      string,
      { overallScore: number; goals: Array<{ goalId: string; title: string; score: number }> }
    >();

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
```

- [ ] **Step 3: Create GoalsController**

`apps/backend/src/modules/goals/controllers/goals.controller.ts`:

```typescript
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

  @Put(':id')
  update(@CurrentUser() user: User, @Param('id') id: string, @Body() dto: UpdateGoalDto) {
    return this.goalsService.update(user.id, id, dto.title);
  }

  @Delete(':id')
  remove(@CurrentUser() user: User, @Param('id') id: string) {
    return this.goalsService.remove(user.id, id);
  }

  @Get('alignment/history')
  getAlignmentHistory(@CurrentUser() user: User, @Query('days') days?: string) {
    return this.goalsService.getAlignmentHistory(user.id, Number(days) || 30);
  }
}
```

- [ ] **Step 4: Create GoalsModule**

`apps/backend/src/modules/goals/goals.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { PrismaModule } from '@database/prisma.module';
import { FirebaseModule } from '@modules/firebase/firebase.module';
import { UsersModule } from '@modules/users/users.module';
import { GoalsController } from './controllers/goals.controller';
import { GoalsService } from './services/goals.service';

@Module({
  imports: [PrismaModule, FirebaseModule, UsersModule],
  controllers: [GoalsController],
  providers: [GoalsService],
  exports: [GoalsService],
})
export class GoalsModule {}
```

- [ ] **Step 5: Register GoalsModule in AppModule**

In `apps/backend/src/app.module.ts`, add import:

```typescript
import { GoalsModule } from '@modules/goals/goals.module';
```

Add `GoalsModule` to the `imports` array after `AnalysisModule`.

- [ ] **Step 6: Verify backend compiles**

Run:

```bash
cd apps/backend && npx nest build
```

Expected: Build succeeds with no errors.

- [ ] **Step 7: Commit**

```bash
git add apps/backend/src/modules/goals/ apps/backend/src/app.module.ts
git commit -m "feat(goals): add Goals module with CRUD and alignment history endpoints"
```

---

## Task 3: Backend — Restructure AI Analysis Prompt

**Files:**

- Modify: `apps/backend/src/modules/analysis/services/analysis.service.ts`

- [ ] **Step 1: Update interface and prompt**

Replace the entire file content of `apps/backend/src/modules/analysis/services/analysis.service.ts`:

```typescript
import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type { Goal } from '@prisma/client';

export interface GoalAlignmentResult {
  goalIndex: number;
  score: number;
  level: 'CLEAR_PROGRESS' | 'PARTIAL_PROGRESS' | 'NO_EVIDENCE' | 'DEVIATION';
  reason: string;
}

export interface AnalysisResult {
  emotion: {
    summary: string;
    emotionScores: Record<string, number>;
    keyThemes: string[];
    sentiment: 'POSITIVE' | 'NEUTRAL' | 'NEGATIVE';
  };
  goalAlignment: {
    overallScore: number;
    goals: GoalAlignmentResult[];
  };
}

function buildSystemPrompt(goals: Goal[]): string {
  const goalsSection = goals.map((g, i) => `  goal_${i}: "${g.title}"`).join('\n');

  return `Eres un analista experto integrado en una app de journaling diario por voz. Tu trabajo es analizar el transcript del usuario y devolver un JSON válido con dos secciones: análisis emocional y alineación con objetivos.

OBJETIVOS DEL USUARIO:
${goalsSection}

DEBES devolver EXCLUSIVAMENTE un JSON válido con esta estructura exacta (sin markdown, sin backticks, sin texto adicional):

{
  "emotion": {
    "summary": "análisis emocional de 150-250 palabras en prosa continua...",
    "emotionScores": { "emocion1": 0.0-1.0, "emocion2": 0.0-1.0 },
    "keyThemes": ["tema1", "tema2"],
    "sentiment": "POSITIVE | NEUTRAL | NEGATIVE"
  },
  "goalAlignment": {
    "overallScore": 0.0-1.0,
    "goals": [
      {
        "goalIndex": 0,
        "score": 0.0-1.0,
        "level": "CLEAR_PROGRESS | PARTIAL_PROGRESS | NO_EVIDENCE | DEVIATION",
        "reason": "justificación basada en el transcript"
      }
    ]
  }
}

REGLAS PARA EL ANÁLISIS EMOCIONAL (campo "summary"):
- MÍNIMO 150 palabras, MÁXIMO 250 palabras, en 2-3 párrafos de prosa continua.
- Identifica emociones específicas (no solo "bien" o "mal" — usa frustración, alivio, nostalgia, etc.).
- Señala patrones que el usuario quizá no ve. Conecta puntos entre las diferentes partes.
- Cierra con una observación específica basada en lo que ha dicho.
- Tono: cálido, inteligente, observador. No clínico, no condescendiente.
- Basa TODO en el transcript. No inventes ni asumas.
- No uses listas ni títulos dentro del summary — prosa natural.

REGLAS PARA ALINEACIÓN CON OBJETIVOS:
- Analiza CADA objetivo del usuario (devuelve un entry por cada goal_N).
- CLEAR_PROGRESS (score 0.7-1.0): el usuario mencionó acciones claras alineadas con el objetivo.
- PARTIAL_PROGRESS (score 0.4-0.69): hubo mención o esfuerzo parcial pero incompleto.
- NO_EVIDENCE (score 0.5): el transcript NO menciona nada sobre este objetivo. Sé prudente — si no hay evidencia, usa este nivel.
- DEVIATION (score 0.0-0.39): el usuario mencionó acciones que contradicen el objetivo.
- El campo "reason" DEBE citar o referenciar lo que el usuario dijo. Si no hay evidencia, di "No mencionaste nada sobre este objetivo en tu entrada de hoy."
- NO inventes hechos. NO asumas. Si no hay evidencia suficiente, devuelve NO_EVIDENCE.
- overallScore es el promedio ponderado de los scores individuales.

REGLA DE IDIOMA: Responde SIEMPRE en el mismo idioma del transcript (summary y reasons).`;
}

@Injectable()
export class AnalysisService {
  private readonly logger = new Logger(AnalysisService.name);
  private readonly geminiApiKey: string;
  private readonly geminiModel = 'gemini-2.5-flash';

  constructor(private readonly config: ConfigService) {
    this.geminiApiKey = this.config.get<string>('GEMINI_API_KEY') ?? '';
  }

  async analyseJournal(transcript: string, goals: Goal[]): Promise<AnalysisResult> {
    this.logger.log('Analysing journal transcript with Gemini (structured JSON)');

    const url = `https://generativelanguage.googleapis.com/v1beta/models/${this.geminiModel}:generateContent?key=${this.geminiApiKey}`;

    const body = {
      contents: [
        {
          role: 'user',
          parts: [{ text: transcript }],
        },
      ],
      systemInstruction: {
        parts: [{ text: buildSystemPrompt(goals) }],
      },
      generationConfig: {
        temperature: 0.7,
        maxOutputTokens: 4096,
        responseMimeType: 'application/json',
        thinkingConfig: {
          thinkingBudget: 0,
        },
      },
      safetySettings: [
        { category: 'HARM_CATEGORY_HARASSMENT', threshold: 'BLOCK_NONE' },
        { category: 'HARM_CATEGORY_HATE_SPEECH', threshold: 'BLOCK_NONE' },
        { category: 'HARM_CATEGORY_SEXUALLY_EXPLICIT', threshold: 'BLOCK_NONE' },
        { category: 'HARM_CATEGORY_DANGEROUS_CONTENT', threshold: 'BLOCK_NONE' },
      ],
    };

    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });

    if (!response.ok) {
      const errorBody = await response.text();
      this.logger.error(`Gemini API error ${response.status}: ${errorBody}`);
      throw new Error(`Gemini API returned ${response.status}`);
    }

    const data = (await response.json()) as {
      candidates?: Array<{
        content?: { parts?: Array<{ text?: string }> };
        finishReason?: string;
      }>;
    };

    const candidate = data.candidates?.[0];
    const rawText = candidate?.content?.parts?.[0]?.text?.trim() ?? '';

    this.logger.log(
      `Gemini response — finishReason: ${candidate?.finishReason}, length: ${rawText.length} chars`
    );

    if (!rawText) {
      this.logger.warn('Gemini returned empty response');
      return this.fallbackResult(goals);
    }

    try {
      const parsed = JSON.parse(rawText) as AnalysisResult;
      return parsed;
    } catch (e) {
      this.logger.error('Failed to parse Gemini JSON response', e);
      return this.fallbackResult(goals);
    }
  }

  private fallbackResult(goals: Goal[]): AnalysisResult {
    return {
      emotion: {
        summary: 'No se ha podido generar un análisis para esta entrada.',
        emotionScores: {},
        keyThemes: [],
        sentiment: 'NEUTRAL',
      },
      goalAlignment: {
        overallScore: 0.5,
        goals: goals.map((_, i) => ({
          goalIndex: i,
          score: 0.5,
          level: 'NO_EVIDENCE' as const,
          reason: 'No se pudo analizar la alineación con este objetivo.',
        })),
      },
    };
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run:

```bash
cd apps/backend && npx tsc --noEmit
```

Expected: May show errors in `audio.service.ts` because `analyseJournal` signature changed — that's expected and will be fixed in Task 4.

- [ ] **Step 3: Commit**

```bash
git add apps/backend/src/modules/analysis/services/analysis.service.ts
git commit -m "feat(analysis): restructure Gemini prompt for JSON with emotion + goal alignment"
```

---

## Task 4: Backend — Update Audio Pipeline to Save Alignments

**Files:**

- Modify: `apps/backend/src/modules/audio/services/audio.service.ts`
- Modify: `apps/backend/src/modules/audio/audio.module.ts`

- [ ] **Step 1: Update AudioModule imports**

In `apps/backend/src/modules/audio/audio.module.ts`, add `GoalsModule` import:

```typescript
import { GoalsModule } from '@modules/goals/goals.module';
```

Add `GoalsModule` to the `imports` array.

- [ ] **Step 2: Update AudioService**

In `apps/backend/src/modules/audio/services/audio.service.ts`:

Add import at top:

```typescript
import { GoalsService } from '@modules/goals/services/goals.service';
```

Add `GoalsService` to constructor:

```typescript
constructor(
  private readonly prisma: PrismaService,
  private readonly transcription: TranscriptionService,
  private readonly analysis: AnalysisService,
  private readonly goalsService: GoalsService,
) {}
```

Replace the `runPipeline` method:

```typescript
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
```

Also update `getById` to include `goalAlignments`:

```typescript
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
```

- [ ] **Step 3: Verify backend compiles**

Run:

```bash
cd apps/backend && npx nest build
```

Expected: Build succeeds.

- [ ] **Step 4: Commit**

```bash
git add apps/backend/src/modules/audio/
git commit -m "feat(audio): update pipeline to save emotion scores and goal alignments"
```

---

## Task 5: Flutter — Add fl_chart Dependency and Goal Entities

**Files:**

- Modify: `apps/mobile/pubspec.yaml`
- Create: `apps/mobile/lib/features/goals/domain/entities/goal_entity.dart`
- Create: `apps/mobile/lib/features/goals/domain/entities/goal_alignment_entity.dart`
- Create: `apps/mobile/lib/features/goals/domain/entities/alignment_history_entity.dart`

- [ ] **Step 1: Add fl_chart to pubspec.yaml**

In `apps/mobile/pubspec.yaml`, add under `dependencies`:

```yaml
fl_chart: ^0.70.2
```

Run:

```bash
cd apps/mobile && flutter pub get
```

- [ ] **Step 2: Create GoalEntity**

`apps/mobile/lib/features/goals/domain/entities/goal_entity.dart`:

```dart
class GoalEntity {
  const GoalEntity({
    required this.id,
    required this.title,
    required this.active,
  });

  final String id;
  final String title;
  final bool active;

  factory GoalEntity.fromJson(Map<String, dynamic> json) {
    return GoalEntity(
      id: json['id'] as String,
      title: json['title'] as String,
      active: json['active'] as bool? ?? true,
    );
  }
}
```

- [ ] **Step 3: Create GoalAlignmentEntity**

`apps/mobile/lib/features/goals/domain/entities/goal_alignment_entity.dart`:

```dart
enum AlignmentLevel {
  clearProgress,
  partialProgress,
  noEvidence,
  deviation;

  static AlignmentLevel fromString(String value) => switch (value) {
        'CLEAR_PROGRESS' => AlignmentLevel.clearProgress,
        'PARTIAL_PROGRESS' => AlignmentLevel.partialProgress,
        'NO_EVIDENCE' => AlignmentLevel.noEvidence,
        'DEVIATION' => AlignmentLevel.deviation,
        _ => AlignmentLevel.noEvidence,
      };

  String get label => switch (this) {
        AlignmentLevel.clearProgress => 'Avance claro',
        AlignmentLevel.partialProgress => 'Avance parcial',
        AlignmentLevel.noEvidence => 'Sin evidencia',
        AlignmentLevel.deviation => 'Desviación',
      };
}

class GoalAlignmentEntity {
  const GoalAlignmentEntity({
    required this.goalId,
    required this.goalTitle,
    required this.score,
    required this.level,
    required this.reason,
  });

  final String goalId;
  final String goalTitle;
  final double score;
  final AlignmentLevel level;
  final String reason;

  factory GoalAlignmentEntity.fromJson(Map<String, dynamic> json) {
    final goal = json['goal'] as Map<String, dynamic>?;
    return GoalAlignmentEntity(
      goalId: goal?['id'] as String? ?? json['goalId'] as String? ?? '',
      goalTitle: goal?['title'] as String? ?? json['goalTitle'] as String? ?? '',
      score: (json['score'] as num).toDouble(),
      level: AlignmentLevel.fromString(json['level'] as String? ?? ''),
      reason: json['reason'] as String? ?? '',
    );
  }
}
```

- [ ] **Step 4: Create AlignmentHistoryEntity**

`apps/mobile/lib/features/goals/domain/entities/alignment_history_entity.dart`:

```dart
class GoalScoreEntry {
  const GoalScoreEntry({
    required this.goalId,
    required this.title,
    required this.score,
  });

  final String goalId;
  final String title;
  final double score;

  factory GoalScoreEntry.fromJson(Map<String, dynamic> json) {
    return GoalScoreEntry(
      goalId: json['goalId'] as String,
      title: json['title'] as String,
      score: (json['score'] as num).toDouble(),
    );
  }
}

class AlignmentHistoryEntry {
  const AlignmentHistoryEntry({
    required this.date,
    required this.overallScore,
    required this.goals,
  });

  final DateTime date;
  final double overallScore;
  final List<GoalScoreEntry> goals;

  factory AlignmentHistoryEntry.fromJson(Map<String, dynamic> json) {
    final rawGoals = json['goals'] as List<dynamic>? ?? [];
    return AlignmentHistoryEntry(
      date: DateTime.parse(json['date'] as String),
      overallScore: (json['overallScore'] as num).toDouble(),
      goals: rawGoals
          .map((g) => GoalScoreEntry.fromJson(g as Map<String, dynamic>))
          .toList(),
    );
  }
}
```

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/pubspec.yaml apps/mobile/pubspec.lock apps/mobile/lib/features/goals/domain/
git commit -m "feat(goals): add fl_chart dependency and goal domain entities"
```

---

## Task 6: Flutter — Goals Repository and Provider

**Files:**

- Create: `apps/mobile/lib/features/goals/domain/repositories/goals_repository.dart`
- Create: `apps/mobile/lib/features/goals/data/repositories/api_goals_repository.dart`
- Create: `apps/mobile/lib/features/goals/application/providers/goals_provider.dart`

- [ ] **Step 1: Create abstract repository**

`apps/mobile/lib/features/goals/domain/repositories/goals_repository.dart`:

```dart
import '../entities/goal_entity.dart';
import '../entities/alignment_history_entity.dart';

abstract class GoalsRepository {
  Future<List<GoalEntity>> getActiveGoals();
  Future<GoalEntity> createGoal(String title);
  Future<GoalEntity> updateGoal(String id, String title);
  Future<void> deleteGoal(String id);
  Future<List<AlignmentHistoryEntry>> getAlignmentHistory({int days = 30});
}
```

- [ ] **Step 2: Create API implementation**

`apps/mobile/lib/features/goals/data/repositories/api_goals_repository.dart`:

```dart
import 'package:dio/dio.dart';
import '../../domain/entities/goal_entity.dart';
import '../../domain/entities/alignment_history_entity.dart';
import '../../domain/repositories/goals_repository.dart';

class ApiGoalsRepository implements GoalsRepository {
  const ApiGoalsRepository(this._dio);
  final Dio _dio;

  Map<String, dynamic> _unwrap(Map<String, dynamic> response) {
    if (response.containsKey('data') && response['data'] is Map) {
      return response['data'] as Map<String, dynamic>;
    }
    return response;
  }

  @override
  Future<List<GoalEntity>> getActiveGoals() async {
    final response = await _dio.get<Map<String, dynamic>>('/goals');
    final data = response.data!;
    // Backend wraps in { success, data } — data is the array
    final list = data['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => GoalEntity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<GoalEntity> createGoal(String title) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/goals',
      data: {'title': title},
    );
    return GoalEntity.fromJson(_unwrap(response.data!));
  }

  @override
  Future<GoalEntity> updateGoal(String id, String title) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/goals/$id',
      data: {'title': title},
    );
    return GoalEntity.fromJson(_unwrap(response.data!));
  }

  @override
  Future<void> deleteGoal(String id) async {
    await _dio.delete('/goals/$id');
  }

  @override
  Future<List<AlignmentHistoryEntry>> getAlignmentHistory({int days = 30}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/goals/alignment/history',
      queryParameters: {'days': days},
    );
    final data = response.data!;
    final list = data['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => AlignmentHistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
```

- [ ] **Step 3: Create GoalsProvider**

`apps/mobile/lib/features/goals/application/providers/goals_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/repositories/api_goals_repository.dart';
import '../../domain/entities/goal_entity.dart';
import '../../domain/repositories/goals_repository.dart';

// Repository provider
final goalsRepositoryProvider = Provider<GoalsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiGoalsRepository(dio);
});

// Goals state
enum GoalsStatus { loading, hasGoals, noGoals, error }

class GoalsState {
  const GoalsState({
    this.status = GoalsStatus.loading,
    this.goals = const [],
    this.error,
  });

  final GoalsStatus status;
  final List<GoalEntity> goals;
  final String? error;

  GoalsState copyWith({
    GoalsStatus? status,
    List<GoalEntity>? goals,
    String? error,
  }) =>
      GoalsState(
        status: status ?? this.status,
        goals: goals ?? this.goals,
        error: error,
      );
}

class GoalsNotifier extends Notifier<GoalsState> {
  @override
  GoalsState build() => const GoalsState(status: GoalsStatus.loading);

  GoalsRepository get _repo => ref.read(goalsRepositoryProvider);

  Future<void> loadGoals() async {
    state = state.copyWith(status: GoalsStatus.loading);
    try {
      final goals = await _repo.getActiveGoals();
      state = GoalsState(
        status: goals.isEmpty ? GoalsStatus.noGoals : GoalsStatus.hasGoals,
        goals: goals,
      );
    } catch (e) {
      state = GoalsState(status: GoalsStatus.error, error: e.toString());
    }
  }

  Future<void> addGoal(String title) async {
    final goal = await _repo.createGoal(title);
    final updated = [...state.goals, goal];
    state = GoalsState(status: GoalsStatus.hasGoals, goals: updated);
  }

  Future<void> updateGoal(String id, String title) async {
    final updated = await _repo.updateGoal(id, title);
    final goals = state.goals.map((g) => g.id == id ? updated : g).toList();
    state = state.copyWith(goals: goals);
  }

  Future<void> removeGoal(String id) async {
    await _repo.deleteGoal(id);
    final goals = state.goals.where((g) => g.id != id).toList();
    state = GoalsState(
      status: goals.isEmpty ? GoalsStatus.noGoals : GoalsStatus.hasGoals,
      goals: goals,
    );
  }
}

final goalsProvider =
    NotifierProvider<GoalsNotifier, GoalsState>(GoalsNotifier.new);
```

- [ ] **Step 4: Commit**

```bash
git add apps/mobile/lib/features/goals/
git commit -m "feat(goals): add goals repository, API client, and state provider"
```

---

## Task 7: Flutter — Goals Onboarding Screen

**Files:**

- Create: `apps/mobile/lib/features/goals/presentation/screens/goals_onboarding_screen.dart`

- [ ] **Step 1: Create GoalsOnboardingScreen**

`apps/mobile/lib/features/goals/presentation/screens/goals_onboarding_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../application/providers/goals_provider.dart';

class GoalsOnboardingScreen extends ConsumerStatefulWidget {
  const GoalsOnboardingScreen({super.key});

  @override
  ConsumerState<GoalsOnboardingScreen> createState() =>
      _GoalsOnboardingScreenState();
}

class _GoalsOnboardingScreenState extends ConsumerState<GoalsOnboardingScreen> {
  final _controller = TextEditingController();
  final _goals = <String>[];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addGoal() {
    final text = _controller.text.trim();
    if (text.isEmpty || _goals.length >= 4) return;
    setState(() {
      _goals.add(text);
      _controller.clear();
    });
  }

  void _removeGoal(int index) {
    setState(() => _goals.removeAt(index));
  }

  Future<void> _submit() async {
    if (_goals.length < 2 || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final notifier = ref.read(goalsProvider.notifier);
      for (final title in _goals) {
        await notifier.addGoal(title);
      }
      if (mounted) context.go(RouteNames.home);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              const Text(
                '¿Qué quieres conseguir?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Define entre 2 y 4 objetivos personales. La IA analizará tu progreso diario.',
                style: TextStyle(color: Colors.grey[400], fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 32),

              // Input row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      maxLength: 100,
                      decoration: InputDecoration(
                        hintText: 'Ej: Ir al gimnasio',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        counterText: '',
                        filled: true,
                        fillColor: const Color(0xFF151518),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF6366F1)),
                        ),
                      ),
                      onSubmitted: (_) => _addGoal(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _goals.length < 4 ? _addGoal : null,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _goals.length < 4
                            ? const Color(0xFF6366F1)
                            : Colors.grey[800],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Goals list
              Expanded(
                child: ListView.separated(
                  itemCount: _goals.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151518),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.05)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Color(0xFF6366F1),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _goals[index],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _removeGoal(index),
                            child: Icon(Icons.close,
                                color: Colors.grey[600], size: 20),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Status text
              if (_goals.isNotEmpty && _goals.length < 2)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Añade al menos ${2 - _goals.length} objetivo${_goals.length == 1 ? "" : "s"} más',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ),

              // Continue button
              ElevatedButton(
                onPressed: _goals.length >= 2 && !_isSubmitting ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.grey[800],
                  disabledForegroundColor: Colors.grey[600],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text('Continuar',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add apps/mobile/lib/features/goals/presentation/screens/goals_onboarding_screen.dart
git commit -m "feat(goals): add goals onboarding screen"
```

---

## Task 8: Flutter — Goals Management Screen

**Files:**

- Create: `apps/mobile/lib/features/goals/presentation/screens/goals_screen.dart`

- [ ] **Step 1: Create GoalsScreen**

`apps/mobile/lib/features/goals/presentation/screens/goals_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/goals_provider.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addGoal() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await ref.read(goalsProvider.notifier).addGoal(text);
    _controller.clear();
  }

  Future<void> _removeGoal(String id) async {
    await ref.read(goalsProvider.notifier).removeGoal(id);
  }

  Future<void> _editGoal(String id, String currentTitle) async {
    final editController = TextEditingController(text: currentTitle);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1D),
        title: const Text('Editar objetivo',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: editController,
          style: const TextStyle(color: Colors.white),
          maxLength: 100,
          decoration: InputDecoration(
            counterStyle: TextStyle(color: Colors.grey[600]),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF6366F1)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, editController.text.trim()),
            child: const Text('Guardar',
                style: TextStyle(color: Color(0xFF6366F1))),
          ),
        ],
      ),
    );
    editController.dispose();

    if (result != null && result.isNotEmpty && result != currentTitle) {
      await ref.read(goalsProvider.notifier).updateGoal(id, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final goalsState = ref.watch(goalsProvider);
    final goals = goalsState.goals;
    final canAdd = goals.length < 4;

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Mis Objetivos',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${goals.length}/4 objetivos activos',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
              const SizedBox(height: 16),

              // Add new goal
              if (canAdd) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white),
                        maxLength: 100,
                        decoration: InputDecoration(
                          hintText: 'Nuevo objetivo...',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          counterText: '',
                          filled: true,
                          fillColor: const Color(0xFF151518),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: Colors.white.withOpacity(0.1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: Colors.white.withOpacity(0.1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                const BorderSide(color: Color(0xFF6366F1)),
                          ),
                        ),
                        onSubmitted: (_) => _addGoal(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _addGoal,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Goals list
              Expanded(
                child: ListView.separated(
                  itemCount: goals.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final goal = goals[index];
                    final canRemove = goals.length > 2;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151518),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.05)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFF6366F1).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Color(0xFF6366F1),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              goal.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _editGoal(goal.id, goal.title),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(Icons.edit_outlined,
                                  color: Colors.grey[500], size: 18),
                            ),
                          ),
                          if (canRemove)
                            GestureDetector(
                              onTap: () => _removeGoal(goal.id),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Icon(Icons.close,
                                    color: Colors.grey[600], size: 18),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add apps/mobile/lib/features/goals/presentation/screens/goals_screen.dart
git commit -m "feat(goals): add goals management screen"
```

---

## Task 9: Flutter — Update Router with Goals Routes and Redirect

**Files:**

- Modify: `apps/mobile/lib/app/router/route_names.dart`
- Modify: `apps/mobile/lib/app/router/app_router.dart`

- [ ] **Step 1: Add route constants**

In `apps/mobile/lib/app/router/route_names.dart`, add inside the class:

```dart
  static const goalsOnboarding = '/goals-onboarding';
  static const goals = '/goals';
```

- [ ] **Step 2: Update app_router.dart**

Add imports at top of `apps/mobile/lib/app/router/app_router.dart`:

```dart
import '../../features/goals/application/providers/goals_provider.dart';
import '../../features/goals/presentation/screens/goals_onboarding_screen.dart';
import '../../features/goals/presentation/screens/goals_screen.dart';
```

Update the `_publicRoutes` set — add `RouteNames.goalsOnboarding`:

```dart
const _publicRoutes = {
  RouteNames.splash,
  RouteNames.onboarding,
  RouteNames.login,
  RouteNames.register,
  RouteNames.forgotPassword,
};
```

(Note: goalsOnboarding is NOT public — it requires auth. Leave `_publicRoutes` unchanged.)

Update the redirect logic. Replace the `// authenticated` comment and final redirect block:

```dart
      // authenticated — check if user has goals
      final goalsStatus = ref.read(goalsProvider).status;
      final isGoalsOnboarding =
          state.matchedLocation == RouteNames.goalsOnboarding;

      if (goalsStatus == GoalsStatus.noGoals) {
        return isGoalsOnboarding ? null : RouteNames.goalsOnboarding;
      }

      if (goalsStatus == GoalsStatus.loading) {
        // Still loading goals — stay where we are
        return null;
      }

      // Has goals — redirect away from public/onboarding routes
      if (isPublic || isVerifyEmail || isGoalsOnboarding) {
        return RouteNames.home;
      }
      return null;
```

Add the goals routes in the `routes` array, before the `settings` route:

```dart
      GoRoute(
        path: RouteNames.goalsOnboarding,
        name: 'goalsOnboarding',
        builder: (context, state) => const GoalsOnboardingScreen(),
      ),
      GoRoute(
        path: RouteNames.goals,
        name: 'goals',
        builder: (context, state) => const GoalsScreen(),
      ),
```

Also watch `goalsProvider` at the top of the provider (alongside `authProvider`):

```dart
  ref.watch(goalsProvider);
```

- [ ] **Step 3: Trigger goals load after auth**

Use `ref.listen` on `authProvider` inside the router provider to trigger goals load when the user becomes authenticated. This avoids side effects during the provider build phase. Add this after the `ref.watch` calls:

```dart
  // Listen for auth changes to trigger goals load (ref.listen avoids side effects in build)
  ref.listen<AsyncValue<AuthState>>(authProvider, (prev, next) {
    final prevStatus = prev?.valueOrNull?.status;
    final nextStatus = next.valueOrNull?.status;
    if (prevStatus != AuthStatus.authenticated &&
        nextStatus == AuthStatus.authenticated) {
      ref.read(goalsProvider.notifier).loadGoals();
    }
  });
```

- [ ] **Step 4: Verify app compiles**

Run:

```bash
cd apps/mobile && flutter analyze
```

Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/app/router/ apps/mobile/lib/features/auth/application/providers/auth_provider.dart
git commit -m "feat(goals): add goals routes and onboarding redirect logic"
```

---

## Task 10: Flutter — Update InsightEntity with Alignment Data

**Files:**

- Modify: `apps/mobile/lib/features/recording/domain/entities/insight_entity.dart`

- [ ] **Step 1: Add alignment fields to InsightEntity**

Update `apps/mobile/lib/features/recording/domain/entities/insight_entity.dart`:

```dart
import '../../../goals/domain/entities/goal_alignment_entity.dart';

class InsightEntity {
  const InsightEntity({
    required this.summary,
    required this.emotionScores,
    required this.keyThemes,
    required this.sentiment,
    this.suggestedActions,
    this.overallAlignment,
    this.goalAlignments = const [],
  });

  final String summary;
  final Map<String, double> emotionScores;
  final List<String> keyThemes;
  final String sentiment;
  final List<Map<String, String>>? suggestedActions;
  final double? overallAlignment;
  final List<GoalAlignmentEntity> goalAlignments;

  String get dominantEmotion {
    if (emotionScores.isEmpty) return 'neutral';
    return emotionScores.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  factory InsightEntity.fromJson(Map<String, dynamic> json) {
    final rawScores = json['emotionScores'] as Map<String, dynamic>? ?? {};
    final rawThemes = json['keyThemes'] as List<dynamic>? ?? [];
    final rawActions = json['suggestedActions'] as List<dynamic>?;
    final rawAlignments = json['goalAlignments'] as List<dynamic>? ?? [];

    return InsightEntity(
      summary: json['summary'] as String? ?? '',
      emotionScores: rawScores.map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      ),
      keyThemes: rawThemes.map((e) => e.toString()).toList(),
      sentiment: json['sentiment'] as String? ?? 'NEUTRAL',
      suggestedActions: rawActions
          ?.map((e) => Map<String, String>.from(e as Map))
          .toList(),
      overallAlignment: (json['overallAlignment'] as num?)?.toDouble(),
      goalAlignments: rawAlignments
          .map((e) => GoalAlignmentEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add apps/mobile/lib/features/recording/domain/entities/insight_entity.dart
git commit -m "feat(insight): add goal alignment fields to InsightEntity"
```

---

## Task 11: Flutter — Alignment Chart Widgets

**Files:**

- Create: `apps/mobile/lib/features/goals/presentation/widgets/alignment_cards.dart`
- Create: `apps/mobile/lib/features/goals/presentation/widgets/alignment_bar_chart.dart`
- Create: `apps/mobile/lib/features/goals/presentation/widgets/alignment_radar_chart.dart`
- Create: `apps/mobile/lib/features/goals/presentation/widgets/alignment_trend_chart.dart`

- [ ] **Step 1: Create AlignmentCards widget**

`apps/mobile/lib/features/goals/presentation/widgets/alignment_cards.dart`:

```dart
import 'package:flutter/material.dart';
import '../../domain/entities/goal_alignment_entity.dart';

class AlignmentCards extends StatelessWidget {
  const AlignmentCards({super.key, required this.alignments});
  final List<GoalAlignmentEntity> alignments;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final a in alignments) ...[
          _AlignmentCard(alignment: a),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _AlignmentCard extends StatelessWidget {
  const _AlignmentCard({required this.alignment});
  final GoalAlignmentEntity alignment;

  Color get _color => switch (alignment.level) {
        AlignmentLevel.clearProgress => const Color(0xFF34D399),
        AlignmentLevel.partialProgress => const Color(0xFFFBBF24),
        AlignmentLevel.noEvidence => const Color(0xFF6B7280),
        AlignmentLevel.deviation => const Color(0xFFEF4444),
      };

  IconData get _icon => switch (alignment.level) {
        AlignmentLevel.clearProgress => Icons.check_circle,
        AlignmentLevel.partialProgress => Icons.timelapse,
        AlignmentLevel.noEvidence => Icons.help_outline,
        AlignmentLevel.deviation => Icons.warning_amber,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151518),
        border: Border.all(color: _color.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon, color: _color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alignment.goalTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  alignment.level.label,
                  style: TextStyle(
                    color: _color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            alignment.reason,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Create AlignmentBarChart widget**

`apps/mobile/lib/features/goals/presentation/widgets/alignment_bar_chart.dart`:

```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/goal_alignment_entity.dart';

class AlignmentBarChart extends StatelessWidget {
  const AlignmentBarChart({
    super.key,
    required this.alignments,
    required this.overallScore,
  });

  final List<GoalAlignmentEntity> alignments;
  final double overallScore;

  Color _barColor(AlignmentLevel level) => switch (level) {
        AlignmentLevel.clearProgress => const Color(0xFF34D399),
        AlignmentLevel.partialProgress => const Color(0xFFFBBF24),
        AlignmentLevel.noEvidence => const Color(0xFF6B7280),
        AlignmentLevel.deviation => const Color(0xFFEF4444),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151518),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ALINEACIÓN',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                '${(overallScore * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: alignments.length * 52.0,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 1.0,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= alignments.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            '${(alignments[idx].score * 100).round()}%',
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 12),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= alignments.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            alignments[idx].goalTitle.length > 12
                                ? '${alignments[idx].goalTitle.substring(0, 12)}...'
                                : alignments[idx].goalTitle,
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 11),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(alignments.length, (i) {
                  final a = alignments[i];
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: a.score,
                        color: _barColor(a.level),
                        width: 28,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Create AlignmentRadarChart widget**

`apps/mobile/lib/features/goals/presentation/widgets/alignment_radar_chart.dart`:

```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/goal_alignment_entity.dart';

class AlignmentRadarChart extends StatelessWidget {
  const AlignmentRadarChart({super.key, required this.alignments});
  final List<GoalAlignmentEntity> alignments;

  @override
  Widget build(BuildContext context) {
    if (alignments.length < 3) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151518),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PERFIL DE ALINEACIÓN',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: RadarChart(
              RadarChartData(
                dataSets: [
                  RadarDataSet(
                    dataEntries: alignments
                        .map((a) => RadarEntry(value: a.score))
                        .toList(),
                    fillColor: const Color(0xFF6366F1).withOpacity(0.2),
                    borderColor: const Color(0xFF6366F1),
                    borderWidth: 2,
                    entryRadius: 4,
                  ),
                ],
                radarBackgroundColor: Colors.transparent,
                borderData: FlBorderData(show: false),
                radarBorderData:
                    BorderSide(color: Colors.white.withOpacity(0.1)),
                tickBorderData:
                    BorderSide(color: Colors.white.withOpacity(0.05)),
                gridBorderData:
                    BorderSide(color: Colors.white.withOpacity(0.08)),
                tickCount: 4,
                ticksTextStyle: const TextStyle(fontSize: 0),
                titlePositionPercentageOffset: 0.2,
                titleTextStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
                getTitle: (index, angle) {
                  if (index >= alignments.length) return const RadarChartTitle(text: '');
                  final title = alignments[index].goalTitle;
                  return RadarChartTitle(
                    text: title.length > 10
                        ? '${title.substring(0, 10)}...'
                        : title,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Create AlignmentTrendChart widget**

`apps/mobile/lib/features/goals/presentation/widgets/alignment_trend_chart.dart`:

```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/alignment_history_entity.dart';

const _lineColors = [
  Color(0xFF6366F1), // overall / goal 0
  Color(0xFF34D399), // goal 1
  Color(0xFFFBBF24), // goal 2
  Color(0xFFEF4444), // goal 3
];

class AlignmentTrendChart extends StatelessWidget {
  const AlignmentTrendChart({super.key, required this.history});
  final List<AlignmentHistoryEntry> history;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151518),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TENDENCIA',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 1,
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 0.25,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withOpacity(0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: 0.25,
                      getTitlesWidget: (value, meta) => Text(
                        '${(value * 100).toInt()}%',
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= history.length) {
                          return const SizedBox.shrink();
                        }
                        // Show label for first, last, and middle
                        if (idx != 0 &&
                            idx != history.length - 1 &&
                            idx != history.length ~/ 2) {
                          return const SizedBox.shrink();
                        }
                        final d = history[idx].date;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${d.day}/${d.month}',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: _buildLines(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _legend('Global', _lineColors[0]),
              if (history.first.goals.isNotEmpty)
                for (var i = 0; i < history.first.goals.length && i < 4; i++)
                  _legend(
                    history.first.goals[i].title,
                    _lineColors[(i + 1) % _lineColors.length],
                  ),
            ],
          ),
        ],
      ),
    );
  }

  List<LineChartBarData> _buildLines() {
    final lines = <LineChartBarData>[];

    // Overall line
    lines.add(LineChartBarData(
      spots: List.generate(
        history.length,
        (i) => FlSpot(i.toDouble(), history[i].overallScore),
      ),
      isCurved: true,
      color: _lineColors[0],
      barWidth: 2.5,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: _lineColors[0].withOpacity(0.1),
      ),
    ));

    // Per-goal lines
    if (history.isNotEmpty) {
      final goalCount = history.first.goals.length;
      for (var g = 0; g < goalCount && g < 4; g++) {
        lines.add(LineChartBarData(
          spots: List.generate(history.length, (i) {
            if (g < history[i].goals.length) {
              return FlSpot(i.toDouble(), history[i].goals[g].score);
            }
            return FlSpot(i.toDouble(), 0);
          }),
          isCurved: true,
          color: _lineColors[(g + 1) % _lineColors.length].withOpacity(0.6),
          barWidth: 1.5,
          dotData: const FlDotData(show: false),
          dashArray: [5, 3],
        ));
      }
    }

    return lines;
  }

  Widget _legend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label.length > 15 ? '${label.substring(0, 15)}...' : label,
          style: TextStyle(color: Colors.grey[500], fontSize: 11),
        ),
      ],
    );
  }
}
```

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/features/goals/presentation/widgets/
git commit -m "feat(goals): add alignment chart widgets (cards, bar, radar, trend)"
```

---

## Task 12: Flutter — Update ResultScreen with Alignment Section

**Files:**

- Modify: `apps/mobile/lib/features/recording/presentation/screens/result_screen.dart`

- [ ] **Step 1: Update ResultScreen**

In `apps/mobile/lib/features/recording/presentation/screens/result_screen.dart`:

Add imports at top:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../goals/application/providers/goals_provider.dart';
import '../../../goals/domain/entities/alignment_history_entity.dart';
import '../../../goals/presentation/widgets/alignment_cards.dart';
import '../../../goals/presentation/widgets/alignment_bar_chart.dart';
import '../../../goals/presentation/widgets/alignment_radar_chart.dart';
import '../../../goals/presentation/widgets/alignment_trend_chart.dart';
```

Replace the body `Column` with a `SingleChildScrollView` to avoid overflow. Replace the `body: SafeArea(...)` section entirely:

```dart
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (insight != null) ...[
                        _SentimentBanner(insight: insight),
                        const SizedBox(height: 24),
                        _SummaryCard(insight: insight),
                        const SizedBox(height: 16),
                        if (insight.keyThemes.isNotEmpty)
                          _ThemesRow(themes: insight.keyThemes),
                        if (insight.suggestedActions != null &&
                            insight.suggestedActions!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _ActionsCard(actions: insight.suggestedActions!),
                        ],
                        // Goal Alignment Section
                        if (insight.goalAlignments.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          Text(
                            'ALINEACIÓN CON TUS OBJETIVOS',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          AlignmentCards(alignments: insight.goalAlignments),
                          const SizedBox(height: 16),
                          AlignmentBarChart(
                            alignments: insight.goalAlignments,
                            overallScore: insight.overallAlignment ?? 0,
                          ),
                          const SizedBox(height: 16),
                          AlignmentRadarChart(
                              alignments: insight.goalAlignments),
                          const SizedBox(height: 16),
                          _TrendChartSection(),
                        ],
                      ] else
                        const _PlaceholderCard(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  ref.read(recordingProvider.notifier).reset();
                  context.go(RouteNames.home);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Done',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
```

Add the `_TrendChartSection` widget at the bottom of the file (before the closing of the file):

```dart
class _TrendChartSection extends ConsumerStatefulWidget {
  const _TrendChartSection();

  @override
  ConsumerState<_TrendChartSection> createState() => _TrendChartSectionState();
}

class _TrendChartSectionState extends ConsumerState<_TrendChartSection> {
  List<AlignmentHistoryEntry>? _history;
  bool _loading = true;
  bool _loadTriggered = false;

  void _loadHistory() {
    if (_loadTriggered) return;
    _loadTriggered = true;
    final repo = ref.read(goalsRepositoryProvider);
    repo.getAlignmentHistory(days: 30).then((history) {
      if (mounted) setState(() { _history = history; _loading = false; });
    }).catchError((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Trigger load on first build (ref is available here, not in initState)
    _loadHistory();

    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
        ),
      );
    }
    if (_history == null || _history!.isEmpty) return const SizedBox.shrink();
    return AlignmentTrendChart(history: _history!);
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add apps/mobile/lib/features/recording/presentation/screens/result_screen.dart
git commit -m "feat(result): add goal alignment section with charts to ResultScreen"
```

---

## Task 13: Flutter — Add "Mis Objetivos" Card to HomeScreen

**Files:**

- Modify: `apps/mobile/lib/features/home/presentation/screens/home_screen.dart`

- [ ] **Step 1: Add imports and goals card**

In `apps/mobile/lib/features/home/presentation/screens/home_screen.dart`, add import:

```dart
import '../../../goals/application/providers/goals_provider.dart';
```

In the `_HomeScreenStateMethods` extension, add a new method:

```dart
  Widget _buildGoalsCard(BuildContext context) {
    final goalsState = ref.watch(goalsProvider);
    final count = goalsState.goals.length;
    if (count == 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => context.push(RouteNames.goals),
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF151518),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.track_changes,
                  color: Color(0xFF6366F1), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mis Objetivos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$count objetivo${count == 1 ? "" : "s"} activo${count == 1 ? "" : "s"}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[700], size: 18),
          ],
        ),
      ),
    );
  }
```

In the `build` method, inside the `SlideTransition` / `FadeTransition` block for content below blob, add `_buildGoalsCard(context)` before the insight card:

Find this line:

```dart
                          if (hasRecordedToday) _buildInsightCard(),
```

Add before it:

```dart
                          _buildGoalsCard(context),
```

- [ ] **Step 2: Commit**

```bash
git add apps/mobile/lib/features/home/presentation/screens/home_screen.dart
git commit -m "feat(home): add Mis Objetivos card to HomeScreen"
```

---

## Task 14: Verify Full Build

- [ ] **Step 1: Verify backend builds**

Run:

```bash
cd /Users/usuario/Desktop/Votio/apps/backend && npx nest build
```

Expected: Build succeeds.

- [ ] **Step 2: Verify Flutter analyzes clean**

Run:

```bash
cd /Users/usuario/Desktop/Votio/apps/mobile && flutter analyze
```

Expected: No analysis issues.

- [ ] **Step 3: Final commit if any fixes needed**

```bash
git add -A && git status
```

If clean, no commit needed. If fixes were required, commit with:

```bash
git commit -m "fix: resolve build issues in goal alignment feature"
```
