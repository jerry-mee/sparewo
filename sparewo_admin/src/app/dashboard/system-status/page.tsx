'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import { AlertTriangle, CheckCircle2, RefreshCw, ServerCrash, Wrench } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { auth } from '@/lib/firebase/config';
import { logError } from '@/lib/diagnostics/logger';

type HealthStatus = 'healthy' | 'degraded' | 'down' | 'unknown';

interface HealthItem {
  key: string;
  name: string;
  status: HealthStatus;
  summary: string;
  updatedAt: string;
}

interface EventItem {
  id: string;
  source: string;
  service: string;
  severity: 'info' | 'warn' | 'error';
  message: string;
  code?: string | null;
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

export default function SystemStatusPage() {
  const [overview, setOverview] = useState<OverviewResponse | null>(null);
  const [events, setEvents] = useState<EventItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [probing, setProbing] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const token = await auth.currentUser?.getIdToken();
      if (!token) return;

      const [overviewRes, eventsRes] = await Promise.all([
        fetch('/api/system-status/overview', {
          headers: { Authorization: `Bearer ${token}` },
          cache: 'no-store',
        }),
        fetch('/api/system-status/events?limit=80', {
          headers: { Authorization: `Bearer ${token}` },
          cache: 'no-store',
        }),
      ]);

      if (!overviewRes.ok) {
        throw new Error('Failed to load overview');
      }
      if (!eventsRes.ok) {
        throw new Error('Failed to load events');
      }

      const overviewData = (await overviewRes.json()) as OverviewResponse;
      const eventsData = (await eventsRes.json()) as { events: EventItem[] };
      setOverview(overviewData);
      setEvents(eventsData.events || []);
    } catch (error) {
      await logError('system_status_page', 'Load failed', error);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const runProbe = async () => {
    setProbing(true);
    try {
      const token = await auth.currentUser?.getIdToken();
      if (!token) return;

      const res = await fetch('/api/system-status/probe', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ target: 'all' }),
      });

      if (!res.ok) {
        throw new Error('Probe execution failed');
      }

      await load();
    } catch (error) {
      await logError('system_status_page', 'Probe failed', error);
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
        <Card>
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

      <Card>
        <CardHeader>
          <CardTitle>Subsystem Health</CardTitle>
          <p className="text-xs text-muted-foreground">Generated: {toLocalTime(overview?.generatedAt)}</p>
        </CardHeader>
        <CardContent className="space-y-3">
          {(overview?.systems || []).map((item) => (
            <div key={item.key} className="flex flex-col gap-2 rounded-xl border p-3 md:flex-row md:items-center md:justify-between">
              <div>
                <p className="font-medium">{item.name}</p>
                <p className="text-sm text-muted-foreground">{item.summary}</p>
                <p className="text-xs text-muted-foreground">Updated: {toLocalTime(item.updatedAt)}</p>
              </div>
              <Badge variant={statusVariant(item.status)}>{item.status.toUpperCase()}</Badge>
            </div>
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
              <div key={event.id} className="rounded-lg border px-3 py-2">
                <div className="flex flex-wrap items-center gap-2">
                  <Badge variant={severityVariant(event.severity)}>{event.severity.toUpperCase()}</Badge>
                  <span className="text-sm font-medium">{event.service}</span>
                  <span className="text-xs text-muted-foreground">{event.source}</span>
                  <span className="text-xs text-muted-foreground">{toLocalTime(event.timestamp)}</span>
                </div>
                <p className="mt-1 text-sm">{event.message}</p>
                {event.code ? <p className="text-xs text-muted-foreground">Code: {event.code}</p> : null}
              </div>
            ))
          )}
        </CardContent>
      </Card>
    </div>
  );
}
