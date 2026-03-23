import { IsString, MinLength } from 'class-validator';

export class AnalyseJournalDto {
  @IsString()
  @MinLength(1, { message: 'Transcript must not be empty' })
  transcript!: string;
}
