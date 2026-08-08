import { IsEmail, IsOptional, IsString, MinLength } from 'class-validator';

export class RegisterDto {
  @IsEmail() email!: string;
  @IsString() @MinLength(8) password!: string;
  @IsOptional() @IsString() fullName?: string;
}

export class LoginDto {
  @IsEmail() email!: string;
  @IsString() password!: string;
}
