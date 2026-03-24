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

// Fixed emotion taxonomy (Plutchik + common journaling emotions)
const EMOTION_KEYS = [
  'joy',
  'sadness',
  'anger',
  'fear',
  'surprise',
  'disgust',
  'anxiety',
  'calm',
  'gratitude',
  'pride',
  'nostalgia',
  'frustration',
] as const;

/**
 * Normalize emotion scores so they sum to 1.0 and discard noise (< 0.05).
 * Unknown keys are dropped. If all scores are 0, returns empty map.
 */
function normalizeEmotionScores(
  raw: Record<string, number>,
): Record<string, number> {
  // Keep only known keys with positive values
  const filtered: Record<string, number> = {};
  for (const key of EMOTION_KEYS) {
    const val = raw[key];
    if (typeof val === 'number' && val > 0) {
      filtered[key] = val;
    }
  }

  const sum = Object.values(filtered).reduce((a, b) => a + b, 0);
  if (sum === 0) return {};

  // Normalize to sum=1 and discard < 0.05
  const normalized: Record<string, number> = {};
  for (const [key, val] of Object.entries(filtered)) {
    const norm = val / sum;
    if (norm >= 0.05) {
      normalized[key] = Math.round(norm * 100) / 100; // 2 decimals
    }
  }

  // Re-normalize after filtering to ensure sum ≈ 1.0
  const newSum = Object.values(normalized).reduce((a, b) => a + b, 0);
  if (newSum > 0 && Math.abs(newSum - 1.0) > 0.01) {
    for (const key of Object.keys(normalized)) {
      normalized[key] = Math.round((normalized[key] / newSum) * 100) / 100;
    }
  }

  return normalized;
}

function buildSystemPrompt(goals: Goal[]): string {
  const goalsSection = goals
    .map((g, i) => `  goal_${i}: "${g.title}"`)
    .join('\n');

  const emotionKeysStr = EMOTION_KEYS.join(', ');

  return `Eres un analista experto integrado en una app de journaling diario por voz. Tu trabajo es analizar el transcript del usuario y devolver un JSON válido con dos secciones: análisis emocional y alineación con objetivos.

OBJETIVOS DEL USUARIO:
${goalsSection}

DEBES devolver EXCLUSIVAMENTE un JSON válido con esta estructura exacta (sin markdown, sin backticks, sin texto adicional):

{
  "emotion": {
    "summary": "análisis emocional de 150-250 palabras en prosa continua...",
    "emotionScores": { ${EMOTION_KEYS.map((k) => `"${k}": 0.0-1.0`).join(', ')} },
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

REGLAS PARA emotionScores:
- DEBES usar EXACTAMENTE estas 12 claves: ${emotionKeysStr}.
- Puntúa cada emoción de 0.0 a 1.0 según su presencia en el transcript.
- Si una emoción no aplica, ponla en 0.0. No omitas ninguna clave.
- No inventes otras claves. Solo las 12 listadas.

REGLAS CRÍTICAS PARA ALINEACIÓN CON OBJETIVOS:
- Analiza CADA objetivo del usuario POR SEPARADO. Devuelve un entry por cada goal_N.
- IMPORTANTE: Para cada objetivo, evalúa ÚNICAMENTE si el transcript contiene evidencia relacionada con ESE objetivo específico. NO mezcles los objetivos entre sí.
- Para goal_0 ("${goals[0]?.title ?? ''}"), busca SOLO evidencia sobre "${goals[0]?.title ?? ''}" en el transcript.
${goals.slice(1).map((g, i) => `- Para goal_${i + 1} ("${g.title}"), busca SOLO evidencia sobre "${g.title}" en el transcript.`).join('\n')}
- Cada objetivo es INDEPENDIENTE. La evaluación de un objetivo NO debe afectar ni confundirse con la de otro.
- El campo "reason" DEBE referirse al objetivo correcto por su título. Ejemplo: si el objetivo es "Ir al gimnasio", la razón debe hablar sobre ir al gimnasio, NO sobre otro objetivo.
- CLEAR_PROGRESS (score 0.7-1.0): el usuario mencionó acciones claras alineadas con ESE objetivo específico.
- PARTIAL_PROGRESS (score 0.4-0.69): hubo mención o esfuerzo parcial relacionado con ESE objetivo específico.
- NO_EVIDENCE (score 0.5): el transcript NO menciona nada sobre ESE objetivo específico. Sé prudente — si no hay evidencia, usa este nivel.
- DEVIATION (score 0.0-0.39): el usuario mencionó acciones que contradicen ESE objetivo específico.
- El campo "reason" DEBE citar o referenciar lo que el usuario dijo. Si no hay evidencia, di "No mencionaste nada sobre [TÍTULO DEL OBJETIVO] en tu entrada de hoy." usando el título real del objetivo.
- NO inventes hechos. NO asumas. Si no hay evidencia suficiente, devuelve NO_EVIDENCE.
- overallScore es el promedio ponderado de los scores individuales.
- VERIFICA antes de responder: ¿cada "reason" corresponde al objetivo correcto? ¿No estoy confundiendo un objetivo con otro?

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
      `Gemini response — finishReason: ${candidate?.finishReason}, length: ${rawText.length} chars`,
    );

    if (!rawText) {
      this.logger.warn('Gemini returned empty response');
      return this.fallbackResult(goals);
    }

    try {
      const parsed = JSON.parse(rawText) as AnalysisResult;

      // Normalize emotion scores to fixed taxonomy
      if (parsed.emotion?.emotionScores) {
        parsed.emotion.emotionScores = normalizeEmotionScores(
          parsed.emotion.emotionScores,
        );
      }

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
