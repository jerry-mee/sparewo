
import * as admin from 'firebase-admin';

if (!admin.apps.length) {
    try {
        if (process.env.FIREBASE_PRIVATE_KEY) {
            admin.initializeApp({
                credential: admin.credential.cert({
                    projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
                    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
                    privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
                }),
            });
        } else {
            console.warn("FIREBASE_PRIVATE_KEY is missing. Skipping Firebase Admin initialization.");
        }
    } catch (error) {
        console.error('Firebase admin initialization error', error);
    }
}

let db: admin.firestore.Firestore;
let auth: admin.auth.Auth;

try {
    if (admin.apps.length) {
        db = admin.firestore();
        auth = admin.auth();
    } else {
        // Prevents build crash if env vars are missing
        // This is a dummy object to satisfy TS, runtime calls will fail if not properly initialized
        db = {} as any;
        auth = {} as any;
        console.warn("Firebase Admin not initialized. DB and Auth are empty.");
    }
} catch (e) {
    db = {} as any;
    auth = {} as any;
}

export { db, auth };
