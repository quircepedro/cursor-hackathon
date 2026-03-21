import { Type } from 'class-transformer';
import {
  IsArray,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
  ValidateNested,
} from 'class-validator';

/** Objetivo enviado por la app (p. ej. almacenado solo en el dispositivo). */
export class JournalGoalDto {
  @IsString()
  @MinLength(1)
  @MaxLength(500)
  title!: string;
}

export class AnalyseJournalDto {
  @IsString()
  @MinLength(1, { message: 'Transcript must not be empty' })
  transcript!: string;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => JournalGoalDto)
  goals?: JournalGoalDto[];
}
