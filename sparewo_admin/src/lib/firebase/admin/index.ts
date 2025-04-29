import {
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  where,
  orderBy,
  limit,
  updateDoc,
  serverTimestamp,
  DocumentData,
  QueryConstraint,
  deleteDoc
} from 'firebase/firestore';
import { db } from '../config';
import { AdminUser } from '@/lib/types';

// Get all admin users
export const getAdminUsers = async (): Promise<AdminUser[]> => {
  try {
    const q = query(
      collection(db, 'adminUsers'),
      orderBy('createdAt', 'desc')
    );

    const querySnapshot = await getDocs(q);

    const adminUsers: AdminUser[] = [];

    querySnapshot.forEach((doc) => {
      adminUsers.push({ id: doc.id, ...doc.data() } as AdminUser);
    });

    return adminUsers;
  } catch (error) {
    console.error('Error getting admin users:', error);
    throw error;
  }
};

// Get admin user by ID
export const getAdminUserById = async (id: string): Promise<AdminUser | null> => {
  try {
    const docRef = doc(db, 'adminUsers', id);
    const docSnap = await getDoc(docRef);

    if (docSnap.exists()) {
      return { id: docSnap.id, ...docSnap.data() } as AdminUser;
    }

    return null;
  } catch (error) {
    console.error('Error getting admin user:', error);
    throw error;
  }
};

// Update admin user role
export const updateAdminUserRole = async (
  id: string,
  role: AdminUser['role']
): Promise<void> => {
  try {
    const docRef = doc(db, 'adminUsers', id);
    await updateDoc(docRef, {
      role,
      updatedAt: serverTimestamp()
    });
  } catch (error) {
    console.error('Error updating admin user role:', error);
    throw error;
  }
};

// Delete admin user
export const deleteAdminUser = async (id: string): Promise<void> => {
  try {
    await deleteDoc(doc(db, 'adminUsers', id));
  } catch (error) {
    console.error('Error deleting admin user:', error);
    throw error;
  }
};
