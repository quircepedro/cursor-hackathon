import { registerAs } from '@nestjs/config';
import * as Joi from 'joi';

/**
 * Database configuration factory.
 * Loads and validates database environment variables.
 */
export default registerAs('database', () => {
  const schema = Joi.object({
    DATABASE_URL: Joi.string().required().uri(),
  });

  const { error, value } = schema.validate(process.env) as unknown as {
    error?: Error;
    value: Record<string, unknown>;
  };

  if (error) {
    throw new Error(`Database config validation error: ${error.message}`);
  }

  return {
    databaseUrl: String(value.DATABASE_URL),
  };
});
