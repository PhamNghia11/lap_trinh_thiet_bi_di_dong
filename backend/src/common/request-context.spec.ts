import type { NextFunction, Request, Response } from 'express';
import { REQUEST_ID_HEADER, RequestContextMiddleware } from './request-context';

describe('RequestContextMiddleware', () => {
  const middleware = new RequestContextMiddleware();

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('preserves a safe request id and logs completion without query data', () => {
    let finish = () => undefined;
    const request = {
      header: jest.fn().mockReturnValue('client-request-123'),
      method: 'GET',
      path: '/api/v1/movies/search',
      url: '/api/v1/movies/search?query=private',
    } as unknown as Request & { requestId?: string };
    const setHeader = jest.fn();
    const response = {
      statusCode: 200,
      setHeader,
      once: jest.fn((_event: string, callback: () => void) => {
        finish = callback;
      }),
    } as unknown as Response;
    const next = jest.fn() as NextFunction;
    const log = jest.spyOn(console, 'log').mockImplementation();

    middleware.use(request, response, next);
    finish();

    expect(request.requestId).toBe('client-request-123');
    expect(setHeader).toHaveBeenCalledWith(
      REQUEST_ID_HEADER,
      'client-request-123',
    );
    expect(next).toHaveBeenCalledTimes(1);
    const entry = JSON.parse(log.mock.calls[0][0] as string) as {
      path: string;
      status: number;
    };
    expect(entry).toMatchObject({
      path: '/api/v1/movies/search',
      status: 200,
    });
    expect(log.mock.calls[0][0]).not.toContain('private');
  });

  it('replaces an unsafe client supplied request id', () => {
    const request = {
      header: jest.fn().mockReturnValue('bad request id'),
      method: 'GET',
      path: '/api/v1/health',
    } as unknown as Request & { requestId?: string };
    const response = {
      statusCode: 200,
      setHeader: jest.fn(),
      once: jest.fn(),
    } as unknown as Response;

    middleware.use(request, response, jest.fn());

    expect(request.requestId).toMatch(
      /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/,
    );
    expect(request.requestId).not.toBe('bad request id');
  });
});
