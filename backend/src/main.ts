import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { NestExpressApplication } from '@nestjs/platform-express';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';
import { json, urlencoded } from 'express';
import { AppModule } from './app.module';
import { ResponseInterceptor } from './common/response.interceptor';
import { HttpExceptionResponseFilter } from './common/http-exception.filter';
import { corsOrigin, swaggerEnabled } from './common/runtime-config';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
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
  await app.listen(process.env.PORT ?? 3000);
}
void bootstrap();
