// src/lib/firebase/vendors/index.ts
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
  setDoc,
  increment,
  Timestamp,
  FieldValue
} from 'firebase/firestore';
import { db } from '../config';
import { Vendor } from '@/lib/types/vendor';

// Type for Firebase update operations
type FirebaseUpdateData = {
  [key: string]: string | number | boolean | Date | FieldValue | Timestamp | null | undefined;
};

// Type definitions
interface VendorMetrics {
  id: string;
  vendorId: string;
  qualityScore: number;
  reliabilityScore: number;
  responseTimeScore: number;
  priceCompetitivenessScore: number;
  overallScore: number;
  totalOrdersFulfilled: number;
  totalOrdersCancelled: number;
  averageResponseTime: number;
  averageDeliveryTime: number;
  totalComplaints: number;
  totalPositiveReviews: number;
  totalNegativeReviews: number;
  lastScoreUpdate: Timestamp;
  scoreHistory: ScoreHistoryEntry[];
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

interface ScoreHistoryEntry {
  date: Timestamp;
  qualityScore: number;
  reliabilityScore: number;
  responseTimeScore: number;
  priceCompetitivenessScore: number;
  overallScore: number;
}

interface VendorWithMetrics extends Vendor {
  metrics: VendorMetrics;
}

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

// Update vendor status (enhanced with initialization)
export const updateVendorStatus = async (
  id: string,
  status: 'pending' | 'approved' | 'rejected',
  rejectionReason?: string
): Promise<void> => {
  try {
    const docRef = doc(db, 'vendors', id);

    const updateData: FirebaseUpdateData = {
      status,
      updatedAt: serverTimestamp(),
    };

    if (status === 'approved') {
      updateData.approvedAt = serverTimestamp();
      
      // Initialize vendor dashboard stats
      await initializeVendorStats(id);
      
      // Initialize vendor metrics
      await initializeVendorMetrics(id);
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

// NEW: Initialize vendor dashboard stats
const initializeVendorStats = async (vendorId: string): Promise<void> => {
  try {
    const statsRef = doc(db, 'dashboard_stats', vendorId);
    
    const initialStats = {
      totalProducts: 0,
      activeProducts: 0,
      pendingProducts: 0,
      totalOrders: 0,
      pendingOrders: 0,
      completedOrders: 0,
      totalRevenue: 0,
      monthlyRevenue: 0,
      averageRating: 0,
      totalRatings: 0,
      lastUpdated: serverTimestamp(),
      createdAt: serverTimestamp(),
    };
    
    await setDoc(statsRef, initialStats);
  } catch (error) {
    console.error('Error initializing vendor stats:', error);
    // Don't throw - this is not critical for vendor approval
  }
};

// NEW: Initialize vendor metrics
const initializeVendorMetrics = async (vendorId: string): Promise<void> => {
  try {
    const metricsRef = doc(db, 'vendor_metrics', vendorId);
    
    const initialMetrics = {
      vendorId,
      qualityScore: 85, // Default starting score
      reliabilityScore: 85,
      responseTimeScore: 85,
      priceCompetitivenessScore: 90,
      overallScore: 86.25, // Average of all scores
      totalOrdersFulfilled: 0,
      totalOrdersCancelled: 0,
      averageResponseTime: 0, // in hours
      averageDeliveryTime: 0, // in days
      totalComplaints: 0,
      totalPositiveReviews: 0,
      totalNegativeReviews: 0,
      lastScoreUpdate: serverTimestamp(),
      scoreHistory: [],
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    };
    
    await setDoc(metricsRef, initialMetrics);
  } catch (error) {
    console.error('Error initializing vendor metrics:', error);
    // Don't throw - this is not critical for vendor approval
  }
};

// NEW: Get vendor metrics
export const getVendorMetrics = async (vendorId: string): Promise<VendorMetrics | null> => {
  try {
    const docRef = doc(db, 'vendor_metrics', vendorId);
    const docSnap = await getDoc(docRef);

    if (docSnap.exists()) {
      return { id: docSnap.id, ...docSnap.data() } as VendorMetrics;
    }

    return null;
  } catch (error) {
    console.error('Error getting vendor metrics:', error);
    throw error;
  }
};

// NEW: Update vendor metrics
export const updateVendorMetrics = async (
  vendorId: string,
  updates: {
    orderFulfilled?: boolean;
    orderCancelled?: boolean;
    responseTime?: number; // in hours
    deliveryTime?: number; // in days
    complaint?: boolean;
    positiveReview?: boolean;
    negativeReview?: boolean;
  }
): Promise<void> => {
  try {
    const metricsRef = doc(db, 'vendor_metrics', vendorId);
    
    const updateData: FirebaseUpdateData = {
      updatedAt: serverTimestamp(),
    };
    
    if (updates.orderFulfilled) {
      updateData.totalOrdersFulfilled = increment(1);
    }
    
    if (updates.orderCancelled) {
      updateData.totalOrdersCancelled = increment(1);
    }
    
    if (updates.complaint) {
      updateData.totalComplaints = increment(1);
    }
    
    if (updates.positiveReview) {
      updateData.totalPositiveReviews = increment(1);
    }
    
    if (updates.negativeReview) {
      updateData.totalNegativeReviews = increment(1);
    }
    
    // Update response and delivery times (these would need more complex averaging logic in production)
    if (updates.responseTime !== undefined) {
      updateData.averageResponseTime = updates.responseTime;
    }
    
    if (updates.deliveryTime !== undefined) {
      updateData.averageDeliveryTime = updates.deliveryTime;
    }
    
    await updateDoc(metricsRef, updateData);
    
    // Recalculate scores after update
    await recalculateVendorScores(vendorId);
  } catch (error) {
    console.error('Error updating vendor metrics:', error);
    throw error;
  }
};

// NEW: Recalculate vendor scores
const recalculateVendorScores = async (vendorId: string): Promise<void> => {
  try {
    const metrics = await getVendorMetrics(vendorId);
    if (!metrics) return;
    
    // Calculate quality score (based on reviews and complaints)
    const totalReviews = metrics.totalPositiveReviews + metrics.totalNegativeReviews;
    const positiveRatio = totalReviews > 0 ? metrics.totalPositiveReviews / totalReviews : 0.85;
    const complaintRatio = metrics.totalOrdersFulfilled > 0 
      ? 1 - (metrics.totalComplaints / metrics.totalOrdersFulfilled) 
      : 0.85;
    const qualityScore = Math.round((positiveRatio * 0.7 + complaintRatio * 0.3) * 100);
    
    // Calculate reliability score (based on fulfillment rate)
    const totalOrders = metrics.totalOrdersFulfilled + metrics.totalOrdersCancelled;
    const fulfillmentRatio = totalOrders > 0 ? metrics.totalOrdersFulfilled / totalOrders : 0.85;
    const reliabilityScore = Math.round(fulfillmentRatio * 100);
    
    // Calculate response time score (assuming < 2 hours is perfect)
    const responseScore = metrics.averageResponseTime > 0
      ? Math.round(Math.max(0, 100 - (metrics.averageResponseTime - 2) * 10))
      : 85;
    
    // Price competitiveness would need market comparison - using default for now
    const priceScore = metrics.priceCompetitivenessScore || 90;
    
    // Calculate overall score
    const overallScore = Math.round(
      (qualityScore * 0.3 + reliabilityScore * 0.3 + responseScore * 0.2 + priceScore * 0.2)
    );
    
    // Update scores
    await updateDoc(doc(db, 'vendor_metrics', vendorId), {
      qualityScore,
      reliabilityScore,
      responseTimeScore: responseScore,
      overallScore,
      lastScoreUpdate: serverTimestamp(),
      scoreHistory: [...(metrics.scoreHistory || []), {
        date: serverTimestamp(),
        qualityScore,
        reliabilityScore,
        responseTimeScore: responseScore,
        priceCompetitivenessScore: priceScore,
        overallScore,
      }],
    });
  } catch (error) {
    console.error('Error recalculating vendor scores:', error);
    // Don't throw - scoring errors shouldn't break other operations
  }
};

// NEW: Get top vendors by score
export const getTopVendorsByScore = async (
  topLimit: number = 10
): Promise<VendorWithMetrics[]> => {
  try {
    const q = query(
      collection(db, 'vendor_metrics'),
      orderBy('overallScore', 'desc'),
      where('overallScore', '>', 0),
      limit(topLimit)
    );
    
    const querySnapshot = await getDocs(q);
    const vendors: VendorWithMetrics[] = [];
    
    for (const docSnap of querySnapshot.docs) {
      const metrics = { id: docSnap.id, ...docSnap.data() } as VendorMetrics;
      // Get vendor details
      const vendor = await getVendorById(metrics.vendorId);
      if (vendor) {
        vendors.push({
          ...vendor,
          metrics,
        });
      }
    }
    
    return vendors;
  } catch (error) {
    console.error('Error getting top vendors:', error);
    throw error;
  }
};

// Suspend or reactivate vendor account
export const toggleVendorSuspension = async (
  id: string,
  suspend: boolean,
  reason?: string
): Promise<void> => {
  try {
    const docRef = doc(db, 'vendors', id);

    const updateData: FirebaseUpdateData = {
      isSuspended: suspend,
      updatedAt: serverTimestamp(),
    };

    if (suspend) {
      updateData.suspendedAt = serverTimestamp();
      updateData.suspensionReason = reason || 'Suspended by admin';
    } else {
      updateData.reactivatedAt = serverTimestamp();
      updateData.suspensionReason = null;
    }

    await updateDoc(docRef, updateData);
  } catch (error) {
    console.error('Error toggling vendor suspension:', error);
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