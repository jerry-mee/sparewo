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
