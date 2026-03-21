import { IsString, MinLength, MaxLength } from 'class-validator';

export class UpdateGoalDto {
  @IsString()
  @MinLength(1, { message: 'Title must not be empty' })
  @MaxLength(100, { message: 'Title must be at most 100 characters' })
  title!: string;
}
