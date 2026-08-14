import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { sessionCleanupIntervalMs } from '../common/runtime-config';

@Injectable()
export class RefreshSessionCleanupService
  implements OnModuleInit, OnModuleDestroy
{
  private readonly logger = new Logger(RefreshSessionCleanupService.name);
  private timer?: NodeJS.Timeout;

  constructor(private readonly prisma: PrismaService) {}

  async onModuleInit() {
    await this.cleanup();
    this.timer = setInterval(() => {
      void this.cleanup();
    }, sessionCleanupIntervalMs());
    this.timer.unref();
  }

  onModuleDestroy() {
    if (this.timer) clearInterval(this.timer);
  }

  private async cleanup() {
    if (!process.env.DATABASE_URL) return;
    try {
      const result = await this.prisma.refreshSession.deleteMany({
        where: { expiresAt: { lt: new Date() } },
      });
      if (result.count > 0) {
        this.logger.log({
          event: 'refresh_session_cleanup',
          deleted: result.count,
        });
      }
    } catch (error) {
      this.logger.warn(
        `Không thể dọn refresh session hết hạn: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }
}
