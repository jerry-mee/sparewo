// src/lib/firebase/orders/index.ts
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
  Timestamp,
  FieldValue
} from 'firebase/firestore';
import { db } from '../config';

// Type for Firebase update operations
type FirebaseUpdateData = {
  [key: string]: string | number | boolean | Date | FieldValue | Timestamp | null | undefined;
};

// Type definitions
interface Order {
  id: string;
  orderNumber: string;
  customerId: string;
  items: OrderItem[];
  status: 'pending' | 'processing' | 'completed' | 'cancelled';
  totalAmount: number;
  deliveryAddress?: DeliveryAddress;
  customerPhone: string;
  adminNotes?: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  completedAt?: Timestamp;
  cancelledAt?: Timestamp;
}

interface OrderItem {
  catalogProductId: string;
  quantity: number;
  price: number;
  productName: string;
}

interface DeliveryAddress {
  street: string;
  city: string;
  state?: string;
  zipCode?: string;
  country: string;
}

interface OrderFulfillment {
  id: string;
  orderId: string;
  orderNumber: string;
  catalogProductId: string;
  vendorProductId: string;
  vendorId: string;
  customerId: string;
  quantity: number;
  vendorPrice: number;
  totalVendorAmount: number;
  status: 'pending' | 'accepted' | 'processing' | 'shipped' | 'delivered' | 'cancelled';
  assignedAt: Timestamp;
  acceptedAt?: Timestamp;
  shippedAt?: Timestamp;
  deliveredAt?: Timestamp;
  cancelledAt?: Timestamp;
  deliveryAddress?: DeliveryAddress;
  customerPhone: string;
  notes: string;
  vendorNotes?: string;
  trackingNumber?: string;
  carrier?: string;
  estimatedDelivery?: Timestamp;
  createdAt: Timestamp;
  updatedAt: Timestamp;
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

interface VendorProduct {
  id: string;
  vendorId: string;
  partName: string;
  partNumber: string;
  stockQuantity: number;
  quantity: number;
  unitPrice: number;
  price: number;
  status: string;
}

interface Vendor {
  id: string;
  businessName: string;
  status: string;
}

interface AvailableVendor {
  vendorId: string;
  vendorName: string;
  vendorProductId: string;
  vendorPrice: number;
  stockQuantity: number;
  qualityScore: number;
  isPreferred: boolean;
  vendor: Vendor;
}

// Get all orders with pagination
export const getOrders = async (
  status: string | null = null,
  pageSize: number = 10,
  lastDoc?: DocumentData
): Promise<{ orders: Order[], lastDoc: DocumentData | undefined }> => {
  try {
    const constraints: QueryConstraint[] = [orderBy('createdAt', 'desc')];
    
    if (status) {
      constraints.push(where('status', '==', status));
    }
    
    let q = query(
      collection(db, 'orders'),
      ...constraints,
      limit(pageSize)
    );
    
    if (lastDoc) {
      q = query(q, startAfter(lastDoc));
    }
    
    const querySnapshot = await getDocs(q);
    
    const orders: Order[] = [];
    let lastVisible: DocumentData | undefined = undefined;
    
    querySnapshot.forEach((doc) => {
      orders.push({ id: doc.id, ...doc.data() } as Order);
      lastVisible = doc;
    });
    
    return { orders, lastDoc: lastVisible };
  } catch (error) {
    console.error('Error getting orders:', error);
    throw error;
  }
};

// Get order by ID
export const getOrderById = async (id: string): Promise<Order | null> => {
  try {
    const docRef = doc(db, 'orders', id);
    const docSnap = await getDoc(docRef);

    if (docSnap.exists()) {
      return { id: docSnap.id, ...docSnap.data() } as Order;
    }

    return null;
  } catch (error) {
    console.error('Error getting order:', error);
    throw error;
  }
};

// Update order status
export const updateOrderStatus = async (
  orderId: string,
  status: 'pending' | 'processing' | 'completed' | 'cancelled',
  notes?: string
): Promise<void> => {
  try {
    const docRef = doc(db, 'orders', orderId);
    
    const updateData: FirebaseUpdateData = {
      status,
      updatedAt: serverTimestamp(),
    };
    
    if (notes) {
      updateData.adminNotes = notes;
    }
    
    if (status === 'completed') {
      updateData.completedAt = serverTimestamp();
    }
    
    if (status === 'cancelled') {
      updateData.cancelledAt = serverTimestamp();
    }
    
    await updateDoc(docRef, updateData);
  } catch (error) {
    console.error('Error updating order status:', error);
    throw error;
  }
};

// NEW: Create order fulfillment
export const createOrderFulfillment = async (
  orderId: string,
  items: Array<{
    catalogProductId: string;
    vendorProductId: string;
    vendorId: string;
    quantity: number;
    vendorPrice: number;
  }>
): Promise<string[]> => {
  try {
    const fulfillmentIds: string[] = [];
    
    // Get order details
    const order = await getOrderById(orderId);
    if (!order) {
      throw new Error('Order not found');
    }
    
    // Create fulfillment for each item
    for (const item of items) {
      const fulfillment = {
        orderId,
        orderNumber: order.orderNumber || orderId,
        catalogProductId: item.catalogProductId,
        vendorProductId: item.vendorProductId,
        vendorId: item.vendorId,
        customerId: order.customerId || '',
        quantity: item.quantity,
        vendorPrice: item.vendorPrice,
        totalVendorAmount: item.vendorPrice * item.quantity,
        status: 'pending', // pending, accepted, processing, shipped, delivered, cancelled
        assignedAt: serverTimestamp(),
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
        deliveryAddress: order.deliveryAddress || null,
        customerPhone: order.customerPhone || '',
        notes: '',
      };
      
      const docRef = await addDoc(collection(db, 'order_fulfillments'), fulfillment);
      fulfillmentIds.push(docRef.id);
    }
    
    // Update order status to processing
    await updateOrderStatus(orderId, 'processing', 'Fulfillments assigned to vendors');
    
    return fulfillmentIds;
  } catch (error) {
    console.error('Error creating order fulfillments:', error);
    throw error;
  }
};

// NEW: Get order fulfillments
export const getOrderFulfillments = async (
  orderId: string
): Promise<OrderFulfillment[]> => {
  try {
    const q = query(
      collection(db, 'order_fulfillments'),
      where('orderId', '==', orderId),
      orderBy('createdAt', 'desc')
    );
    
    const querySnapshot = await getDocs(q);
    const fulfillments: OrderFulfillment[] = [];
    
    querySnapshot.forEach((doc) => {
      fulfillments.push({ id: doc.id, ...doc.data() } as OrderFulfillment);
    });
    
    return fulfillments;
  } catch (error) {
    console.error('Error getting order fulfillments:', error);
    throw error;
  }
};

// NEW: Get fulfillments by vendor
export const getFulfillmentsByVendor = async (
  vendorId: string,
  status?: string,
  pageSize: number = 10,
  lastDoc?: DocumentData
): Promise<{ fulfillments: OrderFulfillment[], lastDoc: DocumentData | undefined }> => {
  try {
    const constraints: QueryConstraint[] = [
      where('vendorId', '==', vendorId),
      orderBy('createdAt', 'desc')
    ];
    
    if (status) {
      constraints.push(where('status', '==', status));
    }
    
    let q = query(
      collection(db, 'order_fulfillments'),
      ...constraints,
      limit(pageSize)
    );
    
    if (lastDoc) {
      q = query(q, startAfter(lastDoc));
    }
    
    const querySnapshot = await getDocs(q);
    const fulfillments: OrderFulfillment[] = [];
    let lastVisible: DocumentData | undefined = undefined;
    
    querySnapshot.forEach((doc) => {
      fulfillments.push({ id: doc.id, ...doc.data() } as OrderFulfillment);
      lastVisible = doc;
    });
    
    return { fulfillments, lastDoc: lastVisible };
  } catch (error) {
    console.error('Error getting vendor fulfillments:', error);
    throw error;
  }
};

// NEW: Update fulfillment status
export const updateFulfillmentStatus = async (
  fulfillmentId: string,
  status: 'pending' | 'accepted' | 'processing' | 'shipped' | 'delivered' | 'cancelled',
  vendorNotes?: string,
  trackingInfo?: {
    trackingNumber?: string;
    carrier?: string;
    estimatedDelivery?: Date;
  }
): Promise<void> => {
  try {
    const docRef = doc(db, 'order_fulfillments', fulfillmentId);
    
    const updateData: FirebaseUpdateData = {
      status,
      updatedAt: serverTimestamp(),
    };
    
    if (vendorNotes) {
      updateData.vendorNotes = vendorNotes;
    }
    
    if (status === 'accepted') {
      updateData.acceptedAt = serverTimestamp();
    }
    
    if (status === 'shipped' && trackingInfo) {
      updateData.shippedAt = serverTimestamp();
      updateData.trackingNumber = trackingInfo.trackingNumber || '';
      updateData.carrier = trackingInfo.carrier || '';
      updateData.estimatedDelivery = trackingInfo.estimatedDelivery 
        ? Timestamp.fromDate(trackingInfo.estimatedDelivery) 
        : null;
    }
    
    if (status === 'delivered') {
      updateData.deliveredAt = serverTimestamp();
    }
    
    if (status === 'cancelled') {
      updateData.cancelledAt = serverTimestamp();
    }
    
    await updateDoc(docRef, updateData);
    
    // Check if all fulfillments for the order are complete
    await checkOrderCompletion(fulfillmentId);
  } catch (error) {
    console.error('Error updating fulfillment status:', error);
    throw error;
  }
};

// Check if all fulfillments for an order are complete
const checkOrderCompletion = async (fulfillmentId: string): Promise<void> => {
  try {
    // Get the fulfillment to find the order ID
    const fulfillmentDoc = await getDoc(doc(db, 'order_fulfillments', fulfillmentId));
    if (!fulfillmentDoc.exists()) return;
    
    const orderId = fulfillmentDoc.data().orderId;
    
    // Get all fulfillments for this order
    const fulfillments = await getOrderFulfillments(orderId);
    
    // Check if all are delivered or cancelled
    const allComplete = fulfillments.every(f => 
      f.status === 'delivered' || f.status === 'cancelled'
    );
    
    if (allComplete) {
      // Check if any were delivered (not all cancelled)
      const anyDelivered = fulfillments.some(f => f.status === 'delivered');
      
      if (anyDelivered) {
        await updateOrderStatus(orderId, 'completed', 'All items delivered');
      } else {
        await updateOrderStatus(orderId, 'cancelled', 'All fulfillments cancelled');
      }
    }
  } catch (error) {
    console.error('Error checking order completion:', error);
    // Don't throw - this is a background check
  }
};

// NEW: Get available vendors for a product
export const getAvailableVendorsForProduct = async (
  catalogProductId: string
): Promise<AvailableVendor[]> => {
  try {
    // First, get all active mappings for this catalog product
    const mappingsQuery = query(
      collection(db, 'product_mappings'),
      where('catalogProductId', '==', catalogProductId),
      where('isActive', '==', true),
      orderBy('qualityScore', 'desc')
    );
    
    const mappingsSnapshot = await getDocs(mappingsQuery);
    const availableVendors: AvailableVendor[] = [];
    
    // For each mapping, get vendor details and check stock
    for (const mappingDoc of mappingsSnapshot.docs) {
      const mapping = { id: mappingDoc.id, ...mappingDoc.data() } as ProductMapping;
      
      // Get vendor product to check stock
      const vendorProductDoc = await getDoc(doc(db, 'vendor_products', mapping.vendorProductId));
      
      if (vendorProductDoc.exists()) {
        const vendorProduct = vendorProductDoc.data() as VendorProduct;
        const stockQuantity = vendorProduct.stockQuantity || vendorProduct.quantity || 0;
        
        if (stockQuantity > 0) {
          // Get vendor details
          const vendorDoc = await getDoc(doc(db, 'vendors', mapping.vendorId));
          
          if (vendorDoc.exists() && vendorDoc.data().status === 'approved') {
            availableVendors.push({
              vendorId: mapping.vendorId,
              vendorName: mapping.vendorName || vendorDoc.data().businessName,
              vendorProductId: mapping.vendorProductId,
              vendorPrice: mapping.vendorPrice,
              stockQuantity,
              qualityScore: mapping.qualityScore,
              isPreferred: mapping.isPreferred,
              vendor: { id: vendorDoc.id, ...vendorDoc.data() } as Vendor,
            });
          }
        }
      }
    }
    
    return availableVendors;
  } catch (error) {
    console.error('Error getting available vendors:', error);
    throw error;
  }
};

// NEW: Auto-assign vendors to order
export const autoAssignVendorsToOrder = async (
  orderId: string,
  preferQuality: boolean = true
): Promise<string[]> => {
  try {
    const order = await getOrderById(orderId);
    if (!order) {
      throw new Error('Order not found');
    }
    
    const fulfillmentItems: Array<{
      catalogProductId: string;
      vendorProductId: string;
      vendorId: string;
      quantity: number;
      vendorPrice: number;
    }> = [];
    
    // For each item in the order
    for (const item of order.items || []) {
      // Get available vendors for this product
      const availableVendors = await getAvailableVendorsForProduct(item.catalogProductId);
      
      if (availableVendors.length === 0) {
        console.warn(`No available vendors for product ${item.catalogProductId}`);
        continue;
      }
      
      // Select vendor based on preference
      let selectedVendor;
      if (preferQuality) {
        // Already sorted by quality score
        selectedVendor = availableVendors[0];
      } else {
        // Sort by price and select cheapest
        availableVendors.sort((a, b) => a.vendorPrice - b.vendorPrice);
        selectedVendor = availableVendors[0];
      }
      
      // Check if vendor has enough stock
      if (selectedVendor.stockQuantity >= item.quantity) {
        fulfillmentItems.push({
          catalogProductId: item.catalogProductId,
          vendorProductId: selectedVendor.vendorProductId,
          vendorId: selectedVendor.vendorId,
          quantity: item.quantity,
          vendorPrice: selectedVendor.vendorPrice,
        });
      } else {
        console.warn(`Vendor ${selectedVendor.vendorId} has insufficient stock for product ${item.catalogProductId}`);
        // In production, you might want to split the order or find multiple vendors
      }
    }
    
    // Create fulfillments
    if (fulfillmentItems.length > 0) {
      return await createOrderFulfillment(orderId, fulfillmentItems);
    } else {
      throw new Error('No vendors available for order items');
    }
  } catch (error) {
    console.error('Error auto-assigning vendors:', error);
    throw error;
  }
};

// Get order statistics
export const getOrderStats = async (): Promise<{
  total: number;
  pending: number;
  processing: number;
  completed: number;
  cancelled: number;
}> => {
  try {
    const [
      totalSnapshot,
      pendingSnapshot,
      processingSnapshot,
      completedSnapshot,
      cancelledSnapshot
    ] = await Promise.all([
      getDocs(collection(db, 'orders')),
      getDocs(query(collection(db, 'orders'), where('status', '==', 'pending'))),
      getDocs(query(collection(db, 'orders'), where('status', '==', 'processing'))),
      getDocs(query(collection(db, 'orders'), where('status', '==', 'completed'))),
      getDocs(query(collection(db, 'orders'), where('status', '==', 'cancelled')))
    ]);
    
    return {
      total: totalSnapshot.size,
      pending: pendingSnapshot.size,
      processing: processingSnapshot.size,
      completed: completedSnapshot.size,
      cancelled: cancelledSnapshot.size,
    };
  } catch (error) {
    console.error('Error getting order stats:', error);
    throw error;
  }
};