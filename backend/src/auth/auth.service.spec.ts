import { ConflictException, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import axios from 'axios';
import { PrismaService } from '../prisma/prisma.service';
import { AuthService } from './auth.service';

jest.mock('axios');

const mockedAxios = jest.mocked(axios);

describe('AuthService social authentication', () => {
  const values: Record<string, string> = {
    GOOGLE_CLIENT_ID: 'google-client-id',
    GOOGLE_CLIENT_SECRET: 'google-client-secret',
    FACEBOOK_APP_ID: 'facebook-app-id',
    FACEBOOK_APP_SECRET: 'facebook-app-secret',
    FACEBOOK_GRAPH_VERSION: 'v-test',
    PUBLIC_API_URL: 'http://localhost:3000',
    OAUTH_RETURN_URL: 'http://localhost:8765/#/auth/callback',
    JWT_SECRET: 'test-secret',
    BREVO_API_KEY: 'brevo-api-key',
    BREVO_SENDER_EMAIL: 'no-reply@flix.test',
    BREVO_SENDER_NAME: 'FLIX',
  };

  const prisma = {
    user: { findUnique: jest.fn() },
  } as unknown as PrismaService;
  const jwt = {
    signAsync: jest.fn().mockResolvedValue('signed-state'),
    verifyAsync: jest.fn(),
  } as unknown as JwtService;
  const config = {
    get: jest.fn((key: string, fallback?: string) => values[key] ?? fallback),
  } as unknown as ConfigService;

  let service: AuthService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new AuthService(prisma, jwt, config);
  });

  it('reports providers only when all required settings exist', () => {
    expect(service.availableSocialProviders()).toEqual({
      google: true,
      facebook: true,
    });
  });

  it('creates a signed Google authorization URL with the registered callback', async () => {
    const result = await service.socialAuthorizationUrl('google');
    const url = new URL(result.url);

    expect(url.origin).toBe('https://accounts.google.com');
    expect(url.searchParams.get('client_id')).toBe('google-client-id');
    expect(url.searchParams.get('state')).toBe('signed-state');
    expect(url.searchParams.get('redirect_uri')).toBe(
      'http://localhost:3000/api/v1/auth/oauth/google/callback',
    );
    expect(result.url).not.toContain('google-client-secret');
  });

  it('rejects a callback whose signed state is invalid', async () => {
    (jwt.verifyAsync as jest.Mock).mockRejectedValueOnce(new Error('invalid'));

    await expect(
      service.completeSocialLogin('google', 'code', 'bad-state'),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('returns social tokens in the URL fragment callback route', () => {
    expect(service.socialReturnUrl({ accessToken: 'a+b/c' })).toBe(
      'http://localhost:8765/#/auth/callback?token=a%2Bb%2Fc',
    );
  });

  it('gives social-only accounts a clear password-change error', async () => {
    (prisma.user.findUnique as jest.Mock).mockResolvedValueOnce({
      id: 'user-id',
      passwordHash: null,
    });

    await expect(
      service.changePassword('user-id', {
        currentPassword: 'old-password',
        newPassword: 'new-password',
      }),
    ).rejects.toBeInstanceOf(ConflictException);
  });

  it('does not reveal whether a reset email exists', async () => {
    (prisma.user.findUnique as jest.Mock).mockResolvedValueOnce(null);

    await expect(
      service.requestPasswordReset({ email: 'missing@example.com' }),
    ).resolves.toEqual({ requested: true });
  });

  it('sends password reset codes through Brevo', async () => {
    const update = jest.fn().mockResolvedValue({});
    (prisma as unknown as { user: { update: jest.Mock } }).user.update = update;
    (prisma.user.findUnique as jest.Mock).mockResolvedValueOnce({
      id: 'user-id',
      email: 'user@example.com',
      fullName: 'FLIX User',
    });
    mockedAxios.post.mockResolvedValueOnce({
      data: { messageId: '1' },
    });

    await expect(
      service.requestPasswordReset({ email: 'USER@example.com' }),
    ).resolves.toEqual({ requested: true });

    // Axios declares `post` as a method, while Jest replaces it with a mock.
    // eslint-disable-next-line @typescript-eslint/unbound-method
    expect(mockedAxios.post).toHaveBeenCalledWith(
      'https://api.brevo.com/v3/smtp/email',
      expect.objectContaining({
        sender: { email: 'no-reply@flix.test', name: 'FLIX' },
        to: [{ email: 'user@example.com', name: 'FLIX User' }],
        subject: 'Mã khôi phục mật khẩu FLIX',
        textContent: expect.stringMatching(/\d{6}/) as string,
      }),
      {
        headers: {
          'api-key': 'brevo-api-key',
          'Content-Type': 'application/json',
        },
      },
    );
    expect(update).toHaveBeenCalledTimes(1);
  });

  it('rejects an expired password reset code', async () => {
    (prisma.user.findUnique as jest.Mock).mockResolvedValueOnce({
      id: 'user-id',
      passwordResetCodeHash: 'invalid',
      passwordResetExpiresAt: new Date(Date.now() - 1000),
    });

    await expect(
      service.resetPassword({
        email: 'user@example.com',
        code: '123456',
        newPassword: 'new-password',
      }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });
});
