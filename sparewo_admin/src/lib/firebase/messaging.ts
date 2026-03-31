"use client";

import {deleteDoc, doc, serverTimestamp, setDoc} from "firebase/firestore";
import {
  getMessaging,
  getToken,
  isSupported,
  onMessage,
  type MessagePayload,
  type Unsubscribe,
} from "firebase/messaging";
import {app, db} from "./config";
import {markNotificationAsRead} from "./notifications";

type PushInitOptions = {
  onForegroundMessage?: (payload: MessagePayload) => void;
};

const TOKEN_COLLECTIONS = ["adminUsers", "users"] as const;
const LEGACY_SERVICE_WORKER_URL = "/firebase-messaging-sw.js";
const RUNTIME_SERVICE_WORKER_URL = "/firebase-messaging-sw-runtime.js";

const defaultClickLink = "/dashboard/notifications";

const resolveLink = (raw?: string): string => {
  if (!raw || raw.trim().length === 0) return defaultClickLink;
  return raw.trim();
};

const persistToken = async (uid: string, token: string): Promise<void> => {
  const payload = {
    token,
    platform: "web",
    userAgent: typeof navigator !== "undefined" ? navigator.userAgent : "unknown",
    updatedAt: serverTimestamp(),
    lastUsed: serverTimestamp(),
  };
  await Promise.all(
    TOKEN_COLLECTIONS.map((collectionName) =>
      setDoc(doc(db, collectionName, uid, "tokens", token), payload, {merge: true})
    )
  );
};

const removeToken = async (uid: string, token: string): Promise<void> => {
  await Promise.all(
    TOKEN_COLLECTIONS.map((collectionName) =>
      deleteDoc(doc(db, collectionName, uid, "tokens", token)).catch(() => {})
    )
  );
};

const showForegroundBrowserNotification = async (
  payload: MessagePayload
): Promise<void> => {
  if (typeof window === "undefined" || !("Notification" in window)) return;
  if (Notification.permission !== "granted") return;

  const title = payload.notification?.title || "SpareWo Update";
  const body = payload.notification?.body || "You have a new update.";
  const link = resolveLink(payload.data?.link);
  const notificationId = payload.data?.notificationId;

  const browserNotification = new Notification(title, {
    body,
    icon: "/images/logo.png",
    badge: "/images/logo.png",
    data: {
      link,
      notificationId,
    },
  });

  browserNotification.onclick = () => {
    window.focus();
    window.location.assign(link);
    if (notificationId && notificationId.trim().length > 0) {
      void markNotificationAsRead(notificationId).catch(() => {});
    }
    browserNotification.close();
  };
};

export const initAdminWebPush = async (
  uid: string,
  options: PushInitOptions = {}
): Promise<() => void> => {
  if (typeof window === "undefined") return () => {};
  if (!("serviceWorker" in navigator) || !("Notification" in window)) {
    return () => {};
  }

  const supported = await isSupported().catch(() => false);
  if (!supported) {
    console.warn("[Push] Firebase Messaging is not supported in this browser.");
    return () => {};
  }

  const permission =
    Notification.permission === "granted" ?
      "granted" :
      await Notification.requestPermission();
  if (permission !== "granted") {
    console.warn("[Push] Browser notification permission not granted.");
    return () => {};
  }

  // Explicitly retire the legacy static worker so a stale hardcoded config
  // does not continue to handle push events.
  const legacyRegistration = await navigator.serviceWorker
    .getRegistration(LEGACY_SERVICE_WORKER_URL)
    .catch(() => undefined);
  if (legacyRegistration) {
    await legacyRegistration.unregister().catch(() => {});
  }

  const swRegistration = await navigator.serviceWorker.register(
    RUNTIME_SERVICE_WORKER_URL,
    {scope: "/"}
  );
  const messaging = getMessaging(app);
  const vapidKey = process.env.NEXT_PUBLIC_FIREBASE_VAPID_KEY;
  const token = await getToken(messaging, {
    serviceWorkerRegistration: swRegistration,
    vapidKey: vapidKey || undefined,
  });

  let activeToken: string | null = null;
  if (token && token.trim().length > 0) {
    activeToken = token.trim();
    await persistToken(uid, activeToken);
  } else {
    console.warn("[Push] No FCM token returned for admin web push.");
  }

  const unsubscribeForeground: Unsubscribe = onMessage(messaging, (payload) => {
    options.onForegroundMessage?.(payload);
    void showForegroundBrowserNotification(payload);
  });

  return () => {
    unsubscribeForeground();
    if (activeToken) {
      void removeToken(uid, activeToken);
    }
  };
};
