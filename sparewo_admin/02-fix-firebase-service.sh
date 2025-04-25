#!/bin/bash

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BOLD}${GREEN}===== SpareWo Admin: Firebase Service Fix (2/3) =====${NC}"
echo -e "This script will update your Firebase service to work with static exports."

# Print progress function
print_progress() {
  local width=50
  local percent=$1
  local completed=$((width * percent / 100))
  local remaining=$((width - completed))
  
  printf "[${GREEN}"
  printf "%${completed}s" | tr ' ' '='
  printf ">${NC}"
  printf "%${remaining}s" | tr ' ' ' '
  printf "] %d%%\n" "$percent"
}

# Create Firebase utility file
echo -e "\n${BLUE}[STEP 1]${NC} Creating Firebase utility helpers..."
mkdir -p lib
cat > lib/firebase-utils.ts << 'EOL'
import { 
  Firestore, 
  DocumentReference, 
  CollectionReference, 
  collection as firestoreCollection,
  doc as firestoreDoc,
  DocumentData,
} from "firebase/firestore";
import { Auth } from "firebase/auth";
import { FirebaseStorage, StorageReference, ref as storageRef } from "firebase/storage";
import { Functions } from "firebase/functions";

/**
 * Safely create a collection reference, ensuring db is not null
 */
export function collection(db: Firestore | null, path: string, ...pathSegments: string[]): CollectionReference<DocumentData> {
  if (!db) {
    throw new Error("Firestore is not initialized");
  }
  return firestoreCollection(db, path, ...pathSegments);
}

/**
 * Safely create a document reference, ensuring db is not null
 */
export function doc(db: Firestore | null, path: string, ...pathSegments: string[]): DocumentReference<DocumentData> {
  if (!db) {
    throw new Error("Firestore is not initialized");
  }
  return firestoreDoc(db, path, ...pathSegments);
}

/**
 * Safely create a storage reference, ensuring storage is not null
 */
export function ref(storage: FirebaseStorage | null, path?: string): StorageReference {
  if (!storage) {
    throw new Error("Firebase Storage is not initialized");
  }
  return storageRef(storage, path);
}

/**
 * Verify auth is initialized
 */
export function verifyAuth(auth: Auth | null): Auth {
  if (!auth) {
    throw new Error("Firebase Auth is not initialized");
  }
  return auth;
}

/**
 * Verify functions is initialized
 */
export function verifyFunctions(functions: Functions | null): Functions {
  if (!functions) {
    throw new Error("Firebase Functions is not initialized");
  }
  return functions;
}

/**
 * Handles safe Firebase function calls with better error messages for static export
 */
export async function safelyCallFunction<T>(
  functionName: string, 
  callback: () => Promise<T>, 
  fallbackValue?: T
): Promise<T> {
  // Skip actual function calls during build or SSR
  if (typeof window === 'undefined') {
    console.log(`Firebase function ${functionName} skipped during build/SSR`);
    return fallbackValue as T;
  }
  
  try {
    return await callback();
  } catch (error) {
    console.error(`Error in Firebase function ${functionName}:`, error);
    
    // Check if it's a network error which is common in static exports
    const isNetworkError = error instanceof Error && 
      (error.message.includes('network') || error.message.includes('connection'));
    
    if (isNetworkError) {
      console.warn(`Network error in ${functionName}. This is expected in static exports.`);
    }
    
    // Return fallback if provided, otherwise re-throw
    if (fallbackValue !== undefined) {
      return fallbackValue;
    }
    throw error;
  }
}
EOL

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓ Successfully created Firebase utility helpers${NC}"
  print_progress 25
else
  echo -e "${RED}✗ Failed to create Firebase utility helpers${NC}"
  exit 1
fi

# Create a hook to track Firebase connection status
echo -e "\n${BLUE}[STEP 2]${NC} Creating Firebase connection hook..."
mkdir -p hooks
cat > hooks/useFirebaseConnection.ts << 'EOL'
import { useState, useEffect } from "react";
import { connectionManager } from "@/services/firebase.service";

/**
 * Hook to monitor Firebase connection status
 * @returns Object containing Firebase connection status and last reconnect attempt time
 */
export function useFirebaseConnection() {
  const [isConnected, setIsConnected] = useState(true);
  const [lastReconnectAttempt, setLastReconnectAttempt] = useState<Date | null>(null);

  useEffect(() => {
    // Use connection manager to track status
    const removeListener = connectionManager.addConnectionListener((connected: boolean) => {
      setIsConnected(connected);
      
      if (!connected) {
        setLastReconnectAttempt(new Date());
      }
    });
    
    // Clean up subscription
    return () => {
      removeListener();
    };
  }, []);

  return { isConnected, lastReconnectAttempt };
}
EOL

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓ Successfully created Firebase connection hook${NC}"
  print_progress 50
else
  echo -e "${RED}✗ Failed to create Firebase connection hook${NC}"
  exit 1
fi

# Backup original firebase.service.ts if it exists
echo -e "\n${BLUE}[STEP 3]${NC} Backing up original firebase.service.ts..."
if [ -f "services/firebase.service.ts" ]; then
  cp services/firebase.service.ts services/firebase.service.ts.bak
  echo -e "${GREEN}✓ Backup created: services/firebase.service.ts.bak${NC}"
else
  echo -e "${YELLOW}! No existing firebase.service.ts found. Will create a new one.${NC}"
  mkdir -p services
fi
print_progress 75

# Create updated Firebase service
echo -e "\n${BLUE}[STEP 4]${NC} Creating optimized Firebase service..."
# First part of the file (we'll split it to ensure it works)
cat > services/firebase.service.ts << 'EOL'
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
import { getStorage, Storage } from 'firebase/storage';

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
let firebaseStorage: Storage | null = null;

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
EOL

# Append the second part of the file
cat >> services/firebase.service.ts << 'EOL'
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
        if (error.code === 'unavailable' || error.code === 'network-request-failed') {
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
EOL

# Append the third part of the file
cat >> services/firebase.service.ts << 'EOL'
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
        if (error.code === 'unavailable' || error.code === 'network-request-failed') {
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
        if (error.code === 'unavailable' || error.code === 'network-request-failed') {
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
EOL

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓ Successfully created optimized Firebase service${NC}"
  print_progress 100
else
  echo -e "${RED}✗ Failed to create Firebase service${NC}"
  exit 1
fi

echo -e "\n${BOLD}${GREEN}Second fix script completed successfully!${NC}"
echo -e "Please run the next script (03-fix-dynamic-routes.sh) after confirming these changes."