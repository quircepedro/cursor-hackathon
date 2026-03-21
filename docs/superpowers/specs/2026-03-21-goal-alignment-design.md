# Goal Alignment System — Design Spec

## Overview

Add a goal-alignment productivity layer to Votio. Users define 2-4 personal objectives during onboarding. The AI analyzes daily journaling transcripts against those objectives, producing both qualitative assessments and numeric scores. Results are displayed as charts (bar, radar, trend line) alongside the existing emotional analysis.

This is NOT generic productivity tracking. It measures alignment between stated intentions and what the user actually reports doing.

## Data Model

### New: `Goal`

| Field     | Type     | Notes                       |
| --------- | -------- | --------------------------- |
| id        | String   | CUID, primary key           |
| userId    | String   | FK → User                   |
| title     | String   | e.g. "Ir al gimnasio"       |
| active    | Boolean  | default: true (soft delete) |
| createdAt | DateTime |                             |
| updatedAt | DateTime |                             |

- Index on `userId`
- Relation: User → Goal[] (one-to-many). Add `goals Goal[]` to the existing `User` model.

### New: Prisma enum `AlignmentLevel`

```prisma
enum AlignmentLevel {
  CLEAR_PROGRESS
  PARTIAL_PROGRESS
  NO_EVIDENCE
  DEVIATION
}
```

### New: `GoalAlignment`

| Field     | Type                  | Notes                                                    |
| --------- | --------------------- | -------------------------------------------------------- |
| id        | String                | CUID, primary key                                        |
| insightId | String                | FK → Insight                                             |
| goalId    | String                | FK → Goal                                                |
| score     | Float                 | 0.0–1.0 (for charts)                                     |
| level     | AlignmentLevel (enum) | CLEAR_PROGRESS, PARTIAL_PROGRESS, NO_EVIDENCE, DEVIATION |
| reason    | String                | AI justification based on transcript evidence            |
| createdAt | DateTime              |                                                          |

- Index on `insightId`
- Unique constraint on `[insightId, goalId]`
- Relations: Insight → GoalAlignment[] (one-to-many), Goal → GoalAlignment[] (one-to-many)

### Modified: `Insight`

Add field:

- `overallAlignment: Float?` — global day alignment score (0.0–1.0)

## Backend

### New Module: `goals/`

NestJS module with controller, service, and DTOs.

**Endpoints (all guarded by `FirebaseAuthGuard`):**

| Method | Path                     | Description                              |
| ------ | ------------------------ | ---------------------------------------- |
| POST   | /goals                   | Create goal (validates max 4 active)     |
| GET    | /goals                   | List active goals for current user       |
| PUT    | /goals/:id               | Update goal title                        |
| DELETE | /goals/:id               | Soft delete (set active = false)         |
| GET    | /goals/alignment/history | Alignment scores over time (query: days) |

**Validation rules:**

- Minimum 2 active goals to proceed past onboarding
- Maximum 4 active goals per user
- Title: non-empty string, max 100 chars

**Alignment history endpoint response:**

```json
[
  {
    "date": "2026-03-21",
    "overallScore": 0.65,
    "goals": [
      { "goalId": "clx...", "title": "Ir al gimnasio", "score": 0.9 },
      { "goalId": "clx...", "title": "Estudiar más", "score": 0.3 }
    ]
  }
]
```

### Modified: `AnalysisService`

**Single prompt approach.** The Gemini prompt is restructured to return JSON with both emotional analysis and goal alignment.

**Prompt changes:**

- System prompt instructs Gemini to return valid JSON (not prose)
- User's active goals are injected into the prompt as context
- AI is instructed to be prudent: if the transcript doesn't mention evidence about a goal, return `NO_EVIDENCE` with score 0.5

**Goal injection format:** Goals are passed to Gemini as an indexed map so the AI returns the index (not the title), avoiding title-matching ambiguity:

```
User goals:
  goal_0: "Ir al gimnasio"
  goal_1: "Estudiar más"
  goal_2: "Leer cada día"
```

**Expected Gemini response schema:**

```json
{
  "emotion": {
    "summary": "150-250 word emotional analysis...",
    "emotionScores": { "esperanza": 0.7, "frustración": 0.3 },
    "keyThemes": ["trabajo", "ejercicio"],
    "sentiment": "POSITIVE"
  },
  "goalAlignment": {
    "overallScore": 0.65,
    "goals": [
      {
        "goalIndex": 0,
        "score": 0.9,
        "level": "CLEAR_PROGRESS",
        "reason": "Mencionaste que fuiste al gimnasio por la mañana y completaste tu rutina"
      }
    ]
  }
}
```

The backend maps `goalIndex` back to the corresponding `goalId` using the same ordered array passed to the prompt.

**Return type change:** `analyseJournal()` signature changes from `(transcript: string) → { insight: string }` to `(transcript: string, goals: Goal[]) → AnalysisResult` where `AnalysisResult` is the full parsed JSON structure above. The `audio.service.ts` pipeline must be updated to populate all `Insight` fields (`emotionScores`, `keyThemes`, `sentiment`) from the parsed JSON instead of hardcoding them to empty/neutral values.

**Level mapping:**

- `CLEAR_PROGRESS`: score 0.7–1.0 — user mentioned clear actions aligned with goal
- `PARTIAL_PROGRESS`: score 0.4–0.69 — some effort or mention but incomplete
- `NO_EVIDENCE`: score fixed at 0.5 — transcript doesn't mention this goal. This level is determined by the AI's `level` field, NOT derived from the score. The backend uses the `level` value returned by Gemini directly.
- `DEVIATION`: score 0.0–0.39 — user mentioned actions contradicting the goal

### Modified: `AudioService.runPipeline()`

1. Transcription (unchanged)
2. Fetch user's active goals from DB
3. Call `analyseJournal(transcript, goals)` — pass goals as context
4. Parse JSON response
5. Save `Insight` with `overallAlignment`
6. Save `GoalAlignment` records (one per goal)

## Frontend (Flutter)

### New: `GoalsOnboardingScreen`

- Route: `/goals-onboarding`
- Appears after login/register, before Home (first time only)
- UI: title "What do you want to achieve?", text input + add button, goal chips with delete
- Continue button enabled when 2+ goals exist
- Calls `POST /goals` for each goal, then navigates to Home

### Modified: Router (`app_router.dart`)

After auth check (authenticated + email verified), check if user has goals:

- No goals → redirect to `/goals-onboarding`
- Has goals → redirect to `/home`

**Implementation:** Goals are fetched once after successful authentication and cached in a `GoalsNotifier` provider. The router redirect checks the cached provider state (not a network call on every navigation). A loading/splash state is shown while the goals request is in-flight. The provider exposes three states: `loading`, `hasGoals`, `noGoals`.

### New: `GoalsScreen`

- Route: `/goals`
- Accessible from a card on HomeScreen ("Mis Objetivos")
- Same UI as onboarding but with pre-loaded goals
- Edit, add, delete goals (respecting 2-4 limit)

### Modified: `ResultScreen`

The screen body must be wrapped in a `SingleChildScrollView` (or `CustomScrollView`) to accommodate the new content — the current fixed `Column` with `Spacer()` pattern will overflow.

After the existing emotional insight section, add new section "Alineación con tus objetivos":

**4 visualization components:**

1. **Qualitative cards** — vertical list of cards per goal showing: title, level badge (color-coded), AI reason text
   - Colors: green (#34D399) = CLEAR_PROGRESS, yellow (#FBBF24) = PARTIAL_PROGRESS, gray (#6B7280) = NO_EVIDENCE, red (#EF4444) = DEVIATION

2. **Horizontal bar chart** (`fl_chart` BarChart) — one bar per goal, score 0-100%, same color coding, overall score label at top

3. **Radar chart** (`fl_chart` RadarChart) — one axis per goal, shows alignment profile of the day, works best with 3-4 goals

4. **Trend line chart** (`fl_chart` LineChart) — overall alignment + per-goal lines over last 7-30 days, fetched from `GET /goals/alignment/history?days=30`

### Modified: `HomeScreen`

- New card "Mis Objetivos" showing active goals count, tap → GoalsScreen
- Optional: show today's overall alignment score if available

### New dependency

Add `fl_chart` to `pubspec.yaml`.

### New data structures (Flutter)

```dart
class GoalEntity {
  final String id;
  final String title;
  final bool active;
}

class GoalAlignmentEntity {
  final String goalId;
  final String goalTitle;
  final double score;
  final String level; // CLEAR_PROGRESS | PARTIAL_PROGRESS | NO_EVIDENCE | DEVIATION
  final String reason;
}

class AlignmentHistoryEntry {
  final DateTime date;
  final double overallScore;
  final List<GoalScoreEntry> goals;
}
```

### Modified: `InsightEntity`

Add fields:

- `double? overallAlignment`
- `List<GoalAlignmentEntity> goalAlignments`

## Key Constraints

- The AI must NOT invent facts. If the transcript doesn't mention a goal, return NO_EVIDENCE.
- The AI must respond in the same language as the transcript.
- The AI must justify every alignment assessment with evidence from the transcript.
- Maximum 4 active goals per user, minimum 2.
- Goals are soft-deleted (active = false) so historical alignment data remains valid.

## Out of Scope

- Goal categories or tags
- Sub-goals or milestones
- Goal deadlines or time-bound tracking
- Social/shared goals
- Notifications based on alignment
- Weekly/monthly aggregated reports (future iteration)
