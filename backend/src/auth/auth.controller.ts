import { Body, Controller, Patch, Post, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { AuthService } from './auth.service';
import { ChangePasswordDto, LoginDto, RegisterDto } from './auth.dto';
import { CurrentUser } from './current-user.decorator';
import type { AuthUser } from './current-user.decorator';

@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}
  @Post('register') register(@Body() dto: RegisterDto) {
    return this.auth.register(dto);
  }
  @Post('login') login(@Body() dto: LoginDto) {
    return this.auth.login(dto);
  }
  @UseGuards(AuthGuard('jwt'))
  @Patch('password') changePassword(
    @CurrentUser() user: AuthUser,
    @Body() dto: ChangePasswordDto,
  ) {
    return this.auth.changePassword(user.id, dto);
  }
}
