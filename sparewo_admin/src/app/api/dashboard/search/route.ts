import { NextResponse } from 'next/server';
import { auth, db } from '@/lib/firebase/admin';
import { normalizeRole } from '@/lib/auth/roles';

type SearchType = 'order' | 'client' | 'vendor' | 'product';

interface SearchResult {
  id: string;
  type: SearchType;
  title: string;
  subtitle: string;
  href: string;
  createdAtMs: number;
}

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

const normalizeText = (value: unknown): string => String(value || '').trim();

const docCreatedAtMs = (docData: Record<string, unknown>): number => {
  const rawMs = Number(docData.createdAtMs || 0);
  if (Number.isFinite(rawMs) && rawMs > 0) return rawMs;
  const ts = docData.createdAt as { toMillis?: () => number } | undefined;
  if (ts && typeof ts.toMillis === 'function') {
    const millis = ts.toMillis();
    if (Number.isFinite(millis) && millis > 0) return millis;
  }
  return 0;
};

const includesNeedle = (value: string, needle: string): boolean =>
  value.toLowerCase().includes(needle);

export async function GET(req: Request) {
  try {
    const token = readToken(req);
    if (!token) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    await ensureOperator(token);

    const url = new URL(req.url);
    const q = (url.searchParams.get('q') || '').trim().toLowerCase();
    if (q.length < 2) {
      return NextResponse.json({ results: [] as SearchResult[] });
    }

    const [ordersSnap, usersSnap, vendorsSnap, productsSnap] = await Promise.all([
      db.collection('orders').orderBy('createdAt', 'desc').limit(80).get(),
      db.collection('users').orderBy('createdAt', 'desc').limit(80).get(),
      db.collection('vendors').orderBy('createdAt', 'desc').limit(80).get(),
      db.collection('vendor_products').orderBy('createdAt', 'desc').limit(80).get(),
    ]);

    const results: SearchResult[] = [];

    for (const doc of ordersSnap.docs) {
      const data = doc.data() as Record<string, unknown>;
      const orderNumber = normalizeText(data.orderNumber || doc.id);
      const customerName = normalizeText(data.customerName || data.userName || data.customerId || data.userId);
      if (
        !includesNeedle(orderNumber, q) &&
        !includesNeedle(customerName, q) &&
        !includesNeedle(doc.id, q)
      ) {
        continue;
      }
      results.push({
        id: doc.id,
        type: 'order',
        title: `Order ${orderNumber}`,
        subtitle: customerName ? `Customer: ${customerName}` : 'Order record',
        href: `/dashboard/orders/${doc.id}`,
        createdAtMs: docCreatedAtMs(data),
      });
    }

    for (const doc of usersSnap.docs) {
      const data = doc.data() as Record<string, unknown>;
      const name = normalizeText(data.name || 'Unknown User');
      const email = normalizeText(data.email);
      if (!includesNeedle(name, q) && !includesNeedle(email, q) && !includesNeedle(doc.id, q)) {
        continue;
      }
      results.push({
        id: doc.id,
        type: 'client',
        title: name,
        subtitle: email || 'Client profile',
        href: `/dashboard/clients/${doc.id}`,
        createdAtMs: docCreatedAtMs(data),
      });
    }

    for (const doc of vendorsSnap.docs) {
      const data = doc.data() as Record<string, unknown>;
      const name = normalizeText(data.name || data.businessName || 'Vendor');
      const email = normalizeText(data.email);
      const business = normalizeText(data.businessName);
      if (
        !includesNeedle(name, q) &&
        !includesNeedle(email, q) &&
        !includesNeedle(business, q) &&
        !includesNeedle(doc.id, q)
      ) {
        continue;
      }
      results.push({
        id: doc.id,
        type: 'vendor',
        title: business || name,
        subtitle: email || name,
        href: `/dashboard/vendors/${doc.id}`,
        createdAtMs: docCreatedAtMs(data),
      });
    }

    for (const doc of productsSnap.docs) {
      const data = doc.data() as Record<string, unknown>;
      const productName = normalizeText(data.name || data.partName || 'Product');
      const brand = normalizeText(data.brand);
      const category = normalizeText(data.category);
      if (
        !includesNeedle(productName, q) &&
        !includesNeedle(brand, q) &&
        !includesNeedle(category, q) &&
        !includesNeedle(doc.id, q)
      ) {
        continue;
      }
      results.push({
        id: doc.id,
        type: 'product',
        title: productName,
        subtitle: [brand, category].filter(Boolean).join(' • ') || 'Product record',
        href: `/dashboard/products/${doc.id}`,
        createdAtMs: docCreatedAtMs(data),
      });
    }

    const ordered = results
      .sort((a, b) => b.createdAtMs - a.createdAtMs)
      .slice(0, 20);

    return NextResponse.json({ results: ordered });
  } catch (error) {
    if (error instanceof Error && error.message === 'forbidden') {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
    }
    console.error('Dashboard search API failed', error);
    return NextResponse.json({ error: 'Search failed' }, { status: 500 });
  }
}

