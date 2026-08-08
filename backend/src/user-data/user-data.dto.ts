import {
  IsBoolean,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export class HistoryDto {
  @IsNumber() @Min(0) @Max(1) progress!: number;
  @IsInt() @Min(0) watchedSeconds!: number;
  @IsOptional() @IsInt() @Min(0) durationSeconds?: number;
}

export class ReviewDto {
  @IsInt() @Min(1) @Max(5) rating!: number;
  @IsString() @MaxLength(1000) comment!: string;
  @IsOptional() @IsBoolean() hasSpoiler?: boolean;
}
