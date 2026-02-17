
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

        const { staff_id, first_name, last_name, username, role, is_active, suspend_auth_access } = await req.json();

        if (!staff_id) {
            return NextResponse.json({ error: 'Missing staff ID' }, { status: 400 });
        }

        const updates: any = {};
        if (first_name) updates.first_name = first_name;
        if (last_name) updates.last_name = last_name;
        if (username) updates.username = username;
        if (role) updates.role = role;
        if (typeof is_active === 'boolean') updates.is_active = is_active;
        if (typeof suspend_auth_access === 'boolean') updates.suspend_auth_access = suspend_auth_access;

        await db.collection('adminUsers').doc(staff_id).update(updates);

        if (updates.suspend_auth_access !== undefined) {
            // Toggle Auth active state
            await auth.updateUser(staff_id, {
                disabled: updates.suspend_auth_access
            });
        }

        // Capture audit log? If I have time.
        // For now, let's just make it work.

        return NextResponse.json({ success: true, message: 'Updated successfully' });

    } catch (error: any) {
        console.error('Update staff error:', error);
        return NextResponse.json({ error: error.message || 'Internal Server Error' }, { status: 500 });
    }
}
