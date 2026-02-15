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
  startAfter,
  Timestamp,
  FieldValue
} from 'firebase/firestore';
import { db } from '../config';

export interface ServiceBooking {
  id: string;
  bookingNumber: string;
  userId: string;
  userName: string;
  userEmail: string;
  userPhone: string;
  vehicleBrand: string;
  vehicleModel: string;
  vehicleYear: number;
  services: string[];
  serviceDescription: string;
  pickupDate: Timestamp | Date;
  pickupTime: string;
  pickupLocation: string;
  status: 'pending' | 'confirmed' | 'in_progress' | 'completed' | 'cancelled';
  assignedProviderId?: string;
  assignedProviderName?: string;
  adminNotes?: string;
  createdAt: Timestamp | Date;
  updatedAt: Timestamp | Date;
}

export interface ServiceProvider {
  id: string;
  name: string;
  type: 'mechanic' | 'garage' | 'towing';
  phone: string;
  address: string;
  isActive: boolean;
}

// Get bookings with filters
export const getServiceBookings = async (
  status?: string,
  pageSize: number = 10,
  lastDoc?: DocumentData
): Promise<{ bookings: ServiceBooking[], lastDoc: DocumentData | undefined }> => {
  try {
    const constraints: QueryConstraint[] = [orderBy('createdAt', 'desc')];
    
    if (status && status !== 'all') {
      constraints.push(where('status', '==', status));
    }
    
    let q = query(
      collection(db, 'service_bookings'),
      ...constraints,
      limit(pageSize)
    );
    
    if (lastDoc) {
      q = query(q, startAfter(lastDoc));
    }
    
    const querySnapshot = await getDocs(q);
    const bookings: ServiceBooking[] = [];
    let lastVisible: DocumentData | undefined = undefined;
    
    querySnapshot.forEach((doc) => {
      const data = doc.data();
      bookings.push({ 
        id: doc.id, 
        ...data,
        pickupDate: data.pickupDate,
        createdAt: data.createdAt,
        updatedAt: data.updatedAt
      } as ServiceBooking);
      lastVisible = doc;
    });
    
    return { bookings, lastDoc: lastVisible };
  } catch (error) {
    console.error('Error getting bookings:', error);
    throw error;
  }
};

// NEW: Get total booking count for stats
export const getTotalBookingCount = async (status?: string): Promise<number> => {
  try {
    let q;
    if (status) {
      q = query(collection(db, 'service_bookings'), where('status', '==', status));
    } else {
      q = query(collection(db, 'service_bookings'));
    }
    const snapshot = await getDocs(q);
    return snapshot.size;
  } catch (error) {
    console.error('Error counting bookings:', error);
    return 0;
  }
};

// Get single booking
export const getBookingById = async (id: string): Promise<ServiceBooking | null> => {
  try {
    const docRef = doc(db, 'service_bookings', id);
    const docSnap = await getDoc(docRef);
    if (docSnap.exists()) {
      return { id: docSnap.id, ...docSnap.data() } as ServiceBooking;
    }
    return null;
  } catch (error) {
    console.error('Error getting booking:', error);
    throw error;
  }
};

// Update booking status
export const updateBookingStatus = async (
  bookingId: string, 
  status: ServiceBooking['status'],
  notes?: string
): Promise<void> => {
  try {
    const docRef = doc(db, 'service_bookings', bookingId);
    
    const updateData: Record<string, string | FieldValue> = {
      status,
      updatedAt: serverTimestamp()
    };
    
    if (notes) updateData.adminNotes = notes;
    
    await updateDoc(docRef, updateData);
  } catch (error) {
    console.error('Error updating booking:', error);
    throw error;
  }
};

// Assign Provider
export const assignProviderToBooking = async (
  bookingId: string,
  providerId: string,
  providerName: string
): Promise<void> => {
  try {
    const docRef = doc(db, 'service_bookings', bookingId);
    await updateDoc(docRef, {
      assignedProviderId: providerId,
      assignedProviderName: providerName,
      status: 'confirmed', // Auto-confirm when assigning
      updatedAt: serverTimestamp()
    });
  } catch (error) {
    console.error('Error assigning provider:', error);
    throw error;
  }
};

// Fetch Providers
export const getServiceProviders = async (): Promise<ServiceProvider[]> => {
  try {
    const q = query(collection(db, 'service_providers'), where('isActive', '==', true));
    const querySnapshot = await getDocs(q);
    return querySnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as ServiceProvider));
  } catch (error) {
    console.error('Error getting providers:', error);
    return [];
  }
};