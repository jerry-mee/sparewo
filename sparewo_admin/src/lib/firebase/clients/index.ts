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
  Timestamp
} from 'firebase/firestore';
import { db } from '../config';

// Types based on your Client App structure
export interface UserProfile {
  id: string;
  name: string;
  email: string;
  phone?: string;
  photoUrl?: string;
  isSuspended?: boolean;
  createdAt: Timestamp | Date;
  lastLogin?: Timestamp | Date;
}

export interface UserCar {
  id: string;
  make: string;
  model: string;
  year: number;
  plateNumber?: string;
  color?: string;
  vin?: string;
  imageUrl?: string;
  createdAt: Timestamp | Date;
}

export interface ClientOrder {
  id: string;
  orderNumber: string;
  totalAmount: number;
  status: string;
  createdAt: Timestamp | Date;
  itemCount: number;
}

export interface ClientBooking {
  id: string;
  bookingNumber: string;
  vehicleBrand: string;
  vehicleModel: string;
  services: string[];
  status: string;
  pickupDate: Timestamp | Date;
  createdAt: Timestamp | Date;
}

// Get all clients with pagination
export const getClients = async (
  searchQuery: string = '',
  pageSize: number = 10,
  lastDoc?: DocumentData
): Promise<{ clients: UserProfile[], lastDoc: DocumentData | undefined }> => {
  try {
    const constraints: QueryConstraint[] = [orderBy('createdAt', 'desc')];
    
    let q = query(
      collection(db, 'users'),
      ...constraints,
      limit(pageSize)
    );
    
    if (lastDoc) {
      q = query(q, startAfter(lastDoc));
    }
    
    const querySnapshot = await getDocs(q);
    
    const clients: UserProfile[] = [];
    let lastVisible: DocumentData | undefined = undefined;
    
    querySnapshot.forEach((doc) => {
      const data = doc.data();
      if (searchQuery) {
        const name = (data.name || '').toLowerCase();
        const email = (data.email || '').toLowerCase();
        const query = searchQuery.toLowerCase();
        if (!name.includes(query) && !email.includes(query)) {
          return; 
        }
      }

      clients.push({ 
        id: doc.id, 
        name: data.name || 'Unknown User',
        email: data.email || '',
        phone: data.phone,
        photoUrl: data.photoUrl,
        isSuspended: data.isSuspended || false,
        createdAt: data.createdAt,
        lastLogin: data.lastLogin
      });
      lastVisible = doc;
    });
    
    return { clients, lastDoc: lastVisible };
  } catch (error) {
    console.error('Error getting clients:', error);
    throw error;
  }
};

// NEW: Get total count of clients
export const getTotalClientCount = async (): Promise<number> => {
  try {
    const q = query(collection(db, 'users'));
    const snapshot = await getDocs(q);
    return snapshot.size;
  } catch (error) {
    console.error('Error counting clients:', error);
    return 0;
  }
};

export const getClientById = async (id: string): Promise<UserProfile | null> => {
  try {
    const docRef = doc(db, 'users', id);
    const docSnap = await getDoc(docRef);

    if (docSnap.exists()) {
      const data = docSnap.data();
      return { 
        id: docSnap.id, 
        name: data.name || 'Unknown',
        email: data.email || '',
        ...data 
      } as UserProfile;
    }

    return null;
  } catch (error) {
    console.error('Error getting client:', error);
    throw error;
  }
};

export const getClientCars = async (userId: string): Promise<UserCar[]> => {
  try {
    const q = query(
      collection(db, 'users', userId, 'cars'),
      orderBy('createdAt', 'desc')
    );

    const querySnapshot = await getDocs(q);
    return querySnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    } as UserCar));
  } catch (error) {
    console.error('Error getting client cars:', error);
    return [];
  }
};

export const getClientOrders = async (userId: string): Promise<ClientOrder[]> => {
  try {
    const q = query(
      collection(db, 'orders'),
      where('userId', '==', userId), 
      orderBy('createdAt', 'desc') 
    );

    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => {
      const data = doc.data();
      return {
        id: doc.id,
        orderNumber: data.orderNumber || doc.id.substring(0,8),
        totalAmount: data.totalAmount || 0,
        status: data.status || 'pending',
        createdAt: data.createdAt,
        itemCount: Array.isArray(data.items) ? data.items.length : 0
      };
    });
  } catch (error) {
    console.error("Error fetching client orders:", error);
    return [];
  }
};

export const getClientBookings = async (userId: string): Promise<ClientBooking[]> => {
  try {
    const q = query(
      collection(db, 'service_bookings'),
      where('userId', '==', userId),
      orderBy('createdAt', 'desc')
    );

    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => {
      const data = doc.data();
      return {
        id: doc.id,
        bookingNumber: data.bookingNumber || 'N/A',
        vehicleBrand: data.vehicleBrand,
        vehicleModel: data.vehicleModel,
        services: data.services || [],
        status: data.status || 'pending',
        pickupDate: data.pickupDate,
        createdAt: data.createdAt
      };
    });
  } catch (error) {
    console.error("Error fetching client bookings:", error);
    return [];
  }
};

export const toggleClientSuspension = async (userId: string, suspend: boolean): Promise<void> => {
  try {
    const docRef = doc(db, 'users', userId);
    await updateDoc(docRef, {
      isSuspended: suspend,
      updatedAt: serverTimestamp()
    });
  } catch (error) {
    console.error('Error updating client suspension:', error);
    throw error;
  }
};