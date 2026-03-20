import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
  Logger,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap, catchError } from 'rxjs/operators';
import { Request, Response } from 'express';
import { throwError } from 'rxjs';

/**
 * LoggingInterceptor logs all requests and responses with correlation IDs.
 * Tracks request duration and includes correlation ID for request tracing.
 */
@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger(LoggingInterceptor.name);

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const request = context.switchToHttp().getRequest<Request>();
    const response = context.switchToHttp().getResponse<Response>();
    const correlationId = request.headers['x-correlation-id'] as string;

    const { method, url, ip } = request;
    const startTime = Date.now();

    return next.handle().pipe(
      tap(() => {
        const duration = Date.now() - startTime;
        const statusCode = response.statusCode;

        this.logger.log(
          `[${correlationId}] ${method} ${url} - ${statusCode} (${duration}ms) - IP: ${ip}`,
        );
      }),
      catchError((error: unknown) => {
        const duration = Date.now() - startTime;
        const statusCode = response.statusCode || 500;
        const errorMessage =
          error instanceof Error ? error.message : 'Unknown error';

        this.logger.error(
          `[${correlationId}] ${method} ${url} - ${statusCode} (${duration}ms) - ${errorMessage}`,
        );

        return throwError(() => error);
      }),
    );
  }
}
