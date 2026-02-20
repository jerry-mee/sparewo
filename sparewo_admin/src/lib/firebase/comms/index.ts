import {
  addDoc,
  collection,
  doc,
  getDoc,
  getDocs,
  limit,
  orderBy,
  query,
  serverTimestamp,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';
import { db } from '../config';

export type CommunicationAudience =
  | 'all_clients'
  | 'active_clients'
  | 'suspended_clients'
  | 'all_vendors'
  | 'active_vendors'
  | 'suspended_vendors'
  | 'individual_client'
  | 'individual_vendor'
  | 'admins';

export type CommunicationType = 'info' | 'success' | 'warning' | 'error';

export interface CommunicationDraft {
  title: string;
  message: string;
  type: CommunicationType;
  audience: CommunicationAudience;
  link?: string;
  recipientIds?: string[];
}

export interface CommunicationSummary {
  id: string;
  title: string;
  audience: CommunicationAudience;
  type: CommunicationType;
  deliveredCount: number;
  attemptedCount: number;
  createdAt: unknown;
  createdBy: string;
}

interface AudienceCounts {
  allClients: number;
  activeClients: number;
  suspendedClients: number;
  allVendors: number;
  activeVendors: number;
  suspendedVendors: number;
  admins: number;
}

interface Recipient {
  id: string;
  label: string;
  email?: string;
}

export type CommunicationRecipientRole = 'client' | 'vendor';

const normalizeString = (value: unknown, fallback = ''): string =>
  typeof value === 'string' ? value : fallback;

const parseBool = (value: unknown): boolean => value === true;

const parseRecipient = (
  id: string,
  source: Record<string, unknown>,
  preferredNameField: string
): Recipient => ({
  id,
  label: normalizeString(source[preferredNameField], id),
  email: normalizeString(source.email, ''),
});

export const getCommunicationAudienceCounts = async (): Promise<AudienceCounts> => {
  const [usersSnap, vendorsSnap, adminsSnap] = await Promise.all([
    getDocs(collection(db, 'users')),
    getDocs(collection(db, 'vendors')),
    getDocs(collection(db, 'adminUsers')),
  ]);

  let activeClients = 0;
  let suspendedClients = 0;
  usersSnap.forEach((docSnap) => {
    if (parseBool(docSnap.data().isSuspended)) {
      suspendedClients += 1;
    } else {
      activeClients += 1;
    }
  });

  let activeVendors = 0;
  let suspendedVendors = 0;
  vendorsSnap.forEach((docSnap) => {
    const data = docSnap.data();
    const isSuspended = parseBool(data.isSuspended);
    const approved = data.status === 'approved';

    if (isSuspended) {
      suspendedVendors += 1;
      return;
    }

    if (approved) {
      activeVendors += 1;
    }
  });

  return {
    allClients: usersSnap.size,
    activeClients,
    suspendedClients,
    allVendors: vendorsSnap.size,
    activeVendors,
    suspendedVendors,
    admins: adminsSnap.size,
  };
};

const getRecipientsByAudience = async (
  audience: CommunicationAudience,
  options?: { recipientIds?: string[] }
): Promise<Recipient[]> => {
  if (audience === 'individual_client' || audience === 'individual_vendor') {
    const ids = (options?.recipientIds ?? []).filter(Boolean);
    if (ids.length === 0) return [];

    const collectionName = audience === 'individual_client' ? 'users' : 'vendors';
    const nameField = audience === 'individual_client' ? 'name' : 'businessName';

    const snaps = await Promise.all(
      ids.map((id) => getDoc(doc(db, collectionName, id)))
    );

    return snaps
      .filter((snap) => snap.exists())
      .map((snap) => parseRecipient(snap.id, snap.data() as Record<string, unknown>, nameField));
  }

  if (audience === 'admins') {
    const adminsSnap = await getDocs(collection(db, 'adminUsers'));
    return adminsSnap.docs.map((docSnap) =>
      parseRecipient(docSnap.id, docSnap.data() as Record<string, unknown>, 'displayName')
    );
  }

  if (audience === 'all_clients' || audience === 'active_clients' || audience === 'suspended_clients') {
    const usersSnap = await getDocs(collection(db, 'users'));

    return usersSnap.docs
      .filter((docSnap) => {
        const isSuspended = parseBool(docSnap.data().isSuspended);
        if (audience === 'all_clients') return true;
        if (audience === 'active_clients') return !isSuspended;
        return isSuspended;
      })
      .map((docSnap) => parseRecipient(docSnap.id, docSnap.data() as Record<string, unknown>, 'name'));
  }

  const vendorsSnap = await getDocs(collection(db, 'vendors'));
  return vendorsSnap.docs
    .filter((docSnap) => {
      const data = docSnap.data();
      const isSuspended = parseBool(data.isSuspended);
      const approved = data.status === 'approved';

      if (audience === 'all_vendors') return true;
      if (audience === 'active_vendors') return approved && !isSuspended;
      return isSuspended;
    })
    .map((docSnap) => parseRecipient(docSnap.id, docSnap.data() as Record<string, unknown>, 'businessName'));
};

export const listCommunicationRecipients = async (
  role: CommunicationRecipientRole,
  searchTerm = '',
  maxResults = 30
): Promise<Recipient[]> => {
  const collectionName = role === 'client' ? 'users' : 'vendors';
  const preferredNameField = role === 'client' ? 'name' : 'businessName';
  const snap = await getDocs(collection(db, collectionName));
  const term = searchTerm.trim().toLowerCase();

  const recipients = snap.docs
    .map((docSnap) => parseRecipient(docSnap.id, docSnap.data() as Record<string, unknown>, preferredNameField))
    .filter((recipient) => {
      if (!term) return true;
      return (
        recipient.label.toLowerCase().includes(term) ||
        recipient.email?.toLowerCase().includes(term) ||
        recipient.id.toLowerCase().includes(term)
      );
    })
    .slice(0, Math.max(1, maxResults));

  return recipients;
};

export const previewCommunicationAudience = async (
  audience: CommunicationAudience,
  sampleSize = 5
): Promise<{ total: number; sample: Recipient[] }> => {
  const recipients = await getRecipientsByAudience(audience);
  return {
    total: recipients.length,
    sample: recipients.slice(0, sampleSize),
  };
};

export const sendAdminCommunication = async (
  draft: CommunicationDraft,
  createdBy: string
): Promise<{ communicationId: string | null; attempted: number; delivered: number }> => {
  const title = draft.title.trim();
  const message = draft.message.trim();

  if (!title || !message) {
    throw new Error('Title and message are required.');
  }

  const recipients = await getRecipientsByAudience(draft.audience, {
    recipientIds: draft.recipientIds,
  });

  if (recipients.length === 0) {
    return { communicationId: null, attempted: 0, delivered: 0 };
  }

  const trimmedLink = draft.link?.trim();
  const communicationRef = await addDoc(collection(db, 'admin_communications'), {
    title,
    message,
    type: draft.type,
    audience: draft.audience,
    link: trimmedLink || null,
    recipientIds: draft.recipientIds ?? [],
    attemptedCount: recipients.length,
    deliveredCount: 0,
    status: 'processing',
    createdBy,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });

  const batchChunkSize = 400;
  let delivered = 0;

  for (let i = 0; i < recipients.length; i += batchChunkSize) {
    const chunk = recipients.slice(i, i + batchChunkSize);
    const batch = writeBatch(db);

    chunk.forEach((recipient) => {
      const notificationRef = doc(collection(db, 'notifications'));
      batch.set(notificationRef, {
        // Keep both legacy and canonical recipient fields for compatibility.
        userId: recipient.id,
        recipientId: recipient.id,
        title,
        message,
        type: draft.type,
        ...(trimmedLink ? { link: trimmedLink } : {}),
        isRead: false,
        read: false,
        source: 'admin_communication',
        communicationId: communicationRef.id,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      });
    });

    await batch.commit();
    delivered += chunk.length;
  }

  await updateDoc(communicationRef, {
    deliveredCount: delivered,
    status: delivered === recipients.length ? 'sent' : 'partial',
    updatedAt: serverTimestamp(),
  });

  return {
    communicationId: communicationRef.id,
    attempted: recipients.length,
    delivered,
  };
};

export const getRecentCommunications = async (maxResults = 20): Promise<CommunicationSummary[]> => {
  const q = query(collection(db, 'admin_communications'), orderBy('createdAt', 'desc'), limit(maxResults));
  const snapshot = await getDocs(q);
  return snapshot.docs.map(
    (docSnap) => ({ id: docSnap.id, ...docSnap.data() }) as CommunicationSummary
  );
};
