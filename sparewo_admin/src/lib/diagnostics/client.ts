import { collection, addDoc, serverTimestamp } from 'firebase/firestore';
import { auth, db } from '@/lib/firebase/config';
import type { DiagnosticEvent } from '@/lib/diagnostics/types';

const EVENT_COLLECTION = 'system_diagnostics_events';
const DEDUPE_WINDOW_MS = 2500;
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

    await addDoc(collection(db, EVENT_COLLECTION), {
      source: event.source,
      service: event.service,
      severity: event.severity,
      message: event.message,
      code: event.code || null,
      fingerprint,
      context: sanitizeContext(event.context),
      platform: event.platform || 'web',
      uid,
      timestamp: serverTimestamp(),
      isoTimestamp: event.timestamp || new Date().toISOString(),
      createdAtMs: nowMs(),
    });
  } catch {
    // Never throw from diagnostics path.
  }
};
