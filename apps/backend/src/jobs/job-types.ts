/**
 * Job payload types for all queues.
 * All jobs must include a version field for compatibility tracking.
 */

/**
 * Payload for audio pipeline jobs.
 * Triggered when a user uploads a new recording.
 */
export interface AudioPipelineJobPayload {
  version: number;
  recordingId: string;
  userId: string;
  audioUrl: string;
  duration: number; // in milliseconds
}

/**
 * Payload for transcription jobs.
 * Triggered after audio is uploaded and validated.
 */
export interface TranscriptionJobPayload {
  version: number;
  recordingId: string;
  userId: string;
  audioUrl: string;
  language?: string;
}

/**
 * Payload for analysis jobs.
 * Triggered after successful transcription.
 */
export interface AnalysisJobPayload {
  version: number;
  recordingId: string;
  userId: string;
  transcriptionText: string;
  language?: string;
}

/**
 * Payload for clip generation jobs.
 * Triggered after emotional analysis is complete.
 */
export interface ClipGenerationJobPayload {
  version: number;
  recordingId: string;
  userId: string;
  audioUrl: string;
  duration: number; // in milliseconds
  emotionScores: Record<string, number>;
  keyThemes: string[];
  sceneStart: number; // in milliseconds
  sceneEnd: number; // in milliseconds
}
