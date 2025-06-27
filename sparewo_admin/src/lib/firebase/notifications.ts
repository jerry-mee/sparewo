// src/lib/firebase/notifications.ts
import {
  collection,
  doc,
  getDocs,
  query,
  where,
  orderBy,
  limit,
  updateDoc,
  serverTimestamp,
  addDoc,
  DocumentData,
  startAfter,
  QueryConstraint
} from 'firebase/firestore';
import { db } from './config';
import { Notification } from '@/lib/types/notification';

// Create a notification
export const createNotification = async (
  notification: Omit<Notification, 'id' | 'createdAt' | 'updatedAt'>
): Promise<string> => {
  try {
    const notificationData = {
      ...notification,
      read: false,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    };
    
    const docRef = await addDoc(collection(db, 'notifications'), notificationData);
    return docRef.id;
  } catch (error) {
    console.error('Error creating notification:', error);
    throw error;
  }
};

// Get notifications for a user
export const getNotifications = async (
  userId: string,
  pageSize: number = 20,
  lastDoc?: DocumentData
): Promise<{ notifications: Notification[], lastDoc: DocumentData | undefined }> => {
  try {
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

// Mark notification as read
export const markNotificationAsRead = async (notificationId: string): Promise<void> => {
  try {
    const docRef = doc(db, 'notifications', notificationId);
    await updateDoc(docRef, {
      read: true,
      updatedAt: serverTimestamp(),
    });
  } catch (error) {
    console.error('Error marking notification as read:', error);
    throw error;
  }
};

// Mark all notifications as read for a user
export const markAllNotificationsAsRead = async (userId: string): Promise<void> => {
  try {
    const q = query(
      collection(db, 'notifications'),
      where('userId', '==', userId),
      where('read', '==', false)
    );
    
    const querySnapshot = await getDocs(q);
    
    const promises = querySnapshot.docs.map((doc) =>
      updateDoc(doc.ref, {
        read: true,
        updatedAt: serverTimestamp(),
      })
    );
    
    await Promise.all(promises);
  } catch (error) {
    console.error('Error marking all notifications as read:', error);
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

// Notification helper functions for common scenarios

// Notify vendor of approval
export const notifyVendorApproval = async (vendorId: string, vendorName: string): Promise<void> => {
  try {
    await createNotification({
      userId: vendorId,
      title: 'Welcome to SpareWo!',
      message: `Congratulations ${vendorName}! Your vendor account has been approved. You can now start adding products.`,
      type: 'success',
      link: '/dashboard',
      read: false,
    });
  } catch (error) {
    console.error('Error sending vendor approval notification:', error);
  }
};

// Notify vendor of rejection
export const notifyVendorRejection = async (
  vendorId: string, 
  vendorName: string, 
  reason: string
): Promise<void> => {
  try {
    await createNotification({
      userId: vendorId,
      title: 'Application Status Update',
      message: `Dear ${vendorName}, your vendor application has been reviewed. ${reason}`,
      type: 'error',
      link: '/profile',
      read: false,
    });
  } catch (error) {
    console.error('Error sending vendor rejection notification:', error);
  }
};

// Notify vendor of product approval
export const notifyProductApproval = async (
  vendorId: string,
  productName: string,
  productId: string
): Promise<void> => {
  try {
    await createNotification({
      userId: vendorId,
      title: 'Product Approved',
      message: `Your product "${productName}" has been approved and is now available in the catalog.`,
      type: 'success',
      link: `/products/${productId}`,
      read: false,
    });
  } catch (error) {
    console.error('Error sending product approval notification:', error);
  }
};

// Notify vendor of product rejection
export const notifyProductRejection = async (
  vendorId: string,
  productName: string,
  productId: string,
  reason: string
): Promise<void> => {
  try {
    await createNotification({
      userId: vendorId,
      title: 'Product Review Update',
      message: `Your product "${productName}" needs attention: ${reason}`,
      type: 'warning',
      link: `/products/${productId}/edit`,
      read: false,
    });
  } catch (error) {
    console.error('Error sending product rejection notification:', error);
  }
};

// Notify vendor of new order fulfillment
export const notifyNewFulfillment = async (
  vendorId: string,
  orderId: string,
  orderNumber: string
): Promise<void> => {
  try {
    await createNotification({
      userId: vendorId,
      title: 'New Order Assigned',
      message: `You have a new order #${orderNumber} to fulfill. Please review and accept.`,
      type: 'info',
      link: `/orders/${orderId}`,
      read: false,
    });
  } catch (error) {
    console.error('Error sending fulfillment notification:', error);
  }
};

// Notify admin of new vendor registration
export const notifyAdminNewVendor = async (
  adminId: string,
  vendorName: string,
  vendorId: string
): Promise<void> => {
  try {
    await createNotification({
      userId: adminId,
      title: 'New Vendor Registration',
      message: `${vendorName} has registered as a vendor and is awaiting approval.`,
      type: 'info',
      link: `/vendors/${vendorId}`,
      read: false,
    });
  } catch (error) {
    console.error('Error sending admin notification:', error);
  }
};

// Notify admin of new product submission
export const notifyAdminNewProduct = async (
  adminId: string,
  productName: string,
  vendorName: string,
  productId: string
): Promise<void> => {
  try {
    await createNotification({
      userId: adminId,
      title: 'New Product Submission',
      message: `${vendorName} has submitted a new product "${productName}" for review.`,
      type: 'info',
      link: `/products/${productId}`,
      read: false,
    });
  } catch (error) {
    console.error('Error sending admin notification:', error);
  }
};

// Send bulk notifications (for announcements)
export const sendBulkNotification = async (
  userIds: string[],
  notification: Omit<Notification, 'id' | 'userId' | 'createdAt' | 'updatedAt' | 'read'>
): Promise<void> => {
  try {
    const promises = userIds.map((userId) =>
      createNotification({
        ...notification,
        userId,
        read: false,
      })
    );
    
    await Promise.all(promises);
  } catch (error) {
    console.error('Error sending bulk notifications:', error);
    throw error;
  }
};