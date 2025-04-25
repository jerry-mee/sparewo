'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { productService, ProductStatus } from '@/services/firebase.service';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardHeader, CardTitle, CardContent, CardFooter } from '@/components/ui/card';
import { Package, Edit, ArrowLeft, Check, X, Image as ImageIcon, Tag, Truck, CalendarClock, Info } from 'lucide-react';
import LoadingScreen from '@/components/LoadingScreen';

interface ProductDetailsProps {
  productId: string;
}

export default function ProductDetails({ productId }: ProductDetailsProps) {
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

      {/* Product Details */}
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        {/* Main Product Info */}
        <div className="lg:col-span-2">
          <Card>
            <CardHeader>
              <CardTitle>Product Details</CardTitle>
            </CardHeader>
            <CardContent className="space-y-6">
              {/* Description */}
              {product.description && (
                <div>
                  <h3 className="mb-2 text-lg font-medium">Description</h3>
                  <p className="text-gray-700 dark:text-gray-300">{product.description}</p>
                </div>
              )}

              {/* Specifications */}
              <div>
                <h3 className="mb-3 text-lg font-medium">Specifications</h3>
                <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                  {product.condition && (
                    <div className="flex items-start gap-2">
                      <Tag className="mt-0.5 h-5 w-5 text-gray-400" />
                      <div>
                        <p className="text-sm font-medium text-gray-500">Condition</p>
                        <p className="text-gray-900 dark:text-white">
                          {product.condition.charAt(0).toUpperCase() + product.condition.slice(1)}
                        </p>
                      </div>
                    </div>
                  )}
                  
                  {product.weight && (
                    <div className="flex items-start gap-2">
                      <Truck className="mt-0.5 h-5 w-5 text-gray-400" />
                      <div>
                        <p className="text-sm font-medium text-gray-500">Weight</p>
                        <p className="text-gray-900 dark:text-white">{product.weight} kg</p>
                      </div>
                    </div>
                  )}
                  
                  {product.dimensions && (
                    <div className="flex items-start gap-2">
                      <Package className="mt-0.5 h-5 w-5 text-gray-400" />
                      <div>
                        <p className="text-sm font-medium text-gray-500">Dimensions</p>
                        <p className="text-gray-900 dark:text-white">{product.dimensions}</p>
                      </div>
                    </div>
                  )}
                  
                  {product.manufacturer && (
                    <div className="flex items-start gap-2">
                      <Package className="mt-0.5 h-5 w-5 text-gray-400" />
                      <div>
                        <p className="text-sm font-medium text-gray-500">Manufacturer</p>
                        <p className="text-gray-900 dark:text-white">{product.manufacturer}</p>
                      </div>
                    </div>
                  )}
                </div>
              </div>

              {/* Compatibility */}
              {product.compatibility && (
                <div>
                  <h3 className="mb-2 text-lg font-medium">Vehicle Compatibility</h3>
                  <p className="text-gray-700 dark:text-gray-300">{product.compatibility}</p>
                </div>
              )}

              {/* Images */}
              {product.images && product.images.length > 0 ? (
                <div>
                  <h3 className="mb-3 text-lg font-medium">Product Images</h3>
                  <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 md:grid-cols-4">
                    {product.images.map((image: string, index: number) => (
                      <div 
                        key={index} 
                        className="aspect-square overflow-hidden rounded-lg border border-gray-200 dark:border-gray-700"
                      >
                        <img 
                          src={image} 
                          alt={`${product.name || 'Product'} image ${index + 1}`} 
                          className="h-full w-full object-cover"
                        />
                      </div>
                    ))}
                  </div>
                </div>
              ) : (
                <div className="flex flex-col items-center justify-center rounded-lg border border-dashed border-gray-300 py-6 dark:border-gray-700">
                  <ImageIcon className="mb-2 h-10 w-10 text-gray-400" />
                  <p className="text-gray-500">No product images available</p>
                </div>
              )}
            </CardContent>
          </Card>
        </div>

        {/* Sidebar Info */}
        <div className="space-y-6">
          {/* Pricing and Inventory */}
          <Card>
            <CardHeader>
              <CardTitle>Pricing & Inventory</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <p className="text-sm font-medium text-gray-500">Price</p>
                <p className="text-2xl font-bold text-gray-900 dark:text-white">
                  {formatUGX(product.unitPrice || product.price || 0)}
                </p>
              </div>
              
              <div>
                <p className="text-sm font-medium text-gray-500">Stock Quantity</p>
                <p className="text-lg font-semibold text-gray-900 dark:text-white">
                  {product.stockQuantity || 0} units
                </p>
              </div>

              {product.cost && (
                <div>
                  <p className="text-sm font-medium text-gray-500">Cost Price</p>
                  <p className="text-lg font-semibold text-gray-900 dark:text-white">
                    {formatUGX(product.cost)}
                  </p>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Vendor Information */}
          <Card>
            <CardHeader>
              <CardTitle>Vendor Information</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <p className="text-sm font-medium text-gray-500">Vendor Name</p>
                <p className="text-gray-900 dark:text-white">{product.vendorName || 'Unknown'}</p>
              </div>
              
              {product.vendorId && (
                <Link 
                  href={`/vendors/${product.vendorId}`}
                  className="inline-flex items-center text-primary hover:underline"
                >
                  View Vendor Details
                </Link>
              )}
            </CardContent>
          </Card>

          {/* Status Management */}
          <Card>
            <CardHeader>
              <CardTitle>Product Status</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="mb-4">
                <p className="mb-2 text-sm font-medium text-gray-500">Current Status</p>
                {getStatusBadge(product.status as string)}
              </div>
              
              <div className="space-y-2">
                <p className="text-sm font-medium text-gray-500">Update Status</p>
                <div className="flex flex-col gap-2">
                  <Button
                    onClick={() => handleStatusChange(ProductStatus.APPROVED)}
                    disabled={statusUpdating || product.status === ProductStatus.APPROVED}
                    className="w-full justify-start bg-green-600 hover:bg-green-700"
                  >
                    <Check className="mr-2 h-4 w-4" />
                    Approve Product
                  </Button>
                  
                  <Button
                    onClick={() => handleStatusChange(ProductStatus.REJECTED)}
                    disabled={statusUpdating || product.status === ProductStatus.REJECTED}
                    className="w-full justify-start bg-red-600 hover:bg-red-700"
                  >
                    <X className="mr-2 h-4 w-4" />
                    Reject Product
                  </Button>
                  
                  <Button
                    onClick={() => handleStatusChange(ProductStatus.OUTOFSTOCK)}
                    disabled={statusUpdating || product.status === ProductStatus.OUTOFSTOCK}
                    className="w-full justify-start bg-blue-600 hover:bg-blue-700"
                  >
                    <Package className="mr-2 h-4 w-4" />
                    Mark as Out of Stock
                  </Button>
                  
                  <Button
                    onClick={() => handleStatusChange(ProductStatus.DISCONTINUED)}
                    disabled={statusUpdating || product.status === ProductStatus.DISCONTINUED}
                    className="w-full justify-start bg-gray-600 hover:bg-gray-700"
                  >
                    <X className="mr-2 h-4 w-4" />
                    Discontinue Product
                  </Button>
                </div>
              </div>
            </CardContent>
          </Card>
          
          {/* Timestamps */}
          <Card>
            <CardHeader>
              <CardTitle>Product Timeline</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-start gap-2">
                <CalendarClock className="mt-0.5 h-5 w-5 text-gray-400" />
                <div>
                  <p className="text-sm font-medium text-gray-500">Created On</p>
                  <p className="text-gray-900 dark:text-white">{formatDate(product.createdAt)}</p>
                </div>
              </div>
              
              {product.updatedAt && (
                <div className="flex items-start gap-2">
                  <CalendarClock className="mt-0.5 h-5 w-5 text-gray-400" />
                  <div>
                    <p className="text-sm font-medium text-gray-500">Last Updated</p>
                    <p className="text-gray-900 dark:text-white">{formatDate(product.updatedAt)}</p>
                  </div>
                </div>
              )}
              
              {product.statusUpdatedAt && (
                <div className="flex items-start gap-2">
                  <CalendarClock className="mt-0.5 h-5 w-5 text-gray-400" />
                  <div>
                    <p className="text-sm font-medium text-gray-500">Status Changed</p>
                    <p className="text-gray-900 dark:text-white">{formatDate(product.statusUpdatedAt)}</p>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}