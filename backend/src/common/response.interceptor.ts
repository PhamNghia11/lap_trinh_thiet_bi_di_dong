import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { map, Observable } from 'rxjs';

@Injectable()
export class ResponseInterceptor implements NestInterceptor {
  intercept(
    _context: ExecutionContext,
    next: CallHandler<unknown>,
  ): Observable<unknown> {
    return next
      .handle()
      .pipe(map((data: unknown) => ({ success: true, data })));
  }
}
