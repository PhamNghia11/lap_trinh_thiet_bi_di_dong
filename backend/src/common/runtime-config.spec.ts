import { ConfigService } from '@nestjs/config';
import { corsOrigin, jwtSecret, swaggerEnabled } from './runtime-config';

describe('runtime config', () => {
  it('keeps development defaults available locally', () => {
    const config = new ConfigService({ NODE_ENV: 'development' });
    expect(jwtSecret(config)).toBe('development-only-change-me');
    expect(corsOrigin({ NODE_ENV: 'development' })).toBe(true);
  });

  it('rejects unsafe production auth and CORS defaults', () => {
    const config = new ConfigService({ NODE_ENV: 'production' });
    expect(() => jwtSecret(config)).toThrow('JWT_SECRET');
    expect(() =>
      corsOrigin({ NODE_ENV: 'production', WEB_ORIGIN: '*' }),
    ).toThrow('WEB_ORIGIN');
  });

  it('normalizes trusted production origins', () => {
    expect(
      corsOrigin({
        NODE_ENV: 'production',
        WEB_ORIGIN: 'https://flix.example, https://admin.flix.example ',
      }),
    ).toEqual(['https://flix.example', 'https://admin.flix.example']);
  });

  it('tắt Swagger mặc định ở production và cho phép bật rõ ràng', () => {
    expect(swaggerEnabled({ NODE_ENV: 'production' })).toBe(false);
    expect(
      swaggerEnabled({ NODE_ENV: 'production', ENABLE_SWAGGER: 'true' }),
    ).toBe(true);
    expect(swaggerEnabled({ NODE_ENV: 'development' })).toBe(true);
  });
});
