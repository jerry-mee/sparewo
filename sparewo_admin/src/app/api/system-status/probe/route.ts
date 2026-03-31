import { NextResponse } from 'next/server';
import { auth, db } from '@/lib/firebase/admin';
import { normalizeRole } from '@/lib/auth/roles';

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

export async function POST(req: Request) {
  try {
    const token = readToken(req);
    if (!token) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    const decoded = await ensureOperator(token);

    const payload = (await req.json()) as { target?: string };
    const target = String(payload.target || 'all').toLowerCase();
    const now = new Date().toISOString();

    const result: Record<string, { ok: boolean; message: string }> = {};

    if (target === 'all' || target === 'auth') {
      try {
        await auth.getUser(decoded.uid);
        result.auth = { ok: true, message: 'Auth token verification succeeded.' };
      } catch (error) {
        result.auth = { ok: false, message: error instanceof Error ? error.message : 'Auth probe failed.' };
      }
    }

    if (target === 'all' || target === 'firestore') {
      try {
        const ref = db.collection('_system_probes').doc('latest');
        await ref.set({ updatedAt: now, updatedBy: decoded.uid }, { merge: true });
        const snap = await ref.get();
        result.firestore = {
          ok: snap.exists,
          message: snap.exists ? 'Firestore write/read probe succeeded.' : 'Probe document missing after write.',
        };
      } catch (error) {
        result.firestore = {
          ok: false,
          message: error instanceof Error ? error.message : 'Firestore probe failed.',
        };
      }
    }

    if (target === 'all' || target === 'storage') {
      try {
        const bucket = db.app.storage().bucket();
        await bucket.getMetadata();
        result.storage = { ok: true, message: 'Storage bucket metadata read succeeded.' };
      } catch (error) {
        result.storage = {
          ok: false,
          message: error instanceof Error ? error.message : 'Storage probe failed.',
        };
      }
    }

    if (target === 'all' || target === 'functions') {
      try {
        const notificationProbe = await db.collection('notifications').orderBy('createdAt', 'desc').limit(1).get();
        result.functions = {
          ok: true,
          message: `Notifications collection reachable (${notificationProbe.size} row sample).`,
        };
      } catch (error) {
        result.functions = {
          ok: false,
          message: error instanceof Error ? error.message : 'Functions path probe failed.',
        };
      }
    }

    await db.collection('system_diagnostics_events').add({
      source: 'admin',
      service: 'system_probe',
      severity: Object.values(result).some((item) => !item.ok) ? 'warn' : 'info',
      code: null,
      message: `Manual probe executed (${target})`,
      context: result,
      platform: 'web',
      uid: decoded.uid,
      timestamp: new Date(),
      isoTimestamp: now,
      createdAtMs: Date.now(),
    });

    return NextResponse.json({ generatedAt: now, result });
  } catch (error) {
    if (error instanceof Error && error.message === 'forbidden') {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
    }
    return NextResponse.json({ error: 'Failed to run probes' }, { status: 500 });
  }
}
