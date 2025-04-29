#!/bin/bash

# SpareWo Admin Dashboard Implementation Script
# This script adds Firebase integration, vendor/product management, and responsive layout improvements
# to the SpareWo Admin Dashboard

# Colors for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Set the project directory (adjust as needed)
PROJECT_DIR="."

# Print header
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}  SpareWo Admin Dashboard Implementation ${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Navigate to project directory
cd "$PROJECT_DIR"

# Verify package.json exists
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ package.json not found. Make sure you're in the correct directory.${NC}"
    exit 1
fi

# Ensure public/images directory exists
echo -e "${BLUE}📁 Ensuring public directories exist...${NC}"
mkdir -p public/images

# Install additional required dependencies
echo -e "${BLUE}📦 Installing dependencies...${NC}"
npm install --legacy-peer-deps firebase react-hook-form zod @hookform/resolvers sonner next-themes @tailwindcss/forms react-firebase-hooks

echo -e "${BLUE}🔧 Implementing Firebase Configuration...${NC}"
# Create Firebase configuration file
mkdir -p src/lib/firebase
cat > src/lib/firebase/config.ts << 'EOL'
// Firebase configuration
import { initializeApp, getApps, getApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getStorage } from 'firebase/storage';

const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
};

// Initialize Firebase
const app = !getApps().length ? initializeApp(firebaseConfig) : getApp();
const auth = getAuth(app);
const db = getFirestore(app);
const storage = getStorage(app);

export { app, auth, db, storage };
EOL

# Create Firebase auth functionality
mkdir -p src/lib/firebase/auth
cat > src/lib/firebase/auth/index.ts << 'EOL'
import {
  signInWithEmailAndPassword,
  signOut,
  sendPasswordResetEmail,
  createUserWithEmailAndPassword,
  updateProfile,
} from 'firebase/auth';
import { doc, setDoc, serverTimestamp } from 'firebase/firestore';
import { auth, db } from '../config';
import { AdminUser } from '@/lib/types';

// Sign in with email and password
export const signIn = async (email: string, password: string) => {
  try {
    const userCredential = await signInWithEmailAndPassword(auth, email, password);
    return userCredential.user;
  } catch (error: any) {
    throw new Error(error.message);
  }
};

// Sign out
export const logOut = async () => {
  try {
    await signOut(auth);
  } catch (error: any) {
    throw new Error(error.message);
  }
};

// Send password reset email
export const resetPassword = async (email: string) => {
  try {
    await sendPasswordResetEmail(auth, email);
  } catch (error: any) {
    throw new Error(error.message);
  }
};

// Create a new admin user
export const createAdmin = async (email: string, password: string, displayName: string, role: AdminUser['role']) => {
  try {
    const userCredential = await createUserWithEmailAndPassword(auth, email, password);
    const user = userCredential.user;

    // Update the user profile with displayName
    await updateProfile(user, { displayName });

    // Create a document in the adminUsers collection
    await setDoc(doc(db, 'adminUsers', user.uid), {
      id: user.uid,
      email,
      displayName,
      role,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });

    return user;
  } catch (error: any) {
    throw new Error(error.message);
  }
};
EOL

# Create Firebase database core functionality
mkdir -p src/lib/firebase/db
cat > src/lib/firebase/db/index.ts << 'EOL'
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

// Generic function to get a document by ID
export const getDocumentById = async <T>(collectionName: string, id: string): Promise<T | null> => {
  try {
    const docRef = doc(db, collectionName, id);
    const docSnap = await getDoc(docRef);

    if (docSnap.exists()) {
      return { id: docSnap.id, ...docSnap.data() } as T;
    }

    return null;
  } catch (error) {
    console.error(`Error getting document from ${collectionName}:`, error);
    throw error;
  }
};

// Generic function to get documents with pagination
export const getDocuments = async <T>(
  collectionName: string,
  constraints: QueryConstraint[] = [],
  pageSize: number = 10,
  lastDoc?: DocumentData
): Promise<{ data: T[], lastDoc: DocumentData | undefined }> => {
  try {
    let q = query(
      collection(db, collectionName),
      ...constraints,
      limit(pageSize)
    );

    if (lastDoc) {
      q = query(q, startAfter(lastDoc));
    }

    const querySnapshot = await getDocs(q);

    const data: T[] = [];
    let lastVisible: DocumentData | undefined = undefined;

    querySnapshot.forEach((doc) => {
      data.push({ id: doc.id, ...doc.data() } as T);
      lastVisible = doc;
    });

    return { data, lastDoc: lastVisible };
  } catch (error) {
    console.error(`Error getting documents from ${collectionName}:`, error);
    throw error;
  }
};

// Generic function to update a document
export const updateDocument = async (
  collectionName: string,
  id: string,
  data: Partial<any>
): Promise<void> => {
  try {
    const docRef = doc(db, collectionName, id);
    await updateDoc(docRef, {
      ...data,
      updatedAt: serverTimestamp(),
    });
  } catch (error) {
    console.error(`Error updating document in ${collectionName}:`, error);
    throw error;
  }
};

// Get documents by field equality
export const getDocumentsByField = async <T>(
  collectionName: string,
  field: string,
  value: any,
  orderByField: string = 'createdAt',
  orderDirection: 'asc' | 'desc' = 'desc',
  pageSize: number = 10
): Promise<T[]> => {
  try {
    const q = query(
      collection(db, collectionName),
      where(field, '==', value),
      orderBy(orderByField, orderDirection),
      limit(pageSize)
    );

    const querySnapshot = await getDocs(q);

    const data: T[] = [];
    querySnapshot.forEach((doc) => {
      data.push({ id: doc.id, ...doc.data() } as T);
    });

    return data;
  } catch (error) {
    console.error(`Error getting documents from ${collectionName} by field:`, error);
    throw error;
  }
};

// Count documents in a collection with optional filtering
export const countDocuments = async (
  collectionName: string,
  constraints: QueryConstraint[] = []
): Promise<number> => {
  try {
    const q = query(
      collection(db, collectionName),
      ...constraints
    );

    const querySnapshot = await getDocs(q);
    return querySnapshot.size;
  } catch (error) {
    console.error(`Error counting documents in ${collectionName}:`, error);
    throw error;
  }
};
EOL

# Create vendor-specific Firebase functionality
mkdir -p src/lib/firebase/vendors
cat > src/lib/firebase/vendors/index.ts << 'EOL'
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
EOL

# Create product-specific Firebase functionality
mkdir -p src/lib/firebase/products
cat > src/lib/firebase/products/index.ts << 'EOL'
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
import { Product } from '@/lib/types/product';

// Get all products with pagination
export const getProducts = async (
  status: string | null = null,
  vendorId: string | null = null,
  pageSize: number = 10,
  lastDoc?: DocumentData
): Promise<{ products: Product[], lastDoc: DocumentData | undefined }> => {
  try {
    // Build query constraints
    const constraints: QueryConstraint[] = [orderBy('createdAt', 'desc')];

    if (status) {
      constraints.push(where('status', '==', status));
    }

    if (vendorId) {
      constraints.push(where('vendorId', '==', vendorId));
    }

    let q = query(
      collection(db, 'products'),
      ...constraints,
      limit(pageSize)
    );

    if (lastDoc) {
      q = query(q, startAfter(lastDoc));
    }

    const querySnapshot = await getDocs(q);

    const products: Product[] = [];
    let lastVisible: DocumentData | undefined = undefined;

    querySnapshot.forEach((doc) => {
      products.push({ id: doc.id, ...doc.data() } as Product);
      lastVisible = doc;
    });

    return { products, lastDoc: lastVisible };
  } catch (error) {
    console.error('Error getting products:', error);
    throw error;
  }
};

// Get product by ID
export const getProductById = async (id: string): Promise<Product | null> => {
  try {
    const docRef = doc(db, 'products', id);
    const docSnap = await getDoc(docRef);

    if (docSnap.exists()) {
      return { id: docSnap.id, ...docSnap.data() } as Product;
    }

    return null;
  } catch (error) {
    console.error('Error getting product:', error);
    throw error;
  }
};

// Get pending products
export const getPendingProducts = async (
  pageSize: number = 10,
  lastDoc?: DocumentData
): Promise<{ products: Product[], lastDoc: DocumentData | undefined }> => {
  return getProducts('pending', null, pageSize, lastDoc);
};

// Update product status
export const updateProductStatus = async (
  id: string,
  status: 'pending' | 'approved' | 'rejected',
  showInCatalog: boolean = false,
  rejectionReason?: string
): Promise<void> => {
  try {
    const docRef = doc(db, 'products', id);

    const updateData: any = {
      status,
      showInCatalog: status === 'approved' ? showInCatalog : false,
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
    console.error('Error updating product status:', error);
    throw error;
  }
};

// Count products by status
export const countProductsByStatus = async (status: string): Promise<number> => {
  try {
    const q = query(
      collection(db, 'products'),
      where('status', '==', status)
    );

    const querySnapshot = await getDocs(q);
    return querySnapshot.size;
  } catch (error) {
    console.error('Error counting products by status:', error);
    throw error;
  }
};

// Get total product count
export const getTotalProductCount = async (): Promise<number> => {
  try {
    const querySnapshot = await getDocs(collection(db, 'products'));
    return querySnapshot.size;
  } catch (error) {
    console.error('Error getting total product count:', error);
    throw error;
  }
};

// Get products by vendor ID
export const getProductsByVendorId = async (
  vendorId: string,
  pageSize: number = 10,
  lastDoc?: DocumentData
): Promise<{ products: Product[], lastDoc: DocumentData | undefined }> => {
  return getProducts(null, vendorId, pageSize, lastDoc);
};
EOL

# Create storage-specific Firebase functionality
mkdir -p src/lib/firebase/storage
cat > src/lib/firebase/storage/index.ts << 'EOL'
import { ref, uploadBytes, getDownloadURL } from 'firebase/storage';
import { storage } from '../config';

// Upload a file to Firebase Storage
export const uploadFile = async (
  file: File,
  path: string
): Promise<string> => {
  try {
    const storageRef = ref(storage, path);
    const snapshot = await uploadBytes(storageRef, file);
    const downloadURL = await getDownloadURL(snapshot.ref);
    return downloadURL;
  } catch (error) {
    console.error('Error uploading file:', error);
    throw error;
  }
};

// Get a file URL from Firebase Storage
export const getFileURL = async (path: string): Promise<string> => {
  try {
    const storageRef = ref(storage, path);
    return await getDownloadURL(storageRef);
  } catch (error) {
    console.error('Error getting file URL:', error);
    throw error;
  }
};
EOL

# Create notifications Firebase functionality
mkdir -p src/lib/firebase/notifications
cat > src/lib/firebase/notifications/index.ts << 'EOL'
import {
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  where,
  orderBy,
  limit,
  addDoc,
  updateDoc,
  serverTimestamp,
  DocumentData,
  QueryConstraint,
  startAfter
} from 'firebase/firestore';
import { db } from '../config';
import { Notification } from '@/lib/types/notification';

// Get notifications for a user
export const getUserNotifications = async (
  userId: string,
  pageSize: number = 10,
  lastDoc?: DocumentData
): Promise<{ notifications: Notification[], lastDoc: DocumentData | undefined }> => {
  try {
    // Build query constraints
    const constraints: QueryConstraint[] = [
      where('userId', '==', userId),
      orderBy('createdAt', 'desc')
    ];

    let q = query(
      collection(db, 'notifications'),
      ...constraints,
      limit(pageSize)
    );

    if (lastDoc) {
      q = query(q, startAfter(lastDoc));
    }

    const querySnapshot = await getDocs(q);

    const notifications: Notification[] = [];
    let lastVisible: DocumentData | undefined = undefined;

    querySnapshot.forEach((doc) => {
      notifications.push({ id: doc.id, ...doc.data() } as Notification);
      lastVisible = doc;
    });

    return { notifications, lastDoc: lastVisible };
  } catch (error) {
    console.error('Error getting notifications:', error);
    throw error;
  }
};

// Create a new notification
export const createNotification = async (
  notification: Omit<Notification, 'id' | 'createdAt' | 'updatedAt'>
): Promise<string> => {
  try {
    const docRef = await addDoc(collection(db, 'notifications'), {
      ...notification,
      read: false,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp()
    });

    return docRef.id;
  } catch (error) {
    console.error('Error creating notification:', error);
    throw error;
  }
};

// Mark notification as read
export const markNotificationAsRead = async (id: string): Promise<void> => {
  try {
    const docRef = doc(db, 'notifications', id);
    await updateDoc(docRef, {
      read: true,
      updatedAt: serverTimestamp()
    });
  } catch (error) {
    console.error('Error marking notification as read:', error);
    throw error;
  }
};

// Get unread notification count
export const getUnreadNotificationCount = async (userId: string): Promise<number> => {
  try {
    const q = query(
      collection(db, 'notifications'),
      where('userId', '==', userId),
      where('read', '==', false)
    );

    const querySnapshot = await getDocs(q);
    return querySnapshot.size;
  } catch (error) {
    console.error('Error getting unread notification count:', error);
    throw error;
  }
};
EOL

# Create admin-specific Firebase functionality
mkdir -p src/lib/firebase/admin
cat > src/lib/firebase/admin/index.ts << 'EOL'
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
  deleteDoc
} from 'firebase/firestore';
import { db } from '../config';
import { AdminUser } from '@/lib/types';

// Get all admin users
export const getAdminUsers = async (): Promise<AdminUser[]> => {
  try {
    const q = query(
      collection(db, 'adminUsers'),
      orderBy('createdAt', 'desc')
    );

    const querySnapshot = await getDocs(q);

    const adminUsers: AdminUser[] = [];

    querySnapshot.forEach((doc) => {
      adminUsers.push({ id: doc.id, ...doc.data() } as AdminUser);
    });

    return adminUsers;
  } catch (error) {
    console.error('Error getting admin users:', error);
    throw error;
  }
};

// Get admin user by ID
export const getAdminUserById = async (id: string): Promise<AdminUser | null> => {
  try {
    const docRef = doc(db, 'adminUsers', id);
    const docSnap = await getDoc(docRef);

    if (docSnap.exists()) {
      return { id: docSnap.id, ...docSnap.data() } as AdminUser;
    }

    return null;
  } catch (error) {
    console.error('Error getting admin user:', error);
    throw error;
  }
};

// Update admin user role
export const updateAdminUserRole = async (
  id: string,
  role: AdminUser['role']
): Promise<void> => {
  try {
    const docRef = doc(db, 'adminUsers', id);
    await updateDoc(docRef, {
      role,
      updatedAt: serverTimestamp()
    });
  } catch (error) {
    console.error('Error updating admin user role:', error);
    throw error;
  }
};

// Delete admin user
export const deleteAdminUser = async (id: string): Promise<void> => {
  try {
    await deleteDoc(doc(db, 'adminUsers', id));
  } catch (error) {
    console.error('Error deleting admin user:', error);
    throw error;
  }
};
EOL

# Define type definitions
echo -e "${BLUE}📝 Creating type definitions...${NC}"

# Update existing types
mkdir -p src/lib/types
cat > src/lib/types/index.ts << 'EOL'
export interface AdminUser {
  id: string;
  email: string;
  displayName: string;
  role: 'superAdmin' | 'admin' | 'viewer';
  createdAt: any;
  updatedAt: any;
}

export interface VendorStatus {
  value: 'pending' | 'approved' | 'rejected';
  label: string;
  color: string;
}

export interface ProductStatus {
  value: 'pending' | 'approved' | 'rejected';
  label: string;
  color: string;
}

export const VENDOR_STATUSES: VendorStatus[] = [
  { value: 'pending', label: 'Pending Review', color: 'bg-amber-500' },
  { value: 'approved', label: 'Approved', color: 'bg-green-500' },
  { value: 'rejected', label: 'Rejected', color: 'bg-red-500' },
];

export const PRODUCT_STATUSES: ProductStatus[] = [
  { value: 'pending', label: 'Pending Review', color: 'bg-amber-500' },
  { value: 'approved', label: 'Approved', color: 'bg-green-500' },
  { value: 'rejected', label: 'Rejected', color: 'bg-red-500' },
];
EOL

# Create vendor type definition
cat > src/lib/types/vendor.ts << 'EOL'
export interface Vendor {
  id: string;
  name: string;
  email: string;
  phone: string;
  address: string;
  businessName: string;
  businessType: string;
  businessRegistrationNumber?: string;
  taxId?: string;
  description?: string;
  status: 'pending' | 'approved' | 'rejected';
  rejectionReason?: string;
  logoUrl?: string;
  documentUrls?: string[];
  createdAt: any;
  updatedAt: any;
  approvedAt?: any;
  rejectedAt?: any;
}
EOL

# Create product type definition
cat > src/lib/types/product.ts << 'EOL'
export interface Product {
  id: string;
  name: string;
  description: string;
  price: number;
  discountPrice?: number;
  category: string;
  subcategory?: string;
  brand: string;
  model: string;
  year: string;
  condition: 'new' | 'used' | 'refurbished';
  quantity: number;
  status: 'pending' | 'approved' | 'rejected';
  rejectionReason?: string;
  showInCatalog: boolean;
  imageUrls: string[];
  specifications?: Record<string, string>;
  vendorId: string;
  createdAt: any;
  updatedAt: any;
  approvedAt?: any;
  rejectedAt?: any;
}
EOL

# Create notification type definition
cat > src/lib/types/notification.ts << 'EOL'
export interface Notification {
  id: string;
  userId: string;
  title: string;
  message: string;
  type: 'info' | 'success' | 'warning' | 'error';
  link?: string;
  read: boolean;
  createdAt: any;
  updatedAt: any;
}
EOL

# Create context files
echo -e "${BLUE}📝 Creating context providers...${NC}"

# Authentication context
mkdir -p src/lib/context
cat > src/lib/context/auth-context.tsx << 'EOL'
"use client";

import React, { createContext, useContext, useEffect, useState } from 'react';
import { User, onAuthStateChanged } from 'firebase/auth';
import { auth } from '@/lib/firebase/config';
import { doc, getDoc } from 'firebase/firestore';
import { db } from '@/lib/firebase/config';
import { AdminUser } from '@/lib/types';

interface AuthContextType {
  user: User | null;
  adminData: AdminUser | null;
  loading: boolean;
}

const AuthContext = createContext<AuthContextType>({
  user: null,
  adminData: null,
  loading: true,
});

export const useAuth = () => useContext(AuthContext);

export const AuthProvider = ({ children }: { children: React.ReactNode }) => {
  const [user, setUser] = useState<User | null>(null);
  const [adminData, setAdminData] = useState<AdminUser | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      setUser(user);

      if (user) {
        try {
          const docRef = doc(db, 'adminUsers', user.uid);
          const docSnap = await getDoc(docRef);

          if (docSnap.exists()) {
            setAdminData({ id: docSnap.id, ...docSnap.data() } as AdminUser);
          } else {
            console.log('No admin data found');
            setAdminData(null);
          }
        } catch (error) {
          console.error('Error fetching admin data:', error);
        }
      } else {
        setAdminData(null);
      }

      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  return (
    <AuthContext.Provider value={{ user, adminData, loading }}>
      {children}
    </AuthContext.Provider>
  );
};
EOL

# Create notification context
cat > src/lib/context/notification-context.tsx << 'EOL'
"use client";

import React, { createContext, useContext, useEffect, useState } from 'react';
import { onSnapshot, query, collection, where, orderBy, limit } from 'firebase/firestore';
import { db } from '@/lib/firebase/config';
import { Notification } from '@/lib/types/notification';
import { useAuth } from './auth-context';
import { markNotificationAsRead } from '@/lib/firebase/notifications';

interface NotificationContextType {
  notifications: Notification[];
  unreadCount: number;
  markAsRead: (id: string) => Promise<void>;
  loading: boolean;
}

const NotificationContext = createContext<NotificationContextType>({
  notifications: [],
  unreadCount: 0,
  markAsRead: async () => {},
  loading: true,
});

export const useNotifications = () => useContext(NotificationContext);

export const NotificationProvider = ({ children }: { children: React.ReactNode }) => {
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const [loading, setLoading] = useState(true);
  const { user } = useAuth();

  useEffect(() => {
    if (!user) {
      setNotifications([]);
      setUnreadCount(0);
      setLoading(false);
      return;
    }

    const q = query(
      collection(db, 'notifications'),
      where('userId', '==', user.uid),
      orderBy('createdAt', 'desc'),
      limit(20)
    );

    const unsubscribe = onSnapshot(q, (querySnapshot) => {
      const notificationList: Notification[] = [];
      let unread = 0;

      querySnapshot.forEach((doc) => {
        const notification = { id: doc.id, ...doc.data() } as Notification;
        notificationList.push(notification);

        if (!notification.read) {
          unread++;
        }
      });

      setNotifications(notificationList);
      setUnreadCount(unread);
      setLoading(false);
    }, (error) => {
      console.error('Error fetching notifications:', error);
      setLoading(false);
    });

    return () => unsubscribe();
  }, [user]);

  const markAsRead = async (id: string) => {
    try {
      await markNotificationAsRead(id);
    } catch (error) {
      console.error('Error marking notification as read:', error);
    }
  };

  return (
    <NotificationContext.Provider value={{ notifications, unreadCount, markAsRead, loading }}>
      {children}
    </NotificationContext.Provider>
  );
};
EOL

# Create auth provider component
mkdir -p src/components/providers
cat > src/components/providers/auth-provider.tsx << 'EOL'
"use client";

import { AuthProvider as AuthContextProvider } from '@/lib/context/auth-context';

export function AuthProvider({ children }: { children: React.ReactNode }) {
  return <AuthContextProvider>{children}</AuthContextProvider>;
}
EOL

# Create notification provider component
cat > src/components/providers/notification-provider.tsx << 'EOL'
"use client";

import { NotificationProvider as NotificationContextProvider } from '@/lib/context/notification-context';

export function NotificationProvider({ children }: { children: React.ReactNode }) {
  return <NotificationContextProvider>{children}</NotificationContextProvider>;
}
EOL

# Create provider wrapper component
cat > src/components/providers/providers.tsx << 'EOL'
"use client";

import { ThemeProvider } from './theme-provider';
import { AuthProvider } from './auth-provider';
import { NotificationProvider } from './notification-provider';

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <ThemeProvider
      attribute="class"
      defaultTheme="light"
      enableSystem
      disableTransitionOnChange
    >
      <AuthProvider>
        <NotificationProvider>
          {children}
        </NotificationProvider>
      </AuthProvider>
    </ThemeProvider>
  );
}
EOL

# Update the root layout component
echo -e "${BLUE}📝 Updating root layout...${NC}"
cat > src/app/layout.tsx << 'EOL'
import { Poppins } from "next/font/google";
import { Providers } from "@/components/providers/providers";
import { Toaster } from "sonner";
import "./globals.css";

import type { Metadata } from "next";

const poppins = Poppins({
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
  variable: "--font-poppins",
});

export const metadata: Metadata = {
  title: "SpareWo Admin Dashboard",
  description: "Admin dashboard for the SpareWo auto parts marketplace",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className={`${poppins.variable} font-sans`}>
        <Providers>
          {children}
          <Toaster position="bottom-right" />
        </Providers>
      </body>
    </html>
  );
}
EOL

# Update middleware for Firebase Auth
echo -e "${BLUE}🔒 Updating authentication middleware...${NC}"
cat > src/middleware.ts << 'EOL'
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

// This function can be marked `async` if using `await` inside
export function middleware(request: NextRequest) {
  // Get the pathname of the request
  const path = request.nextUrl.pathname;

  // Define public paths that don't require authentication
  const isPublicPath = path === '/login' || path === '/forgot-password';

  // Get the Firebase auth session cookie
  const session = request.cookies.get('__session')?.value;

  // Redirect logic
  if (isPublicPath && session) {
    // If user is authenticated and tries to access login page,
    // redirect to dashboard
    return NextResponse.redirect(new URL('/dashboard', request.url));
  }

  if (!isPublicPath && !session) {
    // If user is not authenticated and tries to access protected route,
    // redirect to login page
    return NextResponse.redirect(new URL('/login', request.url));
  }
}

// See "Matching Paths" below to learn more
export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico|images).*)'],
};
EOL

# Create UI components
echo -e "${BLUE}🎨 Creating and updating UI components...${NC}"

# Create stat card component
mkdir -p src/components/ui
cat > src/components/ui/stat-card.tsx << 'EOL'
import { Card, CardContent } from "./card";
import { ReactNode } from "react";

interface StatCardProps {
  title: string;
  value: number | string;
  icon: ReactNode;
  change?: string;
  changeDirection?: 'up' | 'down';
  color?: string;
}

export function StatCard({
  title,
  value,
  icon,
  change,
  changeDirection = 'up',
  color = 'bg-indigo-600',
}: StatCardProps) {
  return (
    <Card>
      <CardContent className="p-4 md:p-6">
        <div className="flex items-center">
          <div className={`p-3 rounded-full ${color} mr-4 flex-shrink-0`}>
            {icon}
          </div>
          <div className="min-w-0 flex-1">
            <p className="text-sm font-medium text-gray-500 dark:text-gray-400 truncate">{title}</p>
            <p className="text-2xl font-semibold truncate">{value}</p>
            {change && (
              <div className="flex items-center mt-1">
                <span className={`text-xs font-medium ${
                  changeDirection === 'up' ? 'text-green-500' : 'text-red-500'
                }`}>
                  {change}
                </span>
                <span className="text-xs ml-1 text-gray-500 dark:text-gray-400">from last month</span>
              </div>
            )}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
EOL

# Create notification dropdown component
cat > src/components/ui/notification-dropdown.tsx << 'EOL'
"use client";

import { useState } from "react";
import { Bell } from "lucide-react";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "./dropdown-menu";
import { useNotifications } from "@/lib/context/notification-context";
import { Button } from "./button";
import { cn } from "@/lib/utils";
import Link from "next/link";

export function NotificationDropdown() {
  const { notifications, unreadCount, markAsRead } = useNotifications();
  const [open, setOpen] = useState(false);

  const handleMarkAsRead = async (id: string) => {
    await markAsRead(id);
  };

  const getNotificationIcon = (type: string) => {
    const colors = {
      info: "text-blue-500",
      success: "text-green-500",
      warning: "text-amber-500",
      error: "text-red-500",
    } as Record<string, string>;

    return <div className={`w-2 h-2 rounded-full ${colors[type] || colors.info}`} />;
  };

  return (
    <DropdownMenu open={open} onOpenChange={setOpen}>
      <DropdownMenuTrigger asChild>
        <Button variant="ghost" size="icon" className="relative">
          <Bell size={20} />
          {unreadCount > 0 && (
            <span className="absolute top-0 right-0 w-3 h-3 bg-red-500 rounded-full" />
          )}
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent className="w-80" align="end">
        <DropdownMenuLabel>Notifications</DropdownMenuLabel>
        <DropdownMenuSeparator />
        <div className="max-h-[600px] overflow-y-auto">
          {notifications.length === 0 ? (
            <div className="py-6 text-center text-sm text-gray-500 dark:text-gray-400">
              No notifications yet
            </div>
          ) : (
            notifications.map((notification) => (
              <DropdownMenuItem
                key={notification.id}
                className={cn(
                  "flex items-start gap-3 p-3 cursor-default",
                  !notification.read && "bg-gray-50 dark:bg-gray-900"
                )}
                onClick={() => handleMarkAsRead(notification.id)}
              >
                <div className="mt-1 flex-shrink-0">
                  {getNotificationIcon(notification.type)}
                </div>
                <div className="flex-1 space-y-1">
                  <div className="font-medium text-sm">
                    {notification.title}
                  </div>
                  <div className="text-xs text-gray-500 dark:text-gray-400">
                    {notification.message}
                  </div>
                  {notification.link && (
                    <Link
                      href={notification.link}
                      className="text-xs text-primary hover:underline"
                      onClick={() => setOpen(false)}
                    >
                      View details
                    </Link>
                  )}
                </div>
              </DropdownMenuItem>
            ))
          )}
        </div>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
EOL

# Create vendor status badge component
mkdir -p src/components/vendor
cat > src/components/vendor/vendor-status-badge.tsx << 'EOL'
import { Badge } from "@/components/ui/badge";
import { VENDOR_STATUSES } from "@/lib/types";

interface VendorStatusBadgeProps {
  status: 'pending' | 'approved' | 'rejected';
}

export function VendorStatusBadge({ status }: VendorStatusBadgeProps) {
  const statusConfig = VENDOR_STATUSES.find(s => s.value === status);

  if (!statusConfig) {
    return null;
  }

  return (
    <Badge
      className={`${statusConfig.color} text-white`}
    >
      {statusConfig.label}
    </Badge>
  );
}
EOL

# Create product status badge component
mkdir -p src/components/product
cat > src/components/product/product-status-badge.tsx << 'EOL'
import { Badge } from "@/components/ui/badge";
import { PRODUCT_STATUSES } from "@/lib/types";

interface ProductStatusBadgeProps {
  status: 'pending' | 'approved' | 'rejected';
}

export function ProductStatusBadge({ status }: ProductStatusBadgeProps) {
  const statusConfig = PRODUCT_STATUSES.find(s => s.value === status);

  if (!statusConfig) {
    return null;
  }

  return (
    <Badge
      className={`${statusConfig.color} text-white`}
    >
      {statusConfig.label}
    </Badge>
  );
}
EOL

# Create better responsive dashboard layout
echo -e "${BLUE}📝 Creating improved dashboard layout...${NC}"
mkdir -p src/app/dashboard
cat > src/app/dashboard/layout.tsx << 'EOL'
"use client";

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { usePathname } from 'next/navigation';
import { useTheme } from 'next-themes';
import {
  LayoutDashboard,
  Users,
  Package,
  ShoppingCart,
  Settings,
  Menu,
  X,
  Sun,
  Moon,
  LogOut
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { NotificationDropdown } from '@/components/ui/notification-dropdown';
import { useAuth } from '@/lib/context/auth-context';
import { logOut } from '@/lib/firebase/auth';
import { toast } from 'sonner';
import { getInitials } from '@/lib/utils';

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);
  const [isMobile, setIsMobile] = useState(false);
  const pathname = usePathname();
  const { theme, setTheme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const { user, adminData } = useAuth();

  // Check if mobile on mount and add resize listener
  useEffect(() => {
    const checkMobile = () => {
      setIsMobile(window.innerWidth < 1024);
      if (window.innerWidth < 1024) {
        setIsSidebarOpen(false);
      } else {
        setIsSidebarOpen(true);
      }
    };

    // Initial check
    checkMobile();

    // Add resize listener
    window.addEventListener('resize', checkMobile);

    // Fix hydration issues by only rendering after mount
    setMounted(true);

    return () => window.removeEventListener('resize', checkMobile);
  }, []);

  const toggleSidebar = () => {
    setIsSidebarOpen(!isSidebarOpen);
  };

  const toggleTheme = () => {
    setTheme(theme === 'dark' ? 'light' : 'dark');
  };

  const handleLogout = async () => {
    try {
      await logOut();
      toast.success('Logged out successfully');
    } catch (error) {
      toast.error('Failed to log out');
    }
  };

  // Navigation items
  const navItems = [
    {
      title: 'Dashboard',
      href: '/dashboard',
      icon: <LayoutDashboard size={20} />,
      active: pathname === '/dashboard',
    },
    {
      title: 'Vendors',
      href: '/dashboard/vendors',
      icon: <Users size={20} />,
      active: pathname.startsWith('/dashboard/vendors'),
    },
    {
      title: 'Products',
      href: '/dashboard/products',
      icon: <Package size={20} />,
      active: pathname.startsWith('/dashboard/products'),
    },
    {
      title: 'Orders',
      href: '/dashboard/orders',
      icon: <ShoppingCart size={20} />,
      active: pathname.startsWith('/dashboard/orders'),
    },
    {
      title: 'Settings',
      href: '/dashboard/settings',
      icon: <Settings size={20} />,
      active: pathname.startsWith('/dashboard/settings'),
    },
  ];

  // Get current page title
  const getCurrentPageTitle = () => {
    if (pathname === '/dashboard') return 'Dashboard';

    const parts = pathname.split('/');
    const lastPart = parts[parts.length - 1];

    if (lastPart === 'dashboard') return 'Dashboard';

    // Handle ID routes like /vendors/[id]
    if (parts.length > 2 && parts[parts.length - 2] === 'vendors') {
      return 'Vendor Details';
    }

    if (parts.length > 2 && parts[parts.length - 2] === 'products') {
      return 'Product Details';
    }

    // Capitalize first letter
    return lastPart.charAt(0).toUpperCase() + lastPart.slice(1);
  };

  // Add overlay when sidebar is open on mobile
  const sidebarOverlay = isMobile && isSidebarOpen ? (
    <div
      className="fixed inset-0 bg-black/50 z-20 lg:hidden"
      onClick={() => setIsSidebarOpen(false)}
    />
  ) : null;

  return (
    <div className={`flex min-h-screen ${mounted && theme === 'dark' ? 'bg-gray-900 text-white' : 'bg-gray-100'}`}>
      {/* Sidebar overlay */}
      {sidebarOverlay}

      {/* Sidebar */}
      <div
        className={`${
          isSidebarOpen ? "w-64" : "w-0 lg:w-20"
        } ${mounted && theme === 'dark' ? 'bg-gray-800' : 'bg-indigo-900'} fixed inset-y-0 left-0 z-30 transition-all duration-300 ease-in-out flex flex-col overflow-hidden`}
      >
        {/* Logo */}
        <div className="flex items-center justify-between h-16 px-4 border-b border-opacity-20 border-gray-600">
          <div className="flex items-center space-x-2">
            {/* Update the path to your logo */}
            {isSidebarOpen && (
              <div className="text-lg font-semibold text-white flex items-center">
                <Image
                  src="/images/logo.png"
                  alt="SpareWo Logo"
                  width={32}
                  height={32}
                  className="mr-2"
                />
                SpareWo Admin
              </div>
            )}
          </div>
          <button onClick={toggleSidebar} className="text-white lg:block hidden">
            {isSidebarOpen ? <X size={20} /> : <Menu size={20} />}
          </button>
        </div>

        {/* Navigation */}
        <nav className="flex-1 overflow-y-auto py-4">
          <div className="px-4 space-y-1">
            {navItems.map((item) => (
              <Link key={item.title} href={item.href}>
                <div
                  className={`flex items-center py-3 px-4 rounded-md cursor-pointer transition-colors ${
                    item.active
                      ? "bg-orange-500 text-white"
                      : "text-gray-300 hover:bg-orange-500 hover:bg-opacity-30 hover:text-white"
                  } ${!isSidebarOpen && 'justify-center'}`}
                >
                  <div className="flex items-center justify-center">
                    {item.icon}
                  </div>
                  {isSidebarOpen && <span className="ml-3 text-sm">{item.title}</span>}
                </div>
              </Link>
            ))}
          </div>
        </nav>

        {/* User */}
        <div className="p-4 border-t border-gray-600 border-opacity-20">
          <div className="flex items-center">
            <div className="flex-shrink-0">
              <div className="w-8 h-8 rounded-full bg-orange-500 flex items-center justify-center text-white font-medium">
                {user ? getInitials(user.displayName || user.email || 'A') : 'A'}
              </div>
            </div>
            {isSidebarOpen && (
              <div className="ml-3 overflow-hidden">
                <p className="text-sm font-medium text-white truncate">
                  {user?.displayName || 'Admin User'}
                </p>
                <p className="text-xs text-gray-300 truncate">
                  {adminData?.role || 'Admin'}
                </p>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div
        className={`flex-1 ${
          isSidebarOpen ? "lg:ml-64" : "lg:ml-20"
        } transition-all duration-300 ease-in-out`}
      >
        {/* Header */}
        <header
          className={`fixed right-0 left-0 lg:left-auto ${
            isSidebarOpen ? "lg:left-64" : "lg:left-20"
          } h-16 z-20 flex items-center justify-between px-4 border-b ${
            mounted && theme === 'dark' ? 'bg-gray-800 border-gray-700' : 'bg-white border-gray-200'
          } transition-all duration-300`}
        >
          <div className="flex items-center">
            <button
              onClick={toggleSidebar}
              className="text-gray-500 dark:text-gray-300 mr-4 lg:hidden"
            >
              <Menu size={20} />
            </button>
            <h1 className="text-xl font-semibold truncate">
              {getCurrentPageTitle()}
            </h1>
          </div>

          <div className="flex items-center space-x-4">
            <button
              onClick={toggleTheme}
              className={`p-1 rounded-full ${theme === 'dark' ? 'text-gray-300 hover:text-white' : 'text-gray-500 hover:text-gray-700'}`}
            >
              {theme === 'dark' ? <Sun size={20} /> : <Moon size={20} />}
            </button>

            <NotificationDropdown />

            <Button
              variant="ghost"
              size="icon"
              onClick={handleLogout}
              aria-label="Log out"
            >
              <LogOut size={20} />
            </Button>
          </div>
        </header>

        {/* Main content */}
        <main className="pt-24 px-4 md:px-6 pb-6 min-h-screen">
          <div className="max-w-7xl mx-auto">
            {children}
          </div>
        </main>
      </div>
    </div>
  );
}
EOL

# Create dashboard page
cat > src/app/dashboard/page.tsx << 'EOL'
"use client";

import React, { useEffect, useState } from "react";
import {
  Users,
  Package,
  ShoppingCart,
  Clock,
  CheckCircle,
  AlertCircle,
  PlusCircle,
  Truck
} from 'lucide-react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { StatCard } from "@/components/ui/stat-card";
import { getTotalVendorCount, countVendorsByStatus } from "@/lib/firebase/vendors";
import { getTotalProductCount, countProductsByStatus } from "@/lib/firebase/products";
import Link from "next/link";

export default function Dashboard() {
  // Stats state
  const [stats, setStats] = useState({
    vendors: 0,
    vendorChange: "+0%",
    products: 0,
    productChange: "+0%",
    pendingApprovals: 0,
    orders: 0,
    orderChange: "+0%"
  });

  // Loading state
  const [loading, setLoading] = useState(true);

  // Fetch stats on component mount
  useEffect(() => {
    const fetchStats = async () => {
      try {
        const totalVendors = await getTotalVendorCount();
        const pendingVendors = await countVendorsByStatus('pending');
        const totalProducts = await getTotalProductCount();
        const pendingProducts = await countProductsByStatus('pending');

        // Calculate total pending approvals
        const totalPending = pendingVendors + pendingProducts;

        setStats({
          vendors: totalVendors,
          vendorChange: "+12%", // Example - would need historical data for real value
          products: totalProducts,
          productChange: "+8%", // Example - would need historical data for real value
          pendingApprovals: totalPending,
          orders: 0, // Would need order data
          orderChange: "+0%"
        });
      } catch (error) {
        console.error('Error fetching dashboard stats:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchStats();
  }, []);

  // Sample activity feed
  const recentActivity = [
    {
      id: '1',
      icon: <Users size={16} />,
      title: 'New vendor registration',
      description: 'Auto Parts Plus has registered as a new vendor',
      time: 'Just now',
      status: 'success',
    },
    {
      id: '2',
      icon: <Package size={16} />,
      title: 'New products added',
      description: '25 new products were uploaded by CarTech Solutions',
      time: '2 hours ago',
      status: 'success',
    },
    {
      id: '3',
      icon: <AlertCircle size={16} />,
      title: 'Product rejected',
      description: 'Brake pads from Mecha Parts were rejected',
      time: '5 hours ago',
      status: 'danger',
    },
    {
      id: '4',
      icon: <ShoppingCart size={16} />,
      title: 'New order received',
      description: 'Order #10234 needs to be assigned to a vendor',
      time: 'Yesterday',
      status: 'warning',
    },
  ];

  return (
    <div className="space-y-6">
      <div className="mb-6">
        <h1 className="text-2xl font-semibold">Dashboard</h1>
        <p className="mt-1 text-gray-500 dark:text-gray-400">
          Welcome back, here&apos;s what&apos;s happening with your platform today.
        </p>
      </div>

      {/* Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <StatCard
          title="Total Vendors"
          value={stats.vendors}
          change={stats.vendorChange}
          icon={<Users className="h-6 w-6 text-white" />}
          color="bg-indigo-600"
        />
        <StatCard
          title="Products"
          value={stats.products}
          change={stats.productChange}
          icon={<Package className="h-6 w-6 text-white" />}
          color="bg-orange-500"
        />
        <StatCard
          title="Pending Approvals"
          value={stats.pendingApprovals}
          change="-"
          icon={<Clock className="h-6 w-6 text-white" />}
          color="bg-amber-500"
        />
        <StatCard
          title="Total Orders"
          value={stats.orders}
          change={stats.orderChange}
          icon={<ShoppingCart className="h-6 w-6 text-white" />}
          color="bg-green-600"
        />
      </div>

      {/* Main Content */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Quick Actions */}
        <Card className="lg:col-span-1">
          <CardHeader>
            <CardTitle>Quick Actions</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <Link href="/dashboard/vendors/pending">
              <Button
                variant="outline"
                className="flex items-center w-full justify-start"
              >
                <CheckCircle size={18} className="mr-2" />
                Approve Vendors
              </Button>
            </Link>
            <Link href="/dashboard/products/pending">
              <Button
                variant="outline"
                className="flex items-center w-full justify-start"
              >
                <Package size={18} className="mr-2" />
                Review Products
              </Button>
            </Link>
            <Link href="/dashboard/orders">
              <Button
                variant="outline"
                className="flex items-center w-full justify-start"
              >
                <Truck size={18} className="mr-2" />
                Process Orders
              </Button>
            </Link>
            <Link href="/dashboard/vendors">
              <Button
                variant="outline"
                className="flex items-center w-full justify-start"
              >
                <PlusCircle size={18} className="mr-2" />
                Manage Vendors
              </Button>
            </Link>
          </CardContent>
        </Card>

        {/* Recent Activity */}
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle>Recent Activity</CardTitle>
            <CardDescription>Latest actions in the system</CardDescription>
          </CardHeader>
          <CardContent>
            {recentActivity.map((activity) => (
              <ActivityItem
                key={activity.id}
                icon={activity.icon}
                title={activity.title}
                description={activity.description}
                time={activity.time}
                status={activity.status}
              />
            ))}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

// Activity Item Component
interface ActivityItemProps {
  icon: React.ReactNode;
  title: string;
  description: string;
  time: string;
  status: 'success' | 'warning' | 'danger';
}

const ActivityItem = ({ icon, title, description, time, status }: ActivityItemProps) => {
  const statusColors: Record<string, string> = {
    success: 'bg-green-500',
    warning: 'bg-amber-500',
    danger: 'bg-red-500'
  };

  return (
    <div className="flex items-start mb-4 pb-4 border-b border-gray-200 dark:border-gray-700 last:border-0">
      <div className={`${statusColors[status]} p-2 rounded-full mr-4 text-white flex-shrink-0`}>
        {icon}
      </div>
      <div className="flex-1 min-w-0">
        <h3 className="text-sm font-medium truncate">{title}</h3>
        <p className="text-xs text-gray-500 dark:text-gray-400 mt-1 truncate">{description}</p>
        <span className="text-xs text-gray-400 dark:text-gray-500 mt-1 block">{time}</span>
      </div>
    </div>
  );
};
EOL

# Create vendors page
mkdir -p src/app/dashboard/vendors
cat > src/app/dashboard/vendors/page.tsx << 'EOL'
"use client";

import { useState, useEffect } from "react";
import { getVendors } from "@/lib/firebase/vendors";
import { Vendor } from "@/lib/types/vendor";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue
} from "@/components/ui/select";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow
} from "@/components/ui/table";
import { VendorStatusBadge } from "@/components/vendor/vendor-status-badge";
import { DocumentData } from "firebase/firestore";
import { formatDate } from "@/lib/utils";
import Link from "next/link";
import { Search, ChevronRight } from "lucide-react";

export default function VendorsPage() {
  const [vendors, setVendors] = useState<Vendor[]>([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState<string>("all");
  const [searchQuery, setSearchQuery] = useState("");
  const [lastDoc, setLastDoc] = useState<DocumentData | undefined>(undefined);
  const [hasMore, setHasMore] = useState(true);

  // Fetch vendors on component mount and when filters change
  useEffect(() => {
    const fetchVendors = async () => {
      setLoading(true);
      try {
        const status = statusFilter === "all" ? null : statusFilter;
        const result = await getVendors(status, 10);
        setVendors(result.vendors);
        setLastDoc(result.lastDoc);
        setHasMore(result.vendors.length === 10);
      } catch (error) {
        console.error("Error fetching vendors:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchVendors();
  }, [statusFilter]);

  // Load more vendors
  const loadMore = async () => {
    if (!lastDoc) return;

    try {
      const status = statusFilter === "all" ? null : statusFilter;
      const result = await getVendors(status, 10, lastDoc);
      setVendors([...vendors, ...result.vendors]);
      setLastDoc(result.lastDoc);
      setHasMore(result.vendors.length === 10);
    } catch (error) {
      console.error("Error loading more vendors:", error);
    }
  };

  // Handle search
  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    // In a real app, this would search by calling the Firebase function
    console.log("Searching for:", searchQuery);
    // For now, we'll just filter the client-side data
    // This is just for demonstration - in a real app, you'd search the database
  };

  // Filter vendors by search query (client-side filtering for demo)
  const filteredVendors = vendors.filter(vendor =>
    vendor.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    vendor.email.toLowerCase().includes(searchQuery.toLowerCase()) ||
    vendor.businessName.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">Vendors</h1>
          <p className="text-gray-500 dark:text-gray-400">
            Manage and review vendor accounts
          </p>
        </div>

        <div className="flex flex-col sm:flex-row gap-2">
          <form onSubmit={handleSearch} className="flex w-full sm:w-auto">
            <Input
              placeholder="Search vendors..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="rounded-r-none"
            />
            <Button type="submit" className="rounded-l-none">
              <Search size={18} />
            </Button>
          </form>

          <Select
            value={statusFilter}
            onValueChange={setStatusFilter}
          >
            <SelectTrigger className="w-full sm:w-32">
              <SelectValue placeholder="Status" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All</SelectItem>
              <SelectItem value="pending">Pending</SelectItem>
              <SelectItem value="approved">Approved</SelectItem>
              <SelectItem value="rejected">Rejected</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>

      <div className="border rounded-lg overflow-hidden">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Vendor Name</TableHead>
              <TableHead>Business Name</TableHead>
              <TableHead>Email</TableHead>
              <TableHead>Date Joined</TableHead>
              <TableHead>Status</TableHead>
              <TableHead className="text-right">Action</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {loading ? (
              <TableRow>
                <TableCell colSpan={6} className="text-center py-10">
                  <div className="flex justify-center">
                    <div className="w-6 h-6 border-2 border-primary border-t-transparent rounded-full animate-spin"></div>
                  </div>
                </TableCell>
              </TableRow>
            ) : filteredVendors.length === 0 ? (
              <TableRow>
                <TableCell colSpan={6} className="text-center py-10">
                  No vendors found
                </TableCell>
              </TableRow>
            ) : (
              filteredVendors.map((vendor) => (
                <TableRow key={vendor.id}>
                  <TableCell>{vendor.name}</TableCell>
                  <TableCell>{vendor.businessName}</TableCell>
                  <TableCell>{vendor.email}</TableCell>
                  <TableCell>{formatDate(vendor.createdAt)}</TableCell>
                  <TableCell>
                    <VendorStatusBadge status={vendor.status} />
                  </TableCell>
                  <TableCell className="text-right">
                    <Link href={`/dashboard/vendors/${vendor.id}`}>
                      <Button variant="ghost" size="icon">
                        <ChevronRight size={18} />
                      </Button>
                    </Link>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </div>

      {hasMore && (
        <div className="flex justify-center mt-4">
          <Button
            variant="outline"
            onClick={loadMore}
            disabled={loading || !hasMore}
          >
            Load More
          </Button>
        </div>
      )}
    </div>
  );
}
EOL

# Create pending vendors page
mkdir -p src/app/dashboard/vendors/pending
cat > src/app/dashboard/vendors/pending/page.tsx << 'EOL'
"use client";

import { useState, useEffect } from "react";
import { getPendingVendors, updateVendorStatus } from "@/lib/firebase/vendors";
import { Vendor } from "@/lib/types/vendor";
import { Button } from "@/components/ui/button";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Textarea } from "@/components/ui/input"; // Changed from input to textarea
import { VendorStatusBadge } from "@/components/vendor/vendor-status-badge";
import { DocumentData } from "firebase/firestore";
import { formatDate } from "@/lib/utils";
import Link from "next/link";
import { CheckCircle, XCircle, ChevronRight } from "lucide-react";
import { toast } from "sonner";

export default function PendingVendorsPage() {
  const [vendors, setVendors] = useState<Vendor[]>([]);
  const [loading, setLoading] = useState(true);
  const [lastDoc, setLastDoc] = useState<DocumentData | undefined>(undefined);
  const [hasMore, setHasMore] = useState(true);

  // Dialog state
  const [dialogOpen, setDialogOpen] = useState(false);
  const [dialogAction, setDialogAction] = useState<"approve" | "reject">("approve");
  const [selectedVendor, setSelectedVendor] = useState<Vendor | null>(null);
  const [rejectionReason, setRejectionReason] = useState("");

  // Fetch pending vendors on component mount
  useEffect(() => {
    const fetchVendors = async () => {
      setLoading(true);
      try {
        const result = await getPendingVendors(10);
        setVendors(result.vendors);
        setLastDoc(result.lastDoc);
        setHasMore(result.vendors.length === 10);
      } catch (error) {
        console.error("Error fetching pending vendors:", error);
        toast.error("Failed to load pending vendors");
      } finally {
        setLoading(false);
      }
    };

    fetchVendors();
  }, []);

  // Load more vendors
  const loadMore = async () => {
    if (!lastDoc) return;

    try {
      const result = await getPendingVendors(10, lastDoc);
      setVendors([...vendors, ...result.vendors]);
      setLastDoc(result.lastDoc);
      setHasMore(result.vendors.length === 10);
    } catch (error) {
      console.error("Error loading more vendors:", error);
      toast.error("Failed to load more vendors");
    }
  };

  // Open approval dialog
  const openApproveDialog = (vendor: Vendor) => {
    setSelectedVendor(vendor);
    setDialogAction("approve");
    setDialogOpen(true);
  };

  // Open rejection dialog
  const openRejectDialog = (vendor: Vendor) => {
    setSelectedVendor(vendor);
    setDialogAction("reject");
    setRejectionReason("");
    setDialogOpen(true);
  };

  // Handle dialog confirmation
  const handleConfirm = async () => {
    if (!selectedVendor) return;

    try {
      if (dialogAction === "approve") {
        await updateVendorStatus(selectedVendor.id, "approved");
        toast.success(`Vendor ${selectedVendor.name} has been approved`);
      } else {
        await updateVendorStatus(selectedVendor.id, "rejected", rejectionReason);
        toast.success(`Vendor ${selectedVendor.name} has been rejected`);
      }

      // Update the local state to remove the processed vendor
      setVendors(vendors.filter(v => v.id !== selectedVendor.id));
    } catch (error) {
      console.error(`Error ${dialogAction}ing vendor:`, error);
      toast.error(`Failed to ${dialogAction} vendor`);
    } finally {
      setDialogOpen(false);
      setSelectedVendor(null);
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">Pending Vendors</h1>
        <p className="text-gray-500 dark:text-gray-400">
          Review and approve vendor registration requests
        </p>
      </div>

      <div className="border rounded-lg overflow-hidden">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Vendor Name</TableHead>
              <TableHead>Business Name</TableHead>
              <TableHead>Email</TableHead>
              <TableHead>Date Joined</TableHead>
              <TableHead>Status</TableHead>
              <TableHead className="text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {loading ? (
              <TableRow>
                <TableCell colSpan={6} className="text-center py-10">
                  <div className="flex justify-center">
                    <div className="w-6 h-6 border-2 border-primary border-t-transparent rounded-full animate-spin"></div>
                  </div>
                </TableCell>
              </TableRow>
            ) : vendors.length === 0 ? (
              <TableRow>
                <TableCell colSpan={6} className="text-center py-10">
                  No pending vendors
                </TableCell>
              </TableRow>
            ) : (
              vendors.map((vendor) => (
                <TableRow key={vendor.id}>
                  <TableCell>{vendor.name}</TableCell>
                  <TableCell>{vendor.businessName}</TableCell>
                  <TableCell>{vendor.email}</TableCell>
                  <TableCell>{formatDate(vendor.createdAt)}</TableCell>
                  <TableCell>
                    <VendorStatusBadge status={vendor.status} />
                  </TableCell>
                  <TableCell className="text-right">
                    <div className="flex justify-end items-center space-x-2">
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => openApproveDialog(vendor)}
                        className="text-green-500 hover:text-green-600 hover:bg-green-50"
                      >
                        <CheckCircle size={18} />
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => openRejectDialog(vendor)}
                        className="text-red-500 hover:text-red-600 hover:bg-red-50"
                      >
                        <XCircle size={18} />
                      </Button>
                      <Link href={`/dashboard/vendors/${vendor.id}`}>
                        <Button variant="ghost" size="icon">
                          <ChevronRight size={18} />
                        </Button>
                      </Link>
                    </div>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </div>

      {hasMore && (
        <div className="flex justify-center mt-4">
          <Button
            variant="outline"
            onClick={loadMore}
            disabled={loading || !hasMore}
          >
            Load More
          </Button>
        </div>
      )}

      {/* Approval/Rejection Dialog */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {dialogAction === "approve" ? "Approve Vendor" : "Reject Vendor"}
            </DialogTitle>
            <DialogDescription>
              {dialogAction === "approve"
                ? "Are you sure you want to approve this vendor? They will be able to upload products to the marketplace."
                : "Please provide a reason for rejecting this vendor."}
            </DialogDescription>
          </DialogHeader>

          {dialogAction === "reject" && (
            <Textarea
              placeholder="Reason for rejection"
              value={rejectionReason}
              onChange={(e) => setRejectionReason(e.target.value)}
              className="min-h-[100px]"
            />
          )}

          <DialogFooter>
            <Button variant="outline" onClick={() => setDialogOpen(false)}>
              Cancel
            </Button>
            <Button
              onClick={handleConfirm}
              variant={dialogAction === "approve" ? "default" : "destructive"}
              disabled={dialogAction === "reject" && !rejectionReason.trim()}
            >
              {dialogAction === "approve" ? "Approve" : "Reject"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
EOL

# Create vendor detail page (Complete version from Part 2)
mkdir -p src/app/dashboard/vendors/\[id\]
cat > src/app/dashboard/vendors/\[id\]/page.tsx << 'EOL'
"use client";

import { useState, useEffect } from "react";
import { useParams } from "next/navigation";
import { getVendorById, updateVendorStatus } from "@/lib/firebase/vendors";
import { getProductsByVendorId } from "@/lib/firebase/products";
import { Vendor } from "@/lib/types/vendor";
import { Product } from "@/lib/types/product";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Tabs,
  TabsContent,
  TabsList,
  TabsTrigger,
} from "@/components/ui/tabs";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Textarea } from "@/components/ui/textarea"; // Use Textarea here
import { VendorStatusBadge } from "@/components/vendor/vendor-status-badge";
import { ProductStatusBadge } from "@/components/product/product-status-badge";
import { formatDate, formatDateTime } from "@/lib/utils";
import Link from "next/link";
import { ChevronRight, CheckCircle, XCircle, ArrowLeft, ExternalLink } from "lucide-react";
import { toast } from "sonner";
import Image from "next/image";

export default function VendorDetailPage() {
  const { id } = useParams<{ id: string }>();
  const [vendor, setVendor] = useState<Vendor | null>(null);
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);

  // Dialog state
  const [dialogOpen, setDialogOpen] = useState(false);
  const [dialogAction, setDialogAction] = useState<"approve" | "reject">("approve");
  const [rejectionReason, setRejectionReason] = useState("");

  // Fetch vendor and products
  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      try {
        const vendorData = await getVendorById(id as string);
        setVendor(vendorData);

        if (vendorData) {
          const productsData = await getProductsByVendorId(id as string);
          setProducts(productsData.products);
        }
      } catch (error) {
        console.error("Error fetching vendor data:", error);
        toast.error("Failed to load vendor data");
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [id]);

  // Open approval dialog
  const openApproveDialog = () => {
    setDialogAction("approve");
    setDialogOpen(true);
  };

  // Open rejection dialog
  const openRejectDialog = () => {
    setDialogAction("reject");
    setRejectionReason("");
    setDialogOpen(true);
  };

  // Handle dialog confirmation
  const handleConfirm = async () => {
    if (!vendor) return;

    try {
      if (dialogAction === "approve") {
        await updateVendorStatus(vendor.id, "approved");
        setVendor({ ...vendor, status: "approved" });
        toast.success(`Vendor ${vendor.name} has been approved`);
      } else {
        await updateVendorStatus(vendor.id, "rejected", rejectionReason);
        setVendor({ ...vendor, status: "rejected", rejectionReason });
        toast.success(`Vendor ${vendor.name} has been rejected`);
      }
    } catch (error) {
      console.error(`Error ${dialogAction}ing vendor:`, error);
      toast.error(`Failed to ${dialogAction} vendor`);
    } finally {
      setDialogOpen(false);
    }
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-96">
        <div className="w-8 h-8 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
      </div>
    );
  }

  if (!vendor) {
    return (
      <div className="text-center py-12">
        <h2 className="text-xl font-semibold mb-2">Vendor Not Found</h2>
        <p className="text-gray-500 dark:text-gray-400 mb-6">
          The vendor you are looking for does not exist or has been removed.
        </p>
        <Link href="/dashboard/vendors">
          <Button>
            <ArrowLeft size={16} className="mr-2" />
            Back to Vendors
          </Button>
        </Link>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center">
          <Link href="/dashboard/vendors">
            <Button variant="ghost" size="icon" className="mr-2">
              <ArrowLeft size={20} />
            </Button>
          </Link>
          <div>
            <h1 className="text-2xl font-semibold">{vendor.name}</h1>
            <p className="text-gray-500 dark:text-gray-400">
              {vendor.businessName}
            </p>
          </div>
        </div>

        {vendor.status === "pending" && (
          <div className="flex space-x-2">
            <Button
              onClick={openApproveDialog}
              variant="default"
              className="bg-green-600 hover:bg-green-700"
            >
              <CheckCircle size={16} className="mr-2" />
              Approve
            </Button>
            <Button
              onClick={openRejectDialog}
              variant="destructive"
            >
              <XCircle size={16} className="mr-2" />
              Reject
            </Button>
          </div>
        )}
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="md:col-span-2">
          <Tabs defaultValue="details">
            <TabsList>
              <TabsTrigger value="details">Details</TabsTrigger>
              <TabsTrigger value="products">Products</TabsTrigger>
              <TabsTrigger value="documents">Documents</TabsTrigger>
            </TabsList>

            <TabsContent value="details" className="pt-4">
              <Card>
                <CardHeader>
                  <CardTitle>Vendor Information</CardTitle>
                  <CardDescription>
                    Detailed information about the vendor
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                        Contact Name
                      </h3>
                      <p>{vendor.name}</p>
                    </div>
                    <div>
                      <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                        Business Name
                      </h3>
                      <p>{vendor.businessName}</p>
                    </div>
                    <div>
                      <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                        Email
                      </h3>
                      <p>{vendor.email}</p>
                    </div>
                    <div>
                      <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                        Phone
                      </h3>
                      <p>{vendor.phone}</p>
                    </div>
                    <div>
                      <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                        Address
                      </h3>
                      <p>{vendor.address}</p>
                    </div>
                    <div>
                      <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                        Business Type
                      </h3>
                      <p>{vendor.businessType}</p>
                    </div>
                    {vendor.businessRegistrationNumber && (
                      <div>
                        <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                          Registration Number
                        </h3>
                        <p>{vendor.businessRegistrationNumber}</p>
                      </div>
                    )}
                    {vendor.taxId && (
                      <div>
                        <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                          Tax ID
                        </h3>
                        <p>{vendor.taxId}</p>
                      </div>
                    )}
                  </div>

                  {vendor.description && (
                    <div>
                      <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400 mb-2">
                        Description
                      </h3>
                      <p className="text-sm">{vendor.description}</p>
                    </div>
                  )}
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="products" className="pt-4">
              <Card>
                <CardHeader>
                  <CardTitle>Vendor Products</CardTitle>
                  <CardDescription>
                    Products uploaded by this vendor
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  {products.length === 0 ? (
                    <p className="text-center py-8 text-gray-500">
                      This vendor has not uploaded any products yet.
                    </p>
                  ) : (
                    <div className="border rounded-lg overflow-hidden">
                      <Table>
                        <TableHeader>
                          <TableRow>
                            <TableHead>Product Name</TableHead>
                            <TableHead>Category</TableHead>
                            <TableHead>Price</TableHead>
                            <TableHead>Status</TableHead>
                            <TableHead className="text-right">Action</TableHead>
                          </TableRow>
                        </TableHeader>
                        <TableBody>
                          {products.map((product) => (
                            <TableRow key={product.id}>
                              <TableCell>{product.name}</TableCell>
                              <TableCell>{product.category}</TableCell>
                              <TableCell>
                                UGX {product.price.toLocaleString()}
                              </TableCell>
                              <TableCell>
                                <ProductStatusBadge status={product.status} />
                              </TableCell>
                              <TableCell className="text-right">
                                <Link href={`/dashboard/products/${product.id}`}>
                                  <Button variant="ghost" size="icon">
                                    <ChevronRight size={18} />
                                  </Button>
                                </Link>
                              </TableCell>
                            </TableRow>
                          ))}
                        </TableBody>
                      </Table>
                    </div>
                  )}
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="documents" className="pt-4">
              <Card>
                <CardHeader>
                  <CardTitle>Vendor Documents</CardTitle>
                  <CardDescription>
                    Business verification documents
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  {!vendor.documentUrls || vendor.documentUrls.length === 0 ? (
                    <p className="text-center py-8 text-gray-500">
                      No documents have been uploaded by this vendor.
                    </p>
                  ) : (
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      {vendor.documentUrls.map((url, index) => (
                        <div key={index} className="border rounded-lg p-4">
                          <div className="aspect-video relative bg-gray-100 mb-3 rounded overflow-hidden">
                            {url.endsWith('.pdf') ? (
                              <div className="flex items-center justify-center h-full">
                                <p className="text-gray-500">PDF Document</p>
                              </div>
                            ) : (
                              <Image
                                src={url}
                                alt={`Document ${index + 1}`}
                                fill
                                className="object-cover"
                              />
                            )}
                          </div>
                          <div className="flex justify-between items-center">
                            <p className="text-sm font-medium">Document {index + 1}</p>
                            <a href={url} target="_blank" rel="noopener noreferrer">
                              <Button variant="ghost" size="sm">
                                <ExternalLink size={14} className="mr-1" />
                                View
                              </Button>
                            </a>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </CardContent>
              </Card>
            </TabsContent>
          </Tabs>
        </div>

        <div>
          <Card>
            <CardHeader>
              <CardTitle>Status</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex justify-between items-center">
                <div>
                  <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                    Current Status
                  </h3>
                  <div className="mt-1">
                    <VendorStatusBadge status={vendor.status} />
                  </div>
                </div>

                {vendor.status !== "pending" && (
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => {
                      if (vendor.status === "approved") {
                        openRejectDialog();
                      } else {
                        openApproveDialog();
                      }
                    }}
                  >
                    {vendor.status === "approved" ? "Reject" : "Approve"}
                  </Button>
                )}
              </div>

              <div>
                <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                  Date Joined
                </h3>
                <p>{formatDateTime(vendor.createdAt)}</p>
              </div>

              {vendor.status === "approved" && vendor.approvedAt && (
                <div>
                  <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                    Approval Date
                  </h3>
                  <p>{formatDateTime(vendor.approvedAt)}</p>
                </div>
              )}

              {vendor.status === "rejected" && vendor.rejectedAt && (
                <>
                  <div>
                    <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                      Rejection Date
                    </h3>
                    <p>{formatDateTime(vendor.rejectedAt)}</p>
                  </div>

                  {vendor.rejectionReason && (
                    <div>
                      <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                        Rejection Reason
                      </h3>
                      <p className="text-sm mt-1">{vendor.rejectionReason}</p>
                    </div>
                  )}
                </>
              )}

              <div>
                <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                  Product Count
                </h3>
                <p>{products.length}</p>
              </div>
            </CardContent>
          </Card>

          {vendor.logoUrl && (
            <Card className="mt-4">
              <CardHeader>
                <CardTitle>Vendor Logo</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="aspect-square relative bg-gray-100 rounded overflow-hidden">
                  <Image
                    src={vendor.logoUrl}
                    alt={`${vendor.businessName} Logo`}
                    fill
                    className="object-contain"
                  />
                </div>
              </CardContent>
            </Card>
          )}
        </div>
      </div>

      {/* Approval/Rejection Dialog */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {dialogAction === "approve" ? "Approve Vendor" : "Reject Vendor"}
            </DialogTitle>
            <DialogDescription>
              {dialogAction === "approve"
                ? "Are you sure you want to approve this vendor? They will be able to upload products to the marketplace."
                : "Please provide a reason for rejecting this vendor."}
            </DialogDescription>
          </DialogHeader>

          {dialogAction === "reject" && (
            <Textarea
              placeholder="Reason for rejection"
              value={rejectionReason}
              onChange={(e) => setRejectionReason(e.target.value)}
              className="min-h-[100px]"
            />
          )}

          <DialogFooter>
            <Button variant="outline" onClick={() => setDialogOpen(false)}>
              Cancel
            </Button>
            <Button
              onClick={handleConfirm}
              variant={dialogAction === "approve" ? "default" : "destructive"}
              disabled={dialogAction === "reject" && !rejectionReason.trim()}
            >
              {dialogAction === "approve" ? "Approve" : "Reject"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
EOL

# Create products page
echo -e "${BLUE}📝 Creating products page...${NC}"
mkdir -p src/app/dashboard/products
cat > src/app/dashboard/products/page.tsx << 'EOL'
"use client";

import { useState, useEffect } from "react";
import { getProducts } from "@/lib/firebase/products";
import { Product } from "@/lib/types/product";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue
} from "@/components/ui/select";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow
} from "@/components/ui/table";
import { ProductStatusBadge } from "@/components/product/product-status-badge";
import { DocumentData } from "firebase/firestore";
import { formatCurrency, formatDate } from "@/lib/utils";
import Link from "next/link";
import { Search, ChevronRight } from "lucide-react";

export default function ProductsPage() {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState<string>("all");
  const [searchQuery, setSearchQuery] = useState("");
  const [lastDoc, setLastDoc] = useState<DocumentData | undefined>(undefined);
  const [hasMore, setHasMore] = useState(true);

  // Fetch products on component mount and when filters change
  useEffect(() => {
    const fetchProducts = async () => {
      setLoading(true);
      try {
        const status = statusFilter === "all" ? null : statusFilter;
        const result = await getProducts(status, null, 10);
        setProducts(result.products);
        setLastDoc(result.lastDoc);
        setHasMore(result.products.length === 10);
      } catch (error) {
        console.error("Error fetching products:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchProducts();
  }, [statusFilter]);

  // Load more products
  const loadMore = async () => {
    if (!lastDoc) return;

    try {
      const status = statusFilter === "all" ? null : statusFilter;
      const result = await getProducts(status, null, 10, lastDoc);
      setProducts([...products, ...result.products]);
      setLastDoc(result.lastDoc);
      setHasMore(result.products.length === 10);
    } catch (error) {
      console.error("Error loading more products:", error);
    }
  };

  // Handle search
  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    // In a real app, this would search by calling the Firebase function
    console.log("Searching for:", searchQuery);
    // For now, we'll just filter the client-side data
    // This is just for demonstration - in a real app, you'd search the database
  };

  // Filter products by search query (client-side filtering for demo)
  const filteredProducts = products.filter(product =>
    product.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    product.brand.toLowerCase().includes(searchQuery.toLowerCase()) ||
    product.category.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">Products</h1>
          <p className="text-gray-500 dark:text-gray-400">
            Manage and review all products
          </p>
        </div>

        <div className="flex flex-col sm:flex-row gap-2">
          <form onSubmit={handleSearch} className="flex w-full sm:w-auto">
            <Input
              placeholder="Search products..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="rounded-r-none"
            />
            <Button type="submit" className="rounded-l-none">
              <Search size={18} />
            </Button>
          </form>

          <Select
            value={statusFilter}
            onValueChange={setStatusFilter}
          >
            <SelectTrigger className="w-full sm:w-32">
              <SelectValue placeholder="Status" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All</SelectItem>
              <SelectItem value="pending">Pending</SelectItem>
              <SelectItem value="approved">Approved</SelectItem>
              <SelectItem value="rejected">Rejected</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>

      <div className="border rounded-lg overflow-hidden">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Product Name</TableHead>
              <TableHead>Category</TableHead>
              <TableHead>Brand</TableHead>
              <TableHead>Price</TableHead>
              <TableHead>Status</TableHead>
              <TableHead className="text-right">Action</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {loading ? (
              <TableRow>
                <TableCell colSpan={6} className="text-center py-10">
                  <div className="flex justify-center">
                    <div className="w-6 h-6 border-2 border-primary border-t-transparent rounded-full animate-spin"></div>
                  </div>
                </TableCell>
              </TableRow>
            ) : filteredProducts.length === 0 ? (
              <TableRow>
                <TableCell colSpan={6} className="text-center py-10">
                  No products found
                </TableCell>
              </TableRow>
            ) : (
              filteredProducts.map((product) => (
                <TableRow key={product.id}>
                  <TableCell>{product.name}</TableCell>
                  <TableCell>{product.category}</TableCell>
                  <TableCell>{product.brand}</TableCell>
                  <TableCell>{formatCurrency(product.price)}</TableCell>
                  <TableCell>
                    <ProductStatusBadge status={product.status} />
                  </TableCell>
                  <TableCell className="text-right">
                    <Link href={`/dashboard/products/${product.id}`}>
                      <Button variant="ghost" size="icon">
                        <ChevronRight size={18} />
                      </Button>
                    </Link>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </div>

      {hasMore && (
        <div className="flex justify-center mt-4">
          <Button
            variant="outline"
            onClick={loadMore}
            disabled={loading || !hasMore}
          >
            Load More
          </Button>
        </div>
      )}
    </div>
  );
}
EOL

# Create pending products page
mkdir -p src/app/dashboard/products/pending
cat > src/app/dashboard/products/pending/page.tsx << 'EOL'
"use client";

import { useState, useEffect } from "react";
import { getPendingProducts, updateProductStatus } from "@/lib/firebase/products";
import { Product } from "@/lib/types/product";
import { Button } from "@/components/ui/button";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Textarea } from "@/components/ui/textarea"; // Use Textarea here
import { Checkbox } from "@/components/ui/checkbox";
import { ProductStatusBadge } from "@/components/product/product-status-badge";
import { DocumentData } from "firebase/firestore";
import { formatCurrency, formatDate } from "@/lib/utils";
import Link from "next/link";
import { CheckCircle, XCircle, ChevronRight } from "lucide-react";
import { toast } from "sonner";

export default function PendingProductsPage() {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [lastDoc, setLastDoc] = useState<DocumentData | undefined>(undefined);
  const [hasMore, setHasMore] = useState(true);

  // Dialog state
  const [dialogOpen, setDialogOpen] = useState(false);
  const [dialogAction, setDialogAction] = useState<"approve" | "reject">("approve");
  const [selectedProduct, setSelectedProduct] = useState<Product | null>(null);
  const [rejectionReason, setRejectionReason] = useState("");
  const [showInCatalog, setShowInCatalog] = useState(false);

  // Fetch pending products on component mount
  useEffect(() => {
    const fetchProducts = async () => {
      setLoading(true);
      try {
        const result = await getPendingProducts(10);
        setProducts(result.products);
        setLastDoc(result.lastDoc);
        setHasMore(result.products.length === 10);
      } catch (error) {
        console.error("Error fetching pending products:", error);
        toast.error("Failed to load pending products");
      } finally {
        setLoading(false);
      }
    };

    fetchProducts();
  }, []);

  // Load more products
  const loadMore = async () => {
    if (!lastDoc) return;

    try {
      const result = await getPendingProducts(10, lastDoc);
      setProducts([...products, ...result.products]);
      setLastDoc(result.lastDoc);
      setHasMore(result.products.length === 10);
    } catch (error) {
      console.error("Error loading more products:", error);
      toast.error("Failed to load more products");
    }
  };

  // Open approval dialog
  const openApproveDialog = (product: Product) => {
    setSelectedProduct(product);
    setDialogAction("approve");
    setShowInCatalog(false);
    setDialogOpen(true);
  };

  // Open rejection dialog
  const openRejectDialog = (product: Product) => {
    setSelectedProduct(product);
    setDialogAction("reject");
    setRejectionReason("");
    setDialogOpen(true);
  };

  // Handle dialog confirmation
  const handleConfirm = async () => {
    if (!selectedProduct) return;

    try {
      if (dialogAction === "approve") {
        await updateProductStatus(selectedProduct.id, "approved", showInCatalog);
        toast.success(`Product ${selectedProduct.name} has been approved`);
      } else {
        await updateProductStatus(selectedProduct.id, "rejected", false, rejectionReason);
        toast.success(`Product ${selectedProduct.name} has been rejected`);
      }

      // Update the local state to remove the processed product
      setProducts(products.filter(p => p.id !== selectedProduct.id));
    } catch (error) {
      console.error(`Error ${dialogAction}ing product:`, error);
      toast.error(`Failed to ${dialogAction} product`);
    } finally {
      setDialogOpen(false);
      setSelectedProduct(null);
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">Pending Products</h1>
        <p className="text-gray-500 dark:text-gray-400">
          Review and approve product submissions
        </p>
      </div>

      <div className="border rounded-lg overflow-hidden">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Product Name</TableHead>
              <TableHead>Category</TableHead>
              <TableHead>Brand</TableHead>
              <TableHead>Price</TableHead>
              <TableHead>Status</TableHead>
              <TableHead className="text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {loading ? (
              <TableRow>
                <TableCell colSpan={6} className="text-center py-10">
                  <div className="flex justify-center">
                    <div className="w-6 h-6 border-2 border-primary border-t-transparent rounded-full animate-spin"></div>
                  </div>
                </TableCell>
              </TableRow>
            ) : products.length === 0 ? (
              <TableRow>
                <TableCell colSpan={6} className="text-center py-10">
                  No pending products
                </TableCell>
              </TableRow>
            ) : (
              products.map((product) => (
                <TableRow key={product.id}>
                  <TableCell>{product.name}</TableCell>
                  <TableCell>{product.category}</TableCell>
                  <TableCell>{product.brand}</TableCell>
                  <TableCell>{formatCurrency(product.price)}</TableCell>
                  <TableCell>
                    <ProductStatusBadge status={product.status} />
                  </TableCell>
                  <TableCell className="text-right">
                    <div className="flex justify-end items-center space-x-2">
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => openApproveDialog(product)}
                        className="text-green-500 hover:text-green-600 hover:bg-green-50"
                      >
                        <CheckCircle size={18} />
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => openRejectDialog(product)}
                        className="text-red-500 hover:text-red-600 hover:bg-red-50"
                      >
                        <XCircle size={18} />
                      </Button>
                      <Link href={`/dashboard/products/${product.id}`}>
                        <Button variant="ghost" size="icon">
                          <ChevronRight size={18} />
                        </Button>
                      </Link>
                    </div>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </div>

      {hasMore && (
        <div className="flex justify-center mt-4">
          <Button
            variant="outline"
            onClick={loadMore}
            disabled={loading || !hasMore}
          >
            Load More
          </Button>
        </div>
      )}

      {/* Approval/Rejection Dialog */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {dialogAction === "approve" ? "Approve Product" : "Reject Product"}
            </DialogTitle>
            <DialogDescription>
              {dialogAction === "approve"
                ? "Are you sure you want to approve this product?"
                : "Please provide a reason for rejecting this product."}
            </DialogDescription>
          </DialogHeader>

          {dialogAction === "approve" && (
            <div className="flex items-center space-x-2 mt-2">
              <Checkbox
                id="show-in-catalog"
                checked={showInCatalog}
                onCheckedChange={(checked) =>
                  setShowInCatalog(checked as boolean)
                }
              />
              <label
                htmlFor="show-in-catalog"
                className="text-sm font-medium leading-none cursor-pointer"
              >
                Show in client-facing catalog
              </label>
            </div>
          )}

          {dialogAction === "reject" && (
            <Textarea
              placeholder="Reason for rejection"
              value={rejectionReason}
              onChange={(e) => setRejectionReason(e.target.value)}
              className="min-h-[100px]"
            />
          )}

          <DialogFooter>
            <Button variant="outline" onClick={() => setDialogOpen(false)}>
              Cancel
            </Button>
            <Button
              onClick={handleConfirm}
              variant={dialogAction === "approve" ? "default" : "destructive"}
              disabled={dialogAction === "reject" && !rejectionReason.trim()}
            >
              {dialogAction === "approve" ? "Approve" : "Reject"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
EOL

# Create product detail page
mkdir -p src/app/dashboard/products/\[id\]
cat > src/app/dashboard/products/\[id\]/page.tsx << 'EOL'
"use client";

import { useState, useEffect } from "react";
import { useParams } from "next/navigation";
import { getProductById, updateProductStatus } from "@/lib/firebase/products";
import { getVendorById } from "@/lib/firebase/vendors";
import { Product } from "@/lib/types/product";
import { Vendor } from "@/lib/types/vendor";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Tabs,
  TabsContent,
  TabsList,
  TabsTrigger,
} from "@/components/ui/tabs";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Textarea } from "@/components/ui/textarea"; // Use Textarea here
import { Checkbox } from "@/components/ui/checkbox";
import { ProductStatusBadge } from "@/components/product/product-status-badge";
import { formatCurrency, formatDateTime } from "@/lib/utils";
import Link from "next/link";
import { CheckCircle, XCircle, ArrowLeft } from "lucide-react";
import { toast } from "sonner";
import Image from "next/image";

export default function ProductDetailPage() {
  const { id } = useParams<{ id: string }>();
  const [product, setProduct] = useState<Product | null>(null);
  const [vendor, setVendor] = useState<Vendor | null>(null);
  const [loading, setLoading] = useState(true);
  const [activeImage, setActiveImage] = useState<string | null>(null);

  // Dialog state
  const [dialogOpen, setDialogOpen] = useState(false);
  const [dialogAction, setDialogAction] = useState<"approve" | "reject">("approve");
  const [rejectionReason, setRejectionReason] = useState("");
  const [showInCatalog, setShowInCatalog] = useState(false);

  // Fetch product and vendor
  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      try {
        const productData = await getProductById(id as string);
        setProduct(productData);

        if (productData && productData.imageUrls.length > 0) {
          setActiveImage(productData.imageUrls[0]);
        }

        if (productData && productData.vendorId) {
          const vendorData = await getVendorById(productData.vendorId);
          setVendor(vendorData);
        }
      } catch (error) {
        console.error("Error fetching product data:", error);
        toast.error("Failed to load product data");
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [id]);

  // Open approval dialog
  const openApproveDialog = () => {
    if (!product) return;
    setDialogAction("approve");
    setShowInCatalog(product.showInCatalog);
    setDialogOpen(true);
  };

  // Open rejection dialog
  const openRejectDialog = () => {
    setDialogAction("reject");
    setRejectionReason("");
    setDialogOpen(true);
  };

  // Handle dialog confirmation
  const handleConfirm = async () => {
    if (!product) return;

    try {
      if (dialogAction === "approve") {
        await updateProductStatus(product.id, "approved", showInCatalog);
        setProduct({ ...product, status: "approved", showInCatalog });
        toast.success(`Product ${product.name} has been approved`);
      } else {
        await updateProductStatus(product.id, "rejected", false, rejectionReason);
        setProduct({
          ...product,
          status: "rejected",
          showInCatalog: false,
          rejectionReason
        });
        toast.success(`Product ${product.name} has been rejected`);
      }
    } catch (error) {
      console.error(`Error ${dialogAction}ing product:`, error);
      toast.error(`Failed to ${dialogAction} product`);
    } finally {
      setDialogOpen(false);
    }
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-96">
        <div className="w-8 h-8 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
      </div>
    );
  }

  if (!product) {
    return (
      <div className="text-center py-12">
        <h2 className="text-xl font-semibold mb-2">Product Not Found</h2>
        <p className="text-gray-500 dark:text-gray-400 mb-6">
          The product you are looking for does not exist or has been removed.
        </p>
        <Link href="/dashboard/products">
          <Button>
            <ArrowLeft size={16} className="mr-2" />
            Back to Products
          </Button>
        </Link>
      </div>
    );
  }

  // Create specifications array from object
  const specifications = product.specifications
    ? Object.entries(product.specifications).map(([key, value]) => ({
        key,
        value,
      }))
    : [];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center">
          <Link href="/dashboard/products">
            <Button variant="ghost" size="icon" className="mr-2">
              <ArrowLeft size={20} />
            </Button>
          </Link>
          <div>
            <h1 className="text-2xl font-semibold">{product.name}</h1>
            <p className="text-gray-500 dark:text-gray-400">
              {product.brand} | {product.category}
            </p>
          </div>
        </div>

        {product.status === "pending" && (
          <div className="flex space-x-2">
            <Button
              onClick={openApproveDialog}
              variant="default"
              className="bg-green-600 hover:bg-green-700"
            >
              <CheckCircle size={16} className="mr-2" />
              Approve
            </Button>
            <Button
              onClick={openRejectDialog}
              variant="destructive"
            >
              <XCircle size={16} className="mr-2" />
              Reject
            </Button>
          </div>
        )}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2">
          <Tabs defaultValue="details">
            <TabsList>
              <TabsTrigger value="details">Details</TabsTrigger>
              <TabsTrigger value="images">Images</TabsTrigger>
              <TabsTrigger value="specifications">Specifications</TabsTrigger>
            </TabsList>

            <TabsContent value="details" className="pt-4">
              <Card>
                <CardHeader>
                  <CardTitle>Product Information</CardTitle>
                  <CardDescription>
                    Detailed information about the product
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                        Product Name
                      </h3>
                      <p>{product.name}</p>
                    </div>
                    <div>
                      <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                        Brand
                      </h3>
                      <p>{product.brand}</p>
                    </div>
                    <div>
                      <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                        Model
                      </h3>
                      <p>{product.model}</p>
                    </div>
                    <div>
                      <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                        Year
                      </h3>
                      <p>{product.year}</p>
                    </div>
                    <div>
                      <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                        Category
                      </h3>
                      <p>{product.category}</p>
                    </div>
                    {product.subcategory && (
                      <div>
                        <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                          Subcategory
                        </h3>
                        <p>{product.subcategory}</p>
                      </div>
                    )}
                    <div>
                      <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                        Price
                      </h3>
                      <p>{formatCurrency(product.price)}</p>
                    </div>
                    {product.discountPrice !== undefined && (
                      <div>
                        <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                          Discount Price
                        </h3>
                        <p>{formatCurrency(product.discountPrice)}</p>
                      </div>
                    )}
                    <div>
                      <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                        Condition
                      </h3>
                      <p className="capitalize">{product.condition}</p>
                    </div>
                    <div>
                      <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                        Quantity
                      </h3>
                      <p>{product.quantity}</p>
                    </div>
                  </div>

                  <div>
                    <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400 mb-2">
                      Description
                    </h3>
                    <p className="text-sm whitespace-pre-line">{product.description}</p>
                  </div>

                  {vendor && (
                    <div>
                      <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400 mb-2">
                        Vendor
                      </h3>
                      <Link
                        href={`/dashboard/vendors/${vendor.id}`}
                        className="text-primary hover:underline"
                      >
                        {vendor.businessName}
                      </Link>
                    </div>
                  )}
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="images" className="pt-4">
              <Card>
                <CardHeader>
                  <CardTitle>Product Images</CardTitle>
                  <CardDescription>
                    Images uploaded for this product
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  {!product.imageUrls || product.imageUrls.length === 0 ? (
                    <p className="text-center py-8 text-gray-500">
                      No images have been uploaded for this product.
                    </p>
                  ) : (
                    <div>
                      <div className="aspect-video relative bg-gray-100 rounded-lg overflow-hidden mb-4">
                        {activeImage && (
                          <Image
                            src={activeImage}
                            alt={product.name}
                            fill
                            className="object-contain"
                          />
                        )}
                      </div>

                      <div className="grid grid-cols-4 sm:grid-cols-5 gap-2">
                        {product.imageUrls.map((url, index) => (
                          <div
                            key={index}
                            className={`
                              aspect-square relative bg-gray-100 rounded-md overflow-hidden cursor-pointer
                              ${url === activeImage ? 'ring-2 ring-primary' : ''}
                            `}
                            onClick={() => setActiveImage(url)}
                          >
                            <Image
                              src={url}
                              alt={`${product.name} - Image ${index + 1}`}
                              fill
                              className="object-cover"
                            />
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="specifications" className="pt-4">
              <Card>
                <CardHeader>
                  <CardTitle>Product Specifications</CardTitle>
                  <CardDescription>
                    Technical details and specifications
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  {specifications.length === 0 ? (
                    <p className="text-center py-8 text-gray-500">
                      No specifications have been added for this product.
                    </p>
                  ) : (
                    <div className="border rounded-lg overflow-hidden">
                      <table className="w-full">
                        <tbody>
                          {specifications.map(({ key, value }, index) => (
                            <tr
                              key={index}
                              className={`
                                ${index % 2 === 0 ? 'bg-gray-50 dark:bg-gray-800' : ''}
                              `}
                            >
                              <td className="px-4 py-3 border-b dark:border-gray-700 font-medium">
                                {key}
                              </td>
                              <td className="px-4 py-3 border-b dark:border-gray-700">
                                {value}
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  )}
                </CardContent>
              </Card>
            </TabsContent>
          </Tabs>
        </div>

        <div>
          <Card>
            <CardHeader>
              <CardTitle>Status</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex justify-between items-center">
                <div>
                  <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                    Current Status
                  </h3>
                  <div className="mt-1">
                    <ProductStatusBadge status={product.status} />
                  </div>
                </div>

                {product.status !== "pending" && (
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => {
                      if (product.status === "approved") {
                        openRejectDialog();
                      } else {
                        openApproveDialog();
                      }
                    }}
                  >
                    {product.status === "approved" ? "Reject" : "Approve"}
                  </Button>
                )}
              </div>

              <div>
                <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                  Show in Client Catalog
                </h3>
                <div className="flex items-center space-x-2 mt-1">
                  <Checkbox
                    id="catalog-status"
                    checked={product.showInCatalog}
                    disabled={product.status !== "approved"}
                    onCheckedChange={async (checked) => {
                      try {
                        await updateProductStatus(
                          product.id,
                          product.status,
                          checked as boolean
                        );
                        setProduct({ ...product, showInCatalog: checked as boolean });
                        toast.success("Catalog status updated");
                      } catch (error) {
                        console.error("Error updating catalog status:", error);
                        toast.error("Failed to update catalog status");
                      }
                    }}
                  />
                  <label
                    htmlFor="catalog-status"
                    className={`text-sm ${product.status !== "approved" ? 'text-gray-400' : ''}`}
                  >
                    {product.showInCatalog ? "Visible to clients" : "Hidden from clients"}
                  </label>
                </div>
              </div>

              <div>
                <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                  Date Added
                </h3>
                <p>{formatDateTime(product.createdAt)}</p>
              </div>

              {product.status === "approved" && product.approvedAt && (
                <div>
                  <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                    Approval Date
                  </h3>
                  <p>{formatDateTime(product.approvedAt)}</p>
                </div>
              )}

              {product.status === "rejected" && product.rejectedAt && (
                <>
                  <div>
                    <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                      Rejection Date
                    </h3>
                    <p>{formatDateTime(product.rejectedAt)}</p>
                  </div>

                  {product.rejectionReason && (
                    <div>
                      <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                        Rejection Reason
                      </h3>
                      <p className="text-sm mt-1">{product.rejectionReason}</p>
                    </div>
                  )}
                </>
              )}
            </CardContent>
          </Card>

          {vendor && (
            <Card className="mt-4">
              <CardHeader>
                <CardTitle>Vendor Information</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div>
                  <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                    Business Name
                  </h3>
                  <p>{vendor.businessName}</p>
                </div>
                <div>
                  <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                    Contact
                  </h3>
                  <p>{vendor.name}</p>
                </div>
                <div>
                  <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                    Email
                  </h3>
                  <p>{vendor.email}</p>
                </div>
                <div>
                  <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                    Status
                  </h3>
                  <div className="mt-1">
                    <VendorStatusBadge status={vendor.status} /> {/* Use VendorStatusBadge here */}
                  </div>
                </div>
                <div>
                  <Link href={`/dashboard/vendors/${vendor.id}`}>
                    <Button variant="outline" className="w-full">
                      View Vendor
                    </Button>
                  </Link>
                </div>
              </CardContent>
            </Card>
          )}
        </div>
      </div>

      {/* Approval/Rejection Dialog */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {dialogAction === "approve" ? "Approve Product" : "Reject Product"}
            </DialogTitle>
            <DialogDescription>
              {dialogAction === "approve"
                ? "Are you sure you want to approve this product?"
                : "Please provide a reason for rejecting this product."}
            </DialogDescription>
          </DialogHeader>

          {dialogAction === "approve" && (
            <div className="flex items-center space-x-2 mt-2">
              <Checkbox
                id="show-in-catalog"
                checked={showInCatalog}
                onCheckedChange={(checked) =>
                  setShowInCatalog(checked as boolean)
                }
              />
              <label
                htmlFor="show-in-catalog"
                className="text-sm font-medium leading-none cursor-pointer"
              >
                Show in client-facing catalog
              </label>
            </div>
          )}

          {dialogAction === "reject" && (
            <Textarea
              placeholder="Reason for rejection"
              value={rejectionReason}
              onChange={(e) => setRejectionReason(e.target.value)}
              className="min-h-[100px]"
            />
          )}

          <DialogFooter>
            <Button variant="outline" onClick={() => setDialogOpen(false)}>
              Cancel
            </Button>
            <Button
              onClick={handleConfirm}
              variant={dialogAction === "approve" ? "default" : "destructive"}
              disabled={dialogAction === "reject" && !rejectionReason.trim()}
            >
              {dialogAction === "approve" ? "Approve" : "Reject"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
EOL

# Update login page with SpareWo logo
echo -e "${BLUE}🔑 Updating login page...${NC}"
mkdir -p src/app/\(auth\)/login
cat > src/app/\(auth\)/login/page.tsx << 'EOL'
'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import Image from 'next/image';
import { useForm } from 'react-hook-form';
import { z } from 'zod';
import { zodResolver } from '@hookform/resolvers/zod';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { toast } from 'sonner';
import { signIn } from '@/lib/firebase/auth';

// Form schema
const loginSchema = z.object({
  email: z.string().email({ message: 'Please enter a valid email' }),
  password: z.string().min(6, { message: 'Password must be at least 6 characters' }),
});

type LoginFormValues = z.infer<typeof loginSchema>;

export default function LoginPage() {
  const router = useRouter();
  const [isLoading, setIsLoading] = useState(false);

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<LoginFormValues>({
    resolver: zodResolver(loginSchema),
    defaultValues: {
      email: '',
      password: '',
    },
  });

  const onSubmit = async (data: LoginFormValues) => {
    setIsLoading(true);

    try {
      await signIn(data.email, data.password);

      // Show success toast
      toast.success('Signed in successfully');

      // Redirect to dashboard
      router.push('/dashboard');
    } catch (err: unknown) {
      const errorMessage = err instanceof Error ? err.message : 'Authentication failed';
      toast.error(errorMessage);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-100 dark:bg-gray-900 p-4">
      <Card className="w-full max-w-md">
        <CardHeader className="space-y-2">
          <div className="mb-4 flex justify-center">
            <Image
              src="/images/logo.png"
              alt="SpareWo Logo"
              width={100}
              height={100}
              className="h-20 w-auto"
              priority
            />
          </div>
          <CardTitle className="text-2xl font-bold text-center">SpareWo Admin</CardTitle>
          <CardDescription className="text-center">Sign in to your admin account</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="email">Email</Label>
              <Input
                id="email"
                type="email"
                placeholder="name@company.com"
                {...register('email')}
                className={errors.email ? 'border-red-500' : ''}
              />
              {errors.email && (
                <p className="text-xs text-red-500">{errors.email.message}</p>
              )}
            </div>
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <Label htmlFor="password">Password</Label>
                <Link
                  href="/forgot-password"
                  className="text-xs text-primary hover:underline"
                >
                  Forgot password?
                </Link>
              </div>
              <Input
                id="password"
                type="password"
                placeholder="••••••••"
                {...register('password')}
                className={errors.password ? 'border-red-500' : ''}
              />
              {errors.password && (
                <p className="text-xs text-red-500">{errors.password.message}</p>
              )}
            </div>

            <Button type="submit" className="w-full bg-primary hover:bg-primary/90" disabled={isLoading}>
              {isLoading ? (
                <div className="flex items-center">
                  <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin mr-2"></div>
                  Signing in...
                </div>
              ) : (
                'Sign in'
              )}
            </Button>
          </form>
        </CardContent>
        <CardFooter className="flex justify-center text-sm text-gray-500 dark:text-gray-400">
          SpareWo Admin Dashboard © {new Date().getFullYear()}
        </CardFooter>
      </Card>
    </div>
  );
}
EOL

# Create forgot password page
mkdir -p src/app/\(auth\)/forgot-password
cat > src/app/\(auth\)/forgot-password/page.tsx << 'EOL'
'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { useForm } from 'react-hook-form';
import { z } from 'zod';
import { zodResolver } from '@hookform/resolvers/zod';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { toast } from 'sonner';
import { resetPassword } from '@/lib/firebase/auth';
import { ArrowLeft } from 'lucide-react';

// Form schema
const forgotPasswordSchema = z.object({
  email: z.string().email({ message: 'Please enter a valid email' }),
});

type ForgotPasswordFormValues = z.infer<typeof forgotPasswordSchema>;

export default function ForgotPasswordPage() {
  const [isLoading, setIsLoading] = useState(false);
  const [isSubmitted, setIsSubmitted] = useState(false);

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<ForgotPasswordFormValues>({
    resolver: zodResolver(forgotPasswordSchema),
    defaultValues: {
      email: '',
    },
  });

  const onSubmit = async (data: ForgotPasswordFormValues) => {
    setIsLoading(true);

    try {
      await resetPassword(data.email);
      setIsSubmitted(true);
      toast.success('Password reset email sent');
    } catch (err: unknown) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to send reset email';
      toast.error(errorMessage);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-100 dark:bg-gray-900 p-4">
      <Card className="w-full max-w-md">
        <CardHeader className="space-y-2">
          <div className="mb-4 flex justify-center">
            <Image
              src="/images/logo.png"
              alt="SpareWo Logo"
              width={100}
              height={100}
              className="h-20 w-auto"
              priority
            />
          </div>
          <CardTitle className="text-2xl font-bold text-center">Forgot Password</CardTitle>
          <CardDescription className="text-center">
            {isSubmitted
              ? 'Check your email for a reset link'
              : 'Enter your email to reset your password'}
          </CardDescription>
        </CardHeader>
        <CardContent>
          {isSubmitted ? (
            <div className="text-center py-4 space-y-6">
              <p className="text-gray-500 dark:text-gray-400">
                We've sent a password reset link to your email.
                Please check your inbox and follow the instructions to reset your password.
              </p>
              <Link href="/login">
                <Button className="w-full">
                  <ArrowLeft size={16} className="mr-2" />
                  Back to Login
                </Button>
              </Link>
            </div>
          ) : (
            <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="email">Email</Label>
                <Input
                  id="email"
                  type="email"
                  placeholder="name@company.com"
                  {...register('email')}
                  className={errors.email ? 'border-red-500' : ''}
                />
                {errors.email && (
                  <p className="text-xs text-red-500">{errors.email.message}</p>
                )}
              </div>

              <Button type="submit" className="w-full bg-primary hover:bg-primary/90" disabled={isLoading}>
                {isLoading ? (
                  <div className="flex items-center">
                    <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin mr-2"></div>
                    Sending...
                  </div>
                ) : (
                  'Send Reset Link'
                )}
              </Button>

              <div className="text-center">
                <Link
                  href="/login"
                  className="text-sm text-primary hover:underline"
                >
                  Back to login
                </Link>
              </div>
            </form>
          )}
        </CardContent>
        <CardFooter className="flex justify-center text-sm text-gray-500 dark:text-gray-400">
          SpareWo Admin Dashboard © {new Date().getFullYear()}
        </CardFooter>
      </Card>
    </div>
  );
}
EOL

# Create a placeholder for the SpareWo logo (already handled by mkdir -p)
echo -e "${BLUE}🖼️ Creating placeholder for SpareWo logo...${NC}"
# mkdir -p public/images # This line is redundant as it was done earlier, but harmless

# Create a .env.local file template
echo -e "${BLUE}📝 Creating .env.local template...${NC}"
cat > .env.local << 'EOL'
# Firebase configuration
NEXT_PUBLIC_FIREBASE_API_KEY=
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=
NEXT_PUBLIC_FIREBASE_PROJECT_ID=
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=
NEXT_PUBLIC_FIREBASE_APP_ID=

# Application settings
NEXT_PUBLIC_APP_URL=http://localhost:3000
EOL

# Create the Checkbox component for shadcn/ui
echo -e "${BLUE}🎨 Creating Checkbox component...${NC}"
# Ensure ui directory exists before writing the file
mkdir -p src/components/ui
cat > src/components/ui/checkbox.tsx << 'EOL'
"use client"

import * as React from "react"
import * as CheckboxPrimitive from "@radix-ui/react-checkbox"
import { Check } from "lucide-react"

import { cn } from "@/lib/utils"

const Checkbox = React.forwardRef<
  React.ElementRef<typeof CheckboxPrimitive.Root>,
  React.ComponentPropsWithoutRef<typeof CheckboxPrimitive.Root>
>(({ className, ...props }, ref) => (
  <CheckboxPrimitive.Root
    ref={ref}
    className={cn(
      "peer h-4 w-4 shrink-0 rounded-sm border border-primary ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 data-[state=checked]:bg-primary data-[state=checked]:text-primary-foreground",
      className
    )}
    {...props}
  >
    <CheckboxPrimitive.Indicator
      className={cn("flex items-center justify-center text-current")}
    >
      <Check className="h-4 w-4" />
    </CheckboxPrimitive.Indicator>
  </CheckboxPrimitive.Root>
))
Checkbox.displayName = CheckboxPrimitive.Root.displayName

export { Checkbox }
EOL

# Create Textarea component
echo -e "${BLUE}🎨 Creating Textarea component...${NC}"
# Ensure ui directory exists before writing the file
mkdir -p src/components/ui
cat > src/components/ui/textarea.tsx << 'EOL'
import * as React from "react"

import { cn } from "@/lib/utils"

export interface TextareaProps
  extends React.TextareaHTMLAttributes<HTMLTextAreaElement> {}

const Textarea = React.forwardRef<HTMLTextAreaElement, TextareaProps>(
  ({ className, ...props }, ref) => {
    return (
      <textarea
        className={cn(
          "flex min-h-[80px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50",
          className
        )}
        ref={ref}
        {...props}
      />
    )
  }
)
Textarea.displayName = "Textarea"

export { Textarea }
EOL

# Create placeholder for SpareWo logo (message)
echo "Creating SpareWo logo placeholder..."
echo "You should replace the placeholder logo at 'public/images/logo.png' with your actual logo file."

# Print completion message
echo -e "${GREEN}✅ Implementation completed successfully!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo -e "1. Replace the placeholder logo at ${YELLOW}public/images/logo.png${NC} with your actual logo"
echo -e "2. Edit the ${YELLOW}.env.local${NC} file with your Firebase configuration"
echo -e "3. You might need to manually install shadcn/ui components if you haven't already: ${YELLOW}npx shadcn-ui@latest add card button dropdown-menu badge select input label dialog table tabs checkbox${NC}"
echo -e "4. Run ${YELLOW}npm install${NC} to ensure all dependencies are installed"
echo -e "5. Run ${YELLOW}npm run dev${NC} to start the development server"
echo -e "6. Visit ${YELLOW}http://localhost:3000${NC} to see your application"
echo ""
echo -e "${YELLOW}⚠️ Important:${NC} Make sure to set up Firebase authentication and Firestore collections (vendors, products, adminUsers, notifications) as expected by the code."