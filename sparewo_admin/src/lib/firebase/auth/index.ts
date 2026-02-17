import {
  signInWithEmailAndPassword,
  signOut,
  sendPasswordResetEmail,
  createUserWithEmailAndPassword,
  updateProfile,
  setPersistence,
  browserLocalPersistence
} from 'firebase/auth';
import { doc, setDoc, getDoc, serverTimestamp, updateDoc } from 'firebase/firestore';
import { auth, db } from '../config';
import { AdminUser } from '@/lib/types';
import { normalizeRole } from '@/lib/auth/roles';

// Sign in with email and password
export const signIn = async (email: string, password: string) => {
  try {
    // Set persistence to LOCAL for session persistence
    await setPersistence(auth, browserLocalPersistence);

    const userCredential = await signInWithEmailAndPassword(auth, email, password);

    // Check if user is an admin
    const adminDocRef = doc(db, 'adminUsers', userCredential.user.uid);
    const adminDocSnap = await getDoc(adminDocRef);

    if (!adminDocSnap.exists()) {
      // If user is not an admin, sign them out and throw error
      await signOut(auth);
      throw new Error('Access denied. You do not have admin privileges.');
    }

    const adminData = adminDocSnap.data();
    const normalizedRole = normalizeRole(adminData?.role);
    if (adminData?.is_active === false) {
      if (adminData?.pending_activation) {
        // Auto-activate on first login
        await updateDoc(adminDocRef, {
          is_active: true,
          pending_activation: false,
          activatedAt: serverTimestamp()
        });
      } else {
        // This is a suspended account
        await signOut(auth);
        throw new Error('Your account is currently disabled. Please contact an administrator.');
      }
    }

    // Keep user_roles in sync for rules/read access across role-based dashboards.
    await setDoc(
      doc(db, 'user_roles', userCredential.user.uid),
      {
        isAdmin: normalizedRole === 'Administrator' || normalizedRole === 'Manager' || normalizedRole === 'Mechanic',
        role: normalizedRole ? normalizedRole.toLowerCase() : 'manager',
        dashboard_role: normalizedRole ?? 'Manager',
        updatedAt: serverTimestamp(),
      },
      { merge: true }
    );

    // Create session cookie for middleware
    document.cookie = `__session=${await userCredential.user.getIdToken()}; path=/; max-age=${60 * 60 * 24 * 14}; SameSite=Strict`;

    return userCredential.user;
  } catch (error: unknown) {
    if (error instanceof Error) {
      throw new Error(error.message);
    }
    throw new Error('Authentication failed');
  }
};

// Sign out
export const logOut = async () => {
  try {
    // Clear session cookie
    document.cookie = '__session=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT';
    await signOut(auth);
  } catch (error: unknown) {
    if (error instanceof Error) {
      throw new Error(error.message);
    }
    throw new Error('Failed to log out');
  }
};

// Send password reset email
export const resetPassword = async (email: string) => {
  try {
    await sendPasswordResetEmail(auth, email);
  } catch (error: unknown) {
    if (error instanceof Error) {
      throw new Error(error.message);
    }
    throw new Error('Failed to send reset email');
  }
};

// Create a new admin user
export const createAdmin = async (email: string, password: string, displayName: string, role: AdminUser['role']) => {
  try {
    const userCredential = await createUserWithEmailAndPassword(auth, email, password);
    const user = userCredential.user;

    // Update the user profile with displayName
    await updateProfile(user, { displayName });

    const normalizedRole = normalizeRole(role) ?? 'Manager';

    // Create a document in the adminUsers collection
    await setDoc(doc(db, 'adminUsers', user.uid), {
      id: user.uid,
      email,
      displayName,
      role: normalizedRole,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });

    // Also create a document in user_roles collection for Firestore rules
    await setDoc(doc(db, 'user_roles', user.uid), {
      isAdmin: true,
      role: normalizedRole.toLowerCase(),
      dashboard_role: normalizedRole,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });

    return user;
  } catch (error: unknown) {
    if (error instanceof Error) {
      throw new Error(error.message);
    }
    throw new Error('Failed to create admin user');
  }
};
