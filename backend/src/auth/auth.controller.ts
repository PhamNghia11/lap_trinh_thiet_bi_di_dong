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
  RefreshTokenDto,
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
  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  register(@Body() dto: RegisterDto) {
    return this.auth.register(dto);
  }

  @Post('login')
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  login(@Body() dto: LoginDto) {
    return this.auth.login(dto);
  }

  @Post('refresh')
  @Throttle({ default: { limit: 20, ttl: 60_000 } })
  refresh(@Body() dto: RefreshTokenDto) {
    return this.auth.refreshSession(dto.refreshToken);
  }

  @Post('logout')
  @Throttle({ default: { limit: 20, ttl: 60_000 } })
  logout(@Body() dto: RefreshTokenDto) {
    return this.auth.logout(dto.refreshToken);
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
  @Throttle({ default: { limit: 20, ttl: 60_000 } })
  socialAuthorizationUrl(
    @Param('provider') provider: string,
    @Query('returnTo') returnTarget: string | undefined,
  ) {
    return this.auth.socialAuthorizationUrl(provider, returnTarget);
  }

  @Get('oauth/:provider/callback')
  async socialCallback(
    @Param('provider') provider: string,
    @Query('code') code: string | undefined,
    @Query('state') state: string | undefined,
    @Query('error_description') providerError: string | undefined,
    @Res() response: Response,
  ) {
    let returnTarget = await this.auth.socialReturnTarget(provider, state);
    try {
      if (providerError) throw new Error(providerError);
      const session = await this.auth.completeSocialLogin(
        provider,
        code,
        state,
      );
      returnTarget = session.returnTarget;
      const targetUrl = this.auth.socialReturnUrl(
        {
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
        },
        returnTarget,
      );
      if (returnTarget === 'mobile') {
        return response.type('html').send(`<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Đang chuyển về FLIX...</title>
  <style>
    body { background: #0f0a0c; color: white; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; margin: 0; text-align: center; padding: 20px; box-sizing: border-box; }
    .btn { display: inline-block; background: #e50914; color: white; text-decoration: none; padding: 14px 28px; border-radius: 8px; font-weight: bold; margin-top: 24px; font-size: 16px; }
    .loader { width: 40px; height: 40px; border: 4px solid rgba(255,255,255,0.15); border-top-color: #e50914; border-radius: 50%; animation: spin 0.8s linear infinite; }
    @keyframes spin { to { transform: rotate(360deg); } }
  </style>
</head>
<body>
  <div class="loader"></div>
  <h2 style="margin-top: 24px; margin-bottom: 8px;">Đang chuyển về ứng dụng FLIX...</h2>
  <p style="color: #888; font-size: 14px; margin: 0;">Nếu ứng dụng không tự mở, vui lòng nhấn nút bên dưới:</p>
  <a class="btn" href="${targetUrl}">Mở ứng dụng FLIX</a>
  <script>
    setTimeout(function() { window.location.href = "${targetUrl}"; }, 100);
  </script>
</body>
</html>`);
      }
      return response.redirect(targetUrl);
    } catch (error) {
      const message =
        error instanceof Error ? error.message : 'Đăng nhập không thành công';
      const errorUrl = this.auth.socialReturnUrl(
        { error: message },
        returnTarget,
      );
      if (returnTarget === 'mobile') {
        return response.type('html').send(`<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Lỗi đăng nhập FLIX</title>
  <style>
    body { background: #0f0a0c; color: white; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; margin: 0; text-align: center; padding: 20px; box-sizing: border-box; }
    .btn { display: inline-block; background: #333; color: white; text-decoration: none; padding: 12px 24px; border-radius: 8px; font-weight: bold; margin-top: 20px; font-size: 14px; }
  </style>
</head>
<body>
  <h2 style="color: #e50914;">Đăng nhập không thành công</h2>
  <p style="color: #aaa;">${message}</p>
  <a class="btn" href="${errorUrl}">Quay lại ứng dụng FLIX</a>
  <script>
    setTimeout(function() { window.location.href = "${errorUrl}"; }, 100);
  </script>
</body>
</html>`);
      }
      return response.redirect(errorUrl);
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
