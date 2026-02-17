
import { NextResponse } from 'next/server';
import { db, auth } from '@/lib/firebase/admin';
import { getResetPasswordEmailHtml, sendEmail } from '@/lib/mail';

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

        // Get user details
        const user = await auth.getUser(staff_id);
        if (!user.email) {
            return NextResponse.json({ error: 'User does not have an email address.' }, { status: 400 });
        }

        // Generate password reset link
        const link = await auth.generatePasswordResetLink(user.email);
        const urlObj = new URL(link);
        const oobCode = urlObj.searchParams.get('oobCode');

        if (!oobCode) {
            throw new Error('Failed to extract reset code');
        }

        // Construct custom link
        const host = req.headers.get('host');
        const protocol = host?.includes('localhost') ? 'http' : 'https';
        const customLink = `${protocol}://${host}/action?mode=resetPassword&oobCode=${oobCode}`;

        // Send Email
        let emailSent = false;
        try {
            await sendEmail({
                to: user.email,
                subject: 'Reset Your SpareWo Admin Password',
                html: getResetPasswordEmailHtml(user.displayName || user.email, customLink),
            });
            emailSent = true;
        } catch (mailError) {
            console.error('Failed to send reset email:', mailError);
        }

        return NextResponse.json({
            success: true,
            message: emailSent
                ? 'Password reset email sent.'
                : 'Reset link generated, but email failed to send. Share the link manually below.',
            link: customLink
        });

    } catch (error: any) {
        console.error('Reset password error:', error);
        return NextResponse.json({ error: error.message || 'Internal Server Error' }, { status: 500 });
    }
}
