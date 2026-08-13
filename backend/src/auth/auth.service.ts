import {
  BadRequestException,
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import axios from 'axios';
import { compare, hash } from 'bcrypt';
import {
  createHash,
  randomBytes,
  randomInt,
  randomUUID,
  timingSafeEqual,
} from 'crypto';
import { OAuth2Client } from 'google-auth-library';
import { PrismaService } from '../prisma/prisma.service';
import {
  ChangePasswordDto,
  LoginDto,
  RegisterDto,
  RequestPasswordResetDto,
  ResetPasswordDto,
} from './auth.dto';

export type SocialProvider = 'google' | 'facebook';

type OAuthState = {
  purpose: 'social_login';
  provider: SocialProvider;
};

type SocialProfile = {
  provider: SocialProvider;
  providerUserId: string;
  email: string;
  fullName?: string;
  avatarUrl?: string;
};

@Injectable()
export class AuthService {
  private readonly google = new OAuth2Client();

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {}

  async register(dto: RegisterDto) {
    const email = dto.email.trim().toLowerCase();
    if (await this.prisma.user.findUnique({ where: { email } })) {
      throw new ConflictException('Email đã được sử dụng');
    }
    const user = await this.prisma.user.create({
      data: {
        email,
        fullName: dto.fullName?.trim(),
        passwordHash: await hash(dto.password, 12),
      },
      select: { id: true, email: true, fullName: true, avatarUrl: true },
    });
    return this.sessionFor(user);
  }

  async login(dto: LoginDto) {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email.trim().toLowerCase() },
    });
    if (
      !user?.passwordHash ||
      !(await compare(dto.password, user.passwordHash))
    ) {
      throw new UnauthorizedException('Email hoặc mật khẩu không đúng');
    }
    return this.sessionFor(user);
  }

  async changePassword(userId: string, dto: ChangePasswordDto) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user?.passwordHash) {
      throw new ConflictException(
        'Tài khoản đăng nhập qua mạng xã hội chưa thiết lập mật khẩu',
      );
    }
    if (!(await compare(dto.currentPassword, user.passwordHash))) {
      throw new UnauthorizedException('Mật khẩu hiện tại không đúng');
    }
    if (dto.currentPassword === dto.newPassword) {
      throw new ConflictException('Mật khẩu mới phải khác mật khẩu hiện tại');
    }
    await this.prisma.user.update({
      where: { id: userId },
      data: { passwordHash: await hash(dto.newPassword, 12) },
    });
    await this.revokeUserSessions(userId);
    return { changed: true };
  }

  async requestPasswordReset(dto: RequestPasswordResetDto) {
    const email = dto.email.trim().toLowerCase();
    const user = await this.prisma.user.findUnique({
      where: { email },
      select: { id: true, email: true, fullName: true },
    });
    if (!user) return { requested: true };

    const code = randomInt(0, 1_000_000).toString().padStart(6, '0');
    await this.prisma.user.update({
      where: { id: user.id },
      data: {
        passwordResetCodeHash: this.passwordResetCodeHash(user.id, code),
        passwordResetExpiresAt: new Date(Date.now() + 15 * 60 * 1000),
      },
    });
    try {
      await this.sendPasswordResetEmail(user.email, user.fullName, code);
    } catch (error) {
      await this.prisma.user.update({
        where: { id: user.id },
        data: {
          passwordResetCodeHash: null,
          passwordResetExpiresAt: null,
        },
      });
      console.error('Không thể gửi email khôi phục mật khẩu', error);
    }
    return { requested: true };
  }

  async resetPassword(dto: ResetPasswordDto) {
    const email = dto.email.trim().toLowerCase();
    const user = await this.prisma.user.findUnique({ where: { email } });
    const expected = user?.passwordResetCodeHash;
    const actual = user
      ? this.passwordResetCodeHash(user.id, dto.code.trim())
      : '';
    if (
      !user ||
      !expected ||
      !user.passwordResetExpiresAt ||
      user.passwordResetExpiresAt.getTime() <= Date.now() ||
      !this.safeEqual(expected, actual)
    ) {
      throw new UnauthorizedException('Mã xác nhận không đúng hoặc đã hết hạn');
    }
    await this.prisma.user.update({
      where: { id: user.id },
      data: {
        passwordHash: await hash(dto.newPassword, 12),
        passwordResetCodeHash: null,
        passwordResetExpiresAt: null,
      },
    });
    await this.revokeUserSessions(user.id);
    return { changed: true };
  }

  async refreshSession(refreshToken: string) {
    const tokenHash = this.refreshTokenHash(refreshToken);
    const current = await this.prisma.refreshSession.findUnique({
      where: { tokenHash },
      include: { user: true },
    });
    if (!current) {
      throw new UnauthorizedException('Phiên đăng nhập không hợp lệ');
    }
    const now = new Date();
    if (current.revokedAt) {
      await this.revokeTokenFamily(current.familyId, now);
      throw new UnauthorizedException('Phiên đăng nhập đã bị thu hồi');
    }
    if (current.expiresAt.getTime() <= now.getTime()) {
      await this.prisma.refreshSession.updateMany({
        where: { id: current.id, revokedAt: null },
        data: { revokedAt: now },
      });
      throw new UnauthorizedException('Phiên đăng nhập đã hết hạn');
    }

    const nextRefreshToken = this.newRefreshToken();
    const rotated = await this.prisma.$transaction(async (tx) => {
      const claimed = await tx.refreshSession.updateMany({
        where: { id: current.id, revokedAt: null },
        data: { revokedAt: now },
      });
      if (claimed.count !== 1) {
        await tx.refreshSession.updateMany({
          where: { familyId: current.familyId, revokedAt: null },
          data: { revokedAt: now },
        });
        return false;
      }
      await tx.refreshSession.create({
        data: {
          tokenHash: this.refreshTokenHash(nextRefreshToken),
          familyId: current.familyId,
          userId: current.userId,
          expiresAt: current.expiresAt,
        },
      });
      return true;
    });
    if (!rotated) {
      throw new UnauthorizedException('Phiên đăng nhập đã bị thu hồi');
    }
    return this.sessionPayload(current.user, nextRefreshToken);
  }

  async logout(refreshToken: string) {
    const current = await this.prisma.refreshSession.findUnique({
      where: { tokenHash: this.refreshTokenHash(refreshToken) },
      select: { familyId: true },
    });
    if (current) await this.revokeTokenFamily(current.familyId);
    return { loggedOut: true };
  }

  availableSocialProviders() {
    return {
      google: this.isProviderConfigured('google'),
      facebook: this.isProviderConfigured('facebook'),
    };
  }

  async socialAuthorizationUrl(providerValue: string) {
    const provider = this.parseProvider(providerValue);
    this.ensureProviderConfigured(provider);
    const state = await this.jwt.signAsync<OAuthState>(
      { purpose: 'social_login', provider },
      { expiresIn: '10m' },
    );
    const redirectUri = this.callbackUrl(provider);

    if (provider === 'google') {
      const query = new URLSearchParams({
        client_id: this.required('GOOGLE_CLIENT_ID'),
        redirect_uri: redirectUri,
        response_type: 'code',
        scope: 'openid email profile',
        prompt: 'select_account',
        state,
      });
      return { url: `https://accounts.google.com/o/oauth2/v2/auth?${query}` };
    }

    const query = new URLSearchParams({
      client_id: this.required('FACEBOOK_APP_ID'),
      redirect_uri: redirectUri,
      response_type: 'code',
      scope: 'email,public_profile',
      state,
    });
    return {
      url: `https://www.facebook.com/${this.required('FACEBOOK_GRAPH_VERSION')}/dialog/oauth?${query}`,
    };
  }

  async completeSocialLogin(
    providerValue: string,
    code?: string,
    state?: string,
  ) {
    const provider = this.parseProvider(providerValue);
    this.ensureProviderConfigured(provider);
    if (!code || !state) {
      throw new BadRequestException('Phản hồi đăng nhập không đầy đủ');
    }

    let payload: OAuthState;
    try {
      payload = await this.jwt.verifyAsync<OAuthState>(state);
    } catch {
      throw new UnauthorizedException('Phiên đăng nhập đã hết hạn');
    }
    if (payload.purpose !== 'social_login' || payload.provider !== provider) {
      throw new UnauthorizedException('Phiên đăng nhập không hợp lệ');
    }

    const profile =
      provider === 'google'
        ? await this.googleProfile(code)
        : await this.facebookProfile(code);
    return this.upsertSocialUser(profile);
  }

  socialReturnUrl(result: {
    accessToken?: string;
    refreshToken?: string;
    error?: string;
  }) {
    const base = this.config.get<string>(
      'OAUTH_RETURN_URL',
      'http://localhost:8765/#/auth/callback',
    );
    const separator = base.includes('?') ? '&' : '?';
    if (result.accessToken && result.refreshToken) {
      const query = new URLSearchParams({
        token: result.accessToken,
        refresh: result.refreshToken,
      });
      return `${base}${separator}${query}`;
    }
    return `${base}${separator}error=${encodeURIComponent(result.error ?? 'Đăng nhập không thành công')}`;
  }

  private async googleProfile(code: string): Promise<SocialProfile> {
    const clientId = this.required('GOOGLE_CLIENT_ID');
    const response = await axios.post<{
      id_token?: string;
    }>(
      'https://oauth2.googleapis.com/token',
      new URLSearchParams({
        code,
        client_id: clientId,
        client_secret: this.required('GOOGLE_CLIENT_SECRET'),
        redirect_uri: this.callbackUrl('google'),
        grant_type: 'authorization_code',
      }),
      { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } },
    );
    if (!response.data.id_token) {
      throw new UnauthorizedException('Google không trả về mã định danh');
    }
    const ticket = await this.google.verifyIdToken({
      idToken: response.data.id_token,
      audience: clientId,
    });
    const payload = ticket.getPayload();
    if (!payload?.sub || !payload.email || payload.email_verified !== true) {
      throw new UnauthorizedException('Tài khoản Google chưa xác minh email');
    }
    return {
      provider: 'google',
      providerUserId: payload.sub,
      email: payload.email.toLowerCase(),
      fullName: payload.name,
      avatarUrl: payload.picture,
    };
  }

  private async facebookProfile(code: string): Promise<SocialProfile> {
    const appId = this.required('FACEBOOK_APP_ID');
    const appSecret = this.required('FACEBOOK_APP_SECRET');
    const graphVersion = this.required('FACEBOOK_GRAPH_VERSION');
    const redirectUri = this.callbackUrl('facebook');
    const tokenResponse = await axios.get<{ access_token?: string }>(
      `https://graph.facebook.com/${graphVersion}/oauth/access_token`,
      {
        params: {
          client_id: appId,
          client_secret: appSecret,
          redirect_uri: redirectUri,
          code,
        },
      },
    );
    const accessToken = tokenResponse.data.access_token;
    if (!accessToken) {
      throw new UnauthorizedException('Facebook không trả về access token');
    }

    const debugResponse = await axios.get<{
      data?: { is_valid?: boolean; app_id?: string; user_id?: string };
    }>(`https://graph.facebook.com/${graphVersion}/debug_token`, {
      params: {
        input_token: accessToken,
        access_token: `${appId}|${appSecret}`,
      },
    });
    const debug = debugResponse.data.data;
    if (!debug?.is_valid || debug.app_id !== appId || !debug.user_id) {
      throw new UnauthorizedException('Access token Facebook không hợp lệ');
    }

    const profileResponse = await axios.get<{
      id?: string;
      name?: string;
      email?: string;
      picture?: { data?: { url?: string } };
    }>(`https://graph.facebook.com/${graphVersion}/me`, {
      params: {
        fields: 'id,name,email,picture.type(large)',
        access_token: accessToken,
      },
    });
    const profile = profileResponse.data;
    if (!profile.id || profile.id !== debug.user_id || !profile.email) {
      throw new UnauthorizedException(
        'Facebook chưa cấp quyền truy cập địa chỉ email',
      );
    }
    return {
      provider: 'facebook',
      providerUserId: profile.id,
      email: profile.email.toLowerCase(),
      fullName: profile.name,
      avatarUrl: profile.picture?.data?.url,
    };
  }

  private async upsertSocialUser(profile: SocialProfile) {
    const user = await this.prisma.$transaction(async (tx) => {
      const existingAccount = await tx.socialAccount.findUnique({
        where: {
          provider_providerUserId: {
            provider: profile.provider,
            providerUserId: profile.providerUserId,
          },
        },
        include: { user: true },
      });
      if (existingAccount) {
        return tx.user.update({
          where: { id: existingAccount.userId },
          data: {
            fullName: profile.fullName ?? existingAccount.user.fullName,
            ...(!existingAccount.user.avatarCustomized && profile.avatarUrl
              ? { avatarUrl: profile.avatarUrl }
              : {}),
          },
        });
      }

      const existingUser = await tx.user.findUnique({
        where: { email: profile.email },
      });
      const linkedUser = existingUser
        ? await tx.user.update({
            where: { id: existingUser.id },
            data: {
              fullName: existingUser.fullName ?? profile.fullName,
              ...(!existingUser.avatarCustomized && profile.avatarUrl
                ? { avatarUrl: profile.avatarUrl }
                : {}),
            },
          })
        : await tx.user.create({
            data: {
              email: profile.email,
              fullName: profile.fullName,
              avatarUrl: profile.avatarUrl,
            },
          });
      await tx.socialAccount.create({
        data: {
          provider: profile.provider,
          providerUserId: profile.providerUserId,
          userId: linkedUser.id,
        },
      });
      return linkedUser;
    });
    return this.sessionFor(user);
  }

  private async sessionFor(user: {
    id: string;
    email: string;
    fullName: string | null;
    avatarUrl: string | null;
  }) {
    const refreshToken = this.newRefreshToken();
    await this.prisma.refreshSession.create({
      data: {
        tokenHash: this.refreshTokenHash(refreshToken),
        familyId: randomUUID(),
        userId: user.id,
        expiresAt: new Date(
          Date.now() + this.refreshTokenDays() * 24 * 60 * 60 * 1000,
        ),
      },
    });
    return this.sessionPayload(user, refreshToken);
  }

  private async sessionPayload(
    user: {
      id: string;
      email: string;
      fullName: string | null;
      avatarUrl: string | null;
    },
    refreshToken: string,
  ) {
    return {
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        avatarUrl: user.avatarUrl,
      },
      accessToken: await this.jwt.signAsync({
        sub: user.id,
        email: user.email,
      }),
      refreshToken,
    };
  }

  private newRefreshToken() {
    return randomBytes(32).toString('base64url');
  }

  private refreshTokenHash(token: string) {
    return createHash('sha256').update(token).digest('hex');
  }

  private refreshTokenDays() {
    const configured = Number(
      this.config.get<string>('REFRESH_TOKEN_DAYS', '30'),
    );
    return Number.isInteger(configured) && configured >= 1 && configured <= 365
      ? configured
      : 30;
  }

  private async revokeUserSessions(userId: string) {
    await this.prisma.refreshSession.updateMany({
      where: { userId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
  }

  private async revokeTokenFamily(familyId: string, revokedAt = new Date()) {
    await this.prisma.refreshSession.updateMany({
      where: { familyId, revokedAt: null },
      data: { revokedAt },
    });
  }

  private parseProvider(value: string): SocialProvider {
    if (value !== 'google' && value !== 'facebook') {
      throw new BadRequestException('Nhà cung cấp đăng nhập không hợp lệ');
    }
    return value;
  }

  private isProviderConfigured(provider: SocialProvider) {
    const keys =
      provider === 'google'
        ? ['GOOGLE_CLIENT_ID', 'GOOGLE_CLIENT_SECRET']
        : ['FACEBOOK_APP_ID', 'FACEBOOK_APP_SECRET', 'FACEBOOK_GRAPH_VERSION'];
    return keys.every((key) => Boolean(this.config.get<string>(key)?.trim()));
  }

  private ensureProviderConfigured(provider: SocialProvider) {
    if (!this.isProviderConfigured(provider)) {
      throw new BadRequestException(
        `Đăng nhập ${provider === 'google' ? 'Google' : 'Facebook'} chưa được cấu hình trên máy chủ`,
      );
    }
  }

  private callbackUrl(provider: SocialProvider) {
    const publicApiUrl = this.config
      .get<string>('PUBLIC_API_URL', 'http://localhost:3000')
      .replace(/\/$/, '');
    return `${publicApiUrl}/api/v1/auth/oauth/${provider}/callback`;
  }

  private passwordResetCodeHash(userId: string, code: string) {
    return createHash('sha256')
      .update(`${userId}:${code}:${this.required('JWT_SECRET')}`)
      .digest('hex');
  }

  private safeEqual(left: string, right: string) {
    const leftBuffer = Buffer.from(left);
    const rightBuffer = Buffer.from(right);
    return (
      leftBuffer.length === rightBuffer.length &&
      timingSafeEqual(leftBuffer, rightBuffer)
    );
  }

  private async sendPasswordResetEmail(
    email: string,
    fullName: string | null,
    code: string,
  ) {
    await axios.post(
      'https://api.brevo.com/v3/smtp/email',
      {
        sender: {
          email: this.required('BREVO_SENDER_EMAIL'),
          name: this.config.get<string>('BREVO_SENDER_NAME', 'FLIX').trim(),
        },
        to: [{ email, name: fullName?.trim() || undefined }],
        subject: 'Mã khôi phục mật khẩu FLIX',
        textContent: `Xin chào ${fullName?.trim() || 'bạn'},\n\nMã khôi phục mật khẩu FLIX của bạn là: ${code}\nMã có hiệu lực trong 15 phút. Nếu bạn không yêu cầu, hãy bỏ qua email này.`,
      },
      {
        headers: {
          'api-key': this.required('BREVO_API_KEY'),
          'Content-Type': 'application/json',
        },
      },
    );
  }

  private required(key: string) {
    const value = this.config.get<string>(key)?.trim();
    if (!value) throw new BadRequestException(`Thiếu cấu hình ${key}`);
    return value;
  }
}
