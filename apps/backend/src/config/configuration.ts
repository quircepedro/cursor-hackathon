import { registerAs } from '@nestjs/config';
import appConfig from './app.config';
import databaseConfig from './database.config';
import queueConfig from './queue.config';
import storageConfig from './storage.config';

export default registerAs('config', () => ({
  app: appConfig(),
  database: databaseConfig(),
  queue: queueConfig(),
  storage: storageConfig(),
}));
