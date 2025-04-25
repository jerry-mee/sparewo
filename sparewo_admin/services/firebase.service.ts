// Firebase service with proper initialization for static export

import { initializeApp, getApps, getApp, FirebaseApp } from 'firebase/app';
import {
  getFirestore,
  collection,
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
  deleteDoc,
  query,
  where,
  orderBy,
  onSnapshot,
  DocumentData,
  QueryConstraint,
  Firestore,
} from 'firebase/firestore';
import {
  getAuth,
  signInWithEmailAndPassword,
  signOut,
  onAuthStateChanged,
  Auth,
  User,
} from 'firebase/auth';
import { getStorage } from 'firebase/storage';

// Enums for status values
export enum VendorStatus {
  PENDING = 'pending',
  APPROVED = 'approved',
  REJECTED = 'rejected',
  SUSPENDED = 'suspended',
}

export enum ProductStatus {
  PENDING = 'pending',
  APPROVED = 'approved',
  REJECTED = 'rejected',
  OUTOFSTOCK = 'outofstock',
  DISCONTINUED = 'discontinued',
}

// Create a singleton for Firebase app
let firebaseApp: FirebaseApp | null = null;
let firestoreDB: Firestore | null = null;
let firebaseAuth: Auth | null = null;
let firebaseStorage: any | null = null;

// Safe initialization function for Firebase
const initializeFirebase = () => {
  try {
    // Skip initialization during build
    if (typeof window === 'undefined') {
      return null;
    }

    const firebaseConfig = {
      apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
      authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
      projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
      storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
      messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
      appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
    };

    // Initialize Firebase only once
    if (!firebaseApp) {
      firebaseApp = getApps().length > 0 ? getApp() : initializeApp(firebaseConfig);
      firestoreDB = getFirestore(firebaseApp);
      firebaseAuth = getAuth(firebaseApp);
      firebaseStorage = getStorage(firebaseApp);
    }

    return {
      app: firebaseApp,
      db: firestoreDB,
      auth: firebaseAuth,
      storage: firebaseStorage,
    };
  } catch (error) {
    console.error('Error initializing Firebase:', error);
    return null;
  }
};

// Initialize on import (client-side only)
if (typeof window !== 'undefined') {
  initializeFirebase();
}

// Connection manager for monitoring Firebase connectivity
export const connectionManager = {
  listeners: [] as ((isConnected: boolean) => void)[],
  
  addConnectionListener(callback: (isConnected: boolean) => void) {
    this.listeners.push(callback);
    return () => {
      this.listeners = this.listeners.filter(listener => listener !== callback);
    };
  },
  
  notifyConnectionChange(isConnected: boolean) {
    this.listeners.forEach(listener => listener(isConnected));
  }
};

// Auth service
export const authService = {
  async signIn(email: string, password: string) {
    try {
      if (!firebaseAuth) {
        const firebase = initializeFirebase();
        if (!firebase || !firebase.auth) {
          throw new Error('Firebase Auth not initialized');
        }
        firebaseAuth = firebase.auth;
      }
      
      return await signInWithEmailAndPassword(firebaseAuth, email, password);
    } catch (error) {
      console.error('Error signing in:', error);
      throw error;
    }
  },

  async signOut() {
    try {
      if (!firebaseAuth) {
        const firebase = initializeFirebase();
        if (!firebase || !firebase.auth) {
          throw new Error('Firebase Auth not initialized');
        }
        firebaseAuth = firebase.auth;
      }
      
      await signOut(firebaseAuth);
    } catch (error) {
      console.error('Error signing out:', error);
      throw error;
    }
  },

  onAuthStateChanged(callback: (user: User | null) => void) {
    try {
      if (!firebaseAuth) {
        const firebase = initializeFirebase();
        if (!firebase || !firebase.auth) {
          throw new Error('Firebase Auth not initialized');
        }
        firebaseAuth = firebase.auth;
      }
      
      return onAuthStateChanged(firebaseAuth, callback);
    } catch (error) {
      console.error('Error setting auth state listener:', error);
      throw error;
    }
  },

  getCurrentUser() {
    try {
      if (!firebaseAuth) {
        const firebase = initializeFirebase();
        if (!firebase || !firebase.auth) {
          throw new Error('Firebase Auth not initialized');
        }
        firebaseAuth = firebase.auth;
      }
      
      return firebaseAuth.currentUser;
    } catch (error) {
      console.error('Error getting current user:', error);
      throw error;
    }
  },
};
// Vendor service
export const vendorService = {
  async getVendor(id: string) {
    try {
      if (!firestoreDB) {
        const firebase = initializeFirebase();
        if (!firebase || !firebase.db) {
          throw new Error('Firestore not initialized');
        }
        firestoreDB = firebase.db;
      }
      
      const vendorDoc = await getDoc(doc(firestoreDB, 'vendors', id));
      if (vendorDoc.exists()) {
        return { id: vendorDoc.id, ...vendorDoc.data() };
      }
      return null;
    } catch (error) {
      console.error('Error getting vendor:', error);
      throw error;
    }
  },

  async getPendingVendors() {
    try {
      if (!firestoreDB) {
        const firebase = initializeFirebase();
        if (!firebase || !firebase.db) {
          throw new Error('Firestore not initialized');
        }
        firestoreDB = firebase.db;
      }
      
      const q = query(
        collection(firestoreDB, 'vendors'),
        where('status', '==', VendorStatus.PENDING)
      );
      
      const vendorsSnapshot = await getDocs(q);
      return vendorsSnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));
    } catch (error) {
      console.error('Error getting pending vendors:', error);
      throw error;
    }
  },

  listenToVendors(callback: (vendors: DocumentData[]) => void) {
    try {
      if (!firestoreDB) {
        const firebase = initializeFirebase();
        if (!firebase || !firebase.db) {
          throw new Error('Firestore not initialized');
        }
        firestoreDB = firebase.db;
      }
      
      const vendorsCollection = collection(firestoreDB, 'vendors');
      
      return onSnapshot(vendorsCollection, (snapshot) => {
        const vendors = snapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        }));
        callback(vendors);
      }, (error) => {
        console.error('Error listening to vendors:', error);
        // Notify connection change if it's a network error
        if (error.code === 'unavailable' || error.message?.includes('network') || error.message?.includes('connection')) {
          connectionManager.notifyConnectionChange(false);
        }
      });
    } catch (error) {
      console.error('Error setting up vendors listener:', error);
      throw error;
    }
  },

  async updateVendorStatus(id: string, status: VendorStatus) {
    try {
      if (!firestoreDB) {
        const firebase = initializeFirebase();
        if (!firebase || !firebase.db) {
          throw new Error('Firestore not initialized');
        }
        firestoreDB = firebase.db;
      }
      
      const vendorRef = doc(firestoreDB, 'vendors', id);
      await updateDoc(vendorRef, {
        status,
        statusUpdatedAt: new Date(),
      });
    } catch (error) {
      console.error('Error updating vendor status:', error);
      throw error;
    }
  },
};
// Product service
export const productService = {
  async getProduct(id: string) {
    try {
      if (!firestoreDB) {
        const firebase = initializeFirebase();
        if (!firebase || !firebase.db) {
          throw new Error('Firestore not initialized');
        }
        firestoreDB = firebase.db;
      }
      
      const productDoc = await getDoc(doc(firestoreDB, 'products', id));
      if (productDoc.exists()) {
        return { id: productDoc.id, ...productDoc.data() };
      }
      return null;
    } catch (error) {
      console.error('Error getting product:', error);
      throw error;
    }
  },

  async getPendingProducts() {
    try {
      if (!firestoreDB) {
        const firebase = initializeFirebase();
        if (!firebase || !firebase.db) {
          throw new Error('Firestore not initialized');
        }
        firestoreDB = firebase.db;
      }
      
      const q = query(
        collection(firestoreDB, 'products'),
        where('status', '==', ProductStatus.PENDING)
      );
      
      const productsSnapshot = await getDocs(q);
      return productsSnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));
    } catch (error) {
      console.error('Error getting pending products:', error);
      throw error;
    }
  },

  listenToProducts(callback: (products: DocumentData[]) => void) {
    try {
      if (!firestoreDB) {
        const firebase = initializeFirebase();
        if (!firebase || !firebase.db) {
          throw new Error('Firestore not initialized');
        }
        firestoreDB = firebase.db;
      }
      
      const productsCollection = collection(firestoreDB, 'products');
      
      return onSnapshot(productsCollection, (snapshot) => {
        const products = snapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        }));
        callback(products);
      }, (error) => {
        console.error('Error listening to products:', error);
        // Notify connection change if it's a network error
        if (error.code === 'unavailable' || error.message?.includes('network') || error.message?.includes('connection')) {
          connectionManager.notifyConnectionChange(false);
        }
      });
    } catch (error) {
      console.error('Error setting up products listener:', error);
      throw error;
    }
  },

  async updateProductStatus(id: string, status: ProductStatus) {
    try {
      if (!firestoreDB) {
        const firebase = initializeFirebase();
        if (!firebase || !firebase.db) {
          throw new Error('Firestore not initialized');
        }
        firestoreDB = firebase.db;
      }
      
      const productRef = doc(firestoreDB, 'products', id);
      await updateDoc(productRef, {
        status,
        statusUpdatedAt: new Date(),
      });
    } catch (error) {
      console.error('Error updating product status:', error);
      throw error;
    }
  },

  async addProduct(productData: any) {
    try {
      if (!firestoreDB) {
        const firebase = initializeFirebase();
        if (!firebase || !firebase.db) {
          throw new Error('Firestore not initialized');
        }
        firestoreDB = firebase.db;
      }
      
      const productsCollection = collection(firestoreDB, 'products');
      const newProductRef = doc(productsCollection);
      
      await setDoc(newProductRef, {
        ...productData,
        createdAt: new Date(),
        updatedAt: new Date(),
      });
      
      return newProductRef.id;
    } catch (error) {
      console.error('Error adding product:', error);
      throw error;
    }
  },
};

// Order service
export const orderService = {
  listenToOrders(callback: (orders: DocumentData[]) => void) {
    try {
      if (!firestoreDB) {
        const firebase = initializeFirebase();
        if (!firebase || !firebase.db) {
          throw new Error('Firestore not initialized');
        }
        firestoreDB = firebase.db;
      }
      
      const ordersCollection = collection(firestoreDB, 'orders');
      
      return onSnapshot(ordersCollection, (snapshot) => {
        const orders = snapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        }));
        callback(orders);
      }, (error) => {
        console.error('Error listening to orders:', error);
        // Notify connection change if it's a network error
        if (error.code === 'unavailable' || error.message?.includes('network') || error.message?.includes('connection')) {
          connectionManager.notifyConnectionChange(false);
        }
      });
    } catch (error) {
      console.error('Error setting up orders listener:', error);
      throw error;
    }
  },
};

// Default export
export default {
  initializeFirebase,
  authService,
  vendorService,
  productService,
  orderService,
  connectionManager,
};
