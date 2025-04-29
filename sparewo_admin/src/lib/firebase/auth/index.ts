import { 
  signInWithEmailAndPassword, 
  signOut, 
  sendPasswordResetEmail,
  createUserWithEmailAndPassword,
  updateProfile,
  setPersistence,
  browserLocalPersistence
} from 'firebase/auth';
import { doc, setDoc, getDoc, serverTimestamp } from 'firebase/firestore';
import { auth, db } from '../config';
import { AdminUser } from '@/lib/types';

// Sign in with email and password
export const signIn = async (email: string, password: string) => {
  try {
    // Enable persistent login sessions
    await setPersistence(auth, browserLocalPersistence);
    
    const userCredential = await signInWithEmailAndPassword(auth, email, password);
    
    // Get the user ID
    const uid = userCredential.user.uid;
    console.log("User signed in with UID:", uid);
    
    // Check if user is an admin
    const adminDocRef = doc(db, 'adminUsers', uid);
    const adminDocSnap = await getDoc(adminDocRef);
    
    if (!adminDocSnap.exists()) {
      console.log("No admin document found for user");
      // Also check user_roles collection for backward compatibility
      const rolesDocRef = doc(db, 'user_roles', uid);
      const rolesDocSnap = await getDoc(rolesDocRef);
      
      if (!rolesDocSnap.exists() || !rolesDocSnap.data().isAdmin) {
        // If user is not an admin, sign them out and throw error
        await signOut(auth);
        throw new Error('Access denied. You do not have admin privileges.');
      }
    }
    
    console.log("Admin access confirmed");
    
    // Create session cookie for middleware
    document.cookie = `__session=${await userCredential.user.getIdToken()}; path=/; max-age=${60 * 60 * 24 * 14}; SameSite=Strict`;
    console.log("Session cookie set");
    
    return userCredential.user;
  } catch (error: unknown) {
    console.error("Sign in error:", error);
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
    
    // Create a document in the adminUsers collection
    await setDoc(doc(db, 'adminUsers', user.uid), {
      id: user.uid,
      email,
      displayName,
      role,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
    
    // Also create a document in user_roles collection for Firestore rules
    await setDoc(doc(db, 'user_roles', user.uid), {
      isAdmin: true,
      role: role,
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