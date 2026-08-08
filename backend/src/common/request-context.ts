import { randomUUID } from 'node:crypto';
import { Injectable, NestMiddleware } from '@nestjs/common';
import type { NextFunction, Request, Response } from 'express';

export const REQUEST_ID_HEADER = 'x-request-id';

@Injectable()
export class RequestContextMiddleware implements NestMiddleware {
  use(request: Request, response: Response, next: NextFunction) {
    const requestId = request.header(REQUEST_ID_HEADER) ?? randomUUID();
    response.setHeader(REQUEST_ID_HEADER, requestId);
    (request as Request & { requestId?: string }).requestId = requestId;
    next();
  }
}
