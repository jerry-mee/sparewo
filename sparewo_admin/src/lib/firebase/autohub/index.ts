import {
  addDoc,
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
  FieldValue,
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
  email?: string;
  createdAt?: Timestamp | Date;
  updatedAt?: Timestamp | Date;
}

export interface ServiceProviderInput {
  name: string;
  type: ServiceProvider['type'];
  phone: string;
  address: string;
  email?: string;
}

export const getServiceBookings = async (
  status?: string,
  pageSize: number = 10,
  lastDoc?: DocumentData
): Promise<{ bookings: ServiceBooking[]; lastDoc: DocumentData | undefined }> => {
  try {
    const constraints: QueryConstraint[] = [orderBy('createdAt', 'desc')];

    if (status && status !== 'all') {
      constraints.push(where('status', '==', status));
    }

    let q = query(collection(db, 'service_bookings'), ...constraints, limit(pageSize));

    if (lastDoc) {
      q = query(q, startAfter(lastDoc));
    }

    const querySnapshot = await getDocs(q);
    const bookings: ServiceBooking[] = [];
    let lastVisible: DocumentData | undefined;

    querySnapshot.forEach((docSnap) => {
      const data = docSnap.data();
      bookings.push({
        id: docSnap.id,
        ...data,
        pickupDate: data.pickupDate,
        createdAt: data.createdAt,
        updatedAt: data.updatedAt,
      } as ServiceBooking);
      lastVisible = docSnap;
    });

    return { bookings, lastDoc: lastVisible };
  } catch (error) {
    console.error('Error getting bookings:', error);
    throw error;
  }
};

export const getTotalBookingCount = async (status?: string): Promise<number> => {
  try {
    const q = status
      ? query(collection(db, 'service_bookings'), where('status', '==', status))
      : query(collection(db, 'service_bookings'));
    const snapshot = await getDocs(q);
    return snapshot.size;
  } catch (error) {
    console.error('Error counting bookings:', error);
    return 0;
  }
};

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

export const updateBookingStatus = async (
  bookingId: string,
  status: ServiceBooking['status'],
  notes?: string
): Promise<void> => {
  try {
    const docRef = doc(db, 'service_bookings', bookingId);

    const updateData: Record<string, string | FieldValue> = {
      status,
      updatedAt: serverTimestamp(),
    };

    if (typeof notes === 'string') {
      updateData.adminNotes = notes;
    }

    await updateDoc(docRef, updateData);
  } catch (error) {
    console.error('Error updating booking:', error);
    throw error;
  }
};

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
      status: 'confirmed',
      updatedAt: serverTimestamp(),
    });
  } catch (error) {
    console.error('Error assigning provider:', error);
    throw error;
  }
};

export const getServiceProviders = async (): Promise<ServiceProvider[]> => {
  try {
    const q = query(
      collection(db, 'service_providers'),
      where('isActive', '==', true),
      orderBy('name', 'asc')
    );
    const querySnapshot = await getDocs(q);
    return querySnapshot.docs.map((docSnap) => ({ id: docSnap.id, ...docSnap.data() }) as ServiceProvider);
  } catch (error) {
    console.error('Error getting active providers:', error);
    return [];
  }
};

export const getAllServiceProviders = async (): Promise<ServiceProvider[]> => {
  try {
    const q = query(collection(db, 'service_providers'), orderBy('name', 'asc'));
    const querySnapshot = await getDocs(q);
    return querySnapshot.docs.map((docSnap) => ({ id: docSnap.id, ...docSnap.data() }) as ServiceProvider);
  } catch (error) {
    console.error('Error getting all providers:', error);
    return [];
  }
};

export const createServiceProvider = async (provider: ServiceProviderInput): Promise<string> => {
  try {
    const payload = {
      ...provider,
      isActive: true,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    };

    const docRef = await addDoc(collection(db, 'service_providers'), payload);
    return docRef.id;
  } catch (error) {
    console.error('Error creating provider:', error);
    throw error;
  }
};

export const toggleServiceProviderActive = async (
  providerId: string,
  isActive: boolean
): Promise<void> => {
  try {
    const docRef = doc(db, 'service_providers', providerId);
    await updateDoc(docRef, {
      isActive,
      updatedAt: serverTimestamp(),
    });
  } catch (error) {
    console.error('Error updating provider status:', error);
    throw error;
  }
};
