import {
  Injectable,
  ValidationPipe as NestValidationPipe,
} from '@nestjs/common';
import { ValidationError } from 'class-validator';
import { ValidationException } from '../exceptions/domain.exception';

/**
 * Enhanced ValidationPipe that throws DomainException on validation errors
 * instead of the default BadRequestException.
 *
 * Integrates class-validator with the domain exception hierarchy.
 */
@Injectable()
export class ValidationPipe extends NestValidationPipe {
  constructor() {
    super({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: {
        enableImplicitConversion: true,
      },
      exceptionFactory: (errors: ValidationError[]) => {
        const messages = errors
          .map((error) => {
            const constraints = error.constraints
              ? Object.values(error.constraints).join(', ')
              : 'Unknown validation error';
            return `${error.property}: ${constraints}`;
          })
          .join('; ');

        return new ValidationException(messages);
      },
    });
  }
}
