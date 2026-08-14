import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';
import { SentryModule } from '@sentry/nestjs/setup';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { RequestContextMiddleware } from './common/request-context';
import { HealthModule } from './health/health.module';
import { PrismaModule } from './prisma/prisma.module';
import { TmdbModule } from './tmdb/tmdb.module';
import { AuthModule } from './auth/auth.module';
import { UserDataModule } from './user-data/user-data.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    SentryModule.forRoot(),
    ThrottlerModule.forRoot([{ ttl: 60_000, limit: 60 }]),
    PrismaModule,
    HealthModule,
    TmdbModule,
    AuthModule,
    UserDataModule,
  ],
  controllers: [AppController],
  providers: [AppService, { provide: APP_GUARD, useClass: ThrottlerGuard }],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(RequestContextMiddleware).forRoutes('*');
  }
}
