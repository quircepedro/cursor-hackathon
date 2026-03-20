import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';
import { ApiResponse, ErrorDetail } from '../dto/api-response.dto';
import { DomainException } from '../exceptions/domain.exception';

/**
 * GlobalExceptionFilter catches all exceptions (both domain and HTTP) and transforms them
 * into the sealed envelope response format.
 *
 * Ensures consistent error response shape across all endpoints.
 */
@Catch()
export class GlobalExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(GlobalExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    const correlationId = request.headers['x-correlation-id'] || 'unknown';
    let statusCode = 500;
    let code = 'INTERNAL_SERVER_ERROR';
    let message = 'An unexpected error occurred';

    // Handle domain exceptions
    if (exception instanceof DomainException) {
      statusCode = exception.statusCode;
      code = exception.code;
      message = exception.message;
    }
    // Handle HTTP exceptions
    else if (exception instanceof HttpException) {
      statusCode = exception.getStatus();
      const exceptionResponse = exception.getResponse();

      if (typeof exceptionResponse === 'object' && exceptionResponse !== null) {
        const responseObj = exceptionResponse as Record<string, unknown>;
        message = (responseObj.message as string) || exception.message;
        code = (responseObj.error as string) || 'HTTP_ERROR';
      } else {
        message = exception.message;
      }
    }
    // Handle unknown errors
    else if (exception instanceof Error) {
      message = exception.message;
    }

    // Log the error with correlation ID
    const correlationIdStr =
      typeof correlationId === 'string' ? correlationId : 'unknown';
    this.logger.error(
      `[${correlationIdStr}] ${code}: ${message}`,
      exception instanceof Error ? exception.stack : undefined,
    );

    // Create error response
    const errorResponse: ApiResponse = {
      success: false,
      error: {
        code,
        message,
      } as ErrorDetail,
    };

    response.status(statusCode).json(errorResponse);
  }
}
