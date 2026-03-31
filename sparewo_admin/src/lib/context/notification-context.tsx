"use client";

import React, { createContext, useContext, useEffect, useState } from 'react';
import { onSnapshot, query, collection, where, orderBy, limit } from 'firebase/firestore';
import { useRouter } from 'next/navigation';
import { db } from '@/lib/firebase/config';
import { Notification } from '@/lib/types/notification';
import { useAuth } from './auth-context';
import { markNotificationAsRead } from '@/lib/firebase/notifications';
import { initAdminWebPush } from '@/lib/firebase/messaging';
import { logError } from '@/lib/diagnostics/logger';

interface NotificationContextType {
  notifications: Notification[];
  unreadCount: number;
  markAsRead: (id: string) => Promise<void>;
  loading: boolean;
}

const NotificationContext = createContext<NotificationContextType>({
  notifications: [],
  unreadCount: 0,
  markAsRead: async () => {},
  loading: true,
});

export const useNotifications = () => useContext(NotificationContext);

export const NotificationProvider = ({ children }: { children: React.ReactNode }) => {
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const [loading, setLoading] = useState(true);
  const { user } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!user) {
      setNotifications([]);
      setUnreadCount(0);
      setLoading(false);
      return;
    }

    const q = query(
      collection(db, 'notifications'),
      where('userId', '==', user.uid),
      orderBy('createdAt', 'desc'),
      limit(20)
    );

    const unsubscribe = onSnapshot(q, (querySnapshot) => {
      const notificationList: Notification[] = [];
      let unread = 0;

      querySnapshot.forEach((doc) => {
        const data = doc.data() as Notification;
        const resolvedRead = data.isRead ?? data.read ?? false;
        const notification = {
          ...data,
          id: doc.id,
          read: resolvedRead,
          isRead: resolvedRead,
        } as Notification;
        notificationList.push(notification);

        if (!resolvedRead) {
          unread++;
        }
      });

      setNotifications(notificationList);
      setUnreadCount(unread);
      setLoading(false);
    }, (error) => {
      void logError('notification_context', 'Error fetching notifications', error);
      setLoading(false);
    });

    return () => unsubscribe();
  }, [user]);

  useEffect(() => {
    if (!user) return;

    let cancelled = false;
    let cleanupPush: (() => void) | null = null;

    const handleServiceWorkerMessage = (event: MessageEvent) => {
      const payload = event.data;
      if (!payload || payload.type !== 'sparewo_notification_click') return;
      const data = payload.data ?? {};
      const link =
        typeof data.link === 'string' && data.link.startsWith('/')
          ? data.link
          : '/dashboard/notifications';
      const notificationId =
        typeof data.notificationId === 'string' ? data.notificationId : '';
      if (notificationId) {
        void markNotificationAsRead(notificationId).catch(() => {});
      }
      router.push(link);
    };

    if (typeof navigator !== 'undefined' && navigator.serviceWorker) {
      navigator.serviceWorker.addEventListener('message', handleServiceWorkerMessage);
    }

    void initAdminWebPush(user.uid)
      .then((cleanup) => {
        if (cancelled) {
          cleanup();
          return;
        }
        cleanupPush = cleanup;
      })
      .catch((error) => {
        void logError('notification_context', 'Admin web push init failed', error);
      });

    return () => {
      cancelled = true;
      if (cleanupPush) {
        cleanupPush();
      }
      if (typeof navigator !== 'undefined' && navigator.serviceWorker) {
        navigator.serviceWorker.removeEventListener('message', handleServiceWorkerMessage);
      }
    };
  }, [user, router]);

  const markAsRead = async (id: string) => {
    try {
      await markNotificationAsRead(id);
    } catch (error) {
      void logError('notification_context', 'Error marking notification as read', error);
    }
  };

  return (
    <NotificationContext.Provider value={{ notifications, unreadCount, markAsRead, loading }}>
      {children}
    </NotificationContext.Provider>
  );
};
