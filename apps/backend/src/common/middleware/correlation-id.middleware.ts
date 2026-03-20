import { Injectable, NestMiddleware } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import { randomUUID } from 'crypto';

/**
 * CorrelationIdMiddleware generates or forwards X-Correlation-ID headers
 * for request tracing across logs and services.
 */
@Injectable()
export class CorrelationIdMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction): void {
    // Check if correlation ID already exists in request headers
    const correlationId = req.headers['x-correlation-id'];

    // If not present, generate a new one
    if (!correlationId) {
      req.headers['x-correlation-id'] = randomUUID();
    }

    // Add correlation ID to response headers for client reference
    const headerValue = req.headers['x-correlation-id'];
    if (typeof headerValue === 'string') {
      res.setHeader('x-correlation-id', headerValue);
    }

    next();
  }
}
