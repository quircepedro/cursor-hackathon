import { registerAs } from '@nestjs/config';
import * as Joi from 'joi';

/**
 * JWT configuration factory.
 * Loads and validates JWT-related environment variables.
 */
export default registerAs('jwt', () => {
  const schema = Joi.object({
    JWT_SECRET: Joi.string().min(32).required(),
    JWT_EXPIRY: Joi.string().default('1h'),
    JWT_REFRESH_SECRET: Joi.string().min(32).required(),
    JWT_REFRESH_EXPIRY: Joi.string().default('7d'),
  });

  const { error, value } = schema.validate(process.env) as unknown as {
    error?: Error;
    value: Record<string, unknown>;
  };

  if (error) {
    throw new Error(`JWT config validation error: ${error.message}`);
  }

  return {
    secret: String(value.JWT_SECRET),
    expiry: String(value.JWT_EXPIRY),
    refreshSecret: String(value.JWT_REFRESH_SECRET),
    refreshExpiry: String(value.JWT_REFRESH_EXPIRY),
  };
});
