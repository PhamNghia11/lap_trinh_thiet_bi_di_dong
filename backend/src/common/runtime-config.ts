import { ConfigService } from '@nestjs/config';

const developmentJwtSecret = 'development-only-change-me';
const productionRequired = [
  'DATABASE_URL',
  'JWT_SECRET',
  'TMDB_API_KEY',
  'WEB_ORIGIN',
] as const;

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

export function validateRuntimeConfig(env = process.env) {
  if (env.NODE_ENV !== 'production') return;
  const missing = productionRequired.filter((name) => !env[name]?.trim());
  if (missing.length > 0) {
    throw new Error(
      `Missing required production configuration: ${missing.join(', ')}`,
    );
  }
  if ((env.JWT_SECRET?.trim().length ?? 0) < 32) {
    throw new Error(
      'JWT_SECRET must contain at least 32 characters in production',
    );
  }
  corsOrigin(env);
  validateOptionalNumber(env.REFRESH_TOKEN_DAYS, 'REFRESH_TOKEN_DAYS', 1, 365);
  validateOptionalNumber(
    env.HTTP_REQUEST_TIMEOUT_MS,
    'HTTP_REQUEST_TIMEOUT_MS',
    5_000,
    120_000,
  );
  validateOptionalNumber(
    env.HEALTHCHECK_TIMEOUT_MS,
    'HEALTHCHECK_TIMEOUT_MS',
    500,
    10_000,
  );
  validateOptionalNumber(
    env.SESSION_CLEANUP_INTERVAL_HOURS,
    'SESSION_CLEANUP_INTERVAL_HOURS',
    1,
    168,
  );
  validateOptionalNumber(
    env.SENTRY_TRACES_SAMPLE_RATE,
    'SENTRY_TRACES_SAMPLE_RATE',
    0,
    1,
  );
  if (
    env.LOG_LEVEL &&
    !['fatal', 'error', 'warn', 'info', 'debug', 'verbose'].includes(
      env.LOG_LEVEL.trim().toLowerCase(),
    )
  ) {
    throw new Error(
      'LOG_LEVEL must be fatal, error, warn, info, debug or verbose',
    );
  }
}

export function httpRequestTimeoutMs(env = process.env) {
  return boundedNumber(env.HTTP_REQUEST_TIMEOUT_MS, 30_000, 5_000, 120_000);
}

export function healthcheckTimeoutMs(env = process.env) {
  return boundedNumber(env.HEALTHCHECK_TIMEOUT_MS, 3_000, 500, 10_000);
}

export function sessionCleanupIntervalMs(env = process.env) {
  const hours = boundedNumber(env.SESSION_CLEANUP_INTERVAL_HOURS, 24, 1, 168);
  return hours * 60 * 60 * 1_000;
}

function validateOptionalNumber(
  value: string | undefined,
  name: string,
  minimum: number,
  maximum: number,
) {
  if (value === undefined) return;
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed < minimum || parsed > maximum) {
    throw new Error(`${name} must be between ${minimum} and ${maximum}`);
  }
}

function boundedNumber(
  value: string | undefined,
  fallback: number,
  minimum: number,
  maximum: number,
) {
  if (!value?.trim()) return fallback;
  const parsed = Number(value);
  return Number.isFinite(parsed)
    ? Math.min(maximum, Math.max(minimum, parsed))
    : fallback;
}
