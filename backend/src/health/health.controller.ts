import { Controller, Get, Header, HttpStatus, Res } from '@nestjs/common';
import type { Response } from 'express';
import { PrismaService } from '../prisma/prisma.service';
import { healthcheckTimeoutMs } from '../common/runtime-config';

@Controller('health')
export class HealthController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  @Header('Cache-Control', 'no-store')
  async check(@Res({ passthrough: true }) response: Response) {
    return this.readiness(response);
  }

  @Get('live')
  @Header('Cache-Control', 'no-store')
  liveness() {
    return {
      status: 'ok',
      uptimeSeconds: Math.floor(process.uptime()),
      timestamp: new Date().toISOString(),
    };
  }

  @Get('ready')
  @Header('Cache-Control', 'no-store')
  async ready(@Res({ passthrough: true }) response: Response) {
    return this.readiness(response);
  }

  private async readiness(response: Response) {
    let database = 'not_configured';
    if (process.env.DATABASE_URL) {
      try {
        await this.withTimeout(
          this.prisma.$queryRaw`SELECT 1`,
          healthcheckTimeoutMs(),
        );
        database = 'up';
      } catch {
        database = 'down';
      }
    }
    const databaseUnavailable =
      database === 'down' ||
      (process.env.NODE_ENV === 'production' && database === 'not_configured');
    response.status(
      databaseUnavailable ? HttpStatus.SERVICE_UNAVAILABLE : HttpStatus.OK,
    );
    return {
      status: databaseUnavailable ? 'degraded' : 'ok',
      database,
      storage:
        process.env.SUPABASE_URL && process.env.SUPABASE_SERVICE_ROLE_KEY
          ? 'configured'
          : 'not_configured',
      uptimeSeconds: Math.floor(process.uptime()),
      version: process.env.RENDER_GIT_COMMIT ?? process.env.npm_package_version,
      timestamp: new Date().toISOString(),
    };
  }

  private async withTimeout<T>(promise: Promise<T>, timeoutMs: number) {
    let timeout: NodeJS.Timeout | undefined;
    try {
      return await Promise.race([
        promise,
        new Promise<never>((_, reject) => {
          timeout = setTimeout(
            () => reject(new Error('Health check timed out')),
            timeoutMs,
          );
        }),
      ]);
    } finally {
      if (timeout) clearTimeout(timeout);
    }
  }
}
