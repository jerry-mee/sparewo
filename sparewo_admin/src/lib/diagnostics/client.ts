import { collection, addDoc, serverTimestamp } from 'firebase/firestore';
import { auth, db } from '@/lib/firebase/config';
import type { DiagnosticEvent } from '@/lib/diagnostics/types';

const EVENT_COLLECTION = 'system_diagnostics_events';
const DEDUPE_WINDOW_MS = 2500;
const DEVICE_ID_STORAGE_KEY = 'sparewo_admin_device_id_v1';
const seenFingerprints = new Map<string, number>();

const nowMs = (): number => Date.now();

const shouldSkipDuplicate = (fingerprint: string): boolean => {
  const now = nowMs();
  const last = seenFingerprints.get(fingerprint) || 0;
  seenFingerprints.set(fingerprint, now);
  return now - last <= DEDUPE_WINDOW_MS;
};

const sanitizeContext = (
  input: Record<string, unknown> | undefined
): Record<string, unknown> | undefined => {
  if (!input) return undefined;
  const redacted = { ...input };
  const blockedKeys = ['token', 'accessToken', 'idToken', 'password', 'secret', 'authorization'];
  for (const key of Object.keys(redacted)) {
    if (blockedKeys.some((needle) => key.toLowerCase().includes(needle.toLowerCase()))) {
      redacted[key] = '[REDACTED]';
    }
  }
  return redacted;
};

const resolveDeviceId = (): string | null => {
  if (typeof window === 'undefined') return null;
  try {
    const existing = window.localStorage.getItem(DEVICE_ID_STORAGE_KEY);
    if (existing && existing.trim().length > 0) return existing;
    const generated =
      typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function'
        ? crypto.randomUUID()
        : `web-${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;
    window.localStorage.setItem(DEVICE_ID_STORAGE_KEY, generated);
    return generated;
  } catch {
    return null;
  }
};

export const recordDiagnosticEvent = async (
  event: DiagnosticEvent
): Promise<void> => {
  try {
    const fingerprint =
      event.fingerprint ||
      `${event.source}|${event.service}|${event.severity}|${event.code || ''}|${event.message}`;

    if (shouldSkipDuplicate(fingerprint)) {
      return;
    }

    const uid = auth.currentUser?.uid || event.uid || null;
    const deviceId = resolveDeviceId();
    const platform =
      event.platform ||
      (typeof navigator !== 'undefined' ? navigator.platform || 'web' : 'web');
    const userAgent =
      typeof navigator !== 'undefined' ? navigator.userAgent : undefined;
    const mergedContext = sanitizeContext({
      ...event.context,
      ...(deviceId ? { deviceId } : {}),
      ...(userAgent ? { userAgent } : {}),
    });

    await addDoc(collection(db, EVENT_COLLECTION), {
      source: event.source,
      service: event.service,
      severity: event.severity,
      message: event.message,
      code: event.code || null,
      fingerprint,
      context: mergedContext,
      platform,
      uid,
      deviceId,
      userAgent: userAgent || null,
      timestamp: serverTimestamp(),
      isoTimestamp: event.timestamp || new Date().toISOString(),
      createdAtMs: nowMs(),
    });
  } catch {
    // Never throw from diagnostics path.
  }
};
