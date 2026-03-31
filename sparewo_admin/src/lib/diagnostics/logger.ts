import { recordDiagnosticEvent } from '@/lib/diagnostics/client';
import type { DiagnosticEvent } from '@/lib/diagnostics/types';

const isProd = process.env.NODE_ENV === 'production';

const safeConsole = (method: 'log' | 'warn' | 'error', ...args: unknown[]): void => {
  if (!isProd) {
    // Keep full verbosity outside production.
    (console[method] as (...a: unknown[]) => void)(...args);
  }
};

const capture = async (event: DiagnosticEvent): Promise<void> => {
  if (!isProd && event.severity === 'info') return;
  await recordDiagnosticEvent(event);
};

export const logInfo = async (
  service: string,
  message: string,
  context?: Record<string, unknown>
): Promise<void> => {
  safeConsole('log', `[${service}]`, message, context || '');
  await capture({ source: 'admin', service, message, context, severity: 'info' });
};

export const logWarn = async (
  service: string,
  message: string,
  context?: Record<string, unknown>
): Promise<void> => {
  safeConsole('warn', `[${service}]`, message, context || '');
  await capture({ source: 'admin', service, message, context, severity: 'warn' });
};

export const logError = async (
  service: string,
  message: string,
  error?: unknown,
  context?: Record<string, unknown>
): Promise<void> => {
  safeConsole('error', `[${service}]`, message, error || '', context || '');
  const code =
    typeof error === 'object' && error && 'code' in (error as Record<string, unknown>)
      ? String((error as Record<string, unknown>).code)
      : undefined;
  await capture({
    source: 'admin',
    service,
    message,
    code,
    context: {
      ...context,
      errorName: error instanceof Error ? error.name : undefined,
      error: error instanceof Error ? error.message : String(error ?? ''),
      stack: error instanceof Error ? error.stack : undefined,
    },
    severity: 'error',
  });
};

export const captureException = async (
  service: string,
  error: unknown,
  context?: Record<string, unknown>
): Promise<void> => {
  await logError(
    service,
    error instanceof Error ? error.message : 'Unhandled exception',
    error,
    context
  );
};
