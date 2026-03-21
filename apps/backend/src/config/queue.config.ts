import { registerAs } from '@nestjs/config';
import * as Joi from 'joi';

/**
 * Queue configuration factory.
 * Loads and validates Redis/Bull queue environment variables.
 */
export default registerAs('queue', () => {
  const schema = Joi.object({
    REDIS_URL: Joi.string().required().uri(),
  });

  const { error, value } = schema.validate(process.env, { allowUnknown: true }) as unknown as {
    error?: Error;
    value: Record<string, unknown>;
  };

  if (error) {
    throw new Error(`Queue config validation error: ${error.message}`);
  }

  return {
    redisUrl: String(value.REDIS_URL),
  };
});
