import { PrismaService } from '../prisma/prisma.service';
import { HealthController } from './health.controller';

describe('HealthController', () => {
  const query = jest.fn();
  const controller = new HealthController({
    $queryRaw: query,
  } as unknown as PrismaService);
  const originalDatabaseUrl = process.env.DATABASE_URL;
  const originalSupabaseUrl = process.env.SUPABASE_URL;
  const originalServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  afterEach(() => {
    process.env.DATABASE_URL = originalDatabaseUrl;
    process.env.SUPABASE_URL = originalSupabaseUrl;
    process.env.SUPABASE_SERVICE_ROLE_KEY = originalServiceKey;
    jest.clearAllMocks();
  });

  it('báo database và object storage đã sẵn sàng', async () => {
    process.env.DATABASE_URL = 'postgresql://example';
    process.env.SUPABASE_URL = 'https://project.supabase.co';
    process.env.SUPABASE_SERVICE_ROLE_KEY = 'service-key';
    query.mockResolvedValue([{ result: 1 }]);
    await expect(controller.check()).resolves.toMatchObject({
      status: 'ok',
      database: 'up',
      storage: 'configured',
    });
  });

  it('báo degraded khi database không phản hồi', async () => {
    process.env.DATABASE_URL = 'postgresql://example';
    query.mockRejectedValue(new Error('offline'));
    await expect(controller.check()).resolves.toMatchObject({
      status: 'degraded',
      database: 'down',
    });
  });
});
