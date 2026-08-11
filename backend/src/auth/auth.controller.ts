import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Res,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { Throttle } from '@nestjs/throttler';
import type { Response } from 'express';
import { AuthService } from './auth.service';
import {
  ChangePasswordDto,
  LoginDto,
  RegisterDto,
  RequestPasswordResetDto,
  ResetPasswordDto,
} from './auth.dto';
import { CurrentUser } from './current-user.decorator';
import type { AuthUser } from './current-user.decorator';

@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('register')
  register(@Body() dto: RegisterDto) {
    return this.auth.register(dto);
  }

  @Post('login')
  login(@Body() dto: LoginDto) {
    return this.auth.login(dto);
  }

  @Post('password/forgot')
  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  requestPasswordReset(@Body() dto: RequestPasswordResetDto) {
    return this.auth.requestPasswordReset(dto);
  }

  @Post('password/reset')
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  resetPassword(@Body() dto: ResetPasswordDto) {
    return this.auth.resetPassword(dto);
  }

  @Get('oauth/providers')
  socialProviders() {
    return this.auth.availableSocialProviders();
  }

  @Get('oauth/:provider/url')
  socialAuthorizationUrl(@Param('provider') provider: string) {
    return this.auth.socialAuthorizationUrl(provider);
  }

  @Get('oauth/:provider/callback')
  async socialCallback(
    @Param('provider') provider: string,
    @Query('code') code: string | undefined,
    @Query('state') state: string | undefined,
    @Query('error_description') providerError: string | undefined,
    @Res() response: Response,
  ) {
    try {
      if (providerError) throw new Error(providerError);
      const session = await this.auth.completeSocialLogin(
        provider,
        code,
        state,
      );
      return response.redirect(
        this.auth.socialReturnUrl({ accessToken: session.accessToken }),
      );
    } catch (error) {
      const message =
        error instanceof Error ? error.message : 'Đăng nhập không thành công';
      return response.redirect(this.auth.socialReturnUrl({ error: message }));
    }
  }

  @UseGuards(AuthGuard('jwt'))
  @Patch('password')
  changePassword(
    @CurrentUser() user: AuthUser,
    @Body() dto: ChangePasswordDto,
  ) {
    return this.auth.changePassword(user.id, dto);
  }
}
