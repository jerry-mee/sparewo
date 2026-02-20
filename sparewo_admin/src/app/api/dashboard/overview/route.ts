import { NextResponse } from 'next/server';
import { auth, db } from '@/lib/firebase/admin';
import { normalizeRole } from '@/lib/auth/roles';
import { enforceRateLimit, getRequestIp, RateLimitError } from '@/lib/security/rate-limit';

const countByStatus = async (collectionName: string, status: string): Promise<number> => {
  const snapshot = await db.collection(collectionName).where('status', '==', status).get();
  return snapshot.size;
};

export async function POST(req: Request) {
  try {
    const ip = getRequestIp(req);
    await enforceRateLimit({
      key: 'api:dashboard_overview:ip',
      identifier: ip,
      windowSeconds: 60,
      maxRequests: 120,
    });

    const authHeader = req.headers.get('Authorization');
    if (!authHeader?.startsWith('Bearer ')) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const token = authHeader.split('Bearer ')[1];
    const decodedToken = await auth.verifyIdToken(token);
    await enforceRateLimit({
      key: 'api:dashboard_overview:user',
      identifier: decodedToken.uid,
      windowSeconds: 60,
      maxRequests: 90,
    });

    const adminSnap = await db.collection('adminUsers').doc(decodedToken.uid).get();
    const role = normalizeRole(adminSnap.data()?.role);
    if (!adminSnap.exists || !role) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
    }

    const includeClientsAndVendors = role === 'Administrator' || role === 'Manager';

    const [
      productsSnap,
      pendingProducts,
      activeBookings,
      usersSnap,
      vendorsSnap,
      pendingVendors,
      ordersSnap,
      latestOrdersSnap,
    ] = await Promise.all([
      db.collection('vendor_products').get(),
      countByStatus('vendor_products', 'pending'),
      countByStatus('service_bookings', 'pending'),
      includeClientsAndVendors ? db.collection('users').get() : Promise.resolve(null),
      includeClientsAndVendors ? db.collection('vendors').get() : Promise.resolve(null),
      includeClientsAndVendors ? countByStatus('vendors', 'pending') : Promise.resolve(0),
      db.collection('orders').get(),
      db.collection('orders').orderBy('createdAt', 'desc').limit(6).get(),
    ]);

    const orderStats = {
      pending: 0,
      processing: 0,
      shipped: 0,
      delivered: 0,
      completed: 0,
      cancelled: 0,
    };

    ordersSnap.docs.forEach((doc) => {
      const status = String(doc.data()?.status || '').toLowerCase();
      if (status in orderStats) {
        orderStats[status as keyof typeof orderStats] += 1;
      }
    });

    const latestOrders = latestOrdersSnap.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        orderNumber: data.orderNumber || doc.id,
        customerName: data.userName || data.customerName || 'Guest User',
        totalAmount: data.totalAmount || 0,
        status: data.status || 'pending',
        createdAt: data.createdAt || null,
      };
    });

    return NextResponse.json({
      stats: {
        vendors: vendorsSnap?.size ?? 0,
        products: productsSnap.size,
        clients: usersSnap?.size ?? 0,
        activeBookings,
        pendingOrders: orderStats.pending,
        pendingVendors,
        pendingProducts,
      },
      latestOrders,
      role,
    });
  } catch (error: unknown) {
    if (error instanceof RateLimitError) {
      return NextResponse.json(
        { error: error.message },
        { status: 429, headers: { 'Retry-After': String(error.retryAfterSeconds) } }
      );
    }

    console.error('Dashboard overview API error:', error);
    const message = error instanceof Error ? error.message : 'Internal Server Error';
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
