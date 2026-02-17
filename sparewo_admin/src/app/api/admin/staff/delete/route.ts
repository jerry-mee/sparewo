
import { NextResponse } from 'next/server';
import { db, auth } from '@/lib/firebase/admin';

export async function POST(req: Request) {
    try {
        const authHeader = req.headers.get('Authorization');
        if (!authHeader?.startsWith('Bearer ')) {
            return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
        }

        const token = authHeader.split('Bearer ')[1];
        const decodedToken = await auth.verifyIdToken(token);

        // Verify admin role
        // Verify admin role
        const adminRef = db.collection('adminUsers').doc(decodedToken.uid);
        const adminSnap = await adminRef.get();
        const callerRole = adminSnap.data()?.role;
        const allowedCallerRoles = ['Administrator', 'superAdmin', 'super_admin', 'admin'];

        if (!adminSnap.exists || !allowedCallerRoles.includes(callerRole)) {
            return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
        }

        const { staff_id } = await req.json();

        if (!staff_id) {
            return NextResponse.json({ error: 'Missing staff ID' }, { status: 400 });
        }

        // Delete from Firestore
        await db.collection('adminUsers').doc(staff_id).delete();

        // Delete from Auth
        await auth.deleteUser(staff_id);

        return NextResponse.json({ success: true, message: 'Deleted successfully' });

    } catch (error: any) {
        console.error('Delete staff error:', error);
        return NextResponse.json({ error: error.message || 'Internal Server Error' }, { status: 500 });
    }
}
