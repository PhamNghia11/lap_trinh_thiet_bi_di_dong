import { ConfigService } from '@nestjs/config';

const developmentJwtSecret = 'development-only-change-me';

export function jwtSecret(config: ConfigService) {
  const secret = config.get<string>('JWT_SECRET');
  if (
    config.get<string>('NODE_ENV') === 'production' &&
    (!secret || secret === developmentJwtSecret)
  ) {
    throw new Error('JWT_SECRET must be configured securely in production');
  }
  return secret || developmentJwtSecret;
}

export function corsOrigin(env = process.env): true | string[] {
  const value = env.WEB_ORIGIN?.trim();
  if (env.NODE_ENV === 'production' && (!value || value === '*')) {
    throw new Error('WEB_ORIGIN must list trusted origins in production');
  }
  if (!value || value === '*') return true;
  return value
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
}

export function swaggerEnabled(env = process.env) {
  return env.ENABLE_SWAGGER === 'true' || env.NODE_ENV !== 'production';
}
