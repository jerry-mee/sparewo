"use client";

import React, { createContext, useContext, useEffect, useState } from 'react';
import { onSnapshot, query, collection, where, orderBy, limit } from 'firebase/firestore';
import { db } from '@/lib/firebase/config';
import { Notification } from '@/lib/types/notification';
import { useAuth } from './auth-context';
import { markNotificationAsRead } from '@/lib/firebase/notifications';

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
          id: doc.id,
          ...data,
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
      console.error('Error fetching notifications:', error);
      setLoading(false);
    });

    return () => unsubscribe();
  }, [user]);

  const markAsRead = async (id: string) => {
    try {
      await markNotificationAsRead(id);
    } catch (error) {
      console.error('Error marking notification as read:', error);
    }
  };

  return (
    <NotificationContext.Provider value={{ notifications, unreadCount, markAsRead, loading }}>
      {children}
    </NotificationContext.Provider>
  );
};
