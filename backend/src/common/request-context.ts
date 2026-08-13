import { randomUUID } from 'node:crypto';
import { Injectable, NestMiddleware } from '@nestjs/common';
import type { NextFunction, Request, Response } from 'express';

export const REQUEST_ID_HEADER = 'x-request-id';

@Injectable()
export class RequestContextMiddleware implements NestMiddleware {
  use(request: Request, response: Response, next: NextFunction) {
    const suppliedRequestId = request.header(REQUEST_ID_HEADER);
    const requestId =
      suppliedRequestId &&
      suppliedRequestId.length <= 128 &&
      /^[A-Za-z0-9._:-]+$/.test(suppliedRequestId)
        ? suppliedRequestId
        : randomUUID();
    const startedAt = Date.now();
    response.setHeader(REQUEST_ID_HEADER, requestId);
    (request as Request & { requestId?: string }).requestId = requestId;
    response.once('finish', () => {
      console.log(
        JSON.stringify({
          level: 'info',
          event: 'http_request',
          requestId,
          method: request.method,
          path: request.path,
          status: response.statusCode,
          durationMs: Date.now() - startedAt,
          timestamp: new Date().toISOString(),
        }),
      );
    });
    next();
  }
}
