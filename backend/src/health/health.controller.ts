import { Controller, Get } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Controller('health')
export class HealthController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  async check() {
    let database = 'not_configured';
    if (process.env.DATABASE_URL) {
      try {
        await this.prisma.$queryRaw`SELECT 1`;
        database = 'up';
      } catch {
        database = 'down';
      }
    }
    return {
      status: database === 'down' ? 'degraded' : 'ok',
      database,
      timestamp: new Date().toISOString(),
    };
  }
}
