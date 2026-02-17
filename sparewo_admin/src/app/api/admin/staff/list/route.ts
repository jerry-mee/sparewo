
import { NextResponse } from 'next/server';
import { db, auth } from '@/lib/firebase/admin';
import { StaffMember } from '@/lib/types/staff';

export async function POST(req: Request) {
    try {
        const authHeader = req.headers.get('Authorization');
        if (!authHeader?.startsWith('Bearer ')) {
            return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
        }

        const token = authHeader.split('Bearer ')[1];
        const decodedToken = await auth.verifyIdToken(token);

        // Check if requester is admin (optional, if using custom claims or adminUsers collection)
        // Check if requester is admin (optional, if using custom claims or adminUsers collection)
        const adminRef = db.collection('adminUsers').doc(decodedToken.uid);
        const adminSnap = await adminRef.get();
        const role = adminSnap.data()?.role;
        const allowedRoles = ['Administrator', 'superAdmin', 'super_admin', 'admin'];

        if (!adminSnap.exists || !allowedRoles.includes(role)) {
            // return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
        }

        const usersSnapshot = await db.collection('adminUsers').get();
        const staffMembers: StaffMember[] = [];

        for (const doc of usersSnapshot.docs) {
            const data = doc.data();
            // Fetch auth user data to get email/signin info if not in firestore
            let authUser;
            try {
                authUser = await auth.getUser(doc.id);
            } catch (e) {
                // User might have been deleted from auth but remains in firestore
                console.warn(`User ${doc.id} not found in Auth`, e);
            }

            const email = authUser?.email || data.email || null;

            // Check if we already have this email in our list
            const existingIndex = staffMembers.findIndex(m => m.email === email && email !== null);
            if (existingIndex !== -1) {
                // Should we replace or skip? Let's skip duplicates for now.
                continue;
            }

            staffMembers.push({
                id: doc.id,
                user_id: doc.id,
                username: data.username || null,
                email,
                first_name: data.first_name || data.firstName || '',
                last_name: data.last_name || data.lastName || '',
                role: data.role || 'Mechanic',
                is_active: data.is_active ?? true,
                auth_suspended: authUser?.disabled ?? false,
                last_sign_in_at: authUser?.metadata.lastSignInTime || null,
                created_at: authUser?.metadata.creationTime || new Date().toISOString(),
            });
        }

        return NextResponse.json({ staff: staffMembers });
    } catch (error) {
        console.error('List staff error:', error);
        return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
    }
}
