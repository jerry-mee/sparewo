// src/services/firebase.service.ts
import type {
  Auth,
  User,
  UserCredential,
} from "firebase/auth";
import type {
  Firestore,
  DocumentReference,
  CollectionReference,
  Timestamp as FirebaseTimestamp,
  DocumentData
} from "firebase/firestore";
import type { FirebaseStorage } from "firebase/storage";
import type { FirebaseApp } from "firebase/app";

// Export a type alias for Timestamp to avoid importing the actual type
export type Timestamp = {
  toDate: () => Date;
  seconds: number;
  nanoseconds: number;
}

// Export a type alias for Unsubscribe to avoid importing the actual type
export type Unsubscribe = () => void;

// Enums for vendor status
export enum VendorStatus {
  PENDING = "pending",
  APPROVED = "approved",
  REJECTED = "rejected",
  SUSPENDED = "suspended"
}

// Enums for product status
export enum ProductStatus {
  PENDING = "pending",
  APPROVED = "approved",
  REJECTED = "rejected",
  OUTOFSTOCK = "outofstock",
  DISCONTINUED = "discontinued"
}

// Enums for order status
export enum OrderStatus {
  PENDING = "pending",
  PROCESSING = "processing",
  SHIPPED = "shipped",
  DELIVERED = "delivered",
  CANCELLED = "cancelled"
}

// Define interfaces for data models
export interface Vendor {
  id: string;
  name: string;
  email: string;
  phone?: string;
  businessName: string;
  businessAddress?: string;
  status: VendorStatus | string;
  isVerified?: boolean;
  createdAt: Timestamp | Date | any;
  productCount?: number;
  statusUpdatedAt?: Timestamp | Date;
  updatedAt?: Timestamp | Date;
  [key: string]: any;
}

export interface Product {
  id: string;
  name?: string;
  partName?: string;
  description?: string;
  price?: number;
  unitPrice?: number;
  vendorId: string;
  vendorName?: string;
  status: ProductStatus | string;
  createdAt: Timestamp | Date | any;
  brand?: string;
  partNumber?: string;
  condition?: string;
  stockQuantity?: number;
  images?: string[];
  statusUpdatedAt?: Timestamp | Date;
  updatedAt?: Timestamp | Date;
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
  createdAt: Timestamp | Date | any;
  statusUpdatedAt?: Timestamp | Date;
  updatedAt?: Timestamp | Date;
  [key: string]: any;
}

// Firebase modules container
let firebaseModules: {
  app?: any;
  auth?: any;
  firestore?: any;
  storage?: any;
  initialized: boolean;
} = {
  initialized: false
};

// Firebase instances
let auth: Auth | null = null;
let db: Firestore | null = null;
let storage: FirebaseStorage | null = null;
let firebaseApp: FirebaseApp | undefined = undefined;

// Initialize Firebase only on the client
async function initializeFirebase() {
  if (typeof window === 'undefined') {
    return;
  }
  
  if (firebaseModules.initialized) {
    return;
  }
  
  try {
    // Dynamically import Firebase modules
    const appModule = await import('firebase/app');
    const authModule = await import('firebase/auth');
    const firestoreModule = await import('firebase/firestore');
    const storageModule = await import('firebase/storage');
    
    firebaseModules = {
      app: appModule,
      auth: authModule,
      firestore: firestoreModule,
      storage: storageModule,
      initialized: true
    };
    
    const firebaseConfig = {
      apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
      authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
      projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
      storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
      messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
      appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
    };
    
    // Initialize Firebase app
    if (appModule.getApps().length === 0) {
      firebaseApp = appModule.initializeApp(firebaseConfig);
    } else {
      firebaseApp = appModule.getApp();
    }
    
    // Initialize Firebase services
    auth = authModule.getAuth(firebaseApp);
    db = firestoreModule.getFirestore(firebaseApp);
    storage = storageModule.getStorage(firebaseApp);
    
  } catch (error) {
    console.error("Error initializing Firebase:", error);
  }
}

// Initialize Firebase when this module is imported on the client
if (typeof window !== 'undefined') {
  initializeFirebase();
}

// Error formatter helper
export const formatFirebaseError = (error: any): string => {
  let message = "An unknown error occurred.";
  
  if (error instanceof Error) {
    message = error.message;
  }
  
  if (error && typeof error === 'object' && 'code' in error) {
    // Handle Firebase error codes
    const errorCode = String(error.code);
    
    if (errorCode.includes('auth/')) {
      if (errorCode.includes('user-not-found') || errorCode.includes('wrong-password')) {
        message = "Invalid email or password. Please try again.";
      } else if (errorCode.includes('too-many-requests')) {
        message = "Too many login attempts. Please try again later.";
      }
    }
  }
  
  console.error("Firebase Error:", error);
  return message;
};

// Auth functions
export const loginUser = async (email: string, password: string): Promise<User> => {
  await initializeFirebase();
  
  if (!auth || !firebaseModules.auth) {
    throw new Error("Auth not initialized.");
  }
  
  try {
    const userCredential = await firebaseModules.auth.signInWithEmailAndPassword(auth, email, password);
    return userCredential.user;
  } catch (error) {
    throw new Error(formatFirebaseError(error));
  }
};

export const logoutUser = async (): Promise<void> => {
  await initializeFirebase();
  
  if (!auth || !firebaseModules.auth) {
    throw new Error("Auth not initialized.");
  }
  
  try {
    await firebaseModules.auth.signOut(auth);
  } catch (error) {
    throw new Error(formatFirebaseError(error));
  }
};

export const setupAuthListener = (callback: (user: User | null) => void): Unsubscribe => {
  initializeFirebase().then(() => {
    if (!auth || !firebaseModules.auth) {
      console.warn("Auth not initialized.");
      callback(null);
      return;
    }
    
    return firebaseModules.auth.onAuthStateChanged(auth, callback);
  });
  
  return () => {};
};

// Generic Firestore listener function
async function createFirestoreListener<T>(
  collectionName: string,
  orderByField: string = "createdAt",
  orderByDirection: "asc" | "desc" = "desc",
  callback: (data: T[]) => void,
  onError?: (error: Error) => void
): Promise<Unsubscribe> {
  await initializeFirebase();
  
  if (!db || !firebaseModules.firestore) {
    console.warn(`Firestore not initialized. Listener for ${collectionName} cannot attach.`);
    callback([]);
    return () => {};
  }
  
  try {
    const collectionRef = firebaseModules.firestore.collection(db, collectionName);
    const q = firebaseModules.firestore.query(
      collectionRef,
      firebaseModules.firestore.orderBy(orderByField, orderByDirection)
    );
    
    const unsubscribe = firebaseModules.firestore.onSnapshot(
      q,
      (snapshot: any) => {
        const dataList = snapshot.docs.map((doc: any) => ({ 
          id: doc.id, 
          ...doc.data() 
        } as T));
        callback(dataList);
      },
      (error: any) => {
        const formattedError = new Error(formatFirebaseError(error));
        console.error(`Error listening to ${collectionName}:`, formattedError.message);
        if (onError) {
          onError(formattedError);
        }
      }
    );
    
    return unsubscribe;
  } catch (error: any) {
    const formattedError = new Error(formatFirebaseError(error));
    console.error(`Error setting up listener for ${collectionName}:`, formattedError.message);
    if (onError) {
      onError(formattedError);
    }
    return () => {};
  }
}

// Vendor service
export const vendorService = {
  listenToVendors: (callback: (vendors: Vendor[]) => void, onError?: (error: Error) => void): Unsubscribe => {
    let unsubscribe: Unsubscribe = () => {};
    
    createFirestoreListener<Vendor>("vendors", "createdAt", "desc", callback, onError)
      .then(unsub => {
        unsubscribe = unsub;
      });
    
    return () => unsubscribe();
  },
  
  getPendingVendors: async (): Promise<Vendor[]> => {
    await initializeFirebase();
    
    if (!db || !firebaseModules.firestore) {
      throw new Error("Firestore is not initialized.");
    }
    
    try {
      const q = firebaseModules.firestore.query(
        firebaseModules.firestore.collection(db, "vendors"),
        firebaseModules.firestore.where("status", "==", VendorStatus.PENDING),
        firebaseModules.firestore.orderBy("createdAt", "desc")
      );
      
      const snapshot = await firebaseModules.firestore.getDocs(q);
      return snapshot.docs.map((doc: any) => ({ 
        id: doc.id, 
        ...doc.data() 
      } as Vendor));
    } catch (error: any) {
      throw new Error(formatFirebaseError(error));
    }
  },
  
  getVendor: async (id: string): Promise<Vendor | null> => {
    await initializeFirebase();
    
    if (!db || !firebaseModules.firestore) {
      throw new Error("Firestore is not initialized.");
    }
    
    try {
      const docRef = firebaseModules.firestore.doc(db, "vendors", id);
      const snapshot = await firebaseModules.firestore.getDoc(docRef);
      
      return snapshot.exists() 
        ? { id: snapshot.id, ...snapshot.data() } as Vendor 
        : null;
    } catch (error: any) {
      throw new Error(formatFirebaseError(error));
    }
  },
  
  updateVendorStatus: async (id: string, status: VendorStatus | string): Promise<void> => {
    await initializeFirebase();
    
    if (!db || !firebaseModules.firestore) {
      throw new Error("Firestore is not initialized.");
    }
    
    try {
      const docRef = firebaseModules.firestore.doc(db, "vendors", id);
      await firebaseModules.firestore.updateDoc(docRef, { 
        status, 
        statusUpdatedAt: firebaseModules.firestore.Timestamp.now() 
      });
    } catch (error: any) {
      throw new Error(formatFirebaseError(error));
    }
  },
  
  updateVendor: async (id: string, data: Partial<Omit<Vendor, 'id' | 'createdAt'>>): Promise<void> => {
    await initializeFirebase();
    
    if (!db || !firebaseModules.firestore) {
      throw new Error("Firestore is not initialized.");
    }
    
    try {
      const docRef = firebaseModules.firestore.doc(db, "vendors", id);
      await firebaseModules.firestore.updateDoc(docRef, { 
        ...data, 
        updatedAt: firebaseModules.firestore.Timestamp.now() 
      });
    } catch (error: any) {
      throw new Error(formatFirebaseError(error));
    }
  },
  
  deleteVendor: async (id: string): Promise<void> => {
    await initializeFirebase();
    
    if (!db || !firebaseModules.firestore) {
      throw new Error("Firestore is not initialized.");
    }
    
    try {
      const docRef = firebaseModules.firestore.doc(db, "vendors", id);
      await firebaseModules.firestore.deleteDoc(docRef);
    } catch (error: any) {
      throw new Error(formatFirebaseError(error));
    }
  }
};

// Product service
export const productService = {
  listenToProducts: (callback: (products: Product[]) => void, onError?: (error: Error) => void): Unsubscribe => {
    let unsubscribe: Unsubscribe = () => {};
    
    createFirestoreListener<Product>("products", "createdAt", "desc", callback, onError)
      .then(unsub => {
        unsubscribe = unsub;
      });
    
    return () => unsubscribe();
  },
  
  getPendingProducts: async (): Promise<Product[]> => {
    await initializeFirebase();
    
    if (!db || !firebaseModules.firestore) {
      throw new Error("Firestore is not initialized.");
    }
    
    try {
      const q = firebaseModules.firestore.query(
        firebaseModules.firestore.collection(db, "products"),
        firebaseModules.firestore.where("status", "==", ProductStatus.PENDING),
        firebaseModules.firestore.orderBy("createdAt", "desc")
      );
      
      const snapshot = await firebaseModules.firestore.getDocs(q);
      return snapshot.docs.map((doc: any) => ({ 
        id: doc.id, 
        ...doc.data() 
      } as Product));
    } catch (error: any) {
      throw new Error(formatFirebaseError(error));
    }
  },
  
  getProduct: async (id: string): Promise<Product | null> => {
    await initializeFirebase();
    
    if (!db || !firebaseModules.firestore) {
      throw new Error("Firestore is not initialized.");
    }
    
    try {
      const docRef = firebaseModules.firestore.doc(db, "products", id);
      const snapshot = await firebaseModules.firestore.getDoc(docRef);
      
      return snapshot.exists() 
        ? { id: snapshot.id, ...snapshot.data() } as Product 
        : null;
    } catch (error: any) {
      throw new Error(formatFirebaseError(error));
    }
  },
  
  updateProductStatus: async (id: string, status: ProductStatus | string): Promise<void> => {
    await initializeFirebase();
    
    if (!db || !firebaseModules.firestore) {
      throw new Error("Firestore is not initialized.");
    }
    
    try {
      const docRef = firebaseModules.firestore.doc(db, "products", id);
      await firebaseModules.firestore.updateDoc(docRef, { 
        status, 
        statusUpdatedAt: firebaseModules.firestore.Timestamp.now() 
      });
    } catch (error: any) {
      throw new Error(formatFirebaseError(error));
    }
  },
  
  updateProduct: async (id: string, data: Partial<Omit<Product, 'id' | 'createdAt'>>): Promise<void> => {
    await initializeFirebase();
    
    if (!db || !firebaseModules.firestore) {
      throw new Error("Firestore is not initialized.");
    }
    
    try {
      const docRef = firebaseModules.firestore.doc(db, "products", id);
      await firebaseModules.firestore.updateDoc(docRef, { 
        ...data, 
        updatedAt: firebaseModules.firestore.Timestamp.now() 
      });
    } catch (error: any) {
      throw new Error(formatFirebaseError(error));
    }
  },
  
  deleteProduct: async (id: string): Promise<void> => {
    await initializeFirebase();
    
    if (!db || !firebaseModules.firestore) {
      throw new Error("Firestore is not initialized.");
    }
    
    try {
      const docRef = firebaseModules.firestore.doc(db, "products", id);
      await firebaseModules.firestore.deleteDoc(docRef);
    } catch (error: any) {
      throw new Error(formatFirebaseError(error));
    }
  },
  
  addProduct: async (data: Omit<Product, 'id' | 'createdAt' | 'updatedAt' | 'status'>): Promise<string> => {
    await initializeFirebase();
    
    if (!db || !firebaseModules.firestore) {
      throw new Error("Firestore is not initialized.");
    }
    
    try {
      const collectionRef = firebaseModules.firestore.collection(db, "products");
      const docRef = await firebaseModules.firestore.addDoc(collectionRef, { 
        ...data, 
        createdAt: firebaseModules.firestore.Timestamp.now(), 
        updatedAt: firebaseModules.firestore.Timestamp.now(), 
        status: ProductStatus.PENDING 
      });
      
      return docRef.id;
    } catch (error: any) {
      throw new Error(formatFirebaseError(error));
    }
  }
};

// Order service
export const orderService = {
  listenToOrders: (callback: (orders: Order[]) => void, onError?: (error: Error) => void): Unsubscribe => {
    let unsubscribe: Unsubscribe = () => {};
    
    createFirestoreListener<Order>("orders", "createdAt", "desc", callback, onError)
      .then(unsub => {
        unsubscribe = unsub;
      });
    
    return () => unsubscribe();
  },
  
  getOrdersByStatus: async (status: OrderStatus | string): Promise<Order[]> => {
    await initializeFirebase();
    
    if (!db || !firebaseModules.firestore) {
      throw new Error("Firestore is not initialized.");
    }
    
    try {
      const q = firebaseModules.firestore.query(
        firebaseModules.firestore.collection(db, "orders"),
        firebaseModules.firestore.where("status", "==", status),
        firebaseModules.firestore.orderBy("createdAt", "desc")
      );
      
      const snapshot = await firebaseModules.firestore.getDocs(q);
      return snapshot.docs.map((doc: any) => ({ 
        id: doc.id, 
        ...doc.data() 
      } as Order));
    } catch (error: any) {
      throw new Error(formatFirebaseError(error));
    }
  },
  
  getOrder: async (id: string): Promise<Order | null> => {
    await initializeFirebase();
    
    if (!db || !firebaseModules.firestore) {
      throw new Error("Firestore is not initialized.");
    }
    
    try {
      const docRef = firebaseModules.firestore.doc(db, "orders", id);
      const snapshot = await firebaseModules.firestore.getDoc(docRef);
      
      return snapshot.exists() 
        ? { id: snapshot.id, ...snapshot.data() } as Order 
        : null;
    } catch (error: any) {
      throw new Error(formatFirebaseError(error));
    }
  },
  
  updateOrderStatus: async (id: string, status: OrderStatus | string): Promise<void> => {
    await initializeFirebase();
    
    if (!db || !firebaseModules.firestore) {
      throw new Error("Firestore is not initialized.");
    }
    
    try {
      const docRef = firebaseModules.firestore.doc(db, "orders", id);
      await firebaseModules.firestore.updateDoc(docRef, { 
        status, 
        statusUpdatedAt: firebaseModules.firestore.Timestamp.now() 
      });
    } catch (error: any) {
      throw new Error(formatFirebaseError(error));
    }
  },
  
  updateOrder: async (id: string, data: Partial<Omit<Order, 'id' | 'createdAt'>>): Promise<void> => {
    await initializeFirebase();
    
    if (!db || !firebaseModules.firestore) {
      throw new Error("Firestore is not initialized.");
    }
    
    try {
      const docRef = firebaseModules.firestore.doc(db, "orders", id);
      await firebaseModules.firestore.updateDoc(docRef, { 
        ...data, 
        updatedAt: firebaseModules.firestore.Timestamp.now() 
      });
    } catch (error: any) {
      throw new Error(formatFirebaseError(error));
    }
  },
  
  deleteOrder: async (id: string): Promise<void> => {
    await initializeFirebase();
    
    if (!db || !firebaseModules.firestore) {
      throw new Error("Firestore is not initialized.");
    }
    
    try {
      const docRef = firebaseModules.firestore.doc(db, "orders", id);
      await firebaseModules.firestore.deleteDoc(docRef);
    } catch (error: any) {
      throw new Error(formatFirebaseError(error));
    }
  }
};

// Storage service
export const storageService = {
  uploadFile: async (file: File, path: string): Promise<string> => {
    await initializeFirebase();
    
    if (!storage || !firebaseModules.storage) {
      throw new Error("Firebase Storage is not initialized.");
    }
    
    try {
      const storageRef = firebaseModules.storage.ref(storage, path);
      const snapshot = await firebaseModules.storage.uploadBytes(storageRef, file);
      return await firebaseModules.storage.getDownloadURL(snapshot.ref);
    } catch (error: any) {
      throw new Error(formatFirebaseError(error));
    }
  }
};

// Connection management
export const connectionManager = {
  addConnectionListener: (callback: (isConnected: boolean) => void): Unsubscribe => {
    initializeFirebase().then(() => {
      if (!db || !firebaseModules.firestore) {
        console.warn("Firestore not initialized. Connection listener cannot be set up.");
        callback(false);
        return;
      }
      
      try {
        const connectedRef = firebaseModules.firestore.doc(db, ".info/connected");
        
        return firebaseModules.firestore.onSnapshot(connectedRef, (snap: any) => {
          const isConnected = snap.exists() && snap.data()?.connected === true;
          callback(isConnected);
        });
      } catch (error) {
        console.error("Error setting up connection listener:", error);
        callback(false);
      }
    });
    
    return () => {};
  }
};

// Export NOW function for timestamp creation
export const NOW = (): Timestamp => {
  if (firebaseModules.firestore) {
    return firebaseModules.firestore.Timestamp.now();
  }
  // Fallback implementation
  return {
    toDate: () => new Date(),
    seconds: Math.floor(Date.now() / 1000),
    nanoseconds: 0
  };
};