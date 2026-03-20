/**
 * Queue name constants used throughout the application.
 * Each queue represents a distinct processing pipeline step.
 */
export const QUEUE_NAMES = {
  /** Audio upload and storage pipeline */
  AUDIO_PIPELINE: 'audio-pipeline',

  /** Transcription processing queue */
  TRANSCRIPTION: 'transcription',

  /** Emotional analysis and insight generation */
  ANALYSIS: 'analysis',

  /** Video clip generation from audio insights */
  CLIP_GENERATION: 'clip-generation',
} as const;
