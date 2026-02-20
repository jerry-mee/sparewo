import { db } from '@/lib/firebase/admin';

type RateLimitConfig = {
  key: string;
  identifier: string;
  windowSeconds: number;
  maxRequests: number;
};

const RATE_LIMIT_COLLECTION = '_rate_limits';

const nowMs = () => Date.now();

const normalizeIdentifier = (value: string): string => {
  const trimmed = value.trim().toLowerCase();
  return trimmed.replace(/[^a-z0-9:_-]/g, '_').slice(0, 120) || 'unknown';
};

export const getRequestIp = (req: Request): string => {
  const forwardedFor = req.headers.get('x-forwarded-for');
  if (forwardedFor) {
    const first = forwardedFor.split(',')[0]?.trim();
    if (first) return first;
  }

  const realIp = req.headers.get('x-real-ip');
  if (realIp?.trim()) return realIp.trim();

  return 'unknown';
};

export class RateLimitError extends Error {
  readonly retryAfterSeconds: number;

  constructor(message: string, retryAfterSeconds: number) {
    super(message);
    this.name = 'RateLimitError';
    this.retryAfterSeconds = retryAfterSeconds;
  }
}

export const enforceRateLimit = async ({
  key,
  identifier,
  windowSeconds,
  maxRequests,
}: RateLimitConfig): Promise<void> => {
  const windowMs = Math.max(1, windowSeconds) * 1000;
  const currentMs = nowMs();
  const bucket = Math.floor(currentMs / windowMs);
  const bucketStart = bucket * windowMs;
  const expiresAtMs = bucketStart + windowMs;
  const retryAfterSeconds = Math.max(1, Math.ceil((expiresAtMs - currentMs) / 1000));

  const normalizedKey = normalizeIdentifier(key);
  const normalizedIdentifier = normalizeIdentifier(identifier);
  const docId = `${normalizedKey}:${normalizedIdentifier}:${bucket}`;
  const docRef = db.collection(RATE_LIMIT_COLLECTION).doc(docId);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(docRef);
    const current = snap.exists ? Number(snap.data()?.count ?? 0) : 0;
    const next = current + 1;

    if (next > maxRequests) {
      throw new RateLimitError('Too many requests. Please try again shortly.', retryAfterSeconds);
    }

    tx.set(
      docRef,
      {
        key: normalizedKey,
        identifier: normalizedIdentifier,
        count: next,
        windowStart: new Date(bucketStart).toISOString(),
        expiresAt: new Date(expiresAtMs).toISOString(),
        updatedAt: new Date(currentMs).toISOString(),
      },
      { merge: true }
    );
  });
};
