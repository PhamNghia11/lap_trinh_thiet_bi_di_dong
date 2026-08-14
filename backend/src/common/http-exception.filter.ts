import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import type { Request, Response } from 'express';
import { captureBackendException } from '../instrument';

@Catch()
export class HttpExceptionResponseFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const context = host.switchToHttp();
    const request = context.getRequest<Request & { requestId?: string }>();
    const response = context.getResponse<Response>();
    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;
    const exceptionResponse =
      exception instanceof HttpException ? exception.getResponse() : undefined;
    const message =
      typeof exceptionResponse === 'string'
        ? exceptionResponse
        : ((exceptionResponse as { message?: string | string[] } | undefined)
            ?.message ?? 'Đã xảy ra lỗi máy chủ');

    if (status >= 500) {
      captureBackendException(exception, {
        requestId: request.requestId,
        method: request.method,
        path: request.path,
        status,
      });
      console.error(
        JSON.stringify({
          level: 'error',
          event: 'http_exception',
          status,
          requestId: request.requestId,
          method: request.method,
          path: request.path,
          message: exception instanceof Error ? exception.message : message,
          stack: exception instanceof Error ? exception.stack : undefined,
          timestamp: new Date().toISOString(),
        }),
      );
    }

    const publicMessage = status >= 500 ? 'Đã xảy ra lỗi máy chủ' : message;
    response.setHeader('Cache-Control', 'no-store');
    response.status(status).json({
      success: false,
      code: status >= 500 ? 'INTERNAL_ERROR' : 'REQUEST_ERROR',
      message: publicMessage,
      requestId: request.requestId,
      path: request.path,
      timestamp: new Date().toISOString(),
    });
  }
}
