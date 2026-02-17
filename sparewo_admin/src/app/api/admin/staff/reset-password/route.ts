
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

        // Get user email
        const user = await auth.getUser(staff_id);
        if (!user.email) {
            return NextResponse.json({ error: 'User does not have an email address.' }, { status: 400 });
        }

        // Generate password reset link
        const link = await auth.generatePasswordResetLink(user.email);

        // Construct custom link
        // Link format: https://<project>.firebaseapp.com/__/auth/action?mode=resetPassword&oobCode=<code>&apiKey=<key>...
        const urlObj = new URL(link);
        const oobCode = urlObj.searchParams.get('oobCode');

        if (!oobCode) {
            throw new Error('Failed to extract reset code');
        }

        // Determine origin
        const host = req.headers.get('host');
        const protocol = host?.includes('localhost') ? 'http' : 'https';
        const customLink = `${protocol}://${host}/action?mode=resetPassword&oobCode=${oobCode}`;

        return NextResponse.json({
            success: true,
            message: 'Password reset link generated.',
            link: customLink
        });

    } catch (error: any) {
        console.error('Reset password error:', error);
        return NextResponse.json({ error: error.message || 'Internal Server Error' }, { status: 500 });
    }
}
