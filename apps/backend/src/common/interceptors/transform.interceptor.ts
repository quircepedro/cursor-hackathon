import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { ApiResponse } from '../dto/api-response.dto';

/**
 * TransformInterceptor wraps all successful responses in the sealed envelope format.
 * Ensures all successful responses follow the ApiResponse<T> structure with success: true.
 */
@Injectable()
export class TransformInterceptor implements NestInterceptor {
  intercept(
    _context: ExecutionContext,
    next: CallHandler,
  ): Observable<ApiResponse> {
    return next.handle().pipe(
      map((data: unknown) => {
        // If the response is already an ApiResponse, return as-is
        if (data instanceof ApiResponse) {
          return data;
        }

        // If it's already an object with success field, return as-is
        if (
          typeof data === 'object' &&
          data !== null &&
          'success' in data &&
          typeof (data as Record<string, unknown>).success === 'boolean'
        ) {
          return data as ApiResponse;
        }

        // Otherwise, wrap in ApiResponse with success: true
        return ApiResponse.ok(data);
      }),
    );
  }
}
