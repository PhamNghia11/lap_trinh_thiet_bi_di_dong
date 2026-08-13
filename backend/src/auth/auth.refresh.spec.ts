import { UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';
import { AuthService } from './auth.service';

describe('AuthService refresh sessions', () => {
  type SessionCreateArgs = {
    data: {
      tokenHash: string;
      familyId: string;
      userId: string;
      expiresAt: Date;
    };
  };
  const now = new Date();
  const user = {
    id: '00000000-0000-4000-8000-000000000001',
    email: 'viewer@flix.test',
    fullName: 'FLIX Viewer',
    avatarUrl: null,
  };
  let issuedCreateArgs: SessionCreateArgs | undefined;
  let rotatedCreateArgs: SessionCreateArgs | undefined;
  const create = jest.fn((args: SessionCreateArgs) => {
    issuedCreateArgs = args;
    return Promise.resolve({});
  });
  const findUnique = jest.fn();
  const updateMany = jest.fn();
  const userFindUnique = jest.fn();
  const userCreate = jest.fn();
  const transactionUpdateMany = jest.fn();
  const transactionCreate = jest.fn((args: SessionCreateArgs) => {
    rotatedCreateArgs = args;
    return Promise.resolve({});
  });
  const signAsync = jest.fn<() => Promise<string>>();
  const prisma = {
    refreshSession: { create, findUnique, updateMany },
    user: { findUnique: userFindUnique, create: userCreate },
    $transaction: jest.fn((callback: (tx: unknown) => unknown) =>
      Promise.resolve(
        callback({
          refreshSession: {
            updateMany: transactionUpdateMany,
            create: transactionCreate,
          },
        }),
      ),
    ),
  } as unknown as PrismaService;
  const jwt = {
    signAsync,
  } as unknown as JwtService;
  const config = {
    get: jest.fn((key: string, fallback?: string) =>
      key === 'REFRESH_TOKEN_DAYS' ? '30' : fallback,
    ),
  } as unknown as ConfigService;

  let service: AuthService;

  beforeEach(() => {
    jest.clearAllMocks();
    issuedCreateArgs = undefined;
    rotatedCreateArgs = undefined;
    signAsync.mockResolvedValue('access-token');
    service = new AuthService(prisma, jwt, config);
  });

  it('issues an access token and a 30-day refresh session', async () => {
    userFindUnique.mockResolvedValue(null);
    userCreate.mockResolvedValue(user);

    const before = Date.now();
    const result = await service.register({
      email: user.email,
      password: 'strong-password',
      fullName: user.fullName,
    });

    expect(result).toMatchObject({ user, accessToken: 'access-token' });
    expect(result.refreshToken).toHaveLength(43);
    expect(issuedCreateArgs).toBeDefined();
    const issuedSession = issuedCreateArgs!.data;
    expect(issuedSession.userId).toBe(user.id);
    expect(issuedSession.expiresAt).toBeInstanceOf(Date);
    const expiresAt = issuedSession.expiresAt;
    expect(expiresAt.getTime() - before).toBeGreaterThan(
      29 * 24 * 60 * 60 * 1000,
    );
    expect(signAsync).toHaveBeenCalledWith({
      sub: user.id,
      email: user.email,
    });
  });

  it('rotates a valid refresh token without extending its absolute expiry', async () => {
    const expiresAt = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
    findUnique.mockResolvedValue({
      id: 'session-id',
      familyId: '00000000-0000-4000-8000-000000000002',
      userId: user.id,
      expiresAt,
      revokedAt: null,
      user,
    });
    transactionUpdateMany.mockResolvedValue({ count: 1 });

    const result = await service.refreshSession('a'.repeat(43));

    expect(result).toMatchObject({ user, accessToken: 'access-token' });
    expect(result.refreshToken).toHaveLength(43);
    expect(rotatedCreateArgs).toBeDefined();
    const rotatedSession = rotatedCreateArgs!.data;
    expect(rotatedSession).toMatchObject({
      familyId: '00000000-0000-4000-8000-000000000002',
      userId: user.id,
      expiresAt,
    });
  });

  it('revokes the active family when an old refresh token is reused', async () => {
    findUnique.mockResolvedValue({
      id: 'old-session-id',
      familyId: '00000000-0000-4000-8000-000000000002',
      userId: user.id,
      expiresAt: new Date(now.getTime() + 60_000),
      revokedAt: new Date(now.getTime() - 1000),
      user,
    });
    updateMany.mockResolvedValue({ count: 1 });

    await expect(service.refreshSession('b'.repeat(43))).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
    expect(updateMany).toHaveBeenCalledWith({
      where: {
        familyId: '00000000-0000-4000-8000-000000000002',
        revokedAt: null,
      },
      data: { revokedAt: expect.any(Date) as Date },
    });
  });

  it('makes logout idempotent and revokes its token family', async () => {
    findUnique.mockResolvedValue({
      familyId: '00000000-0000-4000-8000-000000000002',
    });
    updateMany.mockResolvedValue({ count: 1 });

    await expect(service.logout('c'.repeat(43))).resolves.toEqual({
      loggedOut: true,
    });
    expect(updateMany).toHaveBeenCalledTimes(1);
  });
});
