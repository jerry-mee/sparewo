
import { NextResponse } from 'next/server';
import { db, auth } from '@/lib/firebase/admin';
import { isAdministratorRole } from '@/lib/auth/roles';

export async function POST(req: Request) {
    try {
        const authHeader = req.headers.get('Authorization');
        if (!authHeader?.startsWith('Bearer ')) {
            return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
        }

        const token = authHeader.split('Bearer ')[1];
        const decodedToken = await auth.verifyIdToken(token);

        // Verify admin role
        const adminRef = db.collection('adminUsers').doc(decodedToken.uid);
        const adminSnap = await adminRef.get();
        const callerRole = adminSnap.data()?.role;
        if (!adminSnap.exists || !isAdministratorRole(callerRole)) {
            return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
        }

        const { staff_id } = await req.json();

        if (!staff_id) {
            return NextResponse.json({ error: 'Missing staff ID' }, { status: 400 });
        }

        // Delete from Firestore
        await db.collection('adminUsers').doc(staff_id).delete();
        await db.collection('user_roles').doc(staff_id).delete();

        // Delete from Auth (ignore if already deleted/missing)
        try {
            await auth.deleteUser(staff_id);
        } catch (e: unknown) {
            const code = typeof e === 'object' && e !== null && 'code' in e ? String((e as { code?: string }).code) : '';
            if (code !== 'auth/user-not-found') {
                const message = e instanceof Error ? e.message : 'Unknown error';
                console.error(`Error deleting Auth user ${staff_id}:`, message);
            }
        }

        return NextResponse.json({ success: true, message: 'Deleted successfully' });

    } catch (error: unknown) {
        console.error('Delete staff error:', error);
        const message = error instanceof Error ? error.message : 'Internal Server Error';
        return NextResponse.json({ error: message }, { status: 500 });
    }
}
