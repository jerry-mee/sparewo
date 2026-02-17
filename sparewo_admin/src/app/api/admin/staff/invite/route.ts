
import { NextResponse } from 'next/server';
import { db, auth } from '@/lib/firebase/admin';
import * as crypto from 'crypto';

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

        const { email, first_name, last_name, role, username } = await req.json();

        if (!email || !first_name || !last_name || !role) {
            return NextResponse.json({ error: 'Missing required fields' }, { status: 400 });
        }

        // specific role validation
        const validRoles = ['Administrator', 'Manager', 'Mechanic'];
        if (!validRoles.includes(role)) {
            return NextResponse.json({ error: 'Invalid role' }, { status: 400 });
        }

        // create user in Auth
        const password = crypto.randomBytes(8).toString('hex');
        const user = await auth.createUser({
            email,
            password,
            displayName: `${first_name} ${last_name}`,
            emailVerified: true, // or false if email verification flow exists
        });

        // create user record in Firestore
        await db.collection('adminUsers').doc(user.uid).set({
            email,
            first_name,
            last_name,
            username: username || email.split('@')[0],
            role,
            is_active: true,
            created_at: new Date().toISOString(),
        });

        // Generate password reset link
        const link = await auth.generatePasswordResetLink(email);
        const urlObj = new URL(link);
        const oobCode = urlObj.searchParams.get('oobCode');

        // Construct custom link
        const host = req.headers.get('host');
        const protocol = host?.includes('localhost') ? 'http' : 'https';
        const inviteLink = `${protocol}://${host}/action?mode=resetPassword&oobCode=${oobCode}`;

        return NextResponse.json({
            success: true,
            message: 'User invited. Share the link below to set password.',
            inviteLink
        });

    } catch (error: any) {
        console.error('Invite staff error:', error);
        return NextResponse.json({ error: error.message || 'Internal Server Error' }, { status: 500 });
    }
}
