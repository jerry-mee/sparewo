
import { NextResponse } from 'next/server';
import { db, auth } from '@/lib/firebase/admin';
import { isAdministratorRole, normalizeRole } from '@/lib/auth/roles';

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

        const { staff_id, first_name, last_name, username, role, is_active, suspend_auth_access, password } = await req.json();

        if (!staff_id) {
            return NextResponse.json({ error: 'Missing staff ID' }, { status: 400 });
        }

        const updates: Record<string, unknown> = {};
        if (first_name) updates.first_name = first_name;
        if (last_name) updates.last_name = last_name;
        if (username) updates.username = username;
        if (role) {
            const normalizedRole = normalizeRole(role);
            if (!normalizedRole) {
                return NextResponse.json({ error: 'Invalid role' }, { status: 400 });
            }
            updates.role = normalizedRole;
        }
        if (typeof is_active === 'boolean') {
            updates.is_active = is_active;
            if (is_active) updates.pending_activation = false;
        }
        if (typeof suspend_auth_access === 'boolean') updates.suspend_auth_access = suspend_auth_access;

        if (Object.keys(updates).length > 0) {
            await db.collection('adminUsers').doc(staff_id).update(updates);
        }

        // Handle Auth updates
        const authUpdates: Record<string, unknown> = {};
        if (updates.suspend_auth_access !== undefined) {
            authUpdates.disabled = updates.suspend_auth_access;
        }
        if (password) {
            authUpdates.password = password;
        }

        if (Object.keys(authUpdates).length > 0) {
            await auth.updateUser(staff_id, authUpdates);
        }

        if (updates.role) {
            await db.collection('user_roles').doc(staff_id).set({
                isAdmin: true,
                role: String(updates.role).toLowerCase(),
                dashboard_role: updates.role,
                updatedAt: new Date().toISOString(),
            }, { merge: true });
        }

        // Capture audit log? If I have time.
        // For now, let's just make it work.

        return NextResponse.json({ success: true, message: 'Updated successfully' });

    } catch (error: unknown) {
        console.error('Update staff error:', error);
        const message = error instanceof Error ? error.message : 'Internal Server Error';
        return NextResponse.json({ error: message }, { status: 500 });
    }
}
