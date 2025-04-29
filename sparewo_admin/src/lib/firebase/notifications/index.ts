import {
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  where,
  orderBy,
  limit,
  addDoc,
  updateDoc,
  serverTimestamp,
  DocumentData,
  QueryConstraint,
  startAfter
} from 'firebase/firestore';
import { db } from '../config';
import { Notification } from '@/lib/types/notification';

// Get notifications for a user
export const getUserNotifications = async (
  userId: string,
  pageSize: number = 10,
  lastDoc?: DocumentData
): Promise<{ notifications: Notification[], lastDoc: DocumentData | undefined }> => {
  try {
    // Build query constraints
    const constraints: QueryConstraint[] = [
      where('userId', '==', userId),
      orderBy('createdAt', 'desc')
    ];

    let q = query(
      collection(db, 'notifications'),
      ...constraints,
      limit(pageSize)
    );

    if (lastDoc) {
      q = query(q, startAfter(lastDoc));
    }

    const querySnapshot = await getDocs(q);

    const notifications: Notification[] = [];
    let lastVisible: DocumentData | undefined = undefined;

    querySnapshot.forEach((doc) => {
      notifications.push({ id: doc.id, ...doc.data() } as Notification);
      lastVisible = doc;
    });

    return { notifications, lastDoc: lastVisible };
  } catch (error) {
    console.error('Error getting notifications:', error);
    throw error;
  }
};

// Create a new notification
export const createNotification = async (
  notification: Omit<Notification, 'id' | 'createdAt' | 'updatedAt'>
): Promise<string> => {
  try {
    const docRef = await addDoc(collection(db, 'notifications'), {
      ...notification,
      read: false,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp()
    });

    return docRef.id;
  } catch (error) {
    console.error('Error creating notification:', error);
    throw error;
  }
};

// Mark notification as read
export const markNotificationAsRead = async (id: string): Promise<void> => {
  try {
    const docRef = doc(db, 'notifications', id);
    await updateDoc(docRef, {
      read: true,
      updatedAt: serverTimestamp()
    });
  } catch (error) {
    console.error('Error marking notification as read:', error);
    throw error;
  }
};

// Get unread notification count
export const getUnreadNotificationCount = async (userId: string): Promise<number> => {
  try {
    const q = query(
      collection(db, 'notifications'),
      where('userId', '==', userId),
      where('read', '==', false)
    );

    const querySnapshot = await getDocs(q);
    return querySnapshot.size;
  } catch (error) {
    console.error('Error getting unread notification count:', error);
    throw error;
  }
};
