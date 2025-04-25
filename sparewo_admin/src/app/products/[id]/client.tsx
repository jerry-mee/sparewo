'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { productService, ProductStatus } from '@/services/firebase.service';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardHeader, CardTitle, CardContent, CardFooter } from '@/components/ui/card';
import { Package, Edit, ArrowLeft, Check, X, Image as ImageIcon, Tag, Truck, CalendarClock, Info } from 'lucide-react';
import LoadingScreen from '@/components/LoadingScreen';

export default function ProductClient({ productId }: { productId: string }) {
  const [product, setProduct] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [statusUpdating, setStatusUpdating] = useState(false);
  const [updateSuccess, setUpdateSuccess] = useState<string | null>(null);

  useEffect(() => {
    const fetchProduct = async () => {
      try {
        const productData = await productService.getProduct(productId);
        setProduct(productData);
      } catch (error: any) {
        console.error('Error fetching product:', error);
        setError(error.message || 'Failed to load product details');
      } finally {
        setLoading(false);
      }
    };

    fetchProduct();
  }, [productId]);

  const handleStatusChange = async (status: ProductStatus) => {
    try {
      setStatusUpdating(true);
      await productService.updateProductStatus(productId, status);
      setProduct((prev: any) => ({ ...prev, status }));
      setUpdateSuccess(`Product status updated to ${status} successfully`);
      
      // Clear success message after 3 seconds
      setTimeout(() => {
        setUpdateSuccess(null);
      }, 3000);
    } catch (error: any) {
      console.error('Error updating product status:', error);
      setError(error.message || 'Failed to update product status');
      
      // Clear error message after 3 seconds
      setTimeout(() => {
        setError(null);
      }, 3000);
    } finally {
      setStatusUpdating(false);
    }
  };

  // Format currency to UGX
  const formatUGX = (value: number = 0): string => {
    return new Intl.NumberFormat('en-UG', { 
      style: 'currency', 
      currency: 'UGX',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(value);
  };

  // Format date
  const formatDate = (timestamp: any) => {
    if (!timestamp) return 'N/A';
    try {
      const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
      return date.toLocaleDateString('en-US', {
        year: 'numeric', 
        month: 'short', 
        day: 'numeric'
      });
    } catch (error) {
      return 'Invalid date';
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case ProductStatus.APPROVED:
        return <Badge className="bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400">Approved</Badge>;
      case ProductStatus.PENDING:
        return <Badge className="bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400">Pending</Badge>;
      case ProductStatus.REJECTED:
        return <Badge className="bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400">Rejected</Badge>;
      case ProductStatus.OUTOFSTOCK:
        return <Badge className="bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400">Out of Stock</Badge>;
      case ProductStatus.DISCONTINUED:
        return <Badge className="bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-400">Discontinued</Badge>;
      default:
        return <Badge>{status}</Badge>;
    }
  };

  if (loading) {
    return <LoadingScreen />;
  }

  if (error && !product) {
    return (
      <div className="container mx-auto px-4 py-8">
        <Link href="/products" className="inline-flex items-center text-primary mb-6 hover:underline">
          <ArrowLeft className="mr-2 h-4 w-4" />
          Back to Products
        </Link>
        
        <Card className="border-red-200 dark:border-red-800">
          <CardHeader>
            <CardTitle className="text-red-600 dark:text-red-400 flex items-center">
              <Info className="mr-2 h-5 w-5" />
              Error Loading Product
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p>{error}</p>
          </CardContent>
          <CardFooter>
            <Button onClick={() => window.location.reload()}>
              Try Again
            </Button>
          </CardFooter>
        </Card>
      </div>
    );
  }

  if (!product) {
    return (
      <div className="container mx-auto px-4 py-8">
        <Link href="/products" className="inline-flex items-center text-primary mb-6 hover:underline">
          <ArrowLeft className="mr-2 h-4 w-4" />
          Back to Products
        </Link>
        
        <Card>
          <CardHeader>
            <CardTitle className="text-gray-600 dark:text-gray-400 flex items-center">
              <Info className="mr-2 h-5 w-5" />
              Product Not Found
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p>The product with ID {productId} could not be found.</p>
          </CardContent>
          <CardFooter>
            <Link href="/products">
              <Button>View All Products</Button>
            </Link>
          </CardFooter>
        </Card>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8">
      {/* Back Link */}
      <Link href="/products" className="inline-flex items-center text-primary mb-6 hover:underline">
        <ArrowLeft className="mr-2 h-4 w-4" />
        Back to Products
      </Link>

      {/* Status Messages */}
      {error && (
        <div className="mb-4 rounded-lg bg-red-100 p-4 text-red-800 dark:bg-red-900/30 dark:text-red-400">
          <div className="flex items-center">
            <X className="mr-2 h-5 w-5" />
            <p>{error}</p>
          </div>
        </div>
      )}

      {updateSuccess && (
        <div className="mb-4 rounded-lg bg-green-100 p-4 text-green-800 dark:bg-green-900/30 dark:text-green-400">
          <div className="flex items-center">
            <Check className="mr-2 h-5 w-5" />
            <p>{updateSuccess}</p>
          </div>
        </div>
      )}

      {/* Product Header */}
      <div className="mb-6 rounded-lg bg-white p-6 shadow-sm dark:bg-boxdark">
        <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
          <div className="flex items-center gap-4">
            <div className="flex h-16 w-16 items-center justify-center rounded-full bg-primary/10">
              <Package size={32} className="text-primary" />
            </div>
            <div>
              <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
                {product.partName || product.name || 'Unnamed Product'}
              </h1>
              <div className="flex flex-wrap items-center gap-2 text-sm text-gray-500">
                <span>{product.brand || 'No Brand'}</span>
                {product.partNumber && (
                  <>
                    <span className="text-gray-400">•</span>
                    <span>{product.partNumber}</span>
                  </>
                )}
                {product.category && (
                  <>
                    <span className="text-gray-400">•</span>
                    <span>{product.category}</span>
                  </>
                )}
                <span className="text-gray-400">•</span>
                <span>Added on {formatDate(product.createdAt)}</span>
              </div>
            </div>
          </div>

          <div className="flex items-center gap-3">
            {getStatusBadge(product.status as string)}
            
            <Link href={`/products/${productId}/edit`}>
              <Button variant="outline" className="flex items-center gap-1">
                <Edit size={16} />
                Edit Product
              </Button>
            </Link>
          </div>
        </div>
      </div>

      {/* Rest of your product details UI */}
      {/* Cut for brevity */}
    </div>
  );
}