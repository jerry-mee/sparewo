// src/lib/firebase/products/index.ts
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
  addDoc,
  runTransaction,
  writeBatch,
  Timestamp,
  FieldValue
} from 'firebase/firestore';
import { db } from '../config';
import { Product } from '@/lib/types/product';

// Type for Firebase update operations
type FirebaseUpdateData = {
  [key: string]: string | number | boolean | Date | FieldValue | Timestamp | null | undefined;
};

// Type definitions
interface CatalogProduct {
  id: string;
  partName: string;
  partNumber: string;
  brand: string;
  description: string;
  images: string[];
  compatibility: VehicleCompatibility | null;
  category: string;
  subcategory: string;
  condition: 'new' | 'used' | 'refurbished';
  retailPrice: number;
  currency: string;
  availability: 'in_stock' | 'out_of_stock' | 'limited';
  featured: boolean;
  categories: string[];
  searchKeywords: string[];
  specifications: Record<string, unknown>;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  isActive: boolean;
}

interface ProductMapping {
  id: string;
  catalogProductId: string;
  vendorProductId: string;
  vendorId: string;
  vendorName: string;
  qualityScore: number;
  priceScore: number;
  reliabilityScore: number;
  isPreferred: boolean;
  isActive: boolean;
  vendorPrice: number;
  lastPriceUpdate: Timestamp;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

interface VehicleCompatibility {
  brands: string[];
  models: string[];
  years: string[];
}

interface CatalogSettings {
  retailPrice: number;
  featured?: boolean;
  categories?: string[];
  availability?: 'in_stock' | 'out_of_stock' | 'limited';
}

// Get all vendor products with pagination
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
      const data = doc.data();
      // Ensure all required fields exist to prevent undefined errors
      const product: Product = {
        id: doc.id,
        name: data.name || data.partName || 'Unnamed Product',
        partName: data.partName || data.name,
        description: data.description || '',
        price: data.price || data.unitPrice || 0,
        unitPrice: data.unitPrice || data.price,
        discountPrice: data.discountPrice,
        category: data.category || '',
        subcategory: data.subcategory || '',
        brand: data.brand || '',
        model: data.model || '',
        year: data.year || '',
        condition: (data.condition as 'new' | 'used' | 'refurbished') || 'new',
        quantity: data.quantity || data.stockQuantity || 0,
        stockQuantity: data.stockQuantity || data.quantity,
        status: (data.status as 'pending' | 'approved' | 'rejected') || 'pending',
        rejectionReason: data.rejectionReason || '',
        showInCatalog: data.showInCatalog || false,
        images: data.images || data.imageUrls || [],
        imageUrls: data.imageUrls || data.images || [],
        specifications: data.specifications || {},
        vendorId: data.vendorId || '',
        vendorName: data.vendorName || '',
        partNumber: data.partNumber || '',
        qualityGrade: data.qualityGrade || '',
        wholesalePrice: data.wholesalePrice || 0,
        searchKeywords: data.searchKeywords || [],
        compatibility: data.compatibility || null,
        reviewNotes: data.reviewNotes || '',
        createdAt: data.createdAt || Timestamp.now(),
        updatedAt: data.updatedAt || Timestamp.now(),
        approvedAt: data.approvedAt || null,
        rejectedAt: data.rejectedAt || null,
      };
      
      products.push(product);
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
    const docRef = doc(db, 'vendor_products', id);
    const docSnap = await getDoc(docRef);

    if (docSnap.exists()) {
      const data = docSnap.data();
      const product: Product = {
        id: docSnap.id,
        name: data.name || data.partName || 'Unnamed Product',
        partName: data.partName || data.name,
        description: data.description || '',
        price: data.price || data.unitPrice || 0,
        unitPrice: data.unitPrice || data.price,
        discountPrice: data.discountPrice,
        category: data.category || '',
        subcategory: data.subcategory || '',
        brand: data.brand || '',
        model: data.model || '',
        year: data.year || '',
        condition: (data.condition as 'new' | 'used' | 'refurbished') || 'new',
        quantity: data.quantity || data.stockQuantity || 0,
        stockQuantity: data.stockQuantity || data.quantity,
        status: (data.status as 'pending' | 'approved' | 'rejected') || 'pending',
        rejectionReason: data.rejectionReason || '',
        showInCatalog: data.showInCatalog || false,
        images: data.images || data.imageUrls || [],
        imageUrls: data.imageUrls || data.images || [],
        specifications: data.specifications || {},
        vendorId: data.vendorId || '',
        vendorName: data.vendorName || '',
        partNumber: data.partNumber || '',
        qualityGrade: data.qualityGrade || '',
        wholesalePrice: data.wholesalePrice || 0,
        searchKeywords: data.searchKeywords || [],
        compatibility: data.compatibility || null,
        reviewNotes: data.reviewNotes || '',
        createdAt: data.createdAt || Timestamp.now(),
        updatedAt: data.updatedAt || Timestamp.now(),
        approvedAt: data.approvedAt || null,
        rejectedAt: data.rejectedAt || null,
      };
      
      return product;
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

// Update product status (old method - kept for backward compatibility)
export const updateProductStatus = async (
  id: string,
  status: 'pending' | 'approved' | 'rejected',
  showInCatalog: boolean = false,
  rejectionReason?: string
): Promise<void> => {
  try {
    const docRef = doc(db, 'vendor_products', id);

    const updateData: FirebaseUpdateData = {
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

// NEW: Approve product and create catalog entry
export const approveProductAndCreateCatalog = async (
  productId: string,
  catalogSettings: CatalogSettings
): Promise<void> => {
  try {
    // Use transaction to ensure atomicity
    await runTransaction(db, async (transaction) => {
      // 1. Get the vendor product
      const vendorProductRef = doc(db, 'vendor_products', productId);
      const vendorProductSnap = await transaction.get(vendorProductRef);
      
      if (!vendorProductSnap.exists()) {
        throw new Error('Vendor product not found');
      }
      
      const vendorProduct = vendorProductSnap.data();
      
      // 2. Create catalog product (remove vendor-specific info)
      const catalogProduct = {
        partName: vendorProduct.partName || vendorProduct.name,
        partNumber: vendorProduct.partNumber || '',
        brand: vendorProduct.brand || '',
        description: vendorProduct.description || '',
        images: vendorProduct.images || vendorProduct.imageUrls || [],
        compatibility: vendorProduct.compatibility || null,
        category: vendorProduct.category || '',
        subcategory: vendorProduct.subcategory || '',
        condition: vendorProduct.condition || 'new',
        retailPrice: catalogSettings.retailPrice,
        currency: 'UGX',
        availability: catalogSettings.availability || 'in_stock',
        featured: catalogSettings.featured || false,
        categories: catalogSettings.categories || [vendorProduct.category],
        searchKeywords: vendorProduct.searchKeywords || [],
        specifications: vendorProduct.specifications || {},
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
        isActive: true,
      };
      
      // 3. Add catalog product
      const catalogRef = await addDoc(collection(db, 'catalog_products'), catalogProduct);
      
      // 4. Create product mapping
      const productMapping = {
        catalogProductId: catalogRef.id,
        vendorProductId: productId,
        vendorId: vendorProduct.vendorId,
        vendorName: vendorProduct.vendorName || '',
        qualityScore: 85, // Default score
        priceScore: 90, // Default score
        reliabilityScore: 85, // Default score
        isPreferred: true, // First vendor is preferred by default
        isActive: true,
        vendorPrice: vendorProduct.unitPrice || vendorProduct.price || 0,
        lastPriceUpdate: serverTimestamp(),
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      };
      
      await addDoc(collection(db, 'product_mappings'), productMapping);
      
      // 5. Update vendor product status
      transaction.update(vendorProductRef, {
        status: 'approved',
        showInCatalog: true,
        approvedAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
        catalogProductId: catalogRef.id, // Reference to catalog
      });
    });
    
    console.log('Product approved and catalog entry created successfully');
  } catch (error) {
    console.error('Error approving product and creating catalog:', error);
    throw error;
  }
};

// NEW: Get catalog products
export const getCatalogProducts = async (
  filters?: {
    category?: string;
    availability?: string;
    featured?: boolean;
  },
  pageSize: number = 10,
  lastDoc?: DocumentData
): Promise<{ products: CatalogProduct[], lastDoc: DocumentData | undefined }> => {
  try {
    const constraints: QueryConstraint[] = [
      where('isActive', '==', true),
      orderBy('createdAt', 'desc')
    ];
    
    if (filters?.category) {
      constraints.push(where('category', '==', filters.category));
    }
    
    if (filters?.availability) {
      constraints.push(where('availability', '==', filters.availability));
    }
    
    if (filters?.featured !== undefined) {
      constraints.push(where('featured', '==', filters.featured));
    }
    
    let q = query(
      collection(db, 'catalog_products'),
      ...constraints,
      limit(pageSize)
    );
    
    if (lastDoc) {
      q = query(q, startAfter(lastDoc));
    }
    
    const querySnapshot = await getDocs(q);
    
    const products: CatalogProduct[] = [];
    let lastVisible: DocumentData | undefined = undefined;
    
    querySnapshot.forEach((doc) => {
      products.push({ id: doc.id, ...doc.data() } as CatalogProduct);
      lastVisible = doc;
    });
    
    return { products, lastDoc: lastVisible };
  } catch (error) {
    console.error('Error getting catalog products:', error);
    throw error;
  }
};

// NEW: Get product mappings for a catalog product
export const getProductMappings = async (
  catalogProductId: string
): Promise<ProductMapping[]> => {
  try {
    const q = query(
      collection(db, 'product_mappings'),
      where('catalogProductId', '==', catalogProductId),
      where('isActive', '==', true),
      orderBy('qualityScore', 'desc')
    );
    
    const querySnapshot = await getDocs(q);
    const mappings: ProductMapping[] = [];
    
    querySnapshot.forEach((doc) => {
      mappings.push({ id: doc.id, ...doc.data() } as ProductMapping);
    });
    
    return mappings;
  } catch (error) {
    console.error('Error getting product mappings:', error);
    throw error;
  }
};

// NEW: Get product mappings by vendor
export const getProductMappingsByVendor = async (
  vendorId: string,
  pageSize: number = 10,
  lastDoc?: DocumentData
): Promise<{ mappings: ProductMapping[], lastDoc: DocumentData | undefined }> => {
  try {
    let q = query(
      collection(db, 'product_mappings'),
      where('vendorId', '==', vendorId),
      where('isActive', '==', true),
      orderBy('createdAt', 'desc'),
      limit(pageSize)
    );
    
    if (lastDoc) {
      q = query(q, startAfter(lastDoc));
    }
    
    const querySnapshot = await getDocs(q);
    const mappings: ProductMapping[] = [];
    let lastVisible: DocumentData | undefined = undefined;
    
    querySnapshot.forEach((doc) => {
      mappings.push({ id: doc.id, ...doc.data() } as ProductMapping);
      lastVisible = doc;
    });
    
    return { mappings, lastDoc: lastVisible };
  } catch (error) {
    console.error('Error getting vendor product mappings:', error);
    throw error;
  }
};

// NEW: Create product mapping
export const createProductMapping = async (
  catalogProductId: string,
  vendorProductId: string,
  vendorId: string,
  vendorName: string,
  vendorPrice: number
): Promise<string> => {
  try {
    const productMapping = {
      catalogProductId,
      vendorProductId,
      vendorId,
      vendorName,
      qualityScore: 85,
      priceScore: 90,
      reliabilityScore: 85,
      isPreferred: false, // New vendors not preferred by default
      isActive: true,
      vendorPrice,
      lastPriceUpdate: serverTimestamp(),
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    };
    
    const docRef = await addDoc(collection(db, 'product_mappings'), productMapping);
    return docRef.id;
  } catch (error) {
    console.error('Error creating product mapping:', error);
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

// NEW: Update catalog product
export const updateCatalogProduct = async (
  catalogProductId: string,
  updates: Partial<{
    retailPrice: number;
    availability: 'in_stock' | 'out_of_stock' | 'limited';
    featured: boolean;
    categories: string[];
    isActive: boolean;
  }>
): Promise<void> => {
  try {
    const docRef = doc(db, 'catalog_products', catalogProductId);
    await updateDoc(docRef, {
      ...updates,
      updatedAt: serverTimestamp(),
    });
  } catch (error) {
    console.error('Error updating catalog product:', error);
    throw error;
  }
};

// NEW: Bulk create catalog products from approved vendor products
export const bulkCreateCatalogFromApproved = async (
  markupPercentage: number = 25
): Promise<{ created: number; failed: number }> => {
  try {
    // Get all approved vendor products without catalog entries
    const q = query(
      collection(db, 'vendor_products'),
      where('status', '==', 'approved'),
      where('catalogProductId', '==', null)
    );
    
    const querySnapshot = await getDocs(q);
    let created = 0;
    let failed = 0;
    
    // Process in batches
    const batch = writeBatch(db);
    const batchSize = 500;
    let operationCount = 0;
    
    for (const docSnap of querySnapshot.docs) {
      try {
        const vendorProduct = docSnap.data();
        const vendorPrice = vendorProduct.unitPrice || vendorProduct.price || 0;
        const retailPrice = Math.round(vendorPrice * (1 + markupPercentage / 100));
        
        // Create catalog product
        const catalogProduct = {
          partName: vendorProduct.partName || vendorProduct.name,
          partNumber: vendorProduct.partNumber || '',
          brand: vendorProduct.brand || '',
          description: vendorProduct.description || '',
          images: vendorProduct.images || vendorProduct.imageUrls || [],
          compatibility: vendorProduct.compatibility || null,
          category: vendorProduct.category || '',
          subcategory: vendorProduct.subcategory || '',
          condition: vendorProduct.condition || 'new',
          retailPrice,
          currency: 'UGX',
          availability: vendorProduct.stockQuantity > 0 ? 'in_stock' : 'out_of_stock',
          featured: false,
          categories: [vendorProduct.category],
          searchKeywords: vendorProduct.searchKeywords || [],
          specifications: vendorProduct.specifications || {},
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
          isActive: true,
        };
        
        const catalogRef = doc(collection(db, 'catalog_products'));
        batch.set(catalogRef, catalogProduct);
        
        // Create product mapping
        const mappingRef = doc(collection(db, 'product_mappings'));
        batch.set(mappingRef, {
          catalogProductId: catalogRef.id,
          vendorProductId: docSnap.id,
          vendorId: vendorProduct.vendorId,
          vendorName: vendorProduct.vendorName || '',
          qualityScore: 85,
          priceScore: 90,
          reliabilityScore: 85,
          isPreferred: true,
          isActive: true,
          vendorPrice,
          lastPriceUpdate: serverTimestamp(),
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        });
        
        // Update vendor product with catalog reference
        batch.update(doc(db, 'vendor_products', docSnap.id), {
          catalogProductId: catalogRef.id,
          updatedAt: serverTimestamp(),
        });
        
        operationCount += 3; // 3 operations per product
        created++;
        
        // Commit batch if near limit
        if (operationCount >= batchSize - 3) {
          await batch.commit();
          operationCount = 0;
        }
      } catch (error) {
        console.error(`Error processing product ${docSnap.id}:`, error);
        failed++;
      }
    }
    
    // Commit remaining operations
    if (operationCount > 0) {
      await batch.commit();
    }
    
    return { created, failed };
  } catch (error) {
    console.error('Error in bulk catalog creation:', error);
    throw error;
  }
};