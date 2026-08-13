import {
  IsEmail,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';

export class RegisterDto {
  @IsEmail() email!: string;
  @IsString() @MinLength(8) @MaxLength(72) password!: string;
  @IsOptional() @IsString() @MaxLength(100) fullName?: string;
}

export class LoginDto {
  @IsEmail() email!: string;
  @IsString() @MaxLength(72) password!: string;
}

export class ChangePasswordDto {
  @IsString() @MinLength(8) @MaxLength(72) currentPassword!: string;
  @IsString() @MinLength(8) @MaxLength(72) newPassword!: string;
}

export class RequestPasswordResetDto {
  @IsEmail() email!: string;
}

export class ResetPasswordDto {
  @IsEmail() email!: string;
  @IsString() @MinLength(6) @MaxLength(6) code!: string;
  @IsString() @MinLength(8) @MaxLength(72) newPassword!: string;
}

export class RefreshTokenDto {
  @IsString() @MinLength(32) @MaxLength(200) refreshToken!: string;
}
