import { NextResponse } from 'next/server';
import { db, auth } from '@/lib/firebase/admin';
import { normalizeRole } from '@/lib/auth/roles';
import { enforceRateLimit, getRequestIp, RateLimitError } from '@/lib/security/rate-limit';
import { getAutoHubStatusEmailHtml, sendEmail } from '@/lib/mail';

type BookingStatus = 'pending' | 'confirmed' | 'in_progress' | 'completed' | 'cancelled';

interface UpdateAutoHubBody {
  bookingId?: string;
  status?: BookingStatus;
  notes?: string;
  providerId?: string;
  providerName?: string;
}

const ALLOWED_ROLES = new Set(['Administrator', 'Manager', 'Mechanic']);
const CUSTOMER_NOTIFIABLE_STATUSES: BookingStatus[] = [
  'confirmed',
  'in_progress',
  'completed',
  'cancelled',
];

export async function POST(req: Request) {
  try {
    const ip = getRequestIp(req);
    await enforceRateLimit({
      key: 'api:autohub_status:ip',
      identifier: ip,
      windowSeconds: 300,
      maxRequests: 50,
    });

    const authHeader = req.headers.get('Authorization');
    if (!authHeader?.startsWith('Bearer ')) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const token = authHeader.split('Bearer ')[1];
    const decodedToken = await auth.verifyIdToken(token);
    await enforceRateLimit({
      key: 'api:autohub_status:user',
      identifier: decodedToken.uid,
      windowSeconds: 300,
      maxRequests: 30,
    });
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

    if (CUSTOMER_NOTIFIABLE_STATUSES.includes(status)) {
      const userId = bookingData.userId as string | undefined;
      const userName = (bookingData.userName as string | undefined) || 'Customer';
      const bookingNumber = (bookingData.bookingNumber as string | undefined) || bookingId;
      const userEmail = bookingData.userEmail as string | undefined;
      const now = new Date();
      const statusLabel = status.replace('_', ' ');

      const titleByStatus: Record<typeof status, string> = {
        pending: 'AutoHub Request Pending',
        confirmed: 'AutoHub Request Confirmed',
        in_progress: 'AutoHub Service In Progress',
        completed: 'AutoHub Service Completed',
        cancelled: 'AutoHub Request Cancelled',
      };

      const messageByStatus: Record<typeof status, string> = {
        pending: `Your AutoHub request ${bookingNumber} is pending review.`,
        confirmed: `Your AutoHub request ${bookingNumber} has been confirmed. We will reach out shortly.`,
        in_progress: `Your AutoHub request ${bookingNumber} is now in progress.`,
        completed: `Your AutoHub request ${bookingNumber} has been completed.`,
        cancelled: `Your AutoHub request ${bookingNumber} was cancelled. Please contact support if needed.`,
      };

      if (userId) {
        await db.collection('notifications').add({
          userId,
          recipientId: userId,
          title: titleByStatus[status],
          message: messageByStatus[status],
          type: status === 'cancelled' ? 'warning' : 'success',
          entityType: 'booking',
          status,
          bookingId,
          bookingNumber,
          link: `/booking/${bookingId}`,
          read: false,
          isRead: false,
          statusLabel,
          createdAt: now,
          updatedAt: now,
        });
      }

      if (userEmail) {
        await sendEmail({
          to: userEmail,
          subject: `Your AutoHub Request is ${statusLabel}`,
          html: getAutoHubStatusEmailHtml(
            userName,
            bookingNumber,
            status as 'confirmed' | 'in_progress' | 'completed' | 'cancelled'
          ),
        });
      }
    }

    return NextResponse.json({ success: true });
  } catch (error: unknown) {
    if (error instanceof RateLimitError) {
      return NextResponse.json(
        { error: error.message },
        { status: 429, headers: { 'Retry-After': String(error.retryAfterSeconds) } }
      );
    }

    const message = error instanceof Error ? error.message : 'Internal Server Error';
    console.error('Update AutoHub status API error:', error);
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
