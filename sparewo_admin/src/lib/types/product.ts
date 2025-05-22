import { Timestamp } from 'firebase/firestore';

export interface Product {
  id: string;
  name: string;
  partName?: string; // Some products might use partName instead of name
  description: string;
  price: number;
  unitPrice?: number; // Some products might use unitPrice instead of price
  discountPrice?: number;
  category: string;
  subcategory?: string;
  brand: string;
  model: string;
  year: string;
  condition: 'new' | 'used' | 'refurbished';
  quantity: number;
  stockQuantity?: number; // Some products might use stockQuantity instead of quantity
  status: 'pending' | 'approved' | 'rejected';
  rejectionReason?: string;
  showInCatalog: boolean;
  images: string[]; // Changed from imageUrls to images to match Firestore
  imageUrls?: string[]; // Keep as optional for backward compatibility
  specifications?: Record<string, string>;
  vendorId: string;
  vendorName?: string;
  partNumber?: string;
  qualityGrade?: string;
  wholesalePrice?: number;
  searchKeywords?: string[];
  compatibility?: {
    vehicles: Array<{
      make: string;
      model: string;
      years: number[];
    }>;
  };
  reviewNotes?: string;
  createdAt: Timestamp | Date;
  updatedAt: Timestamp | Date;
  approvedAt?: Timestamp | Date;
  rejectedAt?: Timestamp | Date;
}