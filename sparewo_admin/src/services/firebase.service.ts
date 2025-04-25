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
} from "firebase/firestore";
import { getStorage, ref, uploadBytes, getDownloadURL } from "firebase/storage";
import { initializeApp, FirebaseApp, getApps, getApp } from "firebase/app";

// Make these available to importers
export enum VendorStatus {
  PENDING = "pending",
  APPROVED = "approved",
  REJECTED = "rejected",
  SUSPENDED = "suspended"
}

export enum ProductStatus {
  PENDING = "pending",
  APPROVED = "approved",
  REJECTED = "rejected",
  OUTOFSTOCK = "outofstock",
  DISCONTINUED = "discontinued"
}

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

// Firebase configuration
const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
  databaseURL: process.env.NEXT_PUBLIC_FIREBASE_DATABASE_URL
};

// Initialize Firebase with error handling and singleton pattern
let firebaseApp: FirebaseApp | undefined = undefined;

// Firebase services
export let auth: any = null;
export let db: any = null;
export let storage: any = null;
export let functions: any = null;

// Only initialize in browser environment
if (typeof window !== 'undefined') {
  try {
    // Check if Firebase is already initialized
    if (getApps().length > 0) {
      firebaseApp = getApp();
    } else {
      // Initialize a new Firebase instance
      firebaseApp = initializeApp(firebaseConfig);
    }
    
    // Initialize services
    if (firebaseApp) {
      auth = getAuth(firebaseApp);
      db = getFirestore(firebaseApp);
      storage = getStorage(firebaseApp);
      
      // IMPORTANT: We're not initializing Firebase Functions here
      // to avoid the undici module issue during build
    }
  } catch (error) {
    console.error("Firebase initialization error:", error);
  }
}

// Connection manager implementation
export const connectionManager = {
  addConnectionListener: (listener: (isConnected: boolean) => void) => {
    // Default implementation always returns connected
    listener(true);
    return () => {}; // Cleanup function
  },
  isConnected: () => true,
  getLastOnlineTime: () => new Date(),
  goOffline: async () => {},
  goOnline: async () => {}
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
      
      // Firestore errors
      case "permission-denied": return "You don't have permission to access this resource.";
      case "unavailable": return "The service is currently unavailable. Please try again later.";
      case "not-found": return "The requested document was not found.";
      
      // Default
      default: return error.message || "An unknown error occurred.";
    }
  }
  
  // Fallback for non-standard errors
  return error.message || "An unknown error occurred.";
};

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

// Create a mock function for Firebase Functions operations
// This allows code to compile but won't actually call Firebase Functions during build
export const mockFunctionsService = {
  callFunction: async (name: string, data: any) => {
    console.log(`Mock function call: ${name}`, data);
    return { success: true, message: "This is a mock response" };
  }
};
