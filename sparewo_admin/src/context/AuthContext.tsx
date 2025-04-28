'use client';

import React, { createContext, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import type { User } from 'firebase/auth';

// Define the shape of our AuthContext
interface AuthContextType {
  user: User | null;
  loading: boolean;
  error: string | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  currentUser: User | null;
}

// Create context with a default value
export const AuthContext = createContext<AuthContextType | undefined>(undefined);

// AuthProvider component
export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const router = useRouter();

  // Initialize Firebase modules
  async function loadFirebaseModules() {
    if (typeof window === 'undefined') {
      return null;
    }
    
    try {
      // Dynamic import of Firebase auth module
      const authModule = await import('firebase/auth');
      return authModule;
    } catch (error) {
      console.error("Failed to import Firebase auth module:", error);
      return null;
    }
  }

  // Get Auth instance
  async function getAuthInstance() {
    try {
      const firebaseService = await import('@/services/firebase.service');
      const authModule = await loadFirebaseModules();
      
      if (!authModule) return null;
      
      return await authModule.getAuth();
    } catch (error) {
      console.error("Failed to get auth instance:", error);
      return null;
    }
  }

  // Check auth state on component mount
  useEffect(() => {
    if (typeof window === 'undefined') return;
    
    const checkAuthState = async () => {
      try {
        const authModule = await loadFirebaseModules();
        const auth = await getAuthInstance();
        
        if (!authModule || !auth) {
          setLoading(false);
          return;
        }
        
        const unsubscribe = authModule.onAuthStateChanged(auth, (authUser) => {
          setUser(authUser);
          setLoading(false);
        }, (authError) => {
          console.error("Auth state change error:", authError);
          setError(authError.message);
          setLoading(false);
        });
        
        // Cleanup subscription on unmount
        return () => unsubscribe();
      } catch (error) {
        console.error("Error checking auth state:", error);
        setLoading(false);
      }
    };
    
    checkAuthState();
  }, []);

  // Login function
  const login = async (email: string, password: string) => {
    setError(null);
    setLoading(true);
    
    try {
      const authModule = await loadFirebaseModules();
      const auth = await getAuthInstance();
      
      if (!authModule || !auth) {
        throw new Error("Authentication not available");
      }
      
      await authModule.signInWithEmailAndPassword(auth, email, password);
      router.push('/');
    } catch (error: any) {
      console.error("Login error:", error);
      setError(error.message || 'Failed to login');
    } finally {
      setLoading(false);
    }
  };

  // Logout function
  const logout = async () => {
    setLoading(true);
    
    try {
      const authModule = await loadFirebaseModules();
      const auth = await getAuthInstance();
      
      if (!authModule || !auth) {
        throw new Error("Authentication not available");
      }
      
      await authModule.signOut(auth);
      router.push('/auth/sign-in');
    } catch (error: any) {
      console.error("Logout error:", error);
      setError(error.message || 'Failed to logout');
    } finally {
      setLoading(false);
    }
  };

  // Context value
  const value = {
    user,
    loading,
    error,
    login,
    logout,
    currentUser: user
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};