import { HttpStatus } from '@nestjs/common';
import type { ArgumentsHost } from '@nestjs/common';
import { HttpExceptionResponseFilter } from './http-exception.filter';

describe('HttpExceptionResponseFilter', () => {
  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('does not expose query parameters in error responses or logs', () => {
    const status = jest.fn().mockReturnThis();
    const json = jest.fn();
    const request = {
      requestId: 'request-123',
      method: 'GET',
      path: '/api/v1/auth/oauth/google/callback',
      url: '/api/v1/auth/oauth/google/callback?code=secret-code',
    };
    const host = {
      switchToHttp: () => ({
        getRequest: () => request,
        getResponse: () => ({ status, json }),
      }),
    } as unknown as ArgumentsHost;
    const error = jest.spyOn(console, 'error').mockImplementation();

    new HttpExceptionResponseFilter().catch(new Error('upstream failed'), host);

    expect(status).toHaveBeenCalledWith(HttpStatus.INTERNAL_SERVER_ERROR);
    expect(json).toHaveBeenCalledWith(
      expect.objectContaining({
        path: '/api/v1/auth/oauth/google/callback',
        requestId: 'request-123',
      }),
    );
    expect(JSON.stringify(error.mock.calls)).not.toContain('secret-code');
  });
});
