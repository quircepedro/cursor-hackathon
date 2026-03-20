import { registerAs } from '@nestjs/config';
import appConfig from './app.config';
import databaseConfig from './database.config';
import jwtConfig from './jwt.config';
import queueConfig from './queue.config';
import storageConfig from './storage.config';

/**
 * Root configuration factory that aggregates all config modules.
 * Provides a centralized place to register all configuration sources.
 */
export default registerAs('config', () => ({
  app: appConfig(),
  database: databaseConfig(),
  jwt: jwtConfig(),
  queue: queueConfig(),
  storage: storageConfig(),
}));
