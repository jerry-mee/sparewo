'use client';

import { useEffect } from 'react';
import { recordDiagnosticEvent } from '@/lib/diagnostics/client';

const isProd = process.env.NODE_ENV === 'production';

const joinArgs = (args: unknown[]): string => {
  return args
    .map((arg) => {
      if (typeof arg === 'string') return arg;
      if (arg instanceof Error) return `${arg.name}: ${arg.message}`;
      try {
        return JSON.stringify(arg);
      } catch {
        return String(arg);
      }
    })
    .join(' ')
    .slice(0, 1200);
};

export function ProductionConsoleGuard() {
  useEffect(() => {
    if (!isProd) return;

    const originalError = console.error;
    const originalWarn = console.warn;

    console.error = (...args: unknown[]) => {
      void recordDiagnosticEvent({
        source: 'admin',
        service: 'web_console',
        severity: 'error',
        message: joinArgs(args),
        context: { type: 'console.error' },
        platform: 'web',
      });
    };

    console.warn = (...args: unknown[]) => {
      void recordDiagnosticEvent({
        source: 'admin',
        service: 'web_console',
        severity: 'warn',
        message: joinArgs(args),
        context: { type: 'console.warn' },
        platform: 'web',
      });
    };

    return () => {
      console.error = originalError;
      console.warn = originalWarn;
    };
  }, []);

  return null;
}
