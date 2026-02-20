import * as admin from 'firebase-admin';

type ServiceAccountEnv = {
  projectId?: string;
  clientEmail?: string;
  privateKey?: string;
};

const parseServiceAccountFromEnv = (): ServiceAccountEnv | null => {
  const json = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!json) return null;

  const trimmed = json.trim();
  if (!trimmed.startsWith('{')) {
    return null;
  }

  try {
    const parsed = JSON.parse(json) as ServiceAccountEnv;
    return {
      projectId: parsed.projectId,
      clientEmail: parsed.clientEmail,
      privateKey: parsed.privateKey,
    };
  } catch (error) {
    console.error('Invalid FIREBASE_SERVICE_ACCOUNT_JSON value.', error);
    return null;
  }
};

const getServiceAccount = (): ServiceAccountEnv | null => {
  const fromJson = parseServiceAccountFromEnv();
  if (fromJson?.projectId && fromJson.clientEmail && fromJson.privateKey) {
    return {
      projectId: fromJson.projectId,
      clientEmail: fromJson.clientEmail,
      privateKey: fromJson.privateKey.replace(/\\n/g, '\n'),
    };
  }

  if (process.env.FIREBASE_PRIVATE_KEY && process.env.FIREBASE_CLIENT_EMAIL) {
    return {
      projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
    };
  }

  return null;
};

if (!admin.apps.length) {
  try {
    const serviceAccount = getServiceAccount();

    if (serviceAccount?.projectId && serviceAccount.clientEmail && serviceAccount.privateKey) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
    } else {
      console.warn(
        'Firebase Admin not initialized. Set FIREBASE_SERVICE_ACCOUNT_JSON in host secrets (preferred).'
      );
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
    db = {} as admin.firestore.Firestore;
    auth = {} as admin.auth.Auth;
  }
} catch {
  db = {} as admin.firestore.Firestore;
  auth = {} as admin.auth.Auth;
}

export { db, auth };
