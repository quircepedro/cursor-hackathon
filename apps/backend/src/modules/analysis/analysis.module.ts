import { Module } from '@nestjs/common';
import { AnalysisController } from './controllers/analysis.controller';
import { AnalysisService } from './services/analysis.service';

@Module({
  imports: [],
  controllers: [AnalysisController],
  providers: [AnalysisService],
  exports: [],
})
export class AnalysisModule {}
