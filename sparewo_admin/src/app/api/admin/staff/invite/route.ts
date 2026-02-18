
import { NextResponse } from 'next/server';
import { db, auth } from '@/lib/firebase/admin';
import * as crypto from 'crypto';
import { getInviteEmailHtml, sendEmail } from '@/lib/mail';
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

        const { email, first_name, last_name, role, username } = await req.json();

        if (!email || !first_name || !last_name || !role) {
            return NextResponse.json({ error: 'Missing required fields' }, { status: 400 });
        }

        // Check if user already exists in Auth
        try {
            await auth.getUserByEmail(email);
            return NextResponse.json({ error: 'User with this email already exists.' }, { status: 400 });
        } catch {
            // User doesn't exist, proceed
        }

        // specific role validation
        const normalizedInviteRole = normalizeRole(role);
        if (!normalizedInviteRole) {
            return NextResponse.json({ error: 'Invalid role' }, { status: 400 });
        }

        // create user in Auth
        const initialPassword = crypto.randomBytes(16).toString('hex');
        const user = await auth.createUser({
            email,
            password: initialPassword,
            displayName: `${first_name} ${last_name}`,
            emailVerified: true,
        });

        // create user record in Firestore
        await db.collection('adminUsers').doc(user.uid).set({
            email,
            first_name,
            last_name,
            username: username || email.split('@')[0],
            role: normalizedInviteRole,
            is_active: false,
            pending_activation: true,
            created_at: new Date().toISOString(),
        });

        await db.collection('user_roles').doc(user.uid).set({
            isAdmin: true,
            role: normalizedInviteRole.toLowerCase(),
            dashboard_role: normalizedInviteRole,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
        }, { merge: true });

        // Generate password reset link
        const link = await auth.generatePasswordResetLink(email);
        const urlObj = new URL(link);
        const oobCode = urlObj.searchParams.get('oobCode');

        // Construct custom link pointing to /invite
        const host = req.headers.get('host');
        const protocol = host?.includes('localhost') ? 'http' : 'https';
        const inviteLink = `${protocol}://${host}/invite?oobCode=${oobCode}&name=${encodeURIComponent(first_name)}`;

        // Send Email using Nodemailer
        let emailSent = false;
        try {
            await sendEmail({
                to: email,
                subject: 'Welcome to SpareWo - Activate Your Admin Account',
                html: getInviteEmailHtml(`${first_name} ${last_name}`, inviteLink),
            });
            emailSent = true;
        } catch (mailError) {
            console.error('Failed to send invitation email:', mailError);
        }

        return NextResponse.json({
            success: true,
            message: emailSent
                ? 'Invitation email sent successfully.'
                : 'User created, but email failed to send. Share the link manually below.',
            inviteLink
        });

    } catch (error: unknown) {
        console.error('Invite staff error:', error);
        const message = error instanceof Error ? error.message : 'Internal Server Error';
        return NextResponse.json({ error: message }, { status: 500 });
    }
}
