export type DiagnosticSource = 'client' | 'admin' | 'function';
export type DiagnosticSeverity = 'info' | 'warn' | 'error';

export interface DiagnosticEvent {
  source: DiagnosticSource;
  service: string;
  severity: DiagnosticSeverity;
  message: string;
  code?: string;
  fingerprint?: string;
  context?: Record<string, unknown>;
  platform?: string;
  uid?: string | null;
  timestamp?: string;
}

export interface HealthItem {
  key: string;
  name: string;
  status: 'healthy' | 'degraded' | 'down' | 'unknown';
  summary: string;
  details?: string;
  updatedAt: string;
}

export interface SystemStatusOverview {
  generatedAt: string;
  systems: HealthItem[];
  counters: {
    errors24h: number;
    warnings24h: number;
    events24h: number;
  };
}
