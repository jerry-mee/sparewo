'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import { AlertTriangle, CheckCircle2, ChevronRight, RefreshCw, ServerCrash, Wrench } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { auth } from '@/lib/firebase/config';
import { logError } from '@/lib/diagnostics/logger';

type HealthStatus = 'healthy' | 'degraded' | 'down' | 'unknown';

interface HealthItem {
  key: string;
  name: string;
  status: HealthStatus;
  summary: string;
  details?: string;
  updatedAt: string;
}

interface EventItem {
  id: string;
  source: string;
  service: string;
  severity: 'info' | 'warn' | 'error';
  message: string;
  code?: string | null;
  context?: Record<string, unknown>;
  fingerprint?: string | null;
  platform?: string | null;
  uid?: string | null;
  timestamp?: string | null;
}

interface OverviewResponse {
  generatedAt: string;
  systems: HealthItem[];
  counters: {
    errors24h: number;
    warnings24h: number;
    events24h: number;
  };
}

const statusVariant = (status: HealthStatus): 'default' | 'secondary' | 'destructive' | 'outline' => {
  if (status === 'healthy') return 'default';
  if (status === 'degraded') return 'secondary';
  if (status === 'down') return 'destructive';
  return 'outline';
};

const severityVariant = (severity: 'info' | 'warn' | 'error'): 'default' | 'secondary' | 'destructive' => {
  if (severity === 'error') return 'destructive';
  if (severity === 'warn') return 'secondary';
  return 'default';
};

const toLocalTime = (value?: string | null): string => {
  if (!value) return '—';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '—';
  return date.toLocaleString();
};

const SYSTEM_TRACE_HINTS: Record<string, string[]> = {
  firebase_auth: ['auth', 'google', 'apple', 'signin', 'token'],
  firestore: ['firestore', 'catalog', 'users', 'cars', 'permission-denied'],
  storage: ['storage', 'image', 'thumbnail', 'bucket', '_next/image'],
  functions_push: ['function', 'fanout', 'notification', 'push', 'fcm'],
  fcm_tokens: ['token', 'fcm', 'notifications'],
};

const SYSTEM_PROBE_TARGET: Record<string, 'all' | 'auth' | 'firestore' | 'storage' | 'functions'> = {
  firebase_auth: 'auth',
  firestore: 'firestore',
  storage: 'storage',
  functions_push: 'functions',
  fcm_tokens: 'all',
};

const matchesSystemTrace = (systemKey: string, event: EventItem): boolean => {
  const hints = SYSTEM_TRACE_HINTS[systemKey] || [];
  if (hints.length === 0) return true;
  const searchable = [
    event.service,
    event.source,
    event.message,
    event.code || '',
    event.fingerprint || '',
    JSON.stringify(event.context || {}),
  ]
    .join(' ')
    .toLowerCase();
  return hints.some((hint) => searchable.includes(hint));
};

export default function SystemStatusPage() {
  const [overview, setOverview] = useState<OverviewResponse | null>(null);
  const [events, setEvents] = useState<EventItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [probing, setProbing] = useState(false);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [selectedSystemKey, setSelectedSystemKey] = useState<string | null>(null);
  const [selectedEventId, setSelectedEventId] = useState<string | null>(null);
  const [probeMessage, setProbeMessage] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setLoadError(null);
    setProbeMessage(null);
    try {
      const token = await auth.currentUser?.getIdToken();
      if (!token) return;

      const [overviewRes, eventsRes] = await Promise.all([
        fetch('/api/system-status/overview', {
          headers: { Authorization: `Bearer ${token}` },
          cache: 'no-store',
        }),
        fetch('/api/system-status/events?limit=250', {
          headers: { Authorization: `Bearer ${token}` },
          cache: 'no-store',
        }),
      ]);

      if (!overviewRes.ok) {
        const payload = (await overviewRes.json().catch(() => ({}))) as { error?: string };
        throw new Error(payload.error || 'Failed to load overview');
      }
      if (!eventsRes.ok) {
        const payload = (await eventsRes.json().catch(() => ({}))) as { error?: string };
        throw new Error(payload.error || 'Failed to load events');
      }

      const overviewData = (await overviewRes.json()) as OverviewResponse;
      const eventsData = (await eventsRes.json()) as { events: EventItem[] };
      setOverview(overviewData);
      setEvents(eventsData.events || []);
    } catch (error) {
      await logError('system_status_page', 'Load failed', error);
      setLoadError(error instanceof Error ? error.message : 'Failed to load system status');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const runProbe = async () => {
    await runProbeForTarget('all');
  };

  const runProbeForTarget = async (target: 'all' | 'auth' | 'firestore' | 'storage' | 'functions') => {
    setProbing(true);
    setProbeMessage(null);
    try {
      const token = await auth.currentUser?.getIdToken();
      if (!token) return;

      const res = await fetch('/api/system-status/probe', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ target }),
      });

      if (!res.ok) {
        throw new Error('Probe execution failed');
      }

      const payload = (await res.json()) as { result?: Record<string, { ok: boolean; message: string }> };
      const failing = Object.entries(payload.result || {}).filter(([, item]) => !item.ok);
      if (failing.length > 0) {
        setProbeMessage(
          `Probe completed with ${failing.length} issue(s): ${failing
            .map(([key, item]) => `${key}: ${item.message}`)
            .join(' | ')}`
        );
      } else {
        setProbeMessage('Probe completed successfully.');
      }
      await load();
    } catch (error) {
      await logError('system_status_page', 'Probe failed', error);
      setProbeMessage(error instanceof Error ? error.message : 'Probe failed');
    } finally {
      setProbing(false);
    }
  };

  const counters = useMemo(
    () =>
      overview?.counters || {
        errors24h: 0,
        warnings24h: 0,
        events24h: 0,
      },
    [overview]
  );

  const selectedSystem = useMemo(
    () => (overview?.systems || []).find((item) => item.key === selectedSystemKey) || null,
    [overview, selectedSystemKey]
  );

  const selectedSystemEvents = useMemo(() => {
    if (!selectedSystem) return [];
    return events.filter((event) => matchesSystemTrace(selectedSystem.key, event)).slice(0, 100);
  }, [events, selectedSystem]);

  const selectedEvent = useMemo(
    () => events.find((event) => event.id === selectedEventId) || null,
    [events, selectedEventId]
  );

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-3xl font-display">System Status</h1>
          <p className="text-sm text-muted-foreground">Realtime diagnostics for Firebase, Storage, Firestore, push delivery and app health.</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => void load()} disabled={loading}>
            <RefreshCw className={`mr-2 h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
            Refresh
          </Button>
          <Button onClick={() => void runProbe()} disabled={probing}>
            <Wrench className={`mr-2 h-4 w-4 ${probing ? 'animate-spin' : ''}`} />
            Run Probe
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
        <Card className="cursor-pointer transition hover:border-primary/50" onClick={() => setSelectedEventId(events[0]?.id || null)}>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm flex items-center gap-2"><ServerCrash className="h-4 w-4" /> Events (24h)</CardTitle>
          </CardHeader>
          <CardContent className="text-2xl font-semibold">{counters.events24h}</CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm flex items-center gap-2"><AlertTriangle className="h-4 w-4" /> Warnings (24h)</CardTitle>
          </CardHeader>
          <CardContent className="text-2xl font-semibold">{counters.warnings24h}</CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm flex items-center gap-2"><CheckCircle2 className="h-4 w-4" /> Errors (24h)</CardTitle>
          </CardHeader>
          <CardContent className="text-2xl font-semibold">{counters.errors24h}</CardContent>
        </Card>
      </div>
      {probeMessage ? <p className="text-xs text-muted-foreground">{probeMessage}</p> : null}
      {loadError ? <p className="text-xs text-destructive">{loadError}</p> : null}

      <Card>
        <CardHeader>
          <CardTitle>Subsystem Health</CardTitle>
          <p className="text-xs text-muted-foreground">Generated: {toLocalTime(overview?.generatedAt)}</p>
        </CardHeader>
        <CardContent className="space-y-3">
          {(overview?.systems || []).map((item) => (
            <button
              key={item.key}
              type="button"
              onClick={() => setSelectedSystemKey(item.key)}
              className="flex w-full flex-col gap-2 rounded-xl border p-3 text-left transition hover:border-primary/60 md:flex-row md:items-center md:justify-between"
            >
              <div>
                <p className="font-medium">{item.name}</p>
                <p className="text-sm text-muted-foreground">{item.summary}</p>
                <p className="text-xs text-muted-foreground">Updated: {toLocalTime(item.updatedAt)}</p>
              </div>
              <div className="flex items-center gap-2">
                <Badge variant={statusVariant(item.status)}>{item.status.toUpperCase()}</Badge>
                <ChevronRight className="h-4 w-4 text-muted-foreground" />
              </div>
            </button>
          ))}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Diagnostics Timeline</CardTitle>
        </CardHeader>
        <CardContent className="space-y-2">
          {events.length === 0 ? (
            <p className="text-sm text-muted-foreground">No diagnostics events yet.</p>
          ) : (
            events.map((event) => (
              <button
                key={event.id}
                type="button"
                onClick={() => setSelectedEventId(event.id)}
                className="w-full rounded-lg border px-3 py-2 text-left transition hover:border-primary/60"
              >
                <div className="flex flex-wrap items-center gap-2">
                  <Badge variant={severityVariant(event.severity)}>{event.severity.toUpperCase()}</Badge>
                  <span className="text-sm font-medium">{event.service}</span>
                  <span className="text-xs text-muted-foreground">{event.source}</span>
                  <span className="text-xs text-muted-foreground">{toLocalTime(event.timestamp)}</span>
                </div>
                <p className="mt-1 text-sm">{event.message}</p>
                {event.code ? <p className="text-xs text-muted-foreground">Code: {event.code}</p> : null}
              </button>
            ))
          )}
        </CardContent>
      </Card>

      <Dialog open={Boolean(selectedSystem)} onOpenChange={(open) => !open && setSelectedSystemKey(null)}>
        <DialogContent className="max-w-4xl">
          <DialogHeader>
            <DialogTitle>{selectedSystem?.name ?? 'Subsystem Trace'}</DialogTitle>
            <DialogDescription>
              Exact diagnostics traces and recent events for this subsystem.
            </DialogDescription>
          </DialogHeader>
          {selectedSystem ? (
            <div className="space-y-4">
              <div className="rounded-xl border p-3">
                <div className="flex items-center justify-between gap-2">
                  <p className="font-medium">Current Health</p>
                  <Badge variant={statusVariant(selectedSystem.status)}>{selectedSystem.status.toUpperCase()}</Badge>
                </div>
                <p className="text-sm text-muted-foreground mt-1">{selectedSystem.summary}</p>
                {selectedSystem.details ? (
                  <pre className="mt-2 max-h-40 overflow-auto rounded-md bg-muted/40 p-2 text-xs whitespace-pre-wrap">
                    {selectedSystem.details}
                  </pre>
                ) : null}
                <div className="mt-3 flex flex-wrap gap-2">
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() =>
                      void runProbeForTarget(
                        SYSTEM_PROBE_TARGET[selectedSystem.key] || 'all'
                      )
                    }
                    disabled={probing}
                  >
                    <Wrench className={`mr-2 h-4 w-4 ${probing ? 'animate-spin' : ''}`} />
                    Run Targeted Probe
                  </Button>
                  <Button variant="outline" size="sm" onClick={() => void load()} disabled={loading}>
                    <RefreshCw className={`mr-2 h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
                    Refresh Traces
                  </Button>
                </div>
              </div>
              <div className="space-y-2">
                {selectedSystemEvents.length === 0 ? (
                  <p className="text-sm text-muted-foreground">No trace events mapped to this subsystem yet.</p>
                ) : (
                  selectedSystemEvents.map((event) => (
                    <button
                      key={event.id}
                      type="button"
                      onClick={() => setSelectedEventId(event.id)}
                      className="w-full rounded-lg border px-3 py-2 text-left transition hover:border-primary/60"
                    >
                      <div className="flex flex-wrap items-center gap-2">
                        <Badge variant={severityVariant(event.severity)}>{event.severity.toUpperCase()}</Badge>
                        <span className="text-sm font-medium">{event.service}</span>
                        <span className="text-xs text-muted-foreground">{toLocalTime(event.timestamp)}</span>
                      </div>
                      <p className="mt-1 text-sm">{event.message}</p>
                      {event.code ? <p className="text-xs text-muted-foreground">Code: {event.code}</p> : null}
                    </button>
                  ))
                )}
              </div>
            </div>
          ) : null}
        </DialogContent>
      </Dialog>

      <Dialog open={Boolean(selectedEvent)} onOpenChange={(open) => !open && setSelectedEventId(null)}>
        <DialogContent className="max-w-4xl">
          <DialogHeader>
            <DialogTitle>Trace Detail</DialogTitle>
            <DialogDescription>Full event diagnostics payload.</DialogDescription>
          </DialogHeader>
          {selectedEvent ? (
            <div className="space-y-3">
              <div className="flex flex-wrap items-center gap-2">
                <Badge variant={severityVariant(selectedEvent.severity)}>{selectedEvent.severity.toUpperCase()}</Badge>
                <span className="text-sm font-medium">{selectedEvent.service}</span>
                <span className="text-xs text-muted-foreground">{selectedEvent.source}</span>
                <span className="text-xs text-muted-foreground">{toLocalTime(selectedEvent.timestamp)}</span>
              </div>
              <p className="text-sm">{selectedEvent.message}</p>
              <div className="grid grid-cols-1 gap-2 text-xs text-muted-foreground md:grid-cols-2">
                <p>Code: {selectedEvent.code || '—'}</p>
                <p>Platform: {selectedEvent.platform || '—'}</p>
                <p>UID: {selectedEvent.uid || '—'}</p>
                <p>Fingerprint: {selectedEvent.fingerprint || '—'}</p>
              </div>
              <div>
                <p className="mb-1 text-xs font-medium text-muted-foreground">Raw Context / Stack Trace</p>
                <pre className="max-h-[45vh] overflow-auto rounded-md bg-muted/40 p-3 text-xs">
                  {JSON.stringify(selectedEvent.context || {}, null, 2)}
                </pre>
              </div>
            </div>
          ) : null}
        </DialogContent>
      </Dialog>
    </div>
  );
}
