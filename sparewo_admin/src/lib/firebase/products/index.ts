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
      collection(db, 'vendor_products'),
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
      collection(db, 'vendor_products'),
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
    const querySnapshot = await getDocs(collection(db, 'vendor_products'));
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
