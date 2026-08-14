import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { map, Observable } from 'rxjs';
import type { Request } from 'express';

@Injectable()
export class ResponseInterceptor implements NestInterceptor {
  intercept(
    context: ExecutionContext,
    next: CallHandler<unknown>,
  ): Observable<unknown> {
    const request = context
      .switchToHttp()
      .getRequest<Request & { requestId?: string }>();
    return next.handle().pipe(
      map((data: unknown) => ({
        success: true,
        data,
        requestId: request.requestId,
      })),
    );
  }
}
