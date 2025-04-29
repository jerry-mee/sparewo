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
