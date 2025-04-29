"use client";

import React, { createContext, useContext, useEffect, useState } from 'react';
import { User, onAuthStateChanged } from 'firebase/auth';
import { auth } from '@/lib/firebase/config';
import { doc, getDoc } from 'firebase/firestore';
import { db } from '@/lib/firebase/config';
import { AdminUser } from '@/lib/types';

interface AuthContextType {
  user: User | null;
  adminData: AdminUser | null;
  loading: boolean;
}

const AuthContext = createContext<AuthContextType>({
  user: null,
  adminData: null,
  loading: true,
});

export const useAuth = () => useContext(AuthContext);

export const AuthProvider = ({ children }: { children: React.ReactNode }) => {
  const [user, setUser] = useState<User | null>(null);
  const [adminData, setAdminData] = useState<AdminUser | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      setUser(user);

      if (user) {
        try {
          const docRef = doc(db, 'adminUsers', user.uid);
          const docSnap = await getDoc(docRef);

          if (docSnap.exists()) {
            setAdminData({ id: docSnap.id, ...docSnap.data() } as AdminUser);
          } else {
            console.log('No admin data found');
            setAdminData(null);
          }
        } catch (error) {
          console.error('Error fetching admin data:', error);
        }
      } else {
        setAdminData(null);
      }

      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  return (
    <AuthContext.Provider value={{ user, adminData, loading }}>
      {children}
    </AuthContext.Provider>
  );
};
