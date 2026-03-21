import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_FILTER, APP_INTERCEPTOR, APP_PIPE } from '@nestjs/core';
import configFactory from '@config/configuration';
import firebaseConfig from '@config/firebase.config';
import { PrismaModule } from '@database/prisma.module';
import { GlobalExceptionFilter } from '@common/filters/global-exception.filter';
import { TransformInterceptor } from '@common/interceptors/transform.interceptor';
import { LoggingInterceptor } from '@common/interceptors/logging.interceptor';
import { ValidationPipe } from '@common/pipes/validation.pipe';
import { FirebaseModule } from '@modules/firebase/firebase.module';
import { UsersModule } from '@modules/users/users.module';
import { AuthModule } from '@modules/auth/auth.module';
import { AudioModule } from '@modules/audio/audio.module';
import { TranscriptionModule } from '@modules/transcription/transcription.module';
import { AnalysisModule } from '@modules/analysis/analysis.module';
import { GoalsModule } from '@modules/goals/goals.module';
import { ClipsModule } from '@modules/clips/clips.module';
import { HistoryModule } from '@modules/history/history.module';
import { SubscriptionsModule } from '@modules/subscriptions/subscriptions.module';
import { NotificationsModule } from '@modules/notifications/notifications.module';
import { AppController } from './app.controller';
import { AppService } from './app.service';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [configFactory, firebaseConfig],
    }),
    PrismaModule,
    FirebaseModule,
    UsersModule,
    AuthModule,
    AudioModule,
    TranscriptionModule,
    AnalysisModule,
    GoalsModule,
    ClipsModule,
    HistoryModule,
    SubscriptionsModule,
    NotificationsModule,
  ],
  controllers: [AppController],
  providers: [
    AppService,
    {
      provide: APP_FILTER,
      useClass: GlobalExceptionFilter,
    },
    {
      provide: APP_INTERCEPTOR,
      useClass: TransformInterceptor,
    },
    {
      provide: APP_INTERCEPTOR,
      useClass: LoggingInterceptor,
    },
    {
      provide: APP_PIPE,
      useClass: ValidationPipe,
    },
  ],
})
export class AppModule {}
