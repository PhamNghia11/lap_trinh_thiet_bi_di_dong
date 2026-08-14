import * as Sentry from '@sentry/nestjs';

const dsn = process.env.SENTRY_DSN?.trim();

if (dsn) {
  Sentry.init({
    dsn,
    environment: process.env.SENTRY_ENVIRONMENT ?? process.env.NODE_ENV,
    release: process.env.SENTRY_RELEASE ?? process.env.RENDER_GIT_COMMIT,
    sendDefaultPii: false,
    tracesSampleRate: sampleRate(process.env.SENTRY_TRACES_SAMPLE_RATE, 0.1),
    beforeSend(event) {
      if (!event.request) return event;
      event.request.cookies = undefined;
      event.request.query_string = undefined;
      if (event.request.url) {
        event.request.url = event.request.url.split(/[?#]/, 1)[0];
      }
      const headers = event.request.headers;
      if (headers) {
        for (const name of Object.keys(headers)) {
          if (
            ['authorization', 'cookie', 'set-cookie'].includes(
              name.toLowerCase(),
            )
          ) {
            delete headers[name];
          }
        }
      }
      return event;
    },
  });
}

export function captureBackendException(
  exception: unknown,
  context: {
    requestId?: string;
    method?: string;
    path?: string;
    status?: number;
  },
) {
  if (!dsn) return;
  Sentry.withScope((scope) => {
    if (context.requestId) scope.setTag('request_id', context.requestId);
    if (context.method) scope.setTag('http.method', context.method);
    if (context.status)
      scope.setTag('http.status_code', String(context.status));
    if (context.path) scope.setContext('request', { path: context.path });
    Sentry.captureException(exception);
  });
}

function sampleRate(value: string | undefined, fallback: number) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? Math.min(1, Math.max(0, parsed)) : fallback;
}
