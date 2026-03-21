import { registerAs } from '@nestjs/config';
import * as Joi from 'joi';

/**
 * Storage configuration factory.
 * Loads and validates storage-related environment variables.
 * Supports both local and S3 storage providers.
 */
export default registerAs('storage', () => {
  const schema = Joi.object({
    STORAGE_PROVIDER: Joi.string().valid('local', 's3').default('local'),
    AWS_REGION: Joi.string().optional(),
    AWS_ACCESS_KEY_ID: Joi.string().optional(),
    AWS_SECRET_ACCESS_KEY: Joi.string().optional(),
    AWS_S3_BUCKET: Joi.string().optional(),
  });

  // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
  const { error, value } = schema.validate(process.env, { allowUnknown: true });

  if (error) {
    throw new Error(`Storage config validation error: ${error.message}`);
  }

  // Type-safe extraction with proper narrowing
  const valueObj = value as unknown as Record<string, unknown>;
  const provider = String(valueObj.STORAGE_PROVIDER);

  // Validate S3 credentials if S3 provider is selected
  if (provider === 's3') {
    if (
      !valueObj.AWS_ACCESS_KEY_ID ||
      !valueObj.AWS_SECRET_ACCESS_KEY ||
      !valueObj.AWS_S3_BUCKET
    ) {
      throw new Error(
        'S3 storage provider requires AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and AWS_S3_BUCKET',
      );
    }
  }

  // Type-safe string extraction for optional values
  const isString = (val: unknown): val is string => typeof val === 'string';

  return {
    provider: provider as 'local' | 's3',
    aws: {
      region: isString(valueObj.AWS_REGION) ? valueObj.AWS_REGION : undefined,
      accessKeyId: isString(valueObj.AWS_ACCESS_KEY_ID)
        ? valueObj.AWS_ACCESS_KEY_ID
        : undefined,
      secretAccessKey: isString(valueObj.AWS_SECRET_ACCESS_KEY)
        ? valueObj.AWS_SECRET_ACCESS_KEY
        : undefined,
      s3Bucket: isString(valueObj.AWS_S3_BUCKET)
        ? valueObj.AWS_S3_BUCKET
        : undefined,
    },
  };
});
