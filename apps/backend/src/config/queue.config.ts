import { registerAs } from '@nestjs/config';

/**
 * Queue configuration — Redis/Bull removed, transcription is handled client-side.
 */
export default registerAs('queue', () => ({
  redisUrl: process.env.REDIS_URL ?? '',
}));
