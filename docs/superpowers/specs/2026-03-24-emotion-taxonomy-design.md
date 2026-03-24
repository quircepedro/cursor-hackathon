# Emotion Taxonomy & Algorithm Design

## Problem

Gemini returns free-form emotion labels in `emotionScores`. Keys are inconsistent across analyses ("anxiety" one day, "anxious" the next), making it impossible to track trends or build reliable UI.

## Solution

Fixed 12-emotion taxonomy based on Plutchik + common journaling emotions. Gemini scores all 12, backend normalizes, mobile renders using a constant map.

## Taxonomy (12 emotions)

| Key           | Spanish     | Color     | Source            |
| ------------- | ----------- | --------- | ----------------- |
| `joy`         | Alegria     | `#34D399` | Plutchik primary  |
| `sadness`     | Tristeza    | `#60A5FA` | Plutchik primary  |
| `anger`       | Ira         | `#EF4444` | Plutchik primary  |
| `fear`        | Miedo       | `#A78BFA` | Plutchik primary  |
| `surprise`    | Sorpresa    | `#F472B6` | Plutchik primary  |
| `disgust`     | Asco        | `#6B7280` | Plutchik primary  |
| `anxiety`     | Ansiedad    | `#FB923C` | Journaling common |
| `calm`        | Calma       | `#38BDF8` | Journaling common |
| `gratitude`   | Gratitud    | `#34D399` | Journaling common |
| `pride`       | Orgullo     | `#FBBF24` | Journaling common |
| `nostalgia`   | Nostalgia   | `#C084FC` | Journaling common |
| `frustration` | Frustracion | `#F87171` | Journaling common |

## Algorithm

1. **Gemini prompt** lists the 12 fixed keys. Gemini scores each 0.0-1.0 based on transcript. Emotions not present = 0.0.
2. **Normalization** (backend): `score_i / sum_all_scores` so they sum to 1.0. Discard emotions < 0.05 (noise).
3. **Dominant emotion**: Highest normalized score.
4. **Visibility threshold**: Mobile shows only emotions >= 10% normalized.

## Changes

### Backend (`analysis.service.ts`)

- Update Gemini prompt: list 12 keys, require exactly those keys in response
- Add `normalizeEmotionScores()`: normalize to sum=1.0, filter < 0.05
- Validate response keys match taxonomy (discard unknown keys)

### Database

- No schema change. `emotionScores Json` field already stores the map. Content becomes consistent.

### Mobile

- Add `EmotionTaxonomy` constant map (key -> label + color) in a new file `emotion_taxonomy.dart`
- Wire the emotion daily widget on result_screen to use real InsightEntity data + taxonomy map
- Threshold: only render emotions with normalized score >= 0.10

## What does NOT change

- Insight table schema
- API endpoints
- Goal alignment logic
- Recording pipeline flow
