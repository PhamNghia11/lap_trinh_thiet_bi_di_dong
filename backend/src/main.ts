import './instrument';
import { NestFactory } from '@nestjs/core';
import { ConsoleLogger, ValidationPipe } from '@nestjs/common';
import { NestExpressApplication } from '@nestjs/platform-express';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';
import { json, urlencoded } from 'express';
import { AppModule } from './app.module';
import { ResponseInterceptor } from './common/response.interceptor';
import { HttpExceptionResponseFilter } from './common/http-exception.filter';
import {
  corsOrigin,
  httpRequestTimeoutMs,
  swaggerEnabled,
  validateRuntimeConfig,
} from './common/runtime-config';
import { StructuredLogger } from './common/structured-logger';

const logger =
  process.env.NODE_ENV === 'production'
    ? new StructuredLogger()
    : new ConsoleLogger({ colors: true });

async function bootstrap() {
  validateRuntimeConfig();
  const app = await NestFactory.create<NestExpressApplication>(AppModule, {
    logger,
  });
  app.set('trust proxy', 1);
  app.enableShutdownHooks();
  app.use(json({ limit: '3mb' }));
  app.use(urlencoded({ extended: true, limit: '3mb' }));
  app.setGlobalPrefix('api/v1');
  app.use(helmet());
  app.enableCors({
    origin: corsOrigin(),
    credentials: true,
  });
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );
  app.useGlobalInterceptors(new ResponseInterceptor());
  app.useGlobalFilters(new HttpExceptionResponseFilter());

  if (swaggerEnabled()) {
    const swaggerConfig = new DocumentBuilder()
      .setTitle('FLIX API')
      .setDescription('Backend tra cứu phim và quản lý dữ liệu người dùng')
      .setVersion('1.0')
      .addBearerAuth()
      .build();
    SwaggerModule.setup(
      'api/docs',
      app,
      SwaggerModule.createDocument(app, swaggerConfig),
    );
  }
  const port = Number(process.env.PORT ?? 3000);
  await app.listen(port, '0.0.0.0');
  const server = app.getHttpServer();
  const requestTimeout = httpRequestTimeoutMs();
  server.requestTimeout = requestTimeout;
  server.timeout = requestTimeout;
  server.headersTimeout = Math.min(15_000, requestTimeout);
  server.keepAliveTimeout = 5_000;
  logger.log(
    {
      event: 'application_ready',
      port,
      environment: process.env.NODE_ENV ?? 'development',
      version: process.env.RENDER_GIT_COMMIT ?? process.env.npm_package_version,
    },
    'Bootstrap',
  );
}
void bootstrap().catch((error: unknown) => {
  logger.fatal(error, 'Bootstrap');
  process.exitCode = 1;
});
