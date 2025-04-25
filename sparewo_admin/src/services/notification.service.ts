import { 
  collection, 
  addDoc, 
  updateDoc, 
  getDocs, 
  doc, 
  query, 
  where,
  orderBy,
  Timestamp, 
  getDoc
} from "firebase/firestore";
import { db } from "./firebase.service";
import { collection as safeCollection, doc as safeDoc } from "@/lib/firebase-utils";

export enum NotificationType {
  INFO = "info",
  WARNING = "warning",
  SUCCESS = "success",
  ERROR = "error"
}

export enum NotificationTarget {
  ALL = "all",
  VENDORS = "vendors",
  CUSTOMERS = "customers",
  ADMIN = "admin"
}

export interface Notification {
  id?: string;
  title: string;
  message: string;
  type: NotificationType;
  target: NotificationTarget | string; // Either a target group or specific user ID
  read?: boolean;
  createdAt?: any;
  expiresAt?: any;
  link?: string;
  sendEmail?: boolean;
}

const notificationService = {
  /**
   * Create a new notification
   */
  createNotification: async (notification: Notification) => {
    try {
      const notificationsRef = safeCollection(db, "notifications");
      
      const newNotification = {
        ...notification,
        read: false,
        createdAt: Timestamp.now(),
        expiresAt: notification.expiresAt || Timestamp.fromDate(new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)) // Default 30 days
      };
      
      const docRef = await addDoc(notificationsRef, newNotification);
      
      // If notification should be sent as email, trigger email sending
      if (notification.sendEmail) {
        await sendEmailNotification(newNotification);
      }
      
      return { id: docRef.id, ...newNotification };
    } catch (error) {
      console.error("Error creating notification:", error);
      throw error;
    }
  },
  
  /**
   * Get notifications for a specific user or group
   */
  getNotifications: async (userId: string, unreadOnly: boolean = false) => {
    try {
      const notificationsRef = safeCollection(db, "notifications");
      
      // Query notifications for this specific user or for their group (customer, vendor, admin)
      // Also include notifications targeted at "all"
      let q = query(
        notificationsRef,
        where("target", "in", [userId, "all"]), // Include specific user ID and "all"
        orderBy("createdAt", "desc")
      );
      
      // If only unread notifications are requested
      if (unreadOnly) {
        q = query(
          notificationsRef,
          where("target", "in", [userId, "all"]),
          where("read", "==", false),
          orderBy("createdAt", "desc")
        );
      }
      
      const querySnapshot = await getDocs(q);
      const notifications: Notification[] = [];
      
      querySnapshot.forEach((doc) => {
        notifications.push({ id: doc.id, ...doc.data() } as Notification);
      });
      
      return notifications;
    } catch (error) {
      console.error("Error getting notifications:", error);
      throw error;
    }
  },
  
  /**
   * Mark a notification as read
   */
  markAsRead: async (notificationId: string) => {
    try {
      const notificationRef = safeDoc(db, "notifications", notificationId);
      await updateDoc(notificationRef, {
        read: true
      });
      return true;
    } catch (error) {
      console.error("Error marking notification as read:", error);
      throw error;
    }
  },
  
  /**
   * Delete a notification
   */
  deleteNotification: async (notificationId: string) => {
    try {
      const notificationRef = safeDoc(db, "notifications", notificationId);
      await updateDoc(notificationRef, {
        deleted: true
      });
      return true;
    } catch (error) {
      console.error("Error deleting notification:", error);
      throw error;
    }
  },
  
  /**
   * Send bulk notifications to a group (vendors, customers, all)
   */
  sendBulkNotification: async (notification: Notification) => {
    try {
      // For now, just create a single notification with the target group
      return await notificationService.createNotification(notification);
    } catch (error) {
      console.error("Error sending bulk notification:", error);
      throw error;
    }
  }
};

/**
 * Helper function to send email notifications
 * In a real implementation, this would call a Cloud Function or backend API
 */
async function sendEmailNotification(notification: Notification) {
  try {
    console.log(`Email notification would be sent: ${JSON.stringify(notification)}`);
    
    // In a real implementation, we would:
    // 1. If target is specific user, get their email
    // 2. If target is a group, query all users in that group
    // 3. Send emails via an email service (SendGrid, Mailgun, etc.)
    
    return true;
  } catch (error) {
    console.error("Error sending email notification:", error);
    throw error;
  }
}

export default notificationService;
