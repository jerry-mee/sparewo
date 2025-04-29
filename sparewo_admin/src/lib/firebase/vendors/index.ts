import {
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  where,
  orderBy,
  limit,
  updateDoc,
  serverTimestamp,
  DocumentData,
  QueryConstraint,
  startAfter
} from 'firebase/firestore';
import { db } from '../config';
import { Vendor } from '@/lib/types/vendor';

// Get all vendors with pagination
export const getVendors = async (
  status: string | null = null,
  pageSize: number = 10,
  lastDoc?: DocumentData
): Promise<{ vendors: Vendor[], lastDoc: DocumentData | undefined }> => {
  try {
    // Build query constraints
    const constraints: QueryConstraint[] = [orderBy('createdAt', 'desc')];

    if (status) {
      constraints.push(where('status', '==', status));
    }

    let q = query(
      collection(db, 'vendors'),
      ...constraints,
      limit(pageSize)
    );

    if (lastDoc) {
      q = query(q, startAfter(lastDoc));
    }

    const querySnapshot = await getDocs(q);

    const vendors: Vendor[] = [];
    let lastVisible: DocumentData | undefined = undefined;

    querySnapshot.forEach((doc) => {
      vendors.push({ id: doc.id, ...doc.data() } as Vendor);
      lastVisible = doc;
    });

    return { vendors, lastDoc: lastVisible };
  } catch (error) {
    console.error('Error getting vendors:', error);
    throw error;
  }
};

// Get vendor by ID
export const getVendorById = async (id: string): Promise<Vendor | null> => {
  try {
    const docRef = doc(db, 'vendors', id);
    const docSnap = await getDoc(docRef);

    if (docSnap.exists()) {
      return { id: docSnap.id, ...docSnap.data() } as Vendor;
    }

    return null;
  } catch (error) {
    console.error('Error getting vendor:', error);
    throw error;
  }
};

// Get pending vendors
export const getPendingVendors = async (
  pageSize: number = 10,
  lastDoc?: DocumentData
): Promise<{ vendors: Vendor[], lastDoc: DocumentData | undefined }> => {
  return getVendors('pending', pageSize, lastDoc);
};

// Update vendor status
export const updateVendorStatus = async (
  id: string,
  status: 'pending' | 'approved' | 'rejected',
  rejectionReason?: string
): Promise<void> => {
  try {
    const docRef = doc(db, 'vendors', id);

    const updateData: any = {
      status,
      updatedAt: serverTimestamp(),
    };

    if (status === 'approved') {
      updateData.approvedAt = serverTimestamp();
    }

    if (status === 'rejected' && rejectionReason) {
      updateData.rejectionReason = rejectionReason;
      updateData.rejectedAt = serverTimestamp();
    }

    await updateDoc(docRef, updateData);
  } catch (error) {
    console.error('Error updating vendor status:', error);
    throw error;
  }
};

// Count vendors by status
export const countVendorsByStatus = async (status: string): Promise<number> => {
  try {
    const q = query(
      collection(db, 'vendors'),
      where('status', '==', status)
    );

    const querySnapshot = await getDocs(q);
    return querySnapshot.size;
  } catch (error) {
    console.error('Error counting vendors by status:', error);
    throw error;
  }
};

// Get total vendor count
export const getTotalVendorCount = async (): Promise<number> => {
  try {
    const querySnapshot = await getDocs(collection(db, 'vendors'));
    return querySnapshot.size;
  } catch (error) {
    console.error('Error getting total vendor count:', error);
    throw error;
  }
};
