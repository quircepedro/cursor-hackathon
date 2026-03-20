import { Injectable } from '@nestjs/common';

@Injectable()
export class AnalysisService {
  getHealth() {
    return { status: 'ok' };
  }
}
