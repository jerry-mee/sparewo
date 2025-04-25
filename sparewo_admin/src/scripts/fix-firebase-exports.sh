#!/bin/bash

echo "Fixing Firebase service exports..."

# Create a backup of the firebase.service.ts file
cp src/services/firebase.service.ts src/services/firebase.service.ts.backup

# Create a fixed version of firebase.service.ts that properly exports the variables
cat > src/services/firebase.service.ts << 'EOF'
// src/services/firebase.service.ts
import { 
  getAuth, 
  signInWithEmailAndPassword, 
  signOut, 
  onAuthStateChanged,
  User 
} from "firebase/auth";
import { 
  collection, 
  doc,
  getFirestore, 
  onSnapshot, 
  addDoc, 
  updateDoc, 
  deleteDoc, 
  getDocs,
  query,
  where,
  getDoc,
  orderBy,
  Timestamp,
  enableNetwork,
  disableNetwork,
  enableIndexedDbPersistence,
  setLogLevel
} from "firebase/firestore";
import { getFunctions } from "firebase/functions";
import { getStorage, ref, uploadBytes, getDownloadURL } from "firebase/storage";
import { initializeApp, FirebaseApp, getApps, getApp } from "firebase/app";
import { getDatabase, ref as rtdbRef, onValue, set } from "firebase/database";

// Type to track connection status
interface ConnectionStatus {
  isConnected: boolean;
  lastOnlineTime: Date | null;
  connectionListeners: Array<(status: boolean) => void>;
}

// Global connection status tracker
const connectionStatus: ConnectionStatus = {
  isConnected: true,
  lastOnlineTime: null,
  connectionListeners: []
};

// Firebase configuration
const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
  databaseURL: process.env.NEXT_PUBLIC_FIREBASE_DATABASE_URL // Ensure this is added for Realtime DB
};

// Initialize Firebase with error handling and singleton pattern
let firebaseApp: FirebaseApp | undefined = undefined;

// Firebase services
export let auth: any = null;
export let db: any = null;
export let storage: any = null;
export let functions: any = null;
export let rtdb: any = null;

// Function to initialize Firebase - returns the app instance
const initializeFirebase = () => {
  try {
    // Check if Firebase is already initialized
    if (getApps().length > 0) {
      return getApp();
    }
    
    // Initialize a new Firebase instance
    const app = initializeApp(firebaseConfig);
    
    // Set log level based on environment
    if (typeof window !== 'undefined') { // Only run in browser environment
      db = getFirestore(app);
      if (process.env.NODE_ENV === "development") {
        setLogLevel("warn");
      } else {
        setLogLevel("error");
      }
      
      // Setup indexed DB persistence for offline capabilities
      // This needs to be called before any other Firestore calls
      enableIndexedDbPersistence(db).catch((error) => {
        console.warn("Persistence initialization failed: ", error);
      });
      
      // Initialize other services
      auth = getAuth(app);
      storage = getStorage(app);
      functions = getFunctions(app);
      
      // Initialize Realtime Database if URL is provided
      if (firebaseConfig.databaseURL) {
        rtdb = getDatabase(app);
        // Monitor connection status using Realtime Database
        const connectedRef = rtdbRef(rtdb, ".info/connected");
        
        onValue(connectedRef, (snapshot) => {
          const isConnected = !!snapshot.val();
          connectionStatus.isConnected = isConnected;
          
          if (isConnected) {
            // Record the time when we go online
            connectionStatus.lastOnlineTime = new Date();
          }
          
          // Notify all listeners
          connectionStatus.connectionListeners.forEach(listener => {
            listener(isConnected);
          });
        });
      }
    }
    
    return app;
  } catch (error) {
    console.error("Firebase initialization error:", error);
    throw error;
  }
};

// Initialize Firebase once in browser environment
if (typeof window !== 'undefined') {
  try {
    firebaseApp = initializeFirebase();
  } catch (error) {
    console.error("Firebase initialization error:", error);
  }
}

// Connection management
export const connectionManager = {
  /**
   * Add a listener for connection status changes
   * @param listener Function to call when connection status changes
   * @returns Function to remove the listener
   */
  addConnectionListener: (listener: (isConnected: boolean) => void) => {
    connectionStatus.connectionListeners.push(listener);
    // Immediately notify with current status
    listener(connectionStatus.isConnected);
    
    // Return a function to remove the listener
    return () => {
      const index = connectionStatus.connectionListeners.indexOf(listener);
      if (index > -1) {
        connectionStatus.connectionListeners.splice(index, 1);
      }
    };
  },
  
  /**
   * Get current connection status
   * @returns Whether Firebase is currently connected
   */
  isConnected: () => connectionStatus.isConnected,
  
  /**
   * Get the last time the app was connected
   * @returns Date object or null if never connected
   */
  getLastOnlineTime: () => connectionStatus.lastOnlineTime,
  
  /**
   * Manually go offline (useful for testing)
   */
  goOffline: async () => {
    if (db) {
      try {
        await disableNetwork(db);
        connectionStatus.isConnected = false;
        // Notify listeners
        connectionStatus.connectionListeners.forEach(listener => {
          listener(false);
        });
      } catch (error) {
        console.error("Error going offline:", error);
      }
    }
  },
  
  /**
   * Manually go online
   */
  goOnline: async () => {
    if (db) {
      try {
        await enableNetwork(db);
        connectionStatus.isConnected = true;
        connectionStatus.lastOnlineTime = new Date();
        // Notify listeners
        connectionStatus.connectionListeners.forEach(listener => {
          listener(true);
        });
      } catch (error) {
        console.error("Error going online:", error);
      }
    }
  }
};

// Error formatter helper
const formatFirebaseError = (error: any): string => {
  // Standard Firebase Auth errors
  if (error.code) {
    switch (error.code) {
      // Auth errors
      case "auth/invalid-email": return "The email address is not valid.";
      case "auth/user-disabled": return "This account has been disabled.";
      case "auth/user-not-found": return "No account found with this email.";
      case "auth/wrong-password": return "Incorrect password.";
      case "auth/email-already-in-use": return "This email is already registered.";
      case "auth/weak-password": return "The password is too weak.";
      case "auth/operation-not-allowed": return "This operation is not allowed.";
      case "auth/account-exists-with-different-credential": return "An account already exists with the same email.";
      
      // Firestore errors
      case "permission-denied": return "You don't have permission to access this resource.";
      case "unavailable": return "The service is currently unavailable. Please try again later.";
      case "not-found": return "The requested document was not found.";
      case "already-exists": return "The document already exists.";
      
      // Generic
      case "failed-precondition": return "Operation failed. Please ensure all conditions are met.";
      case "resource-exhausted": return "Too many requests. Please try again later.";
      
      // Default
      default: return error.message || "An unknown error occurred.";
    }
  }
  
  // Fallback for non-standard errors
  return error.message || "An unknown error occurred.";
};

// Enum for Vendor Status
export enum VendorStatus {
  PENDING = "pending",
  APPROVED = "approved",
  REJECTED = "rejected",
  SUSPENDED = "suspended"
}

// Enum for Product Status
export enum ProductStatus {
  PENDING = "pending",
  APPROVED = "approved",
  REJECTED = "rejected",
  OUTOFSTOCK = "outofstock",
  DISCONTINUED = "discontinued"
}

// Enum for Order Status
export enum OrderStatus {
  PENDING = "pending",
  PROCESSING = "processing",
  SHIPPED = "shipped",
  DELIVERED = "delivered",
  CANCELLED = "cancelled"
}

// Type definitions
export interface Vendor {
  id: string;
  name: string;
  email: string;
  phone?: string;
  businessName: string;
  businessAddress?: string;
  status: VendorStatus | string;
  isVerified?: boolean;
  createdAt: any;
  productCount?: number;
  [key: string]: any;
}

export interface Product {
  id: string;
  name: string;
  description: string;
  price: number;
  vendorId: string;
  vendorName?: string;
  status: ProductStatus | string;
  createdAt: any;
  [key: string]: any;
}

export interface Order {
  id: string;
  customerName: string;
  customerEmail: string;
  customerPhone?: string;
  productIds: string[];
  productNames?: string[];
  totalAmount: number;
  status: OrderStatus | string;
  createdAt: any;
  [key: string]: any;
}

// Auth Services with error handling
export const login = async (email: string, password: string) => {
  if (!auth) throw new Error("Firebase Auth is not initialized");
  
  try {
    return await signInWithEmailAndPassword(auth, email, password);
  } catch (error: any) {
    throw new Error(formatFirebaseError(error));
  }
};

export const logout = async () => {
  if (!auth) throw new Error("Firebase Auth is not initialized");
  
  try {
    return await signOut(auth);
  } catch (error: any) {
    throw new Error(formatFirebaseError(error));
  }
};

export const onAuthStateChange = (callback: (user: User | null) => void) => {
  if (!auth) {
    console.error("Firebase Auth is not initialized");
    return () => {};
  }
  
  return onAuthStateChanged(auth, callback);
};

// Vendor Services with enhanced error handling
export const vendorService = {
  // Get all vendors with real-time updates
  listenToVendors: (callback: (vendors: Vendor[]) => void) => {
    if (!db) {
      console.error("Firestore is not initialized");
      callback([]);
      return () => {};
    }
    
    try {
      const vendorsRef = collection(db, "vendors");
      const q = query(vendorsRef, orderBy("createdAt", "desc"));
      
      return onSnapshot(
        q, 
        (snapshot) => {
          const vendorsList = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as Vendor));
          callback(vendorsList);
        },
        (error: any) => {
          console.error("Error listening to vendors:", error);
          // Return empty array on error rather than breaking the UI
          callback([]);
        }
      );
    } catch (error: any) {
      console.error("Error setting up vendors listener:", error);
      callback([]);
      return () => {};
    }
  },

  // Get pending vendors
  getPendingVendors: async () => {
    if (!db) throw new Error("Firestore is not initialized");
    
    try {
      const vendorsRef = collection(db, "vendors");
      const q = query(
        vendorsRef, 
        where("status", "==", VendorStatus.PENDING),
        orderBy("createdAt", "desc")
      );
      const snapshot = await getDocs(q);
      return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as Vendor));
    } catch (error: any) {
      console.error("Error fetching pending vendors:", error);
      throw new Error(formatFirebaseError(error));
    }
  },

  // Get a single vendor
  getVendor: async (id: string) => {
    if (!db) throw new Error("Firestore is not initialized");
    
    try {
      const docRef = doc(db, "vendors", id);
      const snapshot = await getDoc(docRef);
      if (snapshot.exists()) {
        return { id: snapshot.id, ...snapshot.data() } as Vendor;
      }
      return null;
    } catch (error: any) {
      console.error("Error fetching vendor:", error);
      throw new Error(formatFirebaseError(error));
    }
  },

  // Update vendor status
  updateVendorStatus: async (id: string, status: VendorStatus | string) => {
    if (!db) throw new Error("Firestore is not initialized");
    
    try {
      const docRef = doc(db, "vendors", id);
      await updateDoc(docRef, { 
        status,
        statusUpdatedAt: Timestamp.now()
      });
    } catch (error: any) {
      console.error("Error updating vendor status:", error);
      throw new Error(formatFirebaseError(error));
    }
  },

  // Full vendor update
  updateVendor: async (id: string, data: Partial<Vendor>) => {
    if (!db) throw new Error("Firestore is not initialized");
    
    try {
      const docRef = doc(db, "vendors", id);
      await updateDoc(docRef, { 
        ...data,
        updatedAt: Timestamp.now()
      });
    } catch (error: any) {
      console.error("Error updating vendor:", error);
      throw new Error(formatFirebaseError(error));
    }
  },

  // Delete vendor
  deleteVendor: async (id: string) => {
    if (!db) throw new Error("Firestore is not initialized");
    
    try {
      const docRef = doc(db, "vendors", id);
      await deleteDoc(docRef);
    } catch (error: any) {
      console.error("Error deleting vendor:", error);
      throw new Error(formatFirebaseError(error));
    }
  }
};

// Product Services with enhanced error handling
export const productService = {
  // Get all products with real-time updates
  listenToProducts: (callback: (products: Product[]) => void) => {
    if (!db) {
      console.error("Firestore is not initialized");
      callback([]);
      return () => {};
    }
    
    try {
      const productsRef = collection(db, "products");
      const q = query(productsRef, orderBy("createdAt", "desc"));
      
      return onSnapshot(
        q,
        (snapshot) => {
          const productsList = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as Product));
          callback(productsList);
        },
        (error: any) => {
          console.error("Error listening to products:", error);
          // Return empty array on error rather than breaking the UI
          callback([]);
        }
      );
    } catch (error: any) {
      console.error("Error setting up products listener:", error);
      callback([]);
      return () => {};
    }
  },

  // Get pending products
  getPendingProducts: async () => {
    if (!db) throw new Error("Firestore is not initialized");
    
    try {
      const productsRef = collection(db, "products");
      const q = query(
        productsRef, 
        where("status", "==", ProductStatus.PENDING),
        orderBy("createdAt", "desc")
      );
      const snapshot = await getDocs(q);
      return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as Product));
    } catch (error: any) {
      console.error("Error fetching pending products:", error);
      throw new Error(formatFirebaseError(error));
    }
  },

  // Get a single product
  getProduct: async (id: string) => {
    if (!db) throw new Error("Firestore is not initialized");
    
    try {
      const docRef = doc(db, "products", id);
      const snapshot = await getDoc(docRef);
      if (snapshot.exists()) {
        return { id: snapshot.id, ...snapshot.data() } as Product;
      }
      return null;
    } catch (error: any) {
      console.error("Error fetching product:", error);
      throw new Error(formatFirebaseError(error));
    }
  },

  // Update product status
  updateProductStatus: async (id: string, status: ProductStatus | string) => {
    if (!db) throw new Error("Firestore is not initialized");
    
    try {
      const docRef = doc(db, "products", id);
      await updateDoc(docRef, { 
        status,
        statusUpdatedAt: Timestamp.now()
      });
    } catch (error: any) {
      console.error("Error updating product status:", error);
      throw new Error(formatFirebaseError(error));
    }
  },

  // Full product update
  updateProduct: async (id: string, data: Partial<Product>) => {
    if (!db) throw new Error("Firestore is not initialized");
    
    try {
      const docRef = doc(db, "products", id);
      await updateDoc(docRef, { 
        ...data,
        updatedAt: Timestamp.now()
      });
    } catch (error: any) {
      console.error("Error updating product:", error);
      throw new Error(formatFirebaseError(error));
    }
  },

  // Delete product
  deleteProduct: async (id: string) => {
    if (!db) throw new Error("Firestore is not initialized");
    
    try {
      const docRef = doc(db, "products", id);
      await deleteDoc(docRef);
    } catch (error: any) {
      console.error("Error deleting product:", error);
      throw new Error(formatFirebaseError(error));
    }
  },

  // Add new product
  addProduct: async (data: Partial<Product>) => {
    if (!db) throw new Error("Firestore is not initialized");
    
    try {
      const productsRef = collection(db, "products");
      return await addDoc(productsRef, {
        ...data,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
        status: ProductStatus.PENDING
      });
    } catch (error: any) {
      console.error("Error adding product:", error);
      throw new Error(formatFirebaseError(error));
    }
  }
};

// Order Services with enhanced error handling
export const orderService = {
  // Get all orders with real-time updates
  listenToOrders: (callback: (orders: Order[]) => void) => {
    if (!db) {
      console.error("Firestore is not initialized");
      callback([]);
      return () => {};
    }
    
    try {
      const ordersRef = collection(db, "orders");
      const q = query(ordersRef, orderBy("createdAt", "desc"));
      
      return onSnapshot(
        q,
        (snapshot) => {
          const ordersList = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as Order));
          callback(ordersList);
        },
        (error: any) => {
          console.error("Error listening to orders:", error);
          // Return empty array on error rather than breaking the UI
          callback([]);
        }
      );
    } catch (error: any) {
      console.error("Error setting up orders listener:", error);
      callback([]);
      return () => {};
    }
  },

  // Get orders by status
  getOrdersByStatus: async (status: OrderStatus | string) => {
    if (!db) throw new Error("Firestore is not initialized");
    
    try {
      const ordersRef = collection(db, "orders");
      const q = query(
        ordersRef, 
        where("status", "==", status),
        orderBy("createdAt", "desc")
      );
      const snapshot = await getDocs(q);
      return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as Order));
    } catch (error: any) {
      console.error("Error fetching orders by status:", error);
      throw new Error(formatFirebaseError(error));
    }
  },

  // Get a single order
  getOrder: async (id: string) => {
    if (!db) throw new Error("Firestore is not initialized");
    
    try {
      const docRef = doc(db, "orders", id);
      const snapshot = await getDoc(docRef);
      if (snapshot.exists()) {
        return { id: snapshot.id, ...snapshot.data() } as Order;
      }
      return null;
    } catch (error: any) {
      console.error("Error fetching order:", error);
      throw new Error(formatFirebaseError(error));
    }
  },

  // Update order status
  updateOrderStatus: async (id: string, status: OrderStatus | string) => {
    if (!db) throw new Error("Firestore is not initialized");
    
    try {
      const docRef = doc(db, "orders", id);
      await updateDoc(docRef, { 
        status,
        statusUpdatedAt: Timestamp.now()
      });
    } catch (error: any) {
      console.error("Error updating order status:", error);
      throw new Error(formatFirebaseError(error));
    }
  },

  // Full order update
  updateOrder: async (id: string, data: Partial<Order>) => {
    if (!db) throw new Error("Firestore is not initialized");
    
    try {
      const docRef = doc(db, "orders", id);
      await updateDoc(docRef, { 
        ...data,
        updatedAt: Timestamp.now()
      });
    } catch (error: any) {
      console.error("Error updating order:", error);
      throw new Error(formatFirebaseError(error));
    }
  },

  // Delete order
  deleteOrder: async (id: string) => {
    if (!db) throw new Error("Firestore is not initialized");
    
    try {
      const docRef = doc(db, "orders", id);
      await deleteDoc(docRef);
    } catch (error: any) {
      console.error("Error deleting order:", error);
      throw new Error(formatFirebaseError(error));
    }
  }
};

// Storage Service with better error handling
export const storageService = {
  uploadFile: async (file: File, path: string) => {
    if (!storage) throw new Error("Firebase Storage is not initialized");
    
    try {
      const storageRef = ref(storage, path);
      await uploadBytes(storageRef, file);
      return await getDownloadURL(storageRef);
    } catch (error: any) {
      console.error("Error uploading file:", error);
      throw new Error(formatFirebaseError(error));
    }
  }
};
EOF

echo "✅ Fixed Firebase service exports"

# Now fix the useFirebaseConnection hook
cat > src/hooks/useFirebaseConnection.ts << 'EOF'
import { useState, useEffect } from "react";
import { db, rtdb, connectionManager } from "@/services/firebase.service";
import { ref, onValue, off } from "firebase/database";

/**
 * Hook to monitor Firebase connection status
 * @returns Object containing Firebase connection status and last reconnect attempt time
 */
export function useFirebaseConnection() {
  const [isConnected, setIsConnected] = useState(true);
  const [lastReconnectAttempt, setLastReconnectAttempt] = useState<Date | null>(null);

  useEffect(() => {
    // Use the connection manager to track connection status
    const unsubscribe = connectionManager.addConnectionListener((connected) => {
      setIsConnected(connected);
      
      if (!connected) {
        setLastReconnectAttempt(new Date());
      }
    });
    
    // Clean up subscription
    return () => {
      unsubscribe();
    };
  }, []);

  return { isConnected, lastReconnectAttempt };
}
EOF

echo "✅ Fixed useFirebaseConnection hook"

# Clean up build cache
echo "Cleaning up build cache..."
rm -rf .next
rm -rf out
rm -rf node_modules/.cache

echo "✅ Build cache cleaned"

echo ""
echo "NEXT STEPS:"
echo "1. Run 'npm run build' to verify the build works"
echo "2. If everything builds successfully, you can deploy with:"
echo "   npm run build && npm run start"