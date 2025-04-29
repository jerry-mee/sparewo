"use client";

import { NotificationProvider as NotificationContextProvider } from '@/lib/context/notification-context';

export function NotificationProvider({ children }: { children: React.ReactNode }) {
  return <NotificationContextProvider>{children}</NotificationContextProvider>;
}
