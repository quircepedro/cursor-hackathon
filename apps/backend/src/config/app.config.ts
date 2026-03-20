import { registerAs } from '@nestjs/config';
import * as Joi from 'joi';

/**
 * Application configuration factory.
 * Loads and validates app-level environment variables.
 */
export default registerAs('app', () => {
  const schema = Joi.object({
    NODE_ENV: Joi.string()
      .valid('development', 'staging', 'production')
      .default('development'),
    PORT: Joi.number().port().default(3000),
    API_PREFIX: Joi.string().default('api/v1'),
    CORS_ORIGINS: Joi.string().default(
      'http://localhost:3001,http://localhost:3002',
    ),
  });

  const { error, value } = schema.validate(process.env) as unknown as {
    error?: Error;
    value: Record<string, unknown>;
  };

  if (error) {
    throw new Error(`App config validation error: ${error.message}`);
  }

  return {
    nodeEnv: String(value.NODE_ENV),
    port: Number(value.PORT),
    apiPrefix: String(value.API_PREFIX),
    corsOrigins: String(value.CORS_ORIGINS)
      .split(',')
      .map((s: string) => s.trim()),
  };
});
