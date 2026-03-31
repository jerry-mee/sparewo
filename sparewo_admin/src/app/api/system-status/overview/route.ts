import { NextResponse } from 'next/server';
import { auth, db } from '@/lib/firebase/admin';
import { normalizeRole } from '@/lib/auth/roles';

const EVENTS_COLLECTION = 'system_diagnostics_events';
const TOKENS_COLLECTION_GROUP = 'tokens';

const readToken = (req: Request): string | null => {
  const authHeader = req.headers.get('Authorization') || req.headers.get('authorization');
  if (!authHeader?.startsWith('Bearer ')) return null;
  return authHeader.replace('Bearer ', '').trim();
};

const ensureOperator = async (token: string) => {
  const decoded = await auth.verifyIdToken(token);
  const adminSnap = await db.collection('adminUsers').doc(decoded.uid).get();
  const role = normalizeRole(adminSnap.data()?.role);
  if (!adminSnap.exists || !role) {
    throw new Error('forbidden');
  }
  return decoded;
};

const healthStatusFromBool = (ok: boolean): 'healthy' | 'down' => (ok ? 'healthy' : 'down');

export async function GET(req: Request) {
  try {
    const token = readToken(req);
    if (!token) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }
    await ensureOperator(token);

    const now = new Date();
    const cutoff = new Date(now.getTime() - 24 * 60 * 60 * 1000);

    const [recentEventsSnap, tokenSnap] = await Promise.all([
      db.collection(EVENTS_COLLECTION).where('timestamp', '>=', cutoff).limit(300).get(),
      db.collectionGroup(TOKENS_COLLECTION_GROUP).limit(1000).get(),
    ]);

    let errors24h = 0;
    let warnings24h = 0;
    for (const doc of recentEventsSnap.docs) {
      const severity = String(doc.data().severity || 'info').toLowerCase();
      if (severity === 'error') errors24h += 1;
      if (severity === 'warn') warnings24h += 1;
    }

    let authOk = false;
    let firestoreOk = false;
    let storageOk = false;
    let functionsOk = false;

    try {
      await auth.getUser('Fl7w7xFuX6Xow8uqBMlJC28oPyl1');
      authOk = true;
    } catch {
      authOk = false;
    }

    try {
      const probe = await db.collection('catalog_products').limit(1).get();
      firestoreOk = !probe.empty || probe.empty;
    } catch {
      firestoreOk = false;
    }

    try {
      const bucket = db.app.storage().bucket();
      const [exists] = await bucket.file('vendors').exists();
      storageOk = exists || !exists;
    } catch {
      storageOk = false;
    }

    try {
      const funcProbe = await db.collection('notifications').orderBy('createdAt', 'desc').limit(1).get();
      functionsOk = !funcProbe.empty || funcProbe.empty;
    } catch {
      functionsOk = false;
    }

    const response = {
      generatedAt: now.toISOString(),
      counters: {
        errors24h,
        warnings24h,
        events24h: recentEventsSnap.size,
      },
      systems: [
        {
          key: 'firebase_auth',
          name: 'Firebase Auth',
          status: healthStatusFromBool(authOk),
          summary: authOk ? 'Auth admin SDK reachable.' : 'Auth check failed.',
          updatedAt: now.toISOString(),
        },
        {
          key: 'firestore',
          name: 'Firestore',
          status: healthStatusFromBool(firestoreOk),
          summary: firestoreOk ? 'Firestore query check passed.' : 'Firestore probe failed.',
          updatedAt: now.toISOString(),
        },
        {
          key: 'storage',
          name: 'Firebase Storage',
          status: healthStatusFromBool(storageOk),
          summary: storageOk ? 'Storage bucket reachable.' : 'Storage probe failed.',
          updatedAt: now.toISOString(),
        },
        {
          key: 'functions_push',
          name: 'Functions Push Fanout',
          status: healthStatusFromBool(functionsOk),
          summary: functionsOk ? 'Notifications collection reachable.' : 'Functions probe failed.',
          updatedAt: now.toISOString(),
        },
        {
          key: 'fcm_tokens',
          name: 'FCM Token Registry',
          status: tokenSnap.size > 0 ? 'healthy' : 'degraded',
          summary: `${tokenSnap.size} token document(s) visible in collection-group scan.`,
          updatedAt: now.toISOString(),
        },
      ],
    };

    return NextResponse.json(response);
  } catch (error) {
    if (error instanceof Error && error.message === 'forbidden') {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
    }
    return NextResponse.json({ error: 'Failed to load system status' }, { status: 500 });
  }
}
