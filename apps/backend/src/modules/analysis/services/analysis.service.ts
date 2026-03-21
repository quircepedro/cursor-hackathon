import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/** Títulos de objetivos para el prompt (BD o cliente). */
export type GoalPromptInput = { title: string };

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

function escapeForPrompt(title: string): string {
  return title.replace(/\\/g, '\\\\').replace(/"/g, '\\"');
}

function buildSystemPrompt(goals: GoalPromptInput[]): string {
  const goalsSection =
    goals.length === 0
      ? '  (sin objetivos — devuelve goalAlignment.goals como [] y overallScore 0.)'
      : goals
          .map((g, i) => `  goal_${i}: "${escapeForPrompt(g.title)}"`)
          .join('\n');

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

  async analyseJournal(
    transcript: string,
    goals: GoalPromptInput[],
  ): Promise<AnalysisResult> {
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
      `Gemini response — finishReason: ${candidate?.finishReason}, length: ${rawText.length} chars`,
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

  private fallbackResult(goals: GoalPromptInput[]): AnalysisResult {
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
