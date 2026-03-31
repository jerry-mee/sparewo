import { NextResponse } from "next/server";

export const dynamic = "force-dynamic";
export const revalidate = 0;

const toJsString = (value?: string): string => JSON.stringify(value ?? "");

const serviceWorkerScript = `/* eslint-disable no-undef */
importScripts("https://www.gstatic.com/firebasejs/11.6.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/11.6.1/firebase-messaging-compat.js");

const firebaseConfig = {
  apiKey: ${toJsString(process.env.NEXT_PUBLIC_FIREBASE_API_KEY)},
  authDomain: ${toJsString(process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN)},
  projectId: ${toJsString(process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID)},
  storageBucket: ${toJsString(process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET)},
  messagingSenderId: ${toJsString(process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID)},
  appId: ${toJsString(process.env.NEXT_PUBLIC_FIREBASE_APP_ID)},
};

const hasMissingConfig = Object.values(firebaseConfig).some((value) => !value || value.length === 0);
if (hasMissingConfig) {
  console.warn("[Push SW] Missing NEXT_PUBLIC_FIREBASE_* config. Messaging worker not initialized.");
} else {
  firebase.initializeApp(firebaseConfig);
  const messaging = firebase.messaging();

  messaging.onBackgroundMessage((payload) => {
    const title = payload?.notification?.title || "SpareWo Update";
    const body = payload?.notification?.body || "You have a new update.";
    const data = payload?.data || {};
    const link = data.link || "/dashboard/notifications";

    self.registration.showNotification(title, {
      body,
      icon: "/images/logo.png",
      badge: "/images/logo.png",
      data: {
        ...data,
        link,
      },
    });
  });
}

self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  const rawLink = event.notification?.data?.link || "/dashboard/notifications";
  const link = rawLink.startsWith("/") ? rawLink : "/dashboard/notifications";
  event.waitUntil(
    clients.matchAll({type: "window", includeUncontrolled: true}).then((windowClients) => {
      for (const client of windowClients) {
        if ("focus" in client) {
          client.postMessage({
            type: "sparewo_notification_click",
            data: event.notification?.data || {},
          });
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow(link);
      }
      return undefined;
    })
  );
});
`;

export function GET() {
  return new NextResponse(serviceWorkerScript, {
    headers: {
      "Content-Type": "application/javascript; charset=utf-8",
      "Cache-Control": "no-store, no-cache, must-revalidate, proxy-revalidate",
      "Service-Worker-Allowed": "/",
    },
  });
}
