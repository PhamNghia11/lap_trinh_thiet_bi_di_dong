import type { LoggerService } from '@nestjs/common';

type AppLogLevel = 'fatal' | 'error' | 'warn' | 'info' | 'debug' | 'verbose';

const levelPriority: Record<AppLogLevel, number> = {
  fatal: 0,
  error: 1,
  warn: 2,
  info: 3,
  debug: 4,
  verbose: 5,
};

function configuredLogLevel(): AppLogLevel {
  const level = process.env.LOG_LEVEL?.trim().toLowerCase();
  return level && level in levelPriority ? (level as AppLogLevel) : 'info';
}

function serializableMessage(message: unknown): unknown {
  if (message instanceof Error) {
    return {
      name: message.name,
      message: message.message,
      stack: message.stack,
    };
  }
  try {
    JSON.stringify(message);
    return message;
  } catch {
    return String(message);
  }
}

export class StructuredLogger implements LoggerService {
  private readonly minimumLevel = configuredLogLevel();

  log(message: unknown, ...optionalParams: unknown[]) {
    this.write('info', message, optionalParams);
  }

  fatal(message: unknown, ...optionalParams: unknown[]) {
    this.write('fatal', message, optionalParams);
  }

  error(message: unknown, ...optionalParams: unknown[]) {
    this.write('error', message, optionalParams);
  }

  warn(message: unknown, ...optionalParams: unknown[]) {
    this.write('warn', message, optionalParams);
  }

  debug(message: unknown, ...optionalParams: unknown[]) {
    this.write('debug', message, optionalParams);
  }

  verbose(message: unknown, ...optionalParams: unknown[]) {
    this.write('verbose', message, optionalParams);
  }

  private write(
    level: AppLogLevel,
    message: unknown,
    optionalParams: unknown[],
  ) {
    if (levelPriority[level] > levelPriority[this.minimumLevel]) return;
    const context = [...optionalParams]
      .reverse()
      .find((value): value is string => typeof value === 'string');
    const entry = JSON.stringify({
      level,
      event: 'application_log',
      context,
      message: serializableMessage(message),
      timestamp: new Date().toISOString(),
    });
    const stream =
      level === 'fatal' || level === 'error' ? process.stderr : process.stdout;
    stream.write(`${entry}\n`);
  }
}
