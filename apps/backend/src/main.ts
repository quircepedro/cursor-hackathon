import { NestFactory } from '@nestjs/core';
import { ConfigService } from '@nestjs/config';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { CorrelationIdMiddleware } from '@common/middleware/correlation-id.middleware';
import { AppModule } from './app.module';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule);
  const configService = app.get(ConfigService);

  // Setup middleware
  app.use(CorrelationIdMiddleware);

  // Setup CORS
  const corsOrigins = configService.get<string>('app.cors_origins', 'http://localhost:3000');
  app.enableCors({
    origin: corsOrigins.split(','),
    credentials: true,
  });

  // Setup global prefix
  const apiPrefix = configService.get<string>('app.api_prefix', 'api/v1');
  app.setGlobalPrefix(apiPrefix);

  // Setup Swagger
  const swaggerConfig = new DocumentBuilder()
    .setTitle('Votio API')
    .setDescription('Voice journaling with AI analysis and visual clip generation')
    .setVersion('1.0.0')
    .addBearerAuth()
    .build();

  const swaggerDocument = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup('api/docs', app, swaggerDocument);

  const port = configService.get<number>('app.port', 3000);
  await app.listen(port);

  console.log(`✅ NestJS application is running on: http://localhost:${port}/${apiPrefix}`);
  console.log(`📚 Swagger docs at: http://localhost:${port}/api/docs`);
}

void bootstrap();
