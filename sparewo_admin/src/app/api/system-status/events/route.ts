import { NextResponse } from 'next/server';
import { auth, db } from '@/lib/firebase/admin';
import { normalizeRole } from '@/lib/auth/roles';

const EVENTS_COLLECTION = 'system_diagnostics_events';

const readToken = (req: Request): string | null => {
  const authHeader = req.headers.get('Authorization') || req.headers.get('authorization');
  if (!authHeader?.startsWith('Bearer ')) return null;
  return authHeader.replace('Bearer ', '').trim();
};

const ensureOperator = async (token: string) => {
  const decoded = await auth.verifyIdToken(token);
  const adminSnap = await db.collection('adminUsers').doc(decoded.uid).get();
  const role = normalizeRole(adminSnap.data()?.role);
  if (!adminSnap.exists || !role) throw new Error('forbidden');
  return decoded;
};

const sanitizeContext = (value: unknown): unknown => {
  if (!value || typeof value !== 'object') return value;
  const clone = { ...(value as Record<string, unknown>) };
  const blocked = ['token', 'accessToken', 'idToken', 'password', 'secret', 'authorization'];
  for (const key of Object.keys(clone)) {
    if (blocked.some((needle) => key.toLowerCase().includes(needle.toLowerCase()))) {
      clone[key] = '[REDACTED]';
    }
  }
  return clone;
};

export async function GET(req: Request) {
  try {
    const token = readToken(req);
    if (!token) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    await ensureOperator(token);

    const url = new URL(req.url);
    const limit = Math.min(Number(url.searchParams.get('limit') || 50), 200);
    const severity = (url.searchParams.get('severity') || '').toLowerCase();
    const source = (url.searchParams.get('source') || '').toLowerCase();
    const service = (url.searchParams.get('service') || '').toLowerCase();

    let query = db.collection(EVENTS_COLLECTION).orderBy('timestamp', 'desc').limit(limit);
    if (severity) {
      query = db
        .collection(EVENTS_COLLECTION)
        .where('severity', '==', severity)
        .orderBy('timestamp', 'desc')
        .limit(limit);
    }
    if (service) {
      query = db
        .collection(EVENTS_COLLECTION)
        .where('service', '==', service)
        .orderBy('timestamp', 'desc')
        .limit(limit);
    }
    if (source) {
      query = db
        .collection(EVENTS_COLLECTION)
        .where('source', '==', source)
        .orderBy('timestamp', 'desc')
        .limit(limit);
    }

    const snapshot = await query.get();
    const events = snapshot.docs.map((doc) => {
      const data = doc.data();
      const ts = data.timestamp;
      return {
        id: doc.id,
        source: data.source || 'unknown',
        service: data.service || 'unknown',
        severity: data.severity || 'info',
        code: data.code || null,
        message: data.message || 'No message',
        context: sanitizeContext(data.context || {}),
        fingerprint: data.fingerprint || null,
        platform: data.platform || null,
        uid: data.uid || null,
        timestamp: typeof ts?.toDate === 'function' ? ts.toDate().toISOString() : data.isoTimestamp || null,
      };
    });

    return NextResponse.json({ events });
  } catch (error) {
    if (error instanceof Error && error.message === 'forbidden') {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
    }
    return NextResponse.json({ error: 'Failed to read diagnostics events' }, { status: 500 });
  }
}

export async function POST(req: Request) {
  try {
    const token = readToken(req);
    if (!token) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

    const decoded = await auth.verifyIdToken(token);
    const payload = (await req.json()) as Record<string, unknown>;

    const source = String(payload.source || 'admin').toLowerCase();
    const severity = String(payload.severity || 'info').toLowerCase();
    const service = String(payload.service || 'unspecified').slice(0, 120);
    const message = String(payload.message || 'No message').slice(0, 1000);
    const code = payload.code ? String(payload.code).slice(0, 120) : null;
    const fingerprint = String(
      payload.fingerprint || `${source}|${service}|${severity}|${code || ''}|${message}`
    ).slice(0, 240);

    const existing = await db
      .collection(EVENTS_COLLECTION)
      .where('fingerprint', '==', fingerprint)
      .where('uid', '==', decoded.uid)
      .orderBy('timestamp', 'desc')
      .limit(1)
      .get();

    if (!existing.empty) {
      const latestTs = existing.docs[0].data().timestamp;
      const latestMs = typeof latestTs?.toMillis === 'function' ? latestTs.toMillis() : 0;
      if (Date.now() - latestMs < 2500) {
        return NextResponse.json({ accepted: true, deduped: true });
      }
    }

    await db.collection(EVENTS_COLLECTION).add({
      source,
      service,
      severity,
      code,
      message,
      fingerprint,
      context: sanitizeContext((payload.context as Record<string, unknown>) || {}),
      platform: payload.platform ? String(payload.platform).slice(0, 64) : 'web',
      uid: decoded.uid,
      timestamp: new Date(),
      isoTimestamp: new Date().toISOString(),
      createdAtMs: Date.now(),
    });

    return NextResponse.json({ accepted: true });
  } catch {
    return NextResponse.json({ error: 'Failed to ingest diagnostics event' }, { status: 500 });
  }
}
