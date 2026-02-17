import { NextResponse } from 'next/server';
import { db, auth } from '@/lib/firebase/admin';
import { normalizeRole } from '@/lib/auth/roles';
import { getAutoHubApprovedEmailHtml, sendEmail } from '@/lib/mail';

type BookingStatus = 'pending' | 'confirmed' | 'in_progress' | 'completed' | 'cancelled';

interface UpdateAutoHubBody {
  bookingId?: string;
  status?: BookingStatus;
  notes?: string;
  providerId?: string;
  providerName?: string;
}

const ALLOWED_ROLES = new Set(['Administrator', 'Manager', 'Mechanic']);

export async function POST(req: Request) {
  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader?.startsWith('Bearer ')) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const token = authHeader.split('Bearer ')[1];
    const decodedToken = await auth.verifyIdToken(token);
    const adminRef = db.collection('adminUsers').doc(decodedToken.uid);
    const adminSnap = await adminRef.get();
    const callerRole = normalizeRole(adminSnap.data()?.role);

    if (!adminSnap.exists || !callerRole || !ALLOWED_ROLES.has(callerRole)) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
    }

    const body = (await req.json()) as UpdateAutoHubBody;
    const bookingId = body.bookingId?.trim();
    const status = body.status;

    if (!bookingId || !status) {
      return NextResponse.json({ error: 'Booking ID and status are required' }, { status: 400 });
    }

    const bookingRef = db.collection('service_bookings').doc(bookingId);
    const bookingSnap = await bookingRef.get();

    if (!bookingSnap.exists) {
      return NextResponse.json({ error: 'Booking not found' }, { status: 404 });
    }

    const bookingData = bookingSnap.data() || {};
    const updatePayload: Record<string, unknown> = {
      status,
      updatedAt: new Date(),
    };

    if (typeof body.notes === 'string') {
      updatePayload.adminNotes = body.notes;
    }

    if (body.providerId && body.providerName) {
      updatePayload.assignedProviderId = body.providerId;
      updatePayload.assignedProviderName = body.providerName;
    }

    await bookingRef.update(updatePayload);

    if (status === 'confirmed') {
      const userId = bookingData.userId as string | undefined;
      const userName = (bookingData.userName as string | undefined) || 'Customer';
      const bookingNumber = (bookingData.bookingNumber as string | undefined) || bookingId;
      const userEmail = bookingData.userEmail as string | undefined;
      const now = new Date();

      if (userId) {
        await db.collection('notifications').add({
          userId,
          recipientId: userId,
          title: 'AutoHub Request Approved',
          message: 'Your AutoHub request has been approved. We shall reach out shortly with the next steps.',
          type: 'success',
          link: '/orders',
          read: false,
          createdAt: now,
          updatedAt: now,
        });
      }

      if (userEmail) {
        await sendEmail({
          to: userEmail,
          subject: 'Your AutoHub Request Has Been Approved',
          html: getAutoHubApprovedEmailHtml(userName, bookingNumber),
        });
      }
    }

    return NextResponse.json({ success: true });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Internal Server Error';
    console.error('Update AutoHub status API error:', error);
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
