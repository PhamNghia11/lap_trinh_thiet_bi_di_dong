import { Controller, Get, Header, HttpStatus, Res } from '@nestjs/common';
import type { Response } from 'express';
import { PrismaService } from '../prisma/prisma.service';

@Controller('health')
export class HealthController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  @Header('Cache-Control', 'no-store')
  async check(@Res({ passthrough: true }) response: Response) {
    let database = 'not_configured';
    if (process.env.DATABASE_URL) {
      try {
        await this.prisma.$queryRaw`SELECT 1`;
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
}
