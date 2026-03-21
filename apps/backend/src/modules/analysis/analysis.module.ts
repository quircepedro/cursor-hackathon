import { Module } from '@nestjs/common';
import { FirebaseModule } from '@modules/firebase/firebase.module';
import { GoalsModule } from '@modules/goals/goals.module';
import { UsersModule } from '@modules/users/users.module';
import { AnalysisController } from './controllers/analysis.controller';
import { AnalysisService } from './services/analysis.service';

@Module({
  imports: [FirebaseModule, UsersModule, GoalsModule],
  controllers: [AnalysisController],
  providers: [AnalysisService],
  exports: [AnalysisService],
})
export class AnalysisModule {}
