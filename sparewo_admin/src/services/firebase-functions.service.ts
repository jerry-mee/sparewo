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
    Timestamp, // Keep Timestamp
    Firestore,
    Unsubscribe, // Import Unsubscribe type
    DocumentReference // Import DocumentReference for addDoc return type
} from "firebase/firestore";
import {
    getStorage,
    ref,
    uploadBytes,
    getDownloadURL,
    FirebaseStorage
} from "firebase/storage";
import { initializeApp, FirebaseApp, getApps, getApp } from "firebase/app";

// --- EXPORTED Enums and Interfaces ---
export { Timestamp };
export { type Unsubscribe };

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

// Ensure ALL fields used in components are defined here
export interface Vendor {
    id: string;
    name: string;
    email: string;
    phone?: string;
    businessName: string;
    businessAddress?: string;
    status: VendorStatus | string; // Field is present
    isVerified?: boolean;
    createdAt: Timestamp | Date | any;
    productCount?: number;
    statusUpdatedAt?: Timestamp | Date;
    updatedAt?: Timestamp | Date;
    [key: string]: any;
}

export interface Product {
    id: string; // Field is present
    name?: string; // Field is present
    partName?: string; // Field is present
    description?: string; // Field is present
    price?: number; // Field is present
    unitPrice?: number; // Field is present
    vendorId: string;
    vendorName?: string; // Field is present
    status: ProductStatus | string; // Field is present
    createdAt: Timestamp | Date | any;
    brand?: string; // Field is present
    partNumber?: string; // Field is present
    condition?: string;
    stockQuantity?: number; // Field is present
    images?: string[]; // Field is present
    statusUpdatedAt?: Timestamp | Date;
    updatedAt?: Timestamp | Date;
    [key: string]: any;
}

export interface Order {
    id: string; // Field is present
    customerName: string; // Field is present
    customerEmail: string; // Field is present
    customerPhone?: string; // Field is present
    productIds: string[]; // Field is present
    productNames?: string[]; // Field is present
    totalAmount: number; // Field is present
    status: OrderStatus | string; // Field is present
    createdAt: Timestamp | Date | any; // Field is present
    statusUpdatedAt?: Timestamp | Date;
    updatedAt?: Timestamp | Date;
    [key: string]: any;
}

// --- Firebase Configuration ---
const firebaseConfig = { /* ... as before ... */
    apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
    authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
    projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
    storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
    messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
    appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
};

// --- Firebase Initialization ---
let firebaseApp: FirebaseApp | undefined = undefined;
let auth: ReturnType<typeof getAuth> | null = null;
let db: Firestore | null = null;
let storage: FirebaseStorage | null = null;

if (typeof window !== 'undefined') {
    try {
        firebaseApp = getApps().length === 0 ? initializeApp(firebaseConfig) : getApp();
        if (firebaseApp) {
            auth = getAuth(firebaseApp);
            db = getFirestore(firebaseApp);
            storage = getStorage(firebaseApp);
        } else { console.error("Firebase app init failed."); }
    } catch (error) { console.error("Firebase init error:", error); }
}

// --- EXPORTED Error Formatter ---
export const formatFirebaseError = (error: any): string => {
    let message = "An unknown error occurred."; if (error instanceof Error) { message = error.message; }
    if (error && typeof error === 'object' && 'code' in error) { /* ... cases ... */ }
    console.error("Firebase Error:", error); return message;
};

// --- EXPORTED Auth Service Functions ---
export const loginUser = async (email: string, password: string): Promise<User> => {
    if (!auth) throw new Error("Auth not initialized.");
    try { return (await signInWithEmailAndPassword(auth, email, password)).user; }
    catch (error) { throw new Error(formatFirebaseError(error)); } // Re-throw after formatting
};
export const logoutUser = async (): Promise<void> => {
    if (!auth) throw new Error("Auth not initialized.");
    try { await signOut(auth); }
    catch (error) { throw new Error(formatFirebaseError(error)); } // Re-throw
};
export const setupAuthListener = (callback: (user: User | null) => void): Unsubscribe => {
    if (!auth) { console.warn("Auth not initialized."); return () => {}; }
    return onAuthStateChanged(auth, callback);
};

// --- Firestore Listener Base (Internal - not exported) ---
function createFirestoreListener<T>(
    collectionName: string,
    orderByField: string = "createdAt",
    orderByDirection: "asc" | "desc" = "desc",
    callback: (data: T[]) => void,
    onError?: (error: Error) => void
): Unsubscribe {
    const noOpUnsubscribe = () => {};
    if (!db) { callback([]); return noOpUnsubscribe; }
    try {
        const q = query(collection(db, collectionName), orderBy(orderByField, orderByDirection));
        const unsubscribe = onSnapshot( q,
            (snapshot) => { callback(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as T))); },
            (error: any) => {
                const formattedError = new Error(formatFirebaseError(error));
                console.error(`Listener error (${collectionName}):`, formattedError.message);
                if (onError) { onError(formattedError); }
            }
        );
        return unsubscribe; // Return actual unsubscribe
    } catch (error: any) {
        const formattedError = new Error(formatFirebaseError(error));
        console.error(`Listener setup error (${collectionName}):`, formattedError.message);
        if (onError) { onError(formattedError); }
        return noOpUnsubscribe; // Return no-op on setup failure
    }
}

// --- EXPORTED Vendor Service ---
export const vendorService = {
    listenToVendors: (cb: (d: Vendor[]) => void, onErr?: (e: Error) => void): Unsubscribe => createFirestoreListener<Vendor>("vendors", "createdAt", "desc", cb, onErr),
    getPendingVendors: async (): Promise<Vendor[]> => {
        if (!db) throw new Error("DB not initialized.");
        try { const q = query(collection(db, "vendors"), where("status", "==", VendorStatus.PENDING), orderBy("createdAt", "desc")); return (await getDocs(q)).docs.map(doc => ({ id: doc.id, ...doc.data() } as Vendor)); }
        catch (error) { throw new Error(formatFirebaseError(error)); } // Re-throw
    },
    getVendor: async (id: string): Promise<Vendor | null> => {
        if (!db) throw new Error("DB not initialized.");
        try { const snap = await getDoc(doc(db, "vendors", id)); return snap.exists() ? { id: snap.id, ...snap.data() } as Vendor : null; }
        catch (error) { throw new Error(formatFirebaseError(error)); } // Re-throw
    },
    updateVendorStatus: async (id: string, status: VendorStatus | string): Promise<void> => {
        if (!db) throw new Error("DB not initialized.");
        try { await updateDoc(doc(db, "vendors", id), { status, statusUpdatedAt: Timestamp.now() }); }
        catch (error) { throw new Error(formatFirebaseError(error)); } // Re-throw
     },
    updateVendor: async (id: string, data: Partial<Omit<Vendor, 'id' | 'createdAt'>>): Promise<void> => {
        if (!db) throw new Error("DB not initialized.");
        try { await updateDoc(doc(db, "vendors", id), { ...data, updatedAt: Timestamp.now() }); }
        catch (error) { throw new Error(formatFirebaseError(error)); } // Re-throw
    },
    deleteVendor: async (id: string): Promise<void> => {
        if (!db) throw new Error("DB not initialized.");
        try { await deleteDoc(doc(db, "vendors", id)); }
        catch (error) { throw new Error(formatFirebaseError(error)); } // Re-throw
    }
};

// --- EXPORTED Product Service ---
export const productService = {
    listenToProducts: (cb: (d: Product[]) => void, onErr?: (e: Error) => void): Unsubscribe => createFirestoreListener<Product>("products", "createdAt", "desc", cb, onErr),
    getPendingProducts: async (): Promise<Product[]> => {
         if (!db) throw new Error("DB not initialized.");
         try { const q = query(collection(db, "products"), where("status", "==", ProductStatus.PENDING), orderBy("createdAt", "desc")); return (await getDocs(q)).docs.map(doc => ({ id: doc.id, ...doc.data() } as Product)); }
         catch (error) { throw new Error(formatFirebaseError(error)); } // Re-throw
    },
    getProduct: async (id: string): Promise<Product | null> => {
        if (!db) throw new Error("DB not initialized.");
        try { const snap = await getDoc(doc(db, "products", id)); return snap.exists() ? { id: snap.id, ...snap.data() } as Product : null; }
        catch (error) { throw new Error(formatFirebaseError(error)); } // Re-throw
    },
    updateProductStatus: async (id: string, status: ProductStatus | string): Promise<void> => {
        if (!db) throw new Error("DB not initialized.");
        try { await updateDoc(doc(db, "products", id), { status, statusUpdatedAt: Timestamp.now() }); }
        catch (error) { throw new Error(formatFirebaseError(error)); } // Re-throw
    },
    updateProduct: async (id: string, data: Partial<Omit<Product, 'id' | 'createdAt'>>): Promise<void> => {
        if (!db) throw new Error("DB not initialized.");
        try { await updateDoc(doc(db, "products", id), { ...data, updatedAt: Timestamp.now() }); }
        catch (error) { throw new Error(formatFirebaseError(error)); } // Re-throw
    },
    deleteProduct: async (id: string): Promise<void> => {
        if (!db) throw new Error("DB not initialized.");
        try { await deleteDoc(doc(db, "products", id)); }
        catch (error) { throw new Error(formatFirebaseError(error)); } // Re-throw
    },
    addProduct: async (data: Omit<Product, 'id' | 'createdAt' | 'updatedAt' | 'status'>): Promise<string> => {
        if (!db) throw new Error("DB not initialized.");
        try { const docRef = await addDoc(collection(db, "products"), { ...data, createdAt: Timestamp.now(), updatedAt: Timestamp.now(), status: ProductStatus.PENDING }); return docRef.id; }
        catch (error) { throw new Error(formatFirebaseError(error)); } // Re-throw
    }
};

// --- EXPORTED Order Service ---
export const orderService = {
    listenToOrders: (cb: (d: Order[]) => void, onErr?: (e: Error) => void): Unsubscribe => createFirestoreListener<Order>("orders", "createdAt", "desc", cb, onErr),
    getOrdersByStatus: async (status: OrderStatus | string): Promise<Order[]> => {
        if (!db) throw new Error("DB not initialized.");
        try { const q = query(collection(db, "orders"), where("status", "==", status), orderBy("createdAt", "desc")); return (await getDocs(q)).docs.map(doc => ({ id: doc.id, ...doc.data() } as Order)); }
        catch (error) { throw new Error(formatFirebaseError(error)); } // Re-throw
    },
    getOrder: async (id: string): Promise<Order | null> => {
        if (!db) throw new Error("DB not initialized.");
        try { const snap = await getDoc(doc(db, "orders", id)); return snap.exists() ? { id: snap.id, ...snap.data() } as Order : null; }
        catch (error) { throw new Error(formatFirebaseError(error)); } // Re-throw
    },
    updateOrderStatus: async (id: string, status: OrderStatus | string): Promise<void> => {
        if (!db) throw new Error("DB not initialized.");
        try { await updateDoc(doc(db, "orders", id), { status, statusUpdatedAt: Timestamp.now() }); }
        catch (error) { throw new Error(formatFirebaseError(error)); } // Re-throw
     },
    updateOrder: async (id: string, data: Partial<Omit<Order, 'id' | 'createdAt'>>): Promise<void> => {
        if (!db) throw new Error("DB not initialized.");
        try { await updateDoc(doc(db, "orders", id), { ...data, updatedAt: Timestamp.now() }); }
        catch (error) { throw new Error(formatFirebaseError(error)); } // Re-throw
    },
    deleteOrder: async (id: string): Promise<void> => {
        if (!db) throw new Error("DB not initialized.");
        try { await deleteDoc(doc(db, "orders", id)); }
        catch (error) { throw new Error(formatFirebaseError(error)); } // Re-throw
    }
};

// --- EXPORTED Storage Service ---
export const storageService = {
    uploadFile: async (file: File, path: string): Promise<string> => {
        if (!storage) throw new Error("Storage not initialized.");
        try { const storageRef = ref(storage, path); const snapshot = await uploadBytes(storageRef, file); return await getDownloadURL(snapshot.ref); }
        catch (error) { throw new Error(formatFirebaseError(error)); } // Re-throw
    }
};

// --- Functions Service is in firebase-functions.service.ts ---