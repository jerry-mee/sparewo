'use client';

import React, { createContext, useContext, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { 
  getAuth, 
  signInWithEmailAndPassword, 
  signOut, 
  onAuthStateChanged,
  User
} from 'firebase/auth';
import { 
  getFirestore,
  doc,
  getDoc
} from 'firebase/firestore';
import { initializeApp } from 'firebase/app';

// Your Firebase configuration
const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

interface AuthContextType {
  user: User | null;
  userRoles: {
    isAdmin: boolean;
    [key: string]: any;
  } | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  error: string | null;
}

// Export the context so it can be imported elsewhere
export const AuthContext = createContext<AuthContextType>({
  user: null,
  userRoles: null,
  loading: true,
  login: async () => {},
  logout: async () => {},
  error: null
});

export const useAuth = () => useContext(AuthContext);

export const AuthProvider = ({ children }: { children: React.ReactNode }) => {
  const [user, setUser] = useState<User | null>(null);
  const [userRoles, setUserRoles] = useState<{ isAdmin: boolean; [key: string]: any } | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const router = useRouter();

  // Fetch user roles from Firestore
  const fetchUserRoles = async (uid: string) => {
    try {
      const userRolesRef = doc(db, 'user_roles', uid);
      const userRolesSnapshot = await getDoc(userRolesRef);

      if (userRolesSnapshot.exists()) {
        const data = userRolesSnapshot.data();
        setUserRoles({
          isAdmin: data.isAdmin === true,
          ...data
        });
      } else {
        setUserRoles({
          isAdmin: false
        });
      }
    } catch (error) {
      console.error('Error fetching user roles:', error);
      setUserRoles({
        isAdmin: false
      });
    }
  };

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (currentUser) => {
      setUser(currentUser);
      
      if (currentUser) {
        await fetchUserRoles(currentUser.uid);
      } else {
        setUserRoles(null);
      }
      
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const handleLogin = async (email: string, password: string) => {
    setError(null);
    try {
      const userCredential = await signInWithEmailAndPassword(auth, email, password);
      await fetchUserRoles(userCredential.user.uid);
      router.push('/');
    } catch (err: any) {
      console.error('Login error:', err);
      setError(err.message || 'Failed to login');
      throw err;
    }
  };

  const handleLogout = async () => {
    setError(null);
    try {
      await signOut(auth);
      setUser(null);
      setUserRoles(null);
      router.push('/auth/sign-in');
    } catch (err: any) {
      console.error('Logout error:', err);
      setError(err.message || 'Failed to logout');
    }
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        userRoles,
        loading,
        login: handleLogin,
        logout: handleLogout,
        error
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};