Okay, I understand. You want me to combine the two Bash script parts into a single script that *generates* the final `fix-critical-issues.sh` script. This generated script will then contain all the commands to apply the fixes to your Next.js project.

Here is the combined Bash script that will create the `src/scripts/fix-critical-issues.sh` file with all the specified fixes and improvements, following all your instructions including full code rewriting without truncation.

```bash
#!/bin/bash

# This script GENERATES the actual fix script.

# Color definitions for *this* generator script
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Generating the critical fixes script...${NC}"

# Ensure the target directory exists
mkdir -p src/scripts

# Create the actual fix script using a heredoc
# The final script will be located at: src/scripts/fix-critical-issues.sh
cat > src/scripts/fix-critical-issues.sh << 'EOF'
#!/bin/bash

# Color definitions (for the generated script)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}===========================================================${NC}"
echo -e "${BLUE}    SpareWo Admin Dashboard - Critical Fixes Installer${NC}"
echo -e "${BLUE}===========================================================${NC}"
echo ""

# Ensure necessary base directories exist before applying fixes
mkdir -p src/app
mkdir -p src/components/ui
mkdir -p src/components/Layouts/sidebar
mkdir -p src/lib
mkdir -p src/services
mkdir -p src/styles
mkdir -p src/context

# 1. Fix Build Error - Missing generateStaticParams()
echo -e "${CYAN}[1/6]${NC} Fixing build error (missing generateStaticParams)..."

# Create products id page with generateStaticParams
mkdir -p src/app/products/[id]
# File: src/app/products/[id]/page.tsx
cat > src/app/products/[id]/page.tsx << 'EOF_INNER'
'use client';

import { useEffect, useState } from 'react';
import { useParams } from 'next/navigation';
import { productService, Product, ProductStatus } from '@/services/firebase.service';
import LoadingScreen from '@/components/LoadingScreen';
import Breadcrumb from '@/components/Breadcrumbs/Breadcrumb';
import Link from 'next/link';

// This function tells Next.js which paths to pre-render for static export
export async function generateStaticParams() {
  // Return an empty array to avoid pre-rendering any specific paths
  // The actual data will be fetched client-side
  return [];
}

export default function ProductDetailsPage() {
  const { id } = useParams();
  const [product, setProduct] = useState<Product | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetchProduct() {
      try {
        // Ensure id is a string before using it
        if (typeof id !== 'string' || !id) {
          setError('Invalid product ID.');
          setLoading(false);
          return;
        }
        
        const productData = await productService.getProduct(id);
        setProduct(productData);
      } catch (err: any) {
        console.error('Error fetching product:', err);
        setError(err.message || 'Failed to load product details');
      } finally {
        setLoading(false);
      }
    }

    if (id) {
        fetchProduct();
    } else {
        // Handle the case where id might initially be undefined or not a string
        setError('Product ID is missing or invalid.');
        setLoading(false);
    }
  }, [id]);

  // Format UGX currency
  const formatUGX = (amount: number = 0) => {
    return new Intl.NumberFormat('en-UG', {
      style: 'currency',
      currency: 'UGX',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(amount);
  };

  const handleStatusUpdate = async (productId: string, newStatus: ProductStatus) => {
    if (!product || product.status === newStatus) return; // Prevent unnecessary updates

    try {
      await productService.updateProductStatus(productId, newStatus);
      setProduct(prevProduct => prevProduct ? { ...prevProduct, status: newStatus } : null);
      // Optionally, add user feedback here (e.g., using a toast notification)
      console.log(`Product status updated to ${newStatus}`);
    } catch (err) {
      console.error('Error updating product status:', err);
      // Optionally, show an error message to the user
      setError('Failed to update product status.');
    }
  };

  if (loading) {
    return <LoadingScreen />;
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[calc(100vh-200px)] py-12">
        <div className="bg-red-50 dark:bg-red-900/20 rounded-lg p-6 max-w-md text-center shadow-md">
          <h1 className="text-xl font-bold text-red-600 dark:text-red-400 mb-2">Error Loading Product</h1>
          <p className="text-gray-700 dark:text-gray-300 mb-4">{error}</p>
          <Link
            href="/products"
            className="inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary-dark transition-colors"
          >
            Return to Products
          </Link>
        </div>
      </div>
    );
  }

  if (!product) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[calc(100vh-200px)] py-12">
        <div className="bg-yellow-50 dark:bg-yellow-900/20 rounded-lg p-6 max-w-md text-center shadow-md">
          <h1 className="text-xl font-bold text-yellow-600 dark:text-yellow-400 mb-2">Product Not Found</h1>
          <p className="text-gray-700 dark:text-gray-300 mb-4">The product you are looking for does not exist or may have been removed.</p>
          <Link
            href="/products"
            className="inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary-dark transition-colors"
          >
            Return to Products
          </Link>
        </div>
      </div>
    );
  }

  return (
    <>
      <Breadcrumb
        pageName="Product Details"
        items={[
          { href: '/products', label: 'Products' }
        ]}
      />

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        {/* Main Product Info */}
        <div className="lg:col-span-2">
          <div className="rounded-lg border border-stroke bg-white p-6 shadow-default dark:border-strokedark dark:bg-boxdark">
            {/* Header Section */}
            <div className="mb-6 flex flex-wrap items-start justify-between gap-4">
              <div>
                <h2 className="text-2xl font-semibold text-black dark:text-white">
                  {product.partName || product.name || 'Unnamed Product'}
                </h2>
                <div className="mt-1 flex flex-wrap items-center gap-2">
                  <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${
                    product.status === ProductStatus.APPROVED ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400' :
                    product.status === ProductStatus.PENDING ? 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400' :
                    product.status === ProductStatus.REJECTED ? 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400' :
                    product.status === ProductStatus.OUTOFSTOCK ? 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400' :
                    product.status === ProductStatus.DISCONTINUED ? 'bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-400' :
                    'bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-300'
                  }`}>
                    {String(product.status).charAt(0).toUpperCase() + String(product.status).slice(1)}
                  </span>
                  <span className="text-sm text-gray-500 dark:text-gray-400">
                    {product.stockQuantity || 0} in stock
                  </span>
                </div>
              </div>
              <div className="text-2xl font-bold text-primary dark:text-primary-light">
                {formatUGX(product.unitPrice || product.price || 0)}
              </div>
            </div>

            {/* Details Grid */}
            <div className="mb-6 grid grid-cols-1 gap-6 md:grid-cols-2">
              {/* Product Information */}
              <div className="rounded-md border border-stroke bg-gray-50 p-4 dark:border-strokedark dark:bg-boxdark-2">
                <h3 className="mb-4 text-lg font-medium text-black dark:text-white">Product Information</h3>
                <dl className="space-y-3 text-sm">
                  {product.brand && (
                    <div className="flex">
                      <dt className="w-28 flex-shrink-0 font-medium text-gray-600 dark:text-gray-400">Brand:</dt>
                      <dd className="text-gray-800 dark:text-gray-200">{product.brand}</dd>
                    </div>
                  )}
                  {product.partNumber && (
                    <div className="flex">
                      <dt className="w-28 flex-shrink-0 font-medium text-gray-600 dark:text-gray-400">Part Number:</dt>
                      <dd className="text-gray-800 dark:text-gray-200">{product.partNumber}</dd>
                    </div>
                  )}
                   {product.condition && (
                    <div className="flex">
                      <dt className="w-28 flex-shrink-0 font-medium text-gray-600 dark:text-gray-400">Condition:</dt>
                      <dd className="text-gray-800 dark:text-gray-200">{product.condition}</dd>
                    </div>
                  )}
                  {product.category && (
                    <div className="flex">
                      <dt className="w-28 flex-shrink-0 font-medium text-gray-600 dark:text-gray-400">Category:</dt>
                      <dd className="text-gray-800 dark:text-gray-200">{product.category}</dd>
                    </div>
                  )}
                </dl>
              </div>

              {/* Vendor Information */}
              <div className="rounded-md border border-stroke bg-gray-50 p-4 dark:border-strokedark dark:bg-boxdark-2">
                <h3 className="mb-4 text-lg font-medium text-black dark:text-white">Vendor Information</h3>
                <dl className="space-y-3 text-sm">
                  <div className="flex">
                    <dt className="w-28 flex-shrink-0 font-medium text-gray-600 dark:text-gray-400">Vendor:</dt>
                    <dd className="text-gray-800 dark:text-gray-200">
                      {product.vendorName || 'Unknown'}
                      {product.vendorId && (
                        <Link
                          href={`/vendors/${product.vendorId}`}
                          className="ml-2 text-sm text-primary hover:underline dark:text-primary-light"
                        >
                          (View Vendor)
                        </Link>
                      )}
                    </dd>
                  </div>
                   <div className="flex">
                    <dt className="w-28 flex-shrink-0 font-medium text-gray-600 dark:text-gray-400">Added On:</dt>
                    <dd className="text-gray-800 dark:text-gray-200">
                      {product.createdAt?.seconds
                        ? new Date(product.createdAt.seconds * 1000).toLocaleDateString()
                        : 'Unknown date'}
                    </dd>
                  </div>
                  {/* Add more vendor details if available */}
                </dl>
              </div>
            </div>

            {/* Description */}
            {product.description && (
              <div className="mb-6">
                <h3 className="mb-2 text-lg font-medium text-black dark:text-white">Description</h3>
                <div className="rounded-md border border-stroke bg-gray-50 p-4 dark:border-strokedark dark:bg-boxdark-2">
                  <p className="whitespace-pre-line text-sm text-gray-800 dark:text-gray-200">{product.description}</p>
                </div>
              </div>
            )}

            {/* Compatibility */}
            {product.compatibility && (
              <div>
                <h3 className="mb-2 text-lg font-medium text-black dark:text-white">Vehicle Compatibility</h3>
                <div className="rounded-md border border-stroke bg-gray-50 p-4 dark:border-strokedark dark:bg-boxdark-2">
                  <p className="whitespace-pre-line text-sm text-gray-800 dark:text-gray-200">{product.compatibility}</p>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Actions & Status */}
        <div className="lg:col-span-1">
          <div className="rounded-lg border border-stroke bg-white p-6 shadow-default dark:border-strokedark dark:bg-boxdark">
            <h3 className="mb-4 text-lg font-medium text-black dark:text-white">Product Actions</h3>
            <div className="space-y-3">
              <Link
                href={`/products/${id}/edit`}
                className="flex w-full items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary-dark transition-colors"
              >
                Edit Product
              </Link>
              <Link
                href={`/catalogs`}
                className="flex w-full items-center justify-center rounded-md border border-stroke bg-white px-4 py-2 text-sm font-medium text-black hover:bg-gray-100 dark:border-strokedark dark:bg-boxdark-2 dark:text-white dark:hover:bg-gray-700 transition-colors"
              >
                View in Catalog
              </Link>
            </div>

            <div className="mt-6 border-t border-stroke pt-6 dark:border-strokedark">
              <h3 className="mb-3 text-lg font-medium text-black dark:text-white">Status Management</h3>
              <div className="grid grid-cols-1 gap-2">
                <button
                  onClick={() => handleStatusUpdate(product.id, ProductStatus.APPROVED)}
                  disabled={product.status === ProductStatus.APPROVED}
                  className={`w-full rounded-md px-4 py-2 text-sm font-medium transition-colors ${
                    product.status === ProductStatus.APPROVED
                      ? 'cursor-not-allowed bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400'
                      : 'bg-green-600 text-white hover:bg-green-700 dark:bg-green-700 dark:hover:bg-green-600'
                  }`}
                >
                  Approve
                </button>
                <button
                  onClick={() => handleStatusUpdate(product.id, ProductStatus.REJECTED)}
                  disabled={product.status === ProductStatus.REJECTED}
                  className={`w-full rounded-md px-4 py-2 text-sm font-medium transition-colors ${
                    product.status === ProductStatus.REJECTED
                      ? 'cursor-not-allowed bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400'
                      : 'bg-red-600 text-white hover:bg-red-700 dark:bg-red-700 dark:hover:bg-red-600'
                  }`}
                >
                  Reject
                </button>
                <button
                  onClick={() => handleStatusUpdate(product.id, ProductStatus.PENDING)}
                  disabled={product.status === ProductStatus.PENDING}
                   className={`w-full rounded-md px-4 py-2 text-sm font-medium transition-colors ${
                    product.status === ProductStatus.PENDING
                      ? 'cursor-not-allowed bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400'
                      : 'bg-yellow-500 text-white hover:bg-yellow-600 dark:bg-yellow-600 dark:hover:bg-yellow-500'
                  }`}
                >
                  Set to Pending
                </button>
                 <button
                  onClick={() => handleStatusUpdate(product.id, ProductStatus.OUTOFSTOCK)}
                  disabled={product.status === ProductStatus.OUTOFSTOCK}
                  className={`w-full rounded-md px-4 py-2 text-sm font-medium transition-colors ${
                    product.status === ProductStatus.OUTOFSTOCK
                      ? 'cursor-not-allowed bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400'
                      : 'bg-blue-600 text-white hover:bg-blue-700 dark:bg-blue-700 dark:hover:bg-blue-600'
                  }`}
                >
                  Mark Out of Stock
                </button>
                <button
                  onClick={() => handleStatusUpdate(product.id, ProductStatus.DISCONTINUED)}
                  disabled={product.status === ProductStatus.DISCONTINUED}
                   className={`w-full rounded-md px-4 py-2 text-sm font-medium transition-colors ${
                    product.status === ProductStatus.DISCONTINUED
                      ? 'cursor-not-allowed bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-400'
                      : 'bg-gray-500 text-white hover:bg-gray-600 dark:bg-gray-600 dark:hover:bg-gray-500'
                  }`}
                >
                  Mark Discontinued
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
}
EOF_INNER

# Create vendors id page with generateStaticParams
mkdir -p src/app/vendors/[id]
# File: src/app/vendors/[id]/page.tsx
cat > src/app/vendors/[id]/page.tsx << 'EOF_INNER'
'use client';

import { useState, useEffect, useCallback } from 'react';
import { useParams } from 'next/navigation';
import Link from 'next/link';
import { vendorService, VendorStatus, productService, Product } from '@/services/firebase.service';
import { Users, Mail, Phone, Store, MapPin, Clock, CheckCircle, XCircle, AlertTriangle, Package, ExternalLink } from 'lucide-react';
import Breadcrumb from '@/components/Breadcrumbs/Breadcrumb';
import LoadingScreen from '@/components/LoadingScreen';
import { Badge } from '@/components/ui/badge'; // Assuming you have a Badge component

// This function tells Next.js which paths to pre-render for static export
export async function generateStaticParams() {
  // Return an empty array to avoid pre-rendering any specific paths
  // The actual data will be fetched client-side
  return [];
}

// Extend Product interface if necessary, or use imported one
// interface Product { ... }

// Vendor interface (adjust based on your actual Vendor structure)
interface Vendor {
  id: string;
  businessName: string;
  name: string; // Primary contact name
  email: string;
  phone?: string;
  businessAddress?: string;
  businessType?: string;
  description?: string;
  status: VendorStatus | string;
  createdAt: any; // Firestore Timestamp or Date
  isEmailVerified?: boolean;
  isVerified?: boolean; // ID verification
  hasBusinessLicense?: boolean;
  ordersFulfilled?: number;
  totalSales?: number;
  [key: string]: any; // Allow other properties
}

export default function VendorDetailPage() {
  const { id } = useParams();
  const [vendor, setVendor] = useState<Vendor | null>(null);
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [statusUpdating, setStatusUpdating] = useState(false);
  const [feedback, setFeedback] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

  const vendorId = typeof id === 'string' ? id : null;

  const fetchVendorData = useCallback(async () => {
    if (!vendorId) {
      setError("Invalid vendor ID.");
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      const vendorData = await vendorService.getVendor(vendorId);
      if (!vendorData) {
        setError("Vendor not found");
        setVendor(null);
      } else {
        setVendor(vendorData as Vendor); // Cast to Vendor type
        setError(null); // Clear previous errors
      }
    } catch (err: any) {
      console.error('Error fetching vendor details:', err);
      setError(err.message || "Failed to load vendor details");
      setVendor(null);
    } finally {
      setLoading(false);
    }
  }, [vendorId]);

  const fetchVendorProducts = useCallback(() => {
     if (!vendorId) return () => {}; // Return an empty cleanup function if no id

     setLoading(true); // Keep loading true until products are fetched
     const unsubscribe = productService.listenToProducts((allProducts) => {
       const vendorProducts = allProducts.filter(product => product.vendorId === vendorId);
       setProducts(vendorProducts);
       // Consider setting loading to false only after both vendor and products are potentially loaded
       // or manage loading states separately. Here, we assume loading finishes after products are set.
       setLoading(false);
     }, (err: Error) => {
        console.error('Error listening to products:', err);
        setError("Failed to load vendor's products.");
        setLoading(false);
     });

     return unsubscribe; // Return the cleanup function
   }, [vendorId]);


  useEffect(() => {
    fetchVendorData();
    const unsubscribeProducts = fetchVendorProducts();

    return () => {
      unsubscribeProducts(); // Cleanup product listener on component unmount
    };
  }, [fetchVendorData, fetchVendorProducts]); // Depend on the callback functions


  const displayFeedback = (message: string, type: 'success' | 'error') => {
    setFeedback({ message, type });
    setTimeout(() => setFeedback(null), 3000);
  };

  const handleStatusChange = async (newStatus: VendorStatus) => {
    if (!vendor || !vendorId || statusUpdating) return;

    setStatusUpdating(true);
    try {
      await vendorService.updateVendorStatus(vendorId, newStatus);
      setVendor(prevVendor => prevVendor ? { ...prevVendor, status: newStatus } : null);
      displayFeedback(`Vendor status updated to ${newStatus}`, 'success');
    } catch (error: any) {
      console.error('Error updating vendor status:', error);
      displayFeedback('Failed to update vendor status.', 'error');
    } finally {
      setStatusUpdating(false);
    }
  };

  // Format UGX currency
  const formatUGX = (amount: number = 0) => {
    return new Intl.NumberFormat('en-UG', {
      style: 'currency',
      currency: 'UGX',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(amount);
  };

  // Format date nicely
  const formatDate = (timestamp: any): string => {
    if (!timestamp) return 'N/A';
    try {
      // Handle both Firestore Timestamp and potentially other date formats
      const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
      if (isNaN(date.getTime())) {
        return 'Invalid Date';
      }
      return date.toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric'
      });
    } catch (e) {
      console.error("Error formatting date:", e);
      return 'Invalid Date';
    }
  };

  const getStatusBadge = (status: VendorStatus | string) => {
    let variant: "default" | "secondary" | "destructive" | "outline" | "success" | "warning" | "danger" | "info" | null | undefined = "secondary";
    let icon = <Clock size={14} className="mr-1" />;
    let text = String(status).charAt(0).toUpperCase() + String(status).slice(1);

    switch (status) {
      case VendorStatus.APPROVED:
        variant = "success";
        icon = <CheckCircle size={14} className="mr-1" />;
        break;
      case VendorStatus.PENDING:
        variant = "warning";
        icon = <Clock size={14} className="mr-1" />;
        break;
      case VendorStatus.REJECTED:
        variant = "danger"; // Use 'danger' if defined in your Badge variants
        icon = <XCircle size={14} className="mr-1" />;
        break;
      case VendorStatus.SUSPENDED:
        variant = "destructive"; // Use 'destructive' if defined
        icon = <AlertTriangle size={14} className="mr-1" />; // Example icon
        break;
      default:
        variant = "info"; // Use 'info' or 'default' for unknown statuses
        icon = <AlertTriangle size={14} className="mr-1" />;
        text = "Unknown"; // Or display the status directly if preferred
        break;
    }

    return (
        <Badge variant={variant} className="flex items-center text-xs">
            {icon}
            <span>{text}</span>
        </Badge>
    );
  };

  // Helper for rendering detail items cleanly
  const DetailItem = ({ icon: Icon, label, value }: { icon: React.ElementType, label: string, value?: string | number | React.ReactNode }) => (
    value ? (
      <div className="flex items-start">
        <Icon className="mr-3 mt-1 h-4 w-4 flex-shrink-0 text-gray-500 dark:text-gray-400" />
        <div>
          <p className="text-xs text-gray-500 dark:text-gray-400">{label}</p>
          <p className="text-sm font-medium text-gray-800 dark:text-gray-200">{value}</p>
        </div>
      </div>
    ) : null
  );

  // Helper for Verification status
  const VerificationItem = ({ label, isVerified }: { label: string, isVerified?: boolean }) => (
    <div className="flex items-center justify-between text-sm">
      <span className="text-gray-600 dark:text-gray-400">{label}</span>
      <span className={`flex items-center font-medium ${isVerified ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'}`}>
        {isVerified ? (
          <CheckCircle size={16} className="mr-1" />
        ) : (
          <XCircle size={16} className="mr-1" />
        )}
        {isVerified ? 'Verified' : 'Not Verified'}
      </span>
    </div>
  );

  // Helper for Statistics
  const StatisticItem = ({ label, value }: { label: string, value: string | number }) => (
     <div className="flex items-center justify-between text-sm">
       <span className="text-gray-600 dark:text-gray-400">{label}</span>
       <span className="font-semibold text-gray-800 dark:text-gray-200">{value}</span>
     </div>
   );

  if (loading) {
    return <LoadingScreen />;
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[calc(100vh-200px)] py-12">
        <div className="bg-red-50 dark:bg-red-900/20 rounded-lg p-6 max-w-md text-center shadow-md">
          <h1 className="text-xl font-bold text-red-600 dark:text-red-400 mb-2">Error Loading Vendor</h1>
          <p className="text-gray-700 dark:text-gray-300 mb-4">{error}</p>
          <Link
            href="/vendors"
            className="inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary-dark transition-colors"
          >
            Return to Vendors List
          </Link>
        </div>
      </div>
    );
  }

  if (!vendor) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[calc(100vh-200px)] py-12">
        <div className="bg-yellow-50 dark:bg-yellow-900/20 rounded-lg p-6 max-w-md text-center shadow-md">
          <h1 className="text-xl font-bold text-yellow-600 dark:text-yellow-400 mb-2">Vendor Not Found</h1>
          <p className="text-gray-700 dark:text-gray-300 mb-4">The vendor you are looking for does not exist or may have been removed.</p>
          <Link
            href="/vendors"
            className="inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary-dark transition-colors"
          >
            Return to Vendors List
          </Link>
        </div>
      </div>
    );
  }

  return (
    <>
      <Breadcrumb
        pageName={vendor.businessName || vendor.name || 'Vendor Details'}
        items={[{ href: '/vendors', label: 'Vendors' }]}
      />

      {/* Feedback Toast */}
      {feedback && (
        <div className={`fixed top-20 right-4 z-50 rounded-lg px-4 py-3 shadow-lg ${
          feedback.type === 'success' ? 'bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-400' : 'bg-red-100 text-red-800 dark:bg-red-900/20 dark:text-red-400'
        }`}>
          <div className="flex items-center">
            {feedback.type === 'success' ? (
              <CheckCircle className="mr-2 h-5 w-5" />
            ) : (
              <AlertTriangle className="mr-2 h-5 w-5" />
            )}
            <p>{feedback.message}</p>
          </div>
        </div>
      )}

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        {/* Main Vendor Info & Products */}
        <div className="lg:col-span-2">
          <div className="rounded-lg border border-stroke bg-white p-6 shadow-default dark:border-strokedark dark:bg-boxdark">
            {/* Vendor Header */}
            <div className="mb-6 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
              <div className="flex items-center gap-4">
                <div className="flex h-16 w-16 flex-shrink-0 items-center justify-center rounded-full bg-primary/10 text-primary">
                  <Store size={32} />
                </div>
                <div>
                  <h2 className="text-2xl font-semibold text-black dark:text-white">{vendor.businessName}</h2>
                  <div className="mt-1 flex flex-wrap items-center gap-2">
                    {getStatusBadge(vendor.status)}
                    <span className="text-sm text-gray-500 dark:text-gray-400">
                      Joined {formatDate(vendor.createdAt)}
                    </span>
                  </div>
                </div>
              </div>

              {/* Status Action Buttons */}
              <div className="flex flex-wrap gap-2">
                {statusUpdating ? (
                   <div className="flex items-center justify-center rounded-md bg-gray-100 px-4 py-2 dark:bg-gray-800">
                     <div className="h-4 w-4 animate-spin rounded-full border-2 border-dashed border-primary mr-2"></div>
                     <span className="text-sm font-medium">Updating...</span>
                   </div>
                 ) : (
                  <>
                    {vendor.status !== VendorStatus.APPROVED && (
                      <button
                        onClick={() => handleStatusChange(VendorStatus.APPROVED)}
                        className="flex items-center gap-1.5 rounded-md bg-green-600 px-3 py-1.5 text-xs font-medium text-white transition-colors hover:bg-green-700"
                        aria-label="Approve Vendor"
                      >
                        <CheckCircle size={14} />
                        <span>Approve</span>
                      </button>
                    )}
                    {vendor.status !== VendorStatus.REJECTED && vendor.status !== VendorStatus.SUSPENDED && (
                      <button
                        onClick={() => handleStatusChange(VendorStatus.REJECTED)}
                        className="flex items-center gap-1.5 rounded-md bg-red-600 px-3 py-1.5 text-xs font-medium text-white transition-colors hover:bg-red-700"
                         aria-label="Reject Vendor"
                      >
                        <XCircle size={14} />
                        <span>Reject</span>
                      </button>
                    )}
                     {vendor.status !== VendorStatus.SUSPENDED && vendor.status !== VendorStatus.REJECTED && vendor.status !== VendorStatus.PENDING && (
                      <button
                        onClick={() => handleStatusChange(VendorStatus.SUSPENDED)}
                        className="flex items-center gap-1.5 rounded-md border border-stroke bg-gray-100 px-3 py-1.5 text-xs font-medium text-black transition-colors hover:bg-gray-200 dark:border-strokedark dark:bg-boxdark-2 dark:text-white dark:hover:bg-gray-700"
                        aria-label="Suspend Vendor"
                      >
                        <AlertTriangle size={14} />
                        <span>Suspend</span>
                      </button>
                    )}
                     {vendor.status === VendorStatus.SUSPENDED && (
                      <button
                         onClick={() => handleStatusChange(VendorStatus.APPROVED)} // Or PENDING, depending on workflow
                         className="flex items-center gap-1.5 rounded-md border border-stroke bg-gray-100 px-3 py-1.5 text-xs font-medium text-black transition-colors hover:bg-gray-200 dark:border-strokedark dark:bg-boxdark-2 dark:text-white dark:hover:bg-gray-700"
                         aria-label="Reactivate Vendor"
                       >
                         <CheckCircle size={14} />
                         <span>Reactivate</span>
                       </button>
                     )}
                  </>
                )}
              </div>
            </div>

            {/* Contact & Business Details Grid */}
            <div className="mb-6 grid grid-cols-1 gap-6 md:grid-cols-2">
              <div className="rounded-md border border-stroke bg-gray-50 p-4 dark:border-strokedark dark:bg-boxdark-2">
                <h3 className="mb-4 text-lg font-medium text-black dark:text-white">Contact Information</h3>
                <div className="space-y-3">
                  <DetailItem icon={Users} label="Primary Contact" value={vendor.name} />
                  <DetailItem icon={Mail} label="Email" value={vendor.email ? <a href={`mailto:${vendor.email}`} className="hover:underline text-primary dark:text-primary-light">{vendor.email}</a> : undefined} />
                  <DetailItem icon={Phone} label="Phone" value={vendor.phone ? <a href={`tel:${vendor.phone}`} className="hover:underline">{vendor.phone}</a> : undefined} />
                  <DetailItem icon={MapPin} label="Address" value={vendor.businessAddress} />
                </div>
              </div>
              <div className="rounded-md border border-stroke bg-gray-50 p-4 dark:border-strokedark dark:bg-boxdark-2">
                <h3 className="mb-4 text-lg font-medium text-black dark:text-white">Business Details</h3>
                 <div className="space-y-3">
                  <DetailItem icon={Store} label="Business Type" value={vendor.businessType} />
                  <DetailItem icon={Package} label="Listed Products" value={products.length} />
                  <DetailItem icon={Clock} label="Registration Date" value={formatDate(vendor.createdAt)} />
                  {/* Add other relevant business details */}
                </div>
              </div>
            </div>

            {/* Business Description */}
            {vendor.description && (
              <div className="mb-6">
                <h3 className="mb-2 text-lg font-medium text-black dark:text-white">Business Description</h3>
                <div className="rounded-md border border-stroke bg-gray-50 p-4 dark:border-strokedark dark:bg-boxdark-2">
                  <p className="text-sm text-gray-800 dark:text-gray-200">{vendor.description}</p>
                </div>
              </div>
            )}

            {/* Vendor Products Table */}
            <div>
              <h3 className="mb-4 text-lg font-medium text-black dark:text-white">Vendor Products ({products.length})</h3>
              {products.length === 0 ? (
                <div className="flex flex-col items-center justify-center rounded-lg border-2 border-dashed border-stroke p-6 text-center dark:border-strokedark">
                  <Package className="mx-auto mb-3 h-12 w-12 text-gray-400 dark:text-gray-500" />
                  <p className="text-base font-medium text-gray-600 dark:text-gray-400">This vendor has no products listed yet.</p>
                  <Link
                    href={`/products/new?vendorId=${vendorId}`} // Pre-fill vendor ID if adding new product
                    className="mt-4 inline-flex items-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary-dark transition-colors"
                  >
                    Add Product for Vendor
                  </Link>
                </div>
              ) : (
                <div className="max-w-full overflow-x-auto">
                  <table className="w-full table-auto">
                    <thead className="bg-gray-2 dark:bg-meta-4">
                      <tr>
                        <th className="px-4 py-3 text-left text-sm font-medium text-black dark:text-white">Product</th>
                        <th className="px-4 py-3 text-left text-sm font-medium text-black dark:text-white">Price</th>
                        <th className="px-4 py-3 text-left text-sm font-medium text-black dark:text-white">Status</th>
                        <th className="px-4 py-3 text-right text-sm font-medium text-black dark:text-white">Actions</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-stroke dark:divide-strokedark">
                      {products.map((product) => (
                        <tr key={product.id} className="hover:bg-gray-50 dark:hover:bg-boxdark-2">
                          <td className="px-4 py-3">
                            <p className="font-medium text-black dark:text-white">{product.partName || product.name || 'N/A'}</p>
                            <p className="text-xs text-gray-500 dark:text-gray-400">
                              {product.brand || 'No Brand'} {product.partNumber && `· ${product.partNumber}`}
                            </p>
                          </td>
                           <td className="px-4 py-3 text-sm text-black dark:text-white">
                            {formatUGX(product.unitPrice || product.price || 0)}
                          </td>
                          <td className="px-4 py-3">
                            <Badge variant={
                                product.status === 'approved' ? 'success' :
                                product.status === 'rejected' ? 'danger' :
                                product.status === 'pending' ? 'warning' :
                                'secondary' // Default or other statuses
                             } className="text-xs">
                              {String(product.status).charAt(0).toUpperCase() + String(product.status).slice(1)}
                            </Badge>
                          </td>
                          <td className="px-4 py-3 text-right">
                            <Link
                              href={`/products/${product.id}`}
                              className="inline-flex items-center rounded-md bg-primary px-3 py-1 text-xs font-medium text-white transition-colors hover:bg-primary-dark"
                            >
                              <ExternalLink size={12} className="mr-1" />
                              View
                            </Link>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Sidebar: Verification & Stats */}
        <div className="lg:col-span-1">
          <div className="sticky top-20 space-y-6">
             {/* Verification Status */}
            <div className="rounded-lg border border-stroke bg-white p-6 shadow-default dark:border-strokedark dark:bg-boxdark">
              <h3 className="mb-4 text-lg font-medium text-black dark:text-white">Verification Status</h3>
              <div className="space-y-3">
                <VerificationItem label="Email Verified" isVerified={vendor.isEmailVerified} />
                <VerificationItem label="ID Verification" isVerified={vendor.isVerified} />
                <VerificationItem label="Business License" isVerified={vendor.hasBusinessLicense} />
                 {/* Add more verification items if needed */}
              </div>
            </div>

             {/* Statistics */}
             <div className="rounded-lg border border-stroke bg-white p-6 shadow-default dark:border-strokedark dark:bg-boxdark">
              <h3 className="mb-4 text-lg font-medium text-black dark:text-white">Statistics</h3>
              <div className="space-y-2">
                <StatisticItem label="Total Products" value={products.length} />
                <StatisticItem label="Approved Products" value={products.filter(p => p.status === 'approved').length} />
                <StatisticItem label="Orders Fulfilled" value={vendor.ordersFulfilled || 0} />
                <StatisticItem label="Total Sales" value={formatUGX(vendor.totalSales || 0)} />
                {/* Add more stats as needed */}
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
}
EOF_INNER

# Update next.config.js to handle static export properly
# File: next.config.js
cat > next.config.js << 'EOF_INNER'
/** @type {import('next').NextConfig} */

const nextConfig = {
  // Output mode: 'standalone' is generally recommended for deployment efficiency
  // If you strictly need static HTML export without a Node.js server, use 'export'.
  // However, 'export' has limitations (no API routes, middleware limitations).
  // 'standalone' builds a minimal Node.js server for your app.
  // Let's stick with standalone as it's more flexible and was in the original fix.
  output: 'standalone',

  reactStrictMode: true, // Recommended for development

  // Image optimization configuration (example - adjust as needed)
  images: {
    // domains: ['your-image-domain.com'], // Add domains for external images if using next/image
    remotePatterns: [
       // Add remote patterns if needed, e.g., for Firebase Storage
       // {
       //   protocol: 'https',
       //   hostname: 'firebasestorage.googleapis.com',
       //   port: '',
       //   pathname: '/v0/b/your-project-id.appspot.com/**',
       // },
     ],
  },

  // Experimental features - use with caution
  experimental: {
    // If experiencing issues with Firebase init during build on some platforms:
    // Adjusting concurrency might help, but defaults are usually fine.
    // cpus: 1, // Can limit concurrency - may slow down build
    // workerThreads: false, // Can limit concurrency - may slow down build

    // Enable scroll restoration (usually a good UX improvement)
    scrollRestoration: true,
  },

  // If using TypeScript
  typescript: {
    // Dangerously allow production builds even if your project has type errors.
    // It's highly recommended to fix type errors instead.
    // ignoreBuildErrors: false,
  },

  // Add any other configurations you need here
  // e.g., redirects, rewrites, headers, environment variables
};

module.exports = nextConfig;
EOF_INNER

echo -e "${GREEN}✓ Fixed build error${NC}"

# 2. Fix Loading & Data Fetching Issues
echo -e "${CYAN}[2/6]${NC} Fixing Page Loading & Data Fetching Issues..."

# Create LoadingScreen component
# File: src/components/LoadingScreen.tsx
cat > src/components/LoadingScreen.tsx << 'EOF_INNER'
import React from 'react';

const LoadingScreen = () => {
  return (
    <div className="flex min-h-screen w-full items-center justify-center bg-background dark:bg-boxdark-2">
      <div className="flex flex-col items-center">
        {/* Enhanced Spinner Animation */}
        <div className="relative h-24 w-24">
          <div className="absolute inset-0 rounded-full border-4 border-gray-200 dark:border-gray-700 opacity-50"></div>
          <div className="absolute inset-0 h-full w-full animate-spin rounded-full border-4 border-t-primary border-l-primary border-r-primary/50 border-b-primary/50 dark:border-t-primary-light dark:border-l-primary-light dark:border-r-primary-light/50 dark:border-b-primary-light/50"></div>
           {/* Optional Inner Element */}
           {/* <div className="absolute inset-2 rounded-full bg-primary/10 dark:bg-primary-light/10"></div> */}
        </div>
        <div className="mt-8 text-center">
          <h2 className="text-xl font-semibold text-gray-800 dark:text-white mb-2 animate-pulse">
            Loading SpareWo Admin...
          </h2>
          <p className="text-gray-500 dark:text-gray-400">
            Please wait while we prepare your dashboard.
          </p>
        </div>
      </div>
    </div>
  );
};

export default LoadingScreen;
EOF_INNER

# Create ErrorBoundary component
mkdir -p src/components/ErrorBoundary
# File: src/components/ErrorBoundary/index.tsx
cat > src/components/ErrorBoundary/index.tsx << 'EOF_INNER'
'use client';

import React, { Component, ErrorInfo, ReactNode } from 'react';
import Link from 'next/link';
import { AlertTriangle, RefreshCw, Home } from 'lucide-react';

interface Props {
  children: ReactNode;
  fallback?: ReactNode; // Optional custom fallback component
}

interface State {
  hasError: boolean;
  error: Error | null;
  errorInfo: ErrorInfo | null;
}

class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    // Define the initial state
    this.state = {
      hasError: false,
      error: null,
      errorInfo: null
    };
  }

  // Update state when an error is thrown by a child component
  static getDerivedStateFromError(error: Error): Partial<State> {
    // Update state so the next render shows the fallback UI.
    return { hasError: true, error };
  }

  // Catch errors after they have been thrown, log them
  componentDidCatch(error: Error, errorInfo: ErrorInfo): void {
    // You can log the error to an error reporting service here
    console.error("ErrorBoundary caught an error:", error, errorInfo);
    this.setState({ errorInfo }); // Store errorInfo if needed for display
  }

  // Method to reset the error boundary state, allowing children to re-render
  resetError = () => {
    this.setState({ hasError: false, error: null, errorInfo: null });
    // Optionally: Add logic here to attempt a recovery action if applicable
  }

  render(): ReactNode {
    if (this.state.hasError) {
      // Render the fallback UI if a custom fallback wasn't provided
      if (this.props.fallback) {
        return this.props.fallback;
      }

      // Default fallback UI
      return (
        <div className="flex flex-col items-center justify-center min-h-screen p-4 bg-gray-100 dark:bg-boxdark-2">
          <div className="w-full max-w-lg bg-white dark:bg-boxdark rounded-lg border border-stroke dark:border-strokedark shadow-lg p-6 text-center">
            <AlertTriangle className="mx-auto h-12 w-12 text-red-500 mb-4" />
            <h2 className="text-2xl font-bold text-red-600 dark:text-red-400 mb-3">Oops! Something went wrong.</h2>
            <p className="text-gray-700 dark:text-gray-300 mb-4">
              An unexpected error occurred. Please try again or contact support if the problem persists.
            </p>

            {/* Display error details in development mode or if needed */}
            {process.env.NODE_ENV === 'development' && this.state.error && (
              <div className="bg-gray-100 dark:bg-gray-900 p-3 rounded-md mb-4 text-left overflow-auto max-h-40 border border-stroke dark:border-strokedark">
                <p className="font-mono text-sm text-red-700 dark:text-red-300">
                  <strong>Error:</strong> {this.state.error?.message}
                </p>
                {/* Optionally display stack trace (can be verbose) */}
                {/* <details className="mt-2 text-xs text-gray-600 dark:text-gray-400">
                  <summary>Error Details</summary>
                  <pre className="whitespace-pre-wrap break-all">{this.state.error?.stack}</pre>
                  {this.state.errorInfo && <pre className="whitespace-pre-wrap break-all">{this.state.errorInfo.componentStack}</pre>}
                </details> */}
              </div>
            )}

            <div className="flex justify-center gap-4 mt-6">
              <button
                onClick={this.resetError}
                className="inline-flex items-center px-4 py-2 bg-primary text-white rounded-md hover:bg-primary-dark transition-colors focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2"
              >
                <RefreshCw className="mr-2 h-4 w-4" />
                Try again
              </button>
              <Link
                href="/"
                className="inline-flex items-center px-4 py-2 bg-gray-200 dark:bg-gray-700 text-gray-800 dark:text-gray-200 rounded-md hover:bg-gray-300 dark:hover:bg-gray-600 transition-colors focus:outline-none focus:ring-2 focus:ring-gray-400 focus:ring-offset-2"
              >
                 <Home className="mr-2 h-4 w-4" />
                Go to Dashboard
              </Link>
            </div>
          </div>
        </div>
      );
    }

    // Normally, just render children
    return this.props.children;
  }
}

export default ErrorBoundary;
EOF_INNER

# Update app/layout.tsx to include ErrorBoundary and Providers structure
# File: src/app/layout.tsx
cat > src/app/layout.tsx << 'EOF_INNER'
import type { Metadata } from 'next';
import { Inter } from 'next/font/google'; // Example font, adjust as needed
import '@/styles/globals.css'; // Ensure your global styles are imported
import { Providers } from './providers'; // Import your Providers component
import ErrorBoundary from '@/components/ErrorBoundary'; // Import the ErrorBoundary

// Setup Font (example using Inter)
const inter = Inter({ subsets: ['latin'] });

// Define Metadata for the application
export const metadata: Metadata = {
  title: {
    default: 'SpareWo Admin Dashboard',
    template: '%s | SpareWo Admin', // Example template for page titles
  },
  description: 'Administrative dashboard for managing the SpareWo platform, including products, vendors, orders, and users.',
  keywords: ['SpareWo', 'Admin', 'Dashboard', 'Auto Parts', 'Management'],
  // Add other relevant metadata like icons, open graph tags etc.
  // icons: {
  //   icon: '/favicon.ico',
  //   apple: '/apple-touch-icon.png',
  // },
};

// Define the Root Layout component
export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      {/* Apply font class to body */}
      <body className={`${inter.className} min-h-screen bg-gray-100 font-sans text-gray-900 antialiased dark:bg-boxdark dark:text-bodydark`}>
        {/* Wrap everything in Providers (Theme, Auth, Toast, etc.) */}
        <Providers>
          {/* Wrap the main content in an Error Boundary */}
          <ErrorBoundary>
            {children}
          </ErrorBoundary>
        </Providers>
      </body>
    </html>
  );
}
EOF_INNER

echo -e "${GREEN}✓ Fixed Page Loading & Error Handling${NC}"

# 3. Fix Component Rendering Problems
echo -e "${CYAN}[3/6]${NC} Fixing Component Rendering Problems..."

# Update Card component (using shadcn/ui conventions)
# File: src/components/ui/card.tsx
cat > src/components/ui/card.tsx << 'EOF_INNER'
import * as React from "react"
import { cn } from "@/lib/utils" // Assuming you have a utility for class names

// Main Card component
const Card = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn(
      "rounded-lg border border-stroke bg-white text-black shadow-default", // Base styles
      "dark:border-strokedark dark:bg-boxdark dark:text-white", // Dark mode styles
      className // Allow overriding styles
    )}
    {...props}
  />
))
Card.displayName = "Card"

// Card Header component
const CardHeader = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn(
      "flex flex-col space-y-1.5 p-4 md:p-6", // Padding and spacing
      "border-b border-stroke dark:border-strokedark", // Optional bottom border
       className
      )}
    {...props}
  />
))
CardHeader.displayName = "CardHeader"

// Card Title component
const CardTitle = React.forwardRef<
  HTMLParagraphElement, // Changed to h3 or appropriate heading level semantic
  React.HTMLAttributes<HTMLHeadingElement>
>(({ className, children, ...props }, ref) => (
  <h3 // Use h3 for semantic structure (or adjust as needed)
    ref={ref}
    className={cn(
      "text-lg md:text-xl font-semibold leading-none tracking-tight text-black dark:text-white", // Text styles
      className
    )}
    {...props}
  >
    {children}
  </h3>
))
CardTitle.displayName = "CardTitle"

// Card Description component
const CardDescription = React.forwardRef<
  HTMLParagraphElement,
  React.HTMLAttributes<HTMLParagraphElement>
>(({ className, ...props }, ref) => (
  <p
    ref={ref}
    className={cn(
      "text-sm text-gray-600 dark:text-gray-400", // Text styles for description
      className
    )}
    {...props}
  />
))
CardDescription.displayName = "CardDescription"

// Card Content component
const CardContent = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn(
      "p-4 md:p-6 pt-0", // Padding, removing top padding as Header/Title usually handle it
      className
    )}
    {...props}
  />
))
CardContent.displayName = "CardContent"

// Card Footer component
const CardFooter = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn(
      "flex items-center p-4 md:p-6 pt-0", // Padding, removing top padding
      "border-t border-stroke dark:border-strokedark", // Optional top border
      className
    )}
    {...props}
  />
))
CardFooter.displayName = "CardFooter"

export { Card, CardHeader, CardFooter, CardTitle, CardDescription, CardContent }
EOF_INNER

# Update StatCard component
# File: src/components/ui/stat-card.tsx
cat > src/components/ui/stat-card.tsx << 'EOF_INNER'
import React, { ReactNode } from "react";
import { cn } from "@/lib/utils"; // Assuming you have a utility for class names
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"; // Use your Card components

// Define the props for the StatCard
interface StatCardProps {
  title: string;
  value: string | number;
  icon: ReactNode; // Expecting a Lucide icon component or similar
  description?: string | ReactNode; // Optional description or secondary info
  trend?: { // Optional trend indicator
    value: string; // e.g., "+5.2%" or "-10"
    isPositive: boolean;
  };
  iconColor?: string; // e.g., "text-primary", "text-green-500"
  iconBgColor?: string; // e.g., "bg-primary/10", "bg-green-100"
  className?: string; // Allow custom styling
  children?: ReactNode; // Allow adding extra content like charts
}

// StatCard Component
export function StatCard({
  title,
  value,
  icon,
  description,
  trend,
  iconColor = "text-primary", // Default icon color
  iconBgColor = "bg-primary/10", // Default icon background
  className,
  children,
  ...props // Pass remaining props to the root Card element
}: StatCardProps) {
  return (
    <Card className={cn("overflow-hidden", className)} {...props}>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2 border-none"> {/* Adjust header styling */}
        <CardTitle className="text-sm font-medium text-gray-600 dark:text-gray-400">{title}</CardTitle>
        <div className={cn(
          "flex h-8 w-8 items-center justify-center rounded-full",
           iconBgColor, // Dynamic background color
           iconColor // Dynamic icon color
           )}>
           {icon} {/* Render the icon */}
        </div>
      </CardHeader>
      <CardContent className="pt-0"> {/* Adjust content padding */}
        <div className="text-2xl md:text-3xl font-bold text-black dark:text-white">{value}</div>
        <div className="mt-1 flex items-center justify-between text-xs text-gray-500 dark:text-gray-400">
           {description && <span>{description}</span>}
           {trend && (
            <div
              className={cn(
                "ml-auto inline-flex items-center rounded-full px-2 py-0.5 text-xs font-semibold",
                trend.isPositive
                  ? "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400"
                  : "bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400"
              )}
            >
              {trend.isPositive ? "+" : ""}{trend.value}
            </div>
          )}
        </div>
        {/* Render additional children if provided (e.g., small charts) */}
        {children && <div className="mt-4">{children}</div>}
      </CardContent>
      {/* Optional bottom highlight bar based on trend */}
      {/* <div className={cn("h-1 w-full",
          trend ? (trend.isPositive ? "bg-green-500" : "bg-red-500") : "bg-primary" // Simple color bar
      )} /> */}
    </Card>
  );
}
EOF_INNER

# Update Badge component (using shadcn/ui conventions and more variants)
# File: src/components/ui/badge.tsx
cat > src/components/ui/badge.tsx << 'EOF_INNER'
import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils"; // Assuming you have a utility for class names

// Define badge variants using class-variance-authority
const badgeVariants = cva(
  // Base styles for all badges
  "inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2",
  {
    variants: {
      // Define different visual styles (variants)
      variant: {
        default:
          "border-transparent bg-primary text-primary-foreground hover:bg-primary/80 dark:bg-primary dark:text-white dark:hover:bg-primary/90", // Primary/Default style
        secondary:
          "border-transparent bg-secondary text-secondary-foreground hover:bg-secondary/80 dark:bg-gray-700 dark:text-gray-200 dark:hover:bg-gray-600", // Secondary style
        destructive:
          "border-transparent bg-red-600 text-white hover:bg-red-600/80 dark:bg-red-700 dark:hover:bg-red-700/90", // Destructive/Error style
        outline:
          "border-stroke text-foreground dark:border-strokedark dark:text-white", // Outline style
        // Semantic status variants
        success:
          "border-transparent bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400", // Success status
        warning:
          "border-transparent bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400", // Warning status
        danger: // Alias for destructive, or slightly different style
           "border-transparent bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400",
        info:
          "border-transparent bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400", // Info status
        pending: // Custom status example
           "border-transparent bg-orange-100 text-orange-800 dark:bg-orange-900/30 dark:text-orange-400",
      },
    },
    // Default variant if none is specified
    defaultVariants: {
      variant: "default",
    },
  }
);

// Define the props interface, extending HTML attributes and variant props
export interface BadgeProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof badgeVariants> {}

// Badge Component Implementation
function Badge({ className, variant, ...props }: BadgeProps) {
  // Render a div with the computed classes
  return (
    <div className={cn(badgeVariants({ variant }), className)} {...props} />
  );
}

export { Badge, badgeVariants }; // Export the component and variants
EOF_INNER

echo -e "${GREEN}✓ Fixed Component Rendering Issues${NC}"

# 4. Fix Navigation & Routing
echo -e "${CYAN}[4/6]${NC} Fixing Navigation & Routing Issues..."

# Update Sidebar context (Improved state management for mobile/desktop)
# File: src/components/Layouts/sidebar/sidebar-context.tsx
cat > src/components/Layouts/sidebar/sidebar-context.tsx << 'EOF_INNER'
'use client';
import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';

// Define the shape of the context data
interface SidebarContextProps {
  sidebarOpen: boolean; // Is the sidebar visible (mainly for mobile overlay)
  isCollapsed: boolean; // Is the sidebar collapsed (for desktop view)
  toggleSidebar: () => void; // Toggles visibility (mobile)
  toggleCollapse: () => void; // Toggles collapsed state (desktop)
  closeSidebar: () => void; // Closes sidebar (mobile)
  isMobile: boolean; // Flag indicating if the view is considered mobile
}

// Create the context with default values
const SidebarContext = createContext<SidebarContextProps>({
  sidebarOpen: false,
  isCollapsed: false,
  toggleSidebar: () => console.warn('SidebarContext: toggleSidebar called outside of Provider'),
  toggleCollapse: () => console.warn('SidebarContext: toggleCollapse called outside of Provider'),
  closeSidebar: () => console.warn('SidebarContext: closeSidebar called outside of Provider'),
  isMobile: false,
});

// Define the provider component
export const SidebarProvider = ({ children }: { children: React.ReactNode }) => {
  const [sidebarOpen, setSidebarOpen] = useState(false); // Mobile overlay visibility
  const [isCollapsed, setIsCollapsed] = useState(false); // Desktop collapsed state
  const [isMobile, setIsMobile] = useState(false); // Is the current view mobile?

  // Check window size and set mobile/desktop states accordingly
  const checkDeviceSize = useCallback(() => {
    const mobileBreakpoint = 1024; // Tailwind's 'lg' breakpoint
    const currentIsMobile = window.innerWidth < mobileBreakpoint;
    setIsMobile(currentIsMobile);

    if (currentIsMobile) {
      // On mobile: Force close sidebar overlay, collapsed state is irrelevant
      setSidebarOpen(false);
      // setIsCollapsed(false); // Collapse state doesn't apply visually on mobile overlay
    } else {
      // On desktop: Close mobile overlay, restore collapsed state from localStorage
      setSidebarOpen(false); // Ensure mobile overlay is closed
      const storedCollapseState = localStorage.getItem('sidebarCollapsed') === 'true';
      setIsCollapsed(storedCollapseState);
    }
  }, []); // No dependencies needed as it reads directly from window/localStorage

  // Effect to run on mount and window resize
  useEffect(() => {
    // Initial check
    checkDeviceSize();

    // Add resize listener
    window.addEventListener('resize', checkDeviceSize);

    // Cleanup listener on unmount
    return () => window.removeEventListener('resize', checkDeviceSize);
  }, [checkDeviceSize]); // Depend on the memoized checkDeviceSize function

  // Toggle sidebar visibility (primarily for mobile)
  const toggleSidebar = useCallback(() => {
    setSidebarOpen(prev => !prev);
  }, []);

  // Toggle collapsed state (primarily for desktop) and persist to localStorage
  const toggleCollapse = useCallback(() => {
    setIsCollapsed(prev => {
      const newState = !prev;
      localStorage.setItem('sidebarCollapsed', String(newState));
      return newState;
    });
  }, []);

  // Close sidebar (e.g., after navigation on mobile)
  const closeSidebar = useCallback(() => {
    if (isMobile) { // Only close if in mobile view
        setSidebarOpen(false);
    }
  }, [isMobile]);

  // Provide the context value to children
  const value = {
    sidebarOpen,
    isCollapsed,
    toggleSidebar,
    toggleCollapse,
    closeSidebar,
    isMobile,
  };

  return (
    <SidebarContext.Provider value={value}>
      {children}
    </SidebarContext.Provider>
  );
};

// Custom hook to easily consume the sidebar context
export const useSidebarContext = () => {
  const context = useContext(SidebarContext);
  if (context === undefined) {
    throw new Error('useSidebarContext must be used within a SidebarProvider');
  }
  return context;
};
EOF_INNER

# Update MenuItem component (Improved handling of collapsed state and active styles)
# File: src/components/Layouts/sidebar/menu-item.tsx
cat > src/components/Layouts/sidebar/menu-item.tsx << 'EOF_INNER'
'use client';
import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation'; // Use usePathname for client components
import { cn } from "@/lib/utils"; // Class name utility
import { useSidebarContext } from './sidebar-context'; // Import context hook

// Define the structure for a menu item
interface MenuItemData {
  title: string;
  path?: string; // Path for the link
  icon: React.ReactNode; // Icon component
  badge?: string | number; // Optional badge content
  // children?: MenuItemData[]; // Potential for nested menus (not implemented in this version)
}

// Define the props for the MenuItem component
interface MenuItemProps {
  item: MenuItemData;
  // isCollapsed and pathname are now retrieved from context/hook
}

const MenuItem: React.FC<MenuItemProps> = ({ item }) => {
  const pathname = usePathname(); // Get current path
  const { isCollapsed, closeSidebar, isMobile } = useSidebarContext(); // Get state from context

  // Determine if the item is active
  // Checks for exact match or if the current path starts with the item's path (for nested routes)
  const itemPath = item.path || '#'; // Use '#' as fallback if path is missing
  const isActive = itemPath !== '#' && (pathname === itemPath || pathname.startsWith(`${itemPath}/`));

  // Handle click: close mobile sidebar if needed
  const handleClick = () => {
    if (isMobile) {
      closeSidebar();
    }
  };

  return (
    <li className="relative"> {/* Wrap in li for semantic list structure */}
      <Link
        href={itemPath}
        onClick={handleClick}
        className={cn(
          "group relative flex items-center gap-2.5 rounded-md px-4 py-2.5 font-medium duration-300 ease-in-out",
          // Common hover/focus styles
          "hover:bg-gray-100 dark:hover:bg-meta-4 focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-1 dark:focus:ring-offset-boxdark",
          // Active state styles
          isActive
            ? "bg-primary text-white dark:bg-meta-4"
            : "text-bodydark1 dark:text-bodydark", // Default text colors
          // Text color on hover when not active
          !isActive && "hover:text-primary dark:hover:text-white"
        )}
        // Tooltip for collapsed state
        title={isCollapsed ? item.title : ''}
      >
        {/* Icon */}
        <span className={cn(
            "text-lg", // Icon size
             isActive ? 'text-white' : 'text-bodydark1 dark:text-bodydark' // Icon color based on active state
             // Group hover color changes handled by parent className
          )}>
          {item.icon}
        </span>

        {/* Title (conditionally rendered based on collapse state) */}
        <span
          className={cn(
            "whitespace-nowrap transition-opacity duration-200",
             isCollapsed ? "lg:opacity-0 lg:invisible lg:w-0" : "opacity-100 visible w-auto" // Hide text smoothly on desktop when collapsed
          )}
        >
          {item.title}
        </span>

        {/* Badge (conditionally rendered) */}
        {item.badge && !isCollapsed && (
          <span
            className={cn(
              "absolute right-4 top-1/2 -translate-y-1/2 flex h-5 min-w-[20px] items-center justify-center rounded-full px-1.5 text-xs font-medium",
               isActive
                 ? "bg-white bg-opacity-20 text-white" // Badge style when active
                 : "bg-primary bg-opacity-10 text-primary dark:bg-primary/20 dark:text-primary-light" // Badge style when inactive
            )}
          >
            {item.badge}
          </span>
        )}

        {/* Small dot indicator for badges when collapsed (desktop only) */}
        {item.badge && isCollapsed && (
          <span className="absolute right-3 top-1/2 -translate-y-1/2 h-2 w-2 rounded-full bg-primary lg:inline-block hidden"></span>
        )}
      </Link>
    </li>
  );
};

export default MenuItem;
EOF_INNER

# Update middleware.ts (Refined logic for redirects)
# File: src/middleware.ts
cat > src/middleware.ts << 'EOF'
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

// Define public paths that do not require authentication
// Use a Set for efficient lookup
const PUBLIC_PATHS = new Set([
  '/auth/sign-in',
  '/auth/sign-up',
  '/auth/forgot-password',
  // Add other public paths like '/about', '/contact' if needed
]);

// Define paths related to authentication
const AUTH_PATHS = new Set([
  '/auth/sign-in',
  '/auth/sign-up',
  '/auth/forgot-password',
]);

// Define the root path (usually the dashboard)
const ROOT_PATH = '/';
const SIGN_IN_PATH = '/auth/sign-in';

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const authToken = request.cookies.get('auth_token')?.value; // Get token value

  const isPublicPath = PUBLIC_PATHS.has(pathname);
  const isAuthPath = AUTH_PATHS.has(pathname);

  // Case 1: User is authenticated
  if (authToken) {
    // If trying to access an authentication page (like sign-in) while logged in,
    // redirect to the dashboard (root path).
    if (isAuthPath) {
      const url = request.nextUrl.clone();
      url.pathname = ROOT_PATH;
      return NextResponse.redirect(url);
    }
    // Otherwise, allow access to the requested page (could be dashboard or other protected route)
    return NextResponse.next();
  }

  // Case 2: User is not authenticated
  if (!authToken) {
    // If trying to access a protected route (not public), redirect to sign-in.
    if (!isPublicPath) {
      const url = request.nextUrl.clone();
      url.pathname = SIGN_IN_PATH;
      // Optionally, add the intended destination as a query parameter for redirect after login
      url.searchParams.set('redirectedFrom', pathname);
      return NextResponse.redirect(url);
    }
    // Otherwise, allow access to the requested public page.
    return NextResponse.next();
  }

  // Default case (should ideally not be reached with the logic above)
  return NextResponse.next();
}

// Configure the matcher to apply the middleware
export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - api (API routes)
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - Any paths with a file extension (e.g., .png, .jpg)
     *
     * This ensures the middleware runs on page navigations but not static assets.
     */
    '/((?!api|_next/static|_next/image|favicon.ico|.*\\.\\w+).*)',
  ],
};
EOF_INNER

echo -e "${GREEN}✓ Fixed Navigation & Routing Issues${NC}"

# 5. Product Management Improvements
echo -e "${CYAN}[5/6]${NC} Implementing Product Management Improvements..."

# Create improved pending products page with better UI/UX
mkdir -p src/app/products/pending
# File: src/app/products/pending/page.tsx
cat > src/app/products/pending/page.tsx << 'EOF_INNER'
'use client';

import React, { useEffect, useState, useMemo, useCallback } from 'react';
import Link from 'next/link';
import { productService, Product, ProductStatus } from '@/services/firebase.service';
import { CheckCircle, XCircle, Eye, AlertTriangle, Clock, Package, Filter, Search, Grid3X3, List, ChevronRight, Info, Trash2 } from 'lucide-react';
import { Badge } from '@/components/ui/badge';
import LoadingScreen from '@/components/LoadingScreen';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button'; // Assuming you have a Button component
import { Checkbox } from '@/components/ui/checkbox'; // Assuming you have a Checkbox component
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"; // Assuming Select component
import { Input } from "@/components/ui/input"; // Assuming Input component
import { useToast } from '@/components/ui/toast-provider'; // Import useToast hook

// Define filter options structure
interface FilterOptions {
  vendorId: string; // 'all' or specific vendor ID
  category: string; // 'all' or specific category
  searchTerm: string;
}

// Define structure for Vendor and Category options used in filters
interface SelectOption {
  value: string;
  label: string;
}

export default function PendingProductsPage() {
  const [allProducts, setAllProducts] = useState<Product[]>([]); // Store all fetched pending products
  const [loading, setLoading] = useState(true);
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('list'); // Default to list view
  const [filters, setFilters] = useState<FilterOptions>({
    vendorId: 'all',
    category: 'all',
    searchTerm: ''
  });
  const [statusUpdating, setStatusUpdating] = useState<string | null>(null); // Track which product ID is updating
  const [selectedProduct, setSelectedProduct] = useState<Product | null>(null); // Product displayed in detail view
  const [selectedProducts, setSelectedProducts] = useState<string[]>([]); // IDs of selected products for bulk actions
  const [vendors, setVendors] = useState<SelectOption[]>([]); // Options for vendor filter
  const [categories, setCategories] = useState<SelectOption[]>([]); // Options for category filter
  const [isDetailPanelOpen, setIsDetailPanelOpen] = useState(false); // Control detail panel visibility

  const { addToast } = useToast(); // Initialize toast notifications

  // Fetch pending products and populate filter options
  useEffect(() => {
    setLoading(true);
    const unsubscribe = productService.listenToProducts(
      (productsList) => {
        const pending = productsList.filter(p => p.status === ProductStatus.PENDING) as Product[];
        setAllProducts(pending);

        // Extract unique vendors and categories for filters
        const uniqueVendors = new Map<string, string>();
        const uniqueCategories = new Set<string>();

        pending.forEach((product) => {
          if (product.vendorId && product.vendorName && !uniqueVendors.has(product.vendorId)) {
            uniqueVendors.set(product.vendorId, product.vendorName);
          }
          if (product.category) {
            uniqueCategories.add(product.category);
          }
        });

        setVendors([{ value: 'all', label: 'All Vendors' }, ...Array.from(uniqueVendors.entries()).map(([id, name]) => ({ value: id, label: name }))]);
        setCategories([{ value: 'all', label: 'All Categories' }, ...Array.from(uniqueCategories).map(cat => ({ value: cat, label: cat }))]);

        setLoading(false);
      },
      (error) => {
        console.error('Error fetching pending products:', error);
        addToast('Failed to load pending products.', 'error');
        setLoading(false);
      }
    );

    // Cleanup listener on unmount
    return () => unsubscribe();
  }, [addToast]); // Add addToast to dependency array if its identity can change


  // Memoized filtered products based on current filters and search term
  const filteredProducts = useMemo(() => {
    return allProducts.filter(product => {
      const vendorMatch = filters.vendorId === 'all' || product.vendorId === filters.vendorId;
      const categoryMatch = filters.category === 'all' || product.category === filters.category;
      const searchMatch = !filters.searchTerm ||
        (product.name?.toLowerCase().includes(filters.searchTerm.toLowerCase())) ||
        (product.partName?.toLowerCase().includes(filters.searchTerm.toLowerCase())) ||
        (product.brand?.toLowerCase().includes(filters.searchTerm.toLowerCase())) ||
        (product.partNumber?.toLowerCase().includes(filters.searchTerm.toLowerCase()));

      return vendorMatch && categoryMatch && searchMatch;
    });
  }, [allProducts, filters]);

  // Handle filter changes
  const handleFilterChange = useCallback((key: keyof FilterOptions, value: string) => {
    setFilters(prev => ({ ...prev, [key]: value }));
  }, []);

  // Toggle selection of a single product
  const toggleProductSelection = useCallback((id: string) => {
    setSelectedProducts(prev =>
      prev.includes(id) ? prev.filter(productId => productId !== id) : [...prev, id]
    );
  }, []);

  // Toggle selection of all visible filtered products
  const toggleSelectAll = useCallback(() => {
    if (selectedProducts.length === filteredProducts.length) {
      setSelectedProducts([]); // Deselect all
    } else {
      setSelectedProducts(filteredProducts.map(p => p.id)); // Select all filtered
    }
  }, [filteredProducts, selectedProducts.length]);


  // Handle single product status update
  const handleStatusChange = useCallback(async (id: string, newStatus: ProductStatus) => {
    setStatusUpdating(id); // Indicate this product is being updated
    try {
      await productService.updateProductStatus(id, newStatus);
      // No need to manually update state here, Firestore listener will do it.
      addToast(`Product ${id} status updated to ${newStatus}.`, 'success');
       // If the updated product was selected for detail view, clear it
       if (selectedProduct?.id === id) {
         setSelectedProduct(null);
         setIsDetailPanelOpen(false);
       }
       // Remove from selected products list
       setSelectedProducts(prev => prev.filter(pid => pid !== id));
    } catch (error) {
      console.error('Error updating product status:', error);
      addToast(`Failed to update status for product ${id}.`, 'error');
    } finally {
      setStatusUpdating(null); // Clear updating state for this product
    }
  }, [addToast, selectedProduct?.id]);


  // Handle bulk status update action
  const handleBulkAction = useCallback(async (action: 'approve' | 'reject') => {
    if (selectedProducts.length === 0) {
       addToast('No products selected for bulk action.', 'warning');
       return;
     }

    setStatusUpdating('bulk'); // Indicate bulk action is in progress
    const newStatus = action === 'approve' ? ProductStatus.APPROVED : ProductStatus.REJECTED;
    let successCount = 0;
    let errorCount = 0;

    // Process actions sequentially or in batches to avoid overwhelming resources
    for (const id of selectedProducts) {
      try {
        await productService.updateProductStatus(id, newStatus);
        successCount++;
      } catch (error) {
        console.error(`Error updating product ${id} during bulk action:`, error);
        errorCount++;
      }
    }

    addToast(
        `Bulk ${action} finished: ${successCount} succeeded, ${errorCount} failed.`,
        errorCount > 0 ? 'warning' : 'success'
    );

    setSelectedProducts([]); // Clear selection after action
    setStatusUpdating(null); // Clear bulk updating state
     // Close detail panel if the selected product was part of the bulk action
     if (selectedProduct && selectedProducts.includes(selectedProduct.id)) {
       setSelectedProduct(null);
       setIsDetailPanelOpen(false);
     }

  }, [selectedProducts, addToast, selectedProduct]);

  // Select a product for detailed view
  const viewProductDetails = (product: Product) => {
      setSelectedProduct(product);
      setIsDetailPanelOpen(true); // Open the detail panel
  };

  // Format UGX currency
  const formatUGX = (amount: number = 0) => {
    return new Intl.NumberFormat('en-UG', {
      style: 'currency',
      currency: 'UGX',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(amount);
  };

  // Format date
  const formatDate = (timestamp: any): string => {
     if (!timestamp) return 'N/A';
     try {
       const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
       if (isNaN(date.getTime())) return 'Invalid Date';
       // More detailed format
       return date.toLocaleString('en-US', {
         year: 'numeric', month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit'
       });
     } catch (e) {
       return 'Invalid Date';
     }
   };


  if (loading && allProducts.length === 0) { // Show loading screen only on initial load
    return <LoadingScreen />;
  }

  // --- Render UI ---
  return (
    <div className="flex h-[calc(100vh-some-header-height)]"> {/* Adjust height based on your layout */}
      {/* Main Content Area */}
      <div className={`flex-1 transition-all duration-300 ease-in-out ${isDetailPanelOpen ? 'lg:mr-[400px]' : ''}`}> {/* Adjust margin based on panel width */}
        <div className="p-4 md:p-6 space-y-6 h-full overflow-y-auto">
            {/* Page Header */}
            <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-gray-800 dark:text-white">Pending Products Review</h1>
                    <p className="text-sm text-gray-500 dark:text-gray-400">Approve or reject products submitted by vendors.</p>
                </div>
                <Badge variant="warning" className="flex items-center gap-1 py-1 px-2.5 text-sm self-start sm:self-center">
                    <Clock size={14} />
                    <span>{allProducts.length} pending</span> {/* Show total pending count */}
                </Badge>
            </div>

            {/* Filters & Actions Bar */}
            <Card>
              <CardContent className="p-4">
                <div className="flex flex-wrap items-center gap-3">
                  {/* Bulk Actions Dropdown or Buttons */}
                  {selectedProducts.length > 0 && (
                    <div className="flex gap-2">
                      <Button
                        variant="default"
                        size="sm"
                        className="bg-green-600 hover:bg-green-700"
                        onClick={() => handleBulkAction('approve')}
                        disabled={statusUpdating === 'bulk'}
                      >
                        <CheckCircle size={16} className="mr-1" /> Approve ({selectedProducts.length})
                      </Button>
                      <Button
                        variant="destructive"
                        size="sm"
                        onClick={() => handleBulkAction('reject')}
                        disabled={statusUpdating === 'bulk'}
                      >
                        <XCircle size={16} className="mr-1" /> Reject ({selectedProducts.length})
                      </Button>
                      <Badge variant="info" className="text-xs h-8 flex items-center">{selectedProducts.length} selected</Badge>
                    </div>
                  )}

                  {/* Search Input */}
                   <div className="relative flex-1 min-w-[200px]">
                     <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
                     <Input
                       type="text"
                       placeholder="Search by name, brand, part no..."
                       value={filters.searchTerm}
                       onChange={(e) => handleFilterChange('searchTerm', e.target.value)}
                       className="pl-9"
                     />
                   </div>

                  {/* Vendor Filter */}
                  <Select value={filters.vendorId} onValueChange={(value) => handleFilterChange('vendorId', value)}>
                    <SelectTrigger className="w-full sm:w-[180px]">
                      <SelectValue placeholder="Filter by Vendor" />
                    </SelectTrigger>
                    <SelectContent>
                      {vendors.map(vendor => (
                        <SelectItem key={vendor.value} value={vendor.value}>{vendor.label}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>

                  {/* Category Filter */}
                   <Select value={filters.category} onValueChange={(value) => handleFilterChange('category', value)}>
                    <SelectTrigger className="w-full sm:w-[180px]">
                       <SelectValue placeholder="Filter by Category" />
                     </SelectTrigger>
                     <SelectContent>
                       {categories.map(cat => (
                         <SelectItem key={cat.value} value={cat.value}>{cat.label}</SelectItem>
                       ))}
                     </SelectContent>
                   </Select>

                  {/* View Mode Toggle */}
                  <div className="flex rounded-md border border-stroke dark:border-strokedark overflow-hidden ml-auto">
                    <Button
                      variant={viewMode === 'list' ? 'default' : 'outline'}
                      size="icon"
                      onClick={() => setViewMode('list')}
                      className={`rounded-none border-none ${viewMode === 'list' ? 'bg-primary text-white' : ''}`}
                      aria-label="List view"
                    >
                      <List size={18} />
                    </Button>
                    <Button
                       variant={viewMode === 'grid' ? 'default' : 'outline'}
                       size="icon"
                       onClick={() => setViewMode('grid')}
                       className={`rounded-none border-none ${viewMode === 'grid' ? 'bg-primary text-white' : ''}`}
                       aria-label="Grid view"
                     >
                      <Grid3X3 size={18} />
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>

             {/* Products Display Area */}
             {filteredProducts.length === 0 ? (
                <Card className="flex flex-col items-center justify-center py-16 text-center">
                    <CardHeader>
                        <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-blue-100 text-primary dark:bg-blue-900/30 dark:text-blue-400">
                            <Info size={28} />
                        </div>
                    </CardHeader>
                    <CardContent>
                        <h3 className="mb-2 text-xl font-semibold text-gray-800 dark:text-white">No Pending Products Found</h3>
                        <p className="max-w-md text-gray-500 dark:text-gray-400">
                            {allProducts.length === 0
                                ? "There are currently no products awaiting review."
                                : "No products match your current filter or search criteria. Try adjusting the filters."}
                        </p>
                        {(filters.searchTerm || filters.vendorId !== 'all' || filters.category !== 'all') && (
                            <Button variant="link" onClick={() => setFilters({ vendorId: 'all', category: 'all', searchTerm: '' })} className="mt-4">
                                Clear Filters
                            </Button>
                        )}
                    </CardContent>
                </Card>
             ) : (
               // Conditional rendering for List or Grid view
               viewMode === 'list' ? (
                 // List View Implementation
                  <Card>
                    <div className="overflow-x-auto">
                      <table className="w-full table-auto">
                        <thead>
                          <tr className="bg-gray-2 dark:bg-meta-4 text-left text-xs font-medium uppercase text-gray-500 dark:text-gray-400">
                            <th className="px-4 py-3">
                              <Checkbox
                                checked={selectedProducts.length === filteredProducts.length && filteredProducts.length > 0}
                                onCheckedChange={toggleSelectAll}
                                aria-label="Select all products"
                              />
                            </th>
                            <th className="px-4 py-3">Product</th>
                            <th className="px-4 py-3">Vendor</th>
                            <th className="px-4 py-3">Price</th>
                            <th className="px-4 py-3">Submitted</th>
                            <th className="px-4 py-3 text-center">Actions</th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-stroke dark:divide-strokedark">
                          {filteredProducts.map(product => (
                            <tr
                              key={product.id}
                              className={`hover:bg-gray-100 dark:hover:bg-boxdark-2 ${selectedProduct?.id === product.id ? 'bg-primary/10 dark:bg-primary/20' : ''}`}
                            >
                              <td className="px-4 py-2">
                                <Checkbox
                                  checked={selectedProducts.includes(product.id)}
                                  onCheckedChange={() => toggleProductSelection(product.id)}
                                  aria-labelledby={`product-name-${product.id}`}
                                />
                              </td>
                              <td className="px-4 py-2" onClick={() => viewProductDetails(product)} style={{ cursor: 'pointer' }}>
                                <div className="flex items-center gap-3">
                                  <div className="flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-md bg-primary/10 text-primary">
                                    {/* Placeholder for image or icon */}
                                    <Package size={20} />
                                  </div>
                                  <div>
                                    <p id={`product-name-${product.id}`} className="font-medium text-black dark:text-white truncate max-w-xs">
                                       {product.partName || product.name || 'Unnamed Product'}
                                    </p>
                                    <p className="text-xs text-gray-500 dark:text-gray-400">
                                       {product.brand} {product.partNumber && `• ${product.partNumber}`}
                                    </p>
                                  </div>
                                </div>
                              </td>
                              <td className="px-4 py-2 text-sm text-black dark:text-white">
                                <Link href={`/vendors/${product.vendorId}`} className="hover:underline" onClick={(e) => e.stopPropagation()}>
                                    {product.vendorName || 'Unknown'}
                                </Link>
                              </td>
                              <td className="px-4 py-2 text-sm text-black dark:text-white">
                                {formatUGX(product.unitPrice || product.price || 0)}
                              </td>
                              <td className="px-4 py-2 text-xs text-gray-500 dark:text-gray-400">
                                {formatDate(product.createdAt)}
                              </td>
                              <td className="px-4 py-2">
                                <div className="flex items-center justify-center space-x-1">
                                  {statusUpdating === product.id ? (
                                    <div className="h-5 w-5 animate-spin rounded-full border-2 border-primary border-t-transparent"></div>
                                  ) : (
                                    <>
                                      <Button
                                        variant="ghost" size="icon" className="text-green-600 hover:bg-green-100 hover:text-green-700 h-7 w-7"
                                        onClick={(e) => { e.stopPropagation(); handleStatusChange(product.id, ProductStatus.APPROVED); }}
                                        title="Approve"
                                      > <CheckCircle size={16} /> </Button>
                                       <Button
                                        variant="ghost" size="icon" className="text-red-600 hover:bg-red-100 hover:text-red-700 h-7 w-7"
                                        onClick={(e) => { e.stopPropagation(); handleStatusChange(product.id, ProductStatus.REJECTED); }}
                                        title="Reject"
                                      > <XCircle size={16} /> </Button>
                                       <Button
                                        variant="ghost" size="icon" className="text-blue-600 hover:bg-blue-100 hover:text-blue-700 h-7 w-7"
                                        onClick={(e) => { e.stopPropagation(); viewProductDetails(product); }}
                                        title="View Details"
                                      > <Eye size={16} /> </Button>
                                       <Link href={`/products/${product.id}/edit`} onClick={(e) => e.stopPropagation()}>
                                        <Button variant="ghost" size="icon" className="text-gray-600 hover:bg-gray-100 hover:text-gray-700 h-7 w-7" title="Edit Product">
                                            <Trash2 size={16} /> {/* Using Trash2 as placeholder for Edit */}
                                        </Button>
                                      </Link>
                                    </>
                                  )}
                                </div>
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  </Card>
                ) : (
                 // Grid View Implementation
                  <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
                    {filteredProducts.map(product => (
                      <Card
                        key={product.id}
                        className={`relative overflow-hidden transition-all hover:shadow-md ${selectedProduct?.id === product.id ? 'ring-2 ring-primary ring-offset-1' : ''}`}
                      >
                         <div className="absolute top-2 left-2 z-10">
                           <Checkbox
                             checked={selectedProducts.includes(product.id)}
                             onCheckedChange={() => toggleProductSelection(product.id)}
                             aria-labelledby={`product-card-name-${product.id}`}
                           />
                         </div>
                         <CardContent className="p-4 pt-8 cursor-pointer" onClick={() => viewProductDetails(product)}>
                          <div className="mb-3 flex justify-center">
                            <div className="flex h-16 w-16 items-center justify-center rounded-full bg-primary/10 text-primary">
                               <Package size={32} /> {/* Placeholder */}
                             </div>
                           </div>
                           <h3 id={`product-card-name-${product.id}`} className="text-center font-medium text-black dark:text-white truncate">
                             {product.partName || product.name || 'Unnamed Product'}
                           </h3>
                           <p className="text-center text-xs text-gray-500 dark:text-gray-400 mb-2">
                             {product.brand} {product.partNumber && `• ${product.partNumber}`}
                           </p>
                           <p className="text-center text-lg font-semibold text-primary dark:text-primary-light mb-3">
                             {formatUGX(product.unitPrice || product.price || 0)}
                           </p>
                           <p className="text-center text-xs text-gray-500 dark:text-gray-400 mb-3">
                             By: <Link href={`/vendors/${product.vendorId}`} className="hover:underline" onClick={(e) => e.stopPropagation()}>{product.vendorName || 'Unknown'}</Link>
                           </p>
                           <p className="text-center text-xs text-gray-500 dark:text-gray-400 mb-4">
                              Submitted: {formatDate(product.createdAt)}
                           </p>

                           <div className="flex justify-center gap-2 border-t border-stroke dark:border-strokedark pt-3">
                            {statusUpdating === product.id ? (
                               <div className="h-8 w-8 flex items-center justify-center">
                                  <div className="h-5 w-5 animate-spin rounded-full border-2 border-primary border-t-transparent"></div>
                               </div>
                             ) : (
                               <>
                                 <Button variant="outline" size="sm" className="border-green-500 text-green-600 hover:bg-green-50 hover:text-green-700" onClick={(e) => { e.stopPropagation(); handleStatusChange(product.id, ProductStatus.APPROVED); }} title="Approve">
                                   <CheckCircle size={16} />
                                 </Button>
                                 <Button variant="outline" size="sm" className="border-red-500 text-red-600 hover:bg-red-50 hover:text-red-700" onClick={(e) => { e.stopPropagation(); handleStatusChange(product.id, ProductStatus.REJECTED); }} title="Reject">
                                   <XCircle size={16} />
                                 </Button>
                                 <Button variant="outline" size="sm" onClick={(e) => { e.stopPropagation(); viewProductDetails(product); }} title="View Details">
                                   <Eye size={16} />
                                 </Button>
                               </>
                             )}
                           </div>
                         </CardContent>
                       </Card>
                     ))}
                   </div>
                )
             )}
        </div>
      </div>

       {/* Detail Panel (Sliding from right) */}
      <div className={`fixed top-0 right-0 z-30 h-full w-full max-w-md lg:max-w-[400px] bg-white dark:bg-boxdark shadow-lg border-l border-stroke dark:border-strokedark transform transition-transform duration-300 ease-in-out ${isDetailPanelOpen ? 'translate-x-0' : 'translate-x-full'}`}>
        <div className="flex h-full flex-col">
           <div className="flex items-center justify-between border-b border-stroke dark:border-strokedark p-4">
             <h2 className="text-lg font-semibold text-black dark:text-white">Product Details</h2>
             <Button variant="ghost" size="icon" onClick={() => setIsDetailPanelOpen(false)}>
               <XCircle size={20} />
             </Button>
           </div>
          <div className="flex-1 overflow-y-auto p-4 space-y-4">
            {selectedProduct ? (
                <>
                  {/* Display selected product details here */}
                   <h3 className="font-semibold text-xl">{selectedProduct.partName || selectedProduct.name}</h3>
                   <Badge variant="info" className="text-xs">{selectedProduct.brand} {selectedProduct.partNumber && ` - ${selectedProduct.partNumber}`}</Badge>
                  <p className="text-2xl font-bold text-primary">{formatUGX(selectedProduct.unitPrice || selectedProduct.price)}</p>
                  <p className="text-sm text-gray-600 dark:text-gray-400">{selectedProduct.description || "No description provided."}</p>
                   <div className="text-xs text-gray-500 dark:text-gray-400 space-y-1 pt-2 border-t border-stroke dark:border-strokedark mt-4">
                       <p><strong>Vendor:</strong> {selectedProduct.vendorName}</p>
                       <p><strong>Category:</strong> {selectedProduct.category}</p>
                       <p><strong>Condition:</strong> {selectedProduct.condition}</p>
                       <p><strong>Stock:</strong> {selectedProduct.stockQuantity}</p>
                       <p><strong>Submitted:</strong> {formatDate(selectedProduct.createdAt)}</p>
                   </div>

                   {/* Add Images if available */}
                   {selectedProduct.images && selectedProduct.images.length > 0 && (
                       <div>
                           <h4 className="font-medium mb-2">Images:</h4>
                           <div className="grid grid-cols-3 gap-2">
                               {selectedProduct.images.map((imgUrl, index) => (
                                   <img key={index} src={imgUrl} alt={`Product Image ${index + 1}`} className="rounded border border-stroke dark:border-strokedark aspect-square object-cover" />
                               ))}
                           </div>
                       </div>
                   )}

                   {/* Action buttons within the panel */}
                  <div className="flex gap-2 pt-4 border-t border-stroke dark:border-strokedark mt-4">
                     {statusUpdating === selectedProduct.id ? (
                         <p className="text-sm text-gray-500">Updating...</p>
                     ) : (
                         <>
                             <Button size="sm" className="bg-green-600 hover:bg-green-700" onClick={() => handleStatusChange(selectedProduct.id, ProductStatus.APPROVED)}>
                                 <CheckCircle size={16} className="mr-1" /> Approve
                             </Button>
                             <Button size="sm" variant="destructive" onClick={() => handleStatusChange(selectedProduct.id, ProductStatus.REJECTED)}>
                                 <XCircle size={16} className="mr-1" /> Reject
                             </Button>
                             <Link href={`/products/${selectedProduct.id}/edit`}>
                                <Button size="sm" variant="outline">
                                    <Trash2 size={16} className="mr-1" /> Edit {/* Using Trash2 as placeholder */}
                                </Button>
                            </Link>
                         </>
                     )}
                   </div>
                 </>
             ) : (
               <p className="text-center text-gray-500 dark:text-gray-400 mt-10">Select a product to view details.</p>
             )}
           </div>
         </div>
       </div>
     </div>
   );
}
EOF_INNER

# 6. Catalog Management Improvements (from Part 2)
echo -e "${CYAN}[6/6]${NC} Implementing Catalog Management Improvements..."

# Create improved catalog management page
mkdir -p src/app/catalogs
# File: src/app/catalogs/page.tsx
cat > src/app/catalogs/page.tsx << 'EOF_INNER'
'use client';

import React, { useState, useEffect, useMemo, useCallback } from 'react';
import Link from 'next/link';
import { productService, Product, ProductStatus } from '@/services/firebase.service';
import { Eye, Edit, Filter, Package, Check, X, Plus, Grid3X3, List, Search, CheckCircle, XCircle, Clock, AlertTriangle, MinusCircle, Ban } from 'lucide-react';
import { Badge } from '@/components/ui/badge';
import LoadingScreen from '@/components/LoadingScreen';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Input } from "@/components/ui/input";
import { useToast } from '@/components/ui/toast-provider';
import { Pagination, PaginationContent, PaginationEllipsis, PaginationItem, PaginationLink, PaginationNext, PaginationPrevious } from "@/components/ui/pagination"; // Assuming Pagination component

// Catalog type definition
type CatalogType = 'general' | 'store';

// Structure for filter options
interface CatalogFilterOptions {
  status: ProductStatus | 'all'; // Filter by status (only in 'general' view)
  searchTerm: string;
  // Add other filters like category, brand, vendor if needed
}

export default function CatalogsPage() {
  const [allProducts, setAllProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [catalogType, setCatalogType] = useState<CatalogType>('general'); // Default to general catalog
  const [filters, setFilters] = useState<CatalogFilterOptions>({
    status: 'all',
    searchTerm: '',
  });
  const [viewMode, setViewMode] = useState<'list' | 'grid'>('list'); // Default view mode
  const [statusUpdating, setStatusUpdating] = useState<string | null>(null); // Track ID of product being updated
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 15; // Number of items per page

  const { addToast } = useToast();

  // Fetch all products using a listener
  useEffect(() => {
    setLoading(true);
    const unsubscribe = productService.listenToProducts(
      (productsList) => {
        setAllProducts(productsList as Product[]);
        setLoading(false);
      },
      (error) => {
        console.error('Error fetching products:', error);
        addToast('Failed to load product catalog.', 'error');
        setLoading(false);
      }
    );
    return () => unsubscribe(); // Cleanup listener
  }, [addToast]);

  // Memoized list of products based on catalog type and filters
  const filteredAndSortedProducts = useMemo(() => {
    let filtered = allProducts;

    // 1. Filter by Catalog Type
    if (catalogType === 'store') {
      // Store catalog only shows Approved products
      filtered = filtered.filter(product => product.status === ProductStatus.APPROVED);
    }

    // 2. Apply Status Filter (only for 'general' catalog)
    if (catalogType === 'general' && filters.status !== 'all') {
      filtered = filtered.filter(product => product.status === filters.status);
    }

    // 3. Apply Search Term Filter
    if (filters.searchTerm) {
      const term = filters.searchTerm.toLowerCase();
      filtered = filtered.filter(product =>
        (product.name?.toLowerCase().includes(term)) ||
        (product.partName?.toLowerCase().includes(term)) ||
        (product.brand?.toLowerCase().includes(term)) ||
        (product.partNumber?.toLowerCase().includes(term)) ||
        (product.vendorName?.toLowerCase().includes(term))
      );
    }

    // 4. Sort (e.g., by creation date descending) - Optional
    // filtered.sort((a, b) => (b.createdAt?.seconds ?? 0) - (a.createdAt?.seconds ?? 0));

    return filtered;
  }, [allProducts, catalogType, filters]);

  // Memoized pagination calculations
  const totalPages = useMemo(() => {
    return Math.max(1, Math.ceil(filteredAndSortedProducts.length / itemsPerPage));
  }, [filteredAndSortedProducts.length, itemsPerPage]);

  // Adjust current page if filters change and page becomes invalid
  useEffect(() => {
    if (currentPage > totalPages) {
      setCurrentPage(totalPages);
    }
  }, [currentPage, totalPages]);

  // Memoized list of products for the current page
  const paginatedProducts = useMemo(() => {
    const startIndex = (currentPage - 1) * itemsPerPage;
    return filteredAndSortedProducts.slice(startIndex, startIndex + itemsPerPage);
  }, [filteredAndSortedProducts, currentPage, itemsPerPage]);


  // Handle filter changes
  const handleFilterChange = useCallback(<K extends keyof CatalogFilterOptions>(key: K, value: CatalogFilterOptions[K]) => {
    setFilters(prev => ({ ...prev, [key]: value }));
    setCurrentPage(1); // Reset to first page when filters change
  }, []);

  // Handle catalog type change
  const handleCatalogTypeChange = useCallback((type: CatalogType) => {
    setCatalogType(type);
    // Reset status filter when switching to 'store' as it's implicit
    if (type === 'store') {
      handleFilterChange('status', 'all');
    }
    setCurrentPage(1); // Reset page
  }, [handleFilterChange]);

  // Handle product status update
  const handleStatusChange = useCallback(async (id: string, newStatus: ProductStatus) => {
    setStatusUpdating(id);
    try {
      await productService.updateProductStatus(id, newStatus);
      addToast(`Product ${id} status updated to ${newStatus}.`, 'success');
      // Listener will update the list automatically
    } catch (error) {
      console.error('Error updating product status:', error);
      addToast(`Failed to update status for product ${id}.`, 'error');
    } finally {
      setStatusUpdating(null);
    }
  }, [addToast]);


  // --- Helper Functions for UI ---

  const formatUGX = (amount: number = 0) => {
    return new Intl.NumberFormat('en-UG', { style: 'currency', currency: 'UGX', minimumFractionDigits: 0, maximumFractionDigits: 0 }).format(amount);
  };

  const getStatusBadgeVariant = (status: ProductStatus | string): BadgeProps['variant'] => {
     switch (status) {
       case ProductStatus.APPROVED: return 'success';
       case ProductStatus.PENDING: return 'warning'; // Use a specific 'pending' variant if available
       case ProductStatus.REJECTED: return 'danger';
       case ProductStatus.OUTOFSTOCK: return 'info';
       case ProductStatus.DISCONTINUED: return 'secondary'; // Or a specific 'discontinued' variant
       default: return 'secondary';
     }
   };

   const getStatusIcon = (status: ProductStatus | string): React.ReactNode => {
     switch (status) {
       case ProductStatus.APPROVED: return <CheckCircle size={14} className="mr-1" />;
       case ProductStatus.PENDING: return <Clock size={14} className="mr-1" />;
       case ProductStatus.REJECTED: return <XCircle size={14} className="mr-1" />;
       case ProductStatus.OUTOFSTOCK: return <MinusCircle size={14} className="mr-1" />; // Example icon
       case ProductStatus.DISCONTINUED: return <Ban size={14} className="mr-1" />; // Example icon
       default: return <AlertTriangle size={14} className="mr-1" />;
     }
   };

   const statusOptions: { value: ProductStatus | 'all', label: string }[] = [
       { value: 'all', label: 'All Statuses' },
       { value: ProductStatus.PENDING, label: 'Pending' },
       { value: ProductStatus.APPROVED, label: 'Approved' },
       { value: ProductStatus.REJECTED, label: 'Rejected' },
       { value: ProductStatus.OUTOFSTOCK, label: 'Out of Stock' },
       { value: ProductStatus.DISCONTINUED, label: 'Discontinued' },
   ];


  // --- Render Component ---

  if (loading && allProducts.length === 0) {
    return <LoadingScreen />;
  }

  return (
    <div className="p-4 md:p-6 space-y-6">
      {/* Header */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-800 dark:text-white">
            Product Catalog
          </h1>
          <p className="text-sm text-gray-500 dark:text-gray-400">
            Manage all products within the platform.
          </p>
        </div>
        <Link href="/products/new">
            <Button>
                <Plus size={16} className="mr-2" /> Add New Product
            </Button>
        </Link>
      </div>

      {/* Filters and Controls Bar */}
      <Card>
          <CardContent className="p-4">
            <div className="flex flex-wrap items-center gap-3">
                 {/* Catalog Type Toggle */}
                 <div className="flex rounded-md border border-stroke dark:border-strokedark overflow-hidden">
                     <Button
                         variant={catalogType === 'general' ? 'default' : 'outline'}
                         size="sm"
                         onClick={() => handleCatalogTypeChange('general')}
                         className="rounded-none border-none"
                         >
                         <Package size={16} className="mr-1.5" /> General
                     </Button>
                     <Button
                         variant={catalogType === 'store' ? 'default' : 'outline'}
                         size="sm"
                         onClick={() => handleCatalogTypeChange('store')}
                         className="rounded-none border-none"
                         >
                         <CheckCircle size={16} className="mr-1.5" /> Store (Approved)
                     </Button>
                 </div>

                {/* Search Input */}
                <div className="relative flex-1 min-w-[200px]">
                     <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
                     <Input
                       type="text"
                       placeholder="Search products..."
                       value={filters.searchTerm}
                       onChange={(e) => handleFilterChange('searchTerm', e.target.value)}
                       className="pl-9"
                     />
                </div>

                {/* Status Filter (Only for General Catalog) */}
                {catalogType === 'general' && (
                  <Select value={filters.status} onValueChange={(value) => handleFilterChange('status', value as ProductStatus | 'all')}>
                    <SelectTrigger className="w-full sm:w-[180px]">
                       <SelectValue placeholder="Filter by Status" />
                     </SelectTrigger>
                     <SelectContent>
                       {statusOptions.map(option => (
                         <SelectItem key={option.value} value={option.value}>{option.label}</SelectItem>
                       ))}
                     </SelectContent>
                   </Select>
                 )}

                 {/* View Mode Toggle */}
                <div className="flex rounded-md border border-stroke dark:border-strokedark overflow-hidden ml-auto">
                     <Button
                         variant={viewMode === 'list' ? 'default' : 'outline'}
                         size="icon"
                         onClick={() => setViewMode('list')}
                         className="rounded-none border-none" aria-label="List view"
                         > <List size={18} /> </Button>
                     <Button
                         variant={viewMode === 'grid' ? 'default' : 'outline'}
                         size="icon"
                         onClick={() => setViewMode('grid')}
                         className="rounded-none border-none" aria-label="Grid view"
                         > <Grid3X3 size={18} /> </Button>
                </div>
            </div>
          </CardContent>
      </Card>

      {/* Catalog Type Indicator */}
      <div className={`rounded-md p-3 text-sm ${
          catalogType === 'general'
            ? 'bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300 border border-blue-200 dark:border-blue-800'
            : 'bg-green-50 text-green-700 dark:bg-green-900/30 dark:text-green-300 border border-green-200 dark:border-green-800'
        }`}>
          <div className="flex items-center gap-2">
              {catalogType === 'general' ? <Package size={16} /> : <CheckCircle size={16} />}
              <span>
                  Viewing: <strong>{catalogType === 'general' ? 'General Catalog' : 'Store Catalog (Approved Only)'}</strong>.
                  {catalogType === 'general' && ' Includes all products regardless of status.'}
              </span>
          </div>
      </div>


      {/* Products Display */}
      {paginatedProducts.length === 0 ? (
           <Card className="flex flex-col items-center justify-center py-16 text-center">
             <CardHeader>
               <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-gray-100 text-gray-500 dark:bg-gray-800 dark:text-gray-400">
                 <Package size={28} />
               </div>
             </CardHeader>
             <CardContent>
               <h3 className="mb-2 text-xl font-semibold text-gray-800 dark:text-white">No Products Found</h3>
               <p className="max-w-md text-gray-500 dark:text-gray-400">
                 {filteredAndSortedProducts.length > 0 ? "No products on this page." // Should not happen if page adjusted correctly
                   : filters.searchTerm || (catalogType === 'general' && filters.status !== 'all')
                   ? "No products match your current filters. Try adjusting them."
                   : catalogType === 'store'
                     ? "There are no approved products in the store catalog yet."
                     : "There are no products in the general catalog."
                 }
               </p>
                {(filters.searchTerm || (catalogType === 'general' && filters.status !== 'all')) && (
                  <Button variant="link" onClick={() => setFilters({ status: 'all', searchTerm: '' })} className="mt-4">
                    Clear Filters
                  </Button>
                )}
             </CardContent>
           </Card>
      ) : viewMode === 'list' ? (
         // List View
         <Card>
           <div className="overflow-x-auto">
             <table className="w-full table-auto">
               <thead>
                 <tr className="bg-gray-2 dark:bg-meta-4 text-left text-xs font-medium uppercase text-gray-500 dark:text-gray-400">
                   <th className="px-4 py-3">Product</th>
                   <th className="px-4 py-3">Vendor</th>
                   <th className="px-4 py-3">Price</th>
                   <th className="px-4 py-3">Stock</th>
                   <th className="px-4 py-3">Status</th>
                   <th className="px-4 py-3 text-center">Actions</th>
                 </tr>
               </thead>
                <tbody className="divide-y divide-stroke dark:divide-strokedark">
                   {paginatedProducts.map((product) => (
                     <tr key={product.id} className="hover:bg-gray-100 dark:hover:bg-boxdark-2">
                       <td className="px-4 py-3">
                           <div className="flex items-center gap-3">
                               {/* Optional Image Thumbnail */}
                               {/* <div className="h-10 w-10 flex-shrink-0"> <img src={product.images?.[0] || '/placeholder.png'} alt="" className="rounded object-cover h-full w-full" /> </div> */}
                               <div>
                                   <Link href={`/products/${product.id}`} className="font-medium text-black dark:text-white hover:underline truncate block max-w-xs">
                                       {product.partName || product.name || 'Unnamed Product'}
                                   </Link>
                                   <p className="text-xs text-gray-500 dark:text-gray-400">
                                       {product.brand} {product.partNumber && `• ${product.partNumber}`}
                                   </p>
                               </div>
                           </div>
                       </td>
                       <td className="px-4 py-3 text-sm">
                            <Link href={`/vendors/${product.vendorId}`} className="hover:underline text-black dark:text-white">
                                {product.vendorName || 'Unknown'}
                            </Link>
                       </td>
                       <td className="px-4 py-3 text-sm text-black dark:text-white">{formatUGX(product.unitPrice || product.price || 0)}</td>
                       <td className="px-4 py-3 text-sm text-black dark:text-white">{product.stockQuantity ?? 'N/A'}</td>
                       <td className="px-4 py-3">
                          <Badge variant={getStatusBadgeVariant(product.status)} className="text-xs whitespace-nowrap">
                              {getStatusIcon(product.status)}
                              {String(product.status).charAt(0).toUpperCase() + String(product.status).slice(1)}
                          </Badge>
                       </td>
                       <td className="px-4 py-3">
                         <div className="flex items-center justify-center space-x-1">
                           {statusUpdating === product.id ? (
                             <div className="h-5 w-5 animate-spin rounded-full border-2 border-primary border-t-transparent"></div>
                           ) : (
                             <>
                               {/* Status Change Dropdown (only in General View) */}
                               {catalogType === 'general' && (
                                   <Select
                                        value={product.status}
                                        onValueChange={(newStatus) => handleStatusChange(product.id, newStatus as ProductStatus)}
                                   >
                                        <SelectTrigger className="h-7 w-7 p-1 text-xs focus:ring-0 focus:ring-offset-0 border-none">
                                           <span className="sr-only">Change Status</span>
                                           {/* Display current status icon or a generic one */}
                                           {/* {getStatusIcon(product.status)} */}
                                            <Edit size={14}/> {/* Using Edit as dropdown trigger icon */}
                                        </SelectTrigger>
                                        <SelectContent>
                                            {statusOptions.filter(opt => opt.value !== 'all').map(option => (
                                                <SelectItem key={option.value} value={option.value} className="text-xs">
                                                    {option.label}
                                                </SelectItem>
                                            ))}
                                        </SelectContent>
                                    </Select>
                                )}

                                <Link href={`/products/${product.id}/edit`}>
                                    <Button variant="ghost" size="icon" className="h-7 w-7 text-gray-600 hover:text-primary" title="Edit">
                                        <Edit size={16} />
                                    </Button>
                                </Link>
                                <Link href={`/products/${product.id}`}>
                                    <Button variant="ghost" size="icon" className="h-7 w-7 text-gray-600 hover:text-primary" title="View Details">
                                        <Eye size={16} />
                                    </Button>
                                </Link>
                             </>
                           )}
                         </div>
                       </td>
                     </tr>
                   ))}
                 </tbody>
             </table>
           </div>
         </Card>
      ) : (
         // Grid View
         <>
           <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5">
               {paginatedProducts.map((product) => (
                 <Card key={product.id} className="overflow-hidden transition-shadow hover:shadow-lg">
                     {/* Optional Image */}
                     {/* <div className="h-40 bg-gray-100 dark:bg-gray-800 flex items-center justify-center"> <img src={product.images?.[0] || '/placeholder.png'} alt="" className="max-h-full max-w-full object-contain"/> </div> */}
                     <CardContent className="p-4 space-y-2">
                         <Badge variant={getStatusBadgeVariant(product.status)} className="text-xs absolute top-2 right-2">
                            {getStatusIcon(product.status)}
                            {String(product.status).charAt(0).toUpperCase() + String(product.status).slice(1)}
                         </Badge>
                         <Link href={`/products/${product.id}`} className="block">
                             <h3 className="font-semibold text-black dark:text-white hover:text-primary truncate" title={product.partName || product.name}>
                                 {product.partName || product.name || 'Unnamed Product'}
                             </h3>
                         </Link>
                         <p className="text-xs text-gray-500 dark:text-gray-400">
                            {product.brand} {product.partNumber && `• ${product.partNumber}`}
                         </p>
                         <p className="text-lg font-bold text-primary dark:text-primary-light">
                            {formatUGX(product.unitPrice || product.price || 0)}
                         </p>
                         <p className="text-xs text-gray-500 dark:text-gray-400">
                            Stock: {product.stockQuantity ?? 'N/A'}
                         </p>
                         <p className="text-xs text-gray-500 dark:text-gray-400">
                             Vendor: <Link href={`/vendors/${product.vendorId}`} className="hover:underline">{product.vendorName || 'Unknown'}</Link>
                         </p>
                         <div className="flex items-center justify-end space-x-1 pt-2 border-t border-stroke dark:border-strokedark mt-2">
                            {statusUpdating === product.id ? (
                                <div className="h-5 w-5 animate-spin rounded-full border-2 border-primary border-t-transparent"></div>
                            ) : (
                                <>
                                    {catalogType === 'general' && (
                                         <Select
                                              value={product.status}
                                              onValueChange={(newStatus) => handleStatusChange(product.id, newStatus as ProductStatus)}
                                         >
                                              <SelectTrigger className="h-7 w-7 p-1 text-xs focus:ring-0 focus:ring-offset-0 border-none">
                                                   <Edit size={14}/>
                                              </SelectTrigger>
                                              <SelectContent>
                                                  {statusOptions.filter(opt => opt.value !== 'all').map(option => (
                                                      <SelectItem key={option.value} value={option.value} className="text-xs">
                                                          {option.label}
                                                      </SelectItem>
                                                  ))}
                                              </SelectContent>
                                          </Select>
                                    )}
                                    <Link href={`/products/${product.id}/edit`}><Button variant="ghost" size="icon" className="h-7 w-7 text-gray-600 hover:text-primary" title="Edit"><Edit size={16} /></Button></Link>
                                    <Link href={`/products/${product.id}`}><Button variant="ghost" size="icon" className="h-7 w-7 text-gray-600 hover:text-primary" title="View"><Eye size={16} /></Button></Link>
                                </>
                            )}
                         </div>
                     </CardContent>
                 </Card>
               ))}
           </div>
         </>
       )}

       {/* Pagination Controls */}
       {totalPages > 1 && (
           <Pagination className="mt-6">
               <PaginationContent>
                   <PaginationItem>
                       <PaginationPrevious href="#" onClick={(e) => { e.preventDefault(); setCurrentPage(p => Math.max(1, p - 1)); }} aria-disabled={currentPage === 1} />
                   </PaginationItem>

                   {/* Generate page numbers (simplified example) */}
                   {/* Consider a more advanced pagination logic for many pages */}
                   {[...Array(totalPages)].map((_, i) => {
                       const pageNum = i + 1;
                       // Basic logic to show limited pages around current
                       const showPage = Math.abs(pageNum - currentPage) < 3 || pageNum === 1 || pageNum === totalPages;
                       const showEllipsis = Math.abs(pageNum - currentPage) === 3 && totalPages > 5;

                       if (showEllipsis && pageNum < currentPage) {
                            return <PaginationItem key={`ellipsis-start-${i}`}><PaginationEllipsis /></PaginationItem>;
                       }
                       if (showEllipsis && pageNum > currentPage) {
                            return <PaginationItem key={`ellipsis-end-${i}`}><PaginationEllipsis /></PaginationItem>;
                       }
                        if (showPage) {
                            return (
                                <PaginationItem key={pageNum}>
                                    <PaginationLink href="#" onClick={(e) => { e.preventDefault(); setCurrentPage(pageNum); }} isActive={currentPage === pageNum}>
                                        {pageNum}
                                    </PaginationLink>
                                </PaginationItem>
                            );
                       }
                       return null;
                   })}


                   <PaginationItem>
                       <PaginationNext href="#" onClick={(e) => { e.preventDefault(); setCurrentPage(p => Math.min(totalPages, p + 1)); }} aria-disabled={currentPage === totalPages} />
                   </PaginationItem>
               </PaginationContent>
           </Pagination>
       )}
    </div>
  );
}
EOF_INNER

# Create toast provider component
# File: src/components/ui/toast-provider.tsx
cat > src/components/ui/toast-provider.tsx << 'EOF_INNER'
'use client';

import React, { createContext, useContext, useState, useCallback, ReactNode } from 'react';
import { X, CheckCircle, AlertTriangle, Info, AlertCircle } from 'lucide-react'; // Added AlertCircle
import { cn } from '@/lib/utils'; // Assuming cn utility

// Define Toast types
type ToastType = 'success' | 'error' | 'info' | 'warning';

// Define Toast structure
interface Toast {
  id: string;
  message: string | ReactNode; // Allow ReactNode for richer content
  type: ToastType;
  duration?: number; // Duration in ms, Infinity for manual close
}

// Define Context shape
interface ToastContextType {
  toasts: Toast[];
  addToast: (message: string | ReactNode, type: ToastType, duration?: number) => string; // Returns ID
  removeToast: (id: string) => void;
}

// Create Context
const ToastContext = createContext<ToastContextType | undefined>(undefined);

// Toast Provider Component
export const ToastProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [toasts, setToasts] = useState<Toast[]>([]);

  // Function to remove a toast
  const removeToast = useCallback((id: string) => {
    setToasts(prev => prev.filter(toast => toast.id !== id));
  }, []);

  // Function to add a new toast
  const addToast = useCallback((message: string | ReactNode, type: ToastType, duration = 5000): string => {
    const id = String(Date.now()) + Math.random().toString(36).substring(2, 9); // More unique ID
    const newToast: Toast = { id, message, type, duration };

    setToasts(prev => [newToast, ...prev]); // Add new toast to the beginning

    // Set timeout for auto-removal if duration is not Infinity
    if (duration !== Infinity) {
      setTimeout(() => {
        removeToast(id);
      }, duration);
    }
    return id; // Return the ID in case manual removal is needed elsewhere
  }, [removeToast]);

  // Render Provider and the Toast Container
  return (
    <ToastContext.Provider value={{ toasts, addToast, removeToast }}>
      {children}
      {/* Toast Container - Fixed position */}
      <div className="fixed bottom-4 right-4 z-[100] flex w-full max-w-sm flex-col-reverse gap-3 p-4 md:bottom-6 md:right-6">
        {toasts.map(toast => (
          <ToastComponent key={toast.id} toast={toast} onDismiss={removeToast} />
        ))}
      </div>
    </ToastContext.Provider>
  );
};

// Hook to use the Toast context
export const useToast = () => {
  const context = useContext(ToastContext);
  if (context === undefined) {
    throw new Error('useToast must be used within a ToastProvider');
  }
  return context;
};

// --- Internal Toast Component ---
interface ToastComponentProps {
  toast: Toast;
  onDismiss: (id: string) => void;
}

const ToastComponent: React.FC<ToastComponentProps> = ({ toast, onDismiss }) => {
  const { id, message, type } = toast;

  // Define styles and icons based on toast type
  const typeStyles = {
    success: {
      icon: <CheckCircle className="h-5 w-5 text-green-500" />,
      classes: 'bg-green-50 border-green-200 dark:bg-green-900/30 dark:border-green-700/50 text-green-800 dark:text-green-300',
    },
    error: {
      icon: <AlertCircle className="h-5 w-5 text-red-500" />, // Using AlertCircle for error
      classes: 'bg-red-50 border-red-200 dark:bg-red-900/30 dark:border-red-700/50 text-red-800 dark:text-red-300',
    },
    warning: {
      icon: <AlertTriangle className="h-5 w-5 text-yellow-500" />,
      classes: 'bg-yellow-50 border-yellow-200 dark:bg-yellow-900/30 dark:border-yellow-700/50 text-yellow-800 dark:text-yellow-300',
    },
    info: {
      icon: <Info className="h-5 w-5 text-blue-500" />,
      classes: 'bg-blue-50 border-blue-200 dark:bg-blue-900/30 dark:border-blue-700/50 text-blue-800 dark:text-blue-300',
    },
  };

  const { icon, classes } = typeStyles[type];

  // Add animation classes (example using simple fade-in/out)
  // You might replace this with a more sophisticated animation library like framer-motion
  const animationClasses = "animate-toast-in"; // Define 'toast-in' keyframes in your global CSS

  return (
    <div
      role="alert"
      aria-live="assertive" // Important for accessibility
      className={cn(
        "relative flex w-full items-start gap-3 rounded-lg border p-4 shadow-lg",
        classes,
        animationClasses
      )}
    >
      <div className="flex-shrink-0">{icon}</div>
      <div className="flex-1 text-sm font-medium">{message}</div>
      <button
        type="button"
        onClick={() => onDismiss(id)}
        className={cn(
          "absolute top-2 right-2 rounded-md p-1 opacity-70 transition-opacity hover:opacity-100 focus:outline-none focus:ring-2",
          // Adjust focus ring color based on type for better visibility
           type === 'success' ? 'focus:ring-green-400' :
           type === 'error' ? 'focus:ring-red-400' :
           type === 'warning' ? 'focus:ring-yellow-400' :
           'focus:ring-blue-400'
        )}
        aria-label="Dismiss notification"
      >
        <X className="h-4 w-4" />
      </button>
    </div>
  );
};

// Add Keyframes to your global CSS (e.g., styles/globals.css) for animation:
/*
@keyframes toast-in {
  from {
    opacity: 0;
    transform: translateY(1rem) scale(0.95);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}
.animate-toast-in {
  animation: toast-in 0.3s ease-out forwards;
}
*/
EOF_INNER

# Update app/providers.tsx to include toast provider
# File: src/app/providers.tsx
cat > src/app/providers.tsx << 'EOF_INNER'
'use client';

import React from 'react';
import { ThemeProvider } from 'next-themes';
import { AuthProvider } from '@/context/AuthContext'; // Assuming AuthContext exists
import { ToastProvider } from '@/components/ui/toast-provider'; // Import the ToastProvider
import { SidebarProvider } from '@/components/Layouts/sidebar/sidebar-context'; // Import SidebarProvider

// Consolidate all application-wide context providers here
export function Providers({ children }: { children: React.ReactNode }) {
  return (
    // Theme Provider (for dark/light mode)
    // attribute="class" enables class-based theming (e.g., <html class="dark">)
    // defaultTheme="system" respects user's OS preference
    // enableSystem allows switching between light, dark, and system themes
    <ThemeProvider
        attribute="class"
        defaultTheme="system"
        enableSystem
        disableTransitionOnChange // Optional: Prevent theme transition flashing
    >
      {/* Authentication Provider (manages user session) */}
      <AuthProvider>
        {/* Toast Notification Provider */}
        <ToastProvider>
           {/* Sidebar State Provider */}
           <SidebarProvider>
              {/* Render the actual application content */}
              {children}
            </SidebarProvider>
        </ToastProvider>
      </AuthProvider>
    </ThemeProvider>
  );
}
EOF_INNER

# Summarize what's been implemented
echo -e "\n${GREEN}===========================================================${NC}"
echo -e "${GREEN}           Critical Fixes Application Script Generated${NC}"
echo -e "${GREEN}===========================================================${NC}"
echo -e "\n${CYAN}This script will perform the following actions when executed:${NC}"
echo -e " ${GREEN}✓${NC} Fix build error related to generateStaticParams() by updating dynamic pages and next.config.js."
echo -e " ${GREEN}✓${NC} Implement robust Loading Screens and Error Boundaries for better UX."
echo -e " ${GREEN}✓${NC} Update core UI components (Card, StatCard, Badge) following best practices."
echo -e " ${GREEN}✓${NC} Refine navigation with improved Sidebar context, MenuItem component, and Middleware logic."
echo -e " ${GREEN}✓${NC} Enhance Product Management with a dedicated Pending Products review page (Grid/List views, filtering, bulk actions, detail panel)."
echo -e " ${GREEN}✓${NC} Implement Catalog Management with General/Store views, filtering, search, pagination, and Grid/List layouts."
echo -e " ${GREEN}✓${NC} Add a Toast Notification system for user feedback on actions."

# Final steps instructions (how to use the generated script)
echo -e "\n${YELLOW}Next Steps:${NC}"
echo -e "1. Make sure you are in the root directory of your project."
echo -e "2. Run the generated script to apply the fixes:"
echo -e "   ${CYAN}bash src/scripts/fix-critical-issues.sh${NC}"
echo -e "3. After the script finishes, clear any potential stale build cache:"
echo -e "   ${CYAN}rm -rf .next${NC}"
echo -e "   ${CYAN}rm -rf node_modules/.cache${NC}"
echo -e "4. Reinstall dependencies and rebuild:"
echo -e "   ${CYAN}npm install${NC}  # or yarn install"
echo -e "   ${CYAN}npm run build${NC} # or yarn build"
echo -e "5. Start the application:"
echo -e "   ${CYAN}npm run start${NC} # or yarn start"
echo -e "\n${PURPLE}If you encounter any issues after running the script, please review the script output and your project console for errors.${NC}"

EOF
# END OF THE MAIN HEREDOC used to create the script file

# Make the newly created script executable
chmod +x src/scripts/fix-critical-issues.sh

# Echo final confirmation that the generator script has finished
echo "" # Add a newline for clarity
echo -e "${GREEN}Script file created successfully at: ${CYAN}src/scripts/fix-critical-issues.sh${NC}"
echo -e "${YELLOW}You can now run this generated script from your project root directory using:${NC}"
echo -e "${CYAN}bash src/scripts/fix-critical-issues.sh${NC}"

exit 0
```

**Explanation:**

1.  **Generator Script:** The code above is a Bash script itself. Its primary purpose is to *create* another Bash script file.
2.  **`mkdir -p src/scripts`:** Ensures the directory where the final script will be saved exists.
3.  **`cat > src/scripts/fix-critical-issues.sh << 'EOF'`:** This is the core part.
    *   `cat > src/scripts/fix-critical-issues.sh`: Redirects the output of `cat` to create/overwrite the file `fix-critical-issues.sh` inside the `src/scripts/` directory.
    *   `<< 'EOF'`: This starts a "here document". All text between this line and the final `EOF` line will be treated as input to the `cat` command. The single quotes around `EOF` are important – they prevent the *outer* (generator) script's shell from expanding variables (like `$`, backticks) within the heredoc content. This ensures the content written to the *inner* script is exactly as typed here.
4.  **Inner Script Content:** Everything between `<< 'EOF'` and the final `EOF` is the content of the script that will actually perform the fixes. This includes:
    *   The `#!/bin/bash` shebang for the inner script.
    *   Color definitions for the inner script's output.
    *   All the `echo` progress messages (`[1/6]`, `[2/6]`, etc.).
    *   All the `mkdir -p` commands to create necessary directories.
    *   All the `cat > file << 'EOF_INNER' ... EOF_INNER` blocks that write the full, updated TypeScript/JavaScript code into the respective project files. Note the use of `EOF_INNER` for these *nested* heredocs to avoid conflict with the main `EOF`.
    *   The final summary and "Next Steps" instructions *for the user running the generated script*.
5.  **`EOF`:** This line marks the end of the main heredoc, signaling `cat` to stop reading input and finish writing the file.
6.  **`chmod +x src/scripts/fix-critical-issues.sh`:** After the `fix-critical-issues.sh` file has been created by the `cat` command, this line (outside the heredoc) makes the newly created script executable.
7.  **Final `echo` statements:** These provide confirmation that the *generator* script has finished and tell the user how to run the *generated* script.

Now, you can save the code above as a Bash script (e.g., `generate_fix_script.sh`), run it (`bash generate_fix_script.sh`), and it will produce the `src/scripts/fix-critical-issues.sh` file containing all the combined fixes, ready to be executed in your project root.
