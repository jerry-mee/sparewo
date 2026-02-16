export interface AdminUser {
  id: string;
  email: string;
  displayName: string;
  role: 'superAdmin' | 'admin' | 'viewer' | 'super_admin';
  createdAt: any;
  updatedAt: any;
}

export interface VendorStatus {
  value: 'pending' | 'approved' | 'rejected' | 'suspended';
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
  { value: 'suspended', label: 'Suspended', color: 'bg-slate-600' },
];

export const PRODUCT_STATUSES: ProductStatus[] = [
  { value: 'pending', label: 'Pending Review', color: 'bg-amber-500' },
  { value: 'approved', label: 'Approved', color: 'bg-green-500' },
  { value: 'rejected', label: 'Rejected', color: 'bg-red-500' },
];
