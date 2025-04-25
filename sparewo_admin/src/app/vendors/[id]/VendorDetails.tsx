'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { vendorService, VendorStatus, productService, Product } from '@/services/firebase.service';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardHeader, CardTitle, CardContent, CardFooter } from '@/components/ui/card';
import { Store, Edit, ArrowLeft, Check, X, Mail, Phone, MapPin, Package, CalendarClock, Info, User, ShieldCheck, ShieldX } from 'lucide-react';
import LoadingScreen from '@/components/LoadingScreen';

interface VendorDetailsProps {
  vendorId: string;
}

export default function VendorDetails({ vendorId }: VendorDetailsProps) {
  const [vendor, setVendor] = useState<any>(null);
  const [vendorProducts, setVendorProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [statusUpdating, setStatusUpdating] = useState(false);
  const [updateSuccess, setUpdateSuccess] = useState<string | null>(null);

  useEffect(() => {
    const fetchVendorData = async () => {
      try {
        // Fetch vendor details
        const vendorData = await vendorService.getVendor(vendorId);
        setVendor(vendorData);
        
        // If vendor exists, fetch their products
        if (vendorData) {
          // This would be an actual implementation to fetch vendor products
          // For now, we'll use a placeholder/mock approach
          const mockVendorProducts: Product[] = []; // Explicitly typed as Product[]
          setVendorProducts(mockVendorProducts);
        }
      } catch (error: any) {
        console.error('Error fetching vendor:', error);
        setError(error.message || 'Failed to load vendor details');
      } finally {
        setLoading(false);
      }
    };

    fetchVendorData();
  }, [vendorId]);

  const handleStatusChange = async (status: VendorStatus) => {
    try {
      setStatusUpdating(true);
      await vendorService.updateVendorStatus(vendorId, status);
      setVendor((prev: any) => ({ ...prev, status }));
      setUpdateSuccess(`Vendor status updated to ${status} successfully`);
      
      // Clear success message after 3 seconds
      setTimeout(() => {
        setUpdateSuccess(null);
      }, 3000);
    } catch (error: any) {
      console.error('Error updating vendor status:', error);
      setError(error.message || 'Failed to update vendor status');
      
      // Clear error message after 3 seconds
      setTimeout(() => {
        setError(null);
      }, 3000);
    } finally {
      setStatusUpdating(false);
    }
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
      case VendorStatus.APPROVED:
        return <Badge className="bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400">Approved</Badge>;
      case VendorStatus.PENDING:
        return <Badge className="bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400">Pending</Badge>;
      case VendorStatus.REJECTED:
        return <Badge className="bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400">Rejected</Badge>;
      case VendorStatus.SUSPENDED:
        return <Badge className="bg-orange-100 text-orange-800 dark:bg-orange-900/30 dark:text-orange-400">Suspended</Badge>;
      default:
        return <Badge>{status}</Badge>;
    }
  };

  if (loading) {
    return <LoadingScreen />;
  }

  if (error && !vendor) {
    return (
      <div className="container mx-auto px-4 py-8">
        <Link href="/vendors" className="inline-flex items-center text-primary mb-6 hover:underline">
          <ArrowLeft className="mr-2 h-4 w-4" />
          Back to Vendors
        </Link>
        
        <Card className="border-red-200 dark:border-red-800">
          <CardHeader>
            <CardTitle className="text-red-600 dark:text-red-400 flex items-center">
              <Info className="mr-2 h-5 w-5" />
              Error Loading Vendor
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

  if (!vendor) {
    return (
      <div className="container mx-auto px-4 py-8">
        <Link href="/vendors" className="inline-flex items-center text-primary mb-6 hover:underline">
          <ArrowLeft className="mr-2 h-4 w-4" />
          Back to Vendors
        </Link>
        
        <Card>
          <CardHeader>
            <CardTitle className="text-gray-600 dark:text-gray-400 flex items-center">
              <Info className="mr-2 h-5 w-5" />
              Vendor Not Found
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p>The vendor with ID {vendorId} could not be found.</p>
          </CardContent>
          <CardFooter>
            <Link href="/vendors">
              <Button>View All Vendors</Button>
            </Link>
          </CardFooter>
        </Card>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8">
      {/* Back Link */}
      <Link href="/vendors" className="inline-flex items-center text-primary mb-6 hover:underline">
        <ArrowLeft className="mr-2 h-4 w-4" />
        Back to Vendors
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

      {/* Vendor Header */}
      <div className="mb-6 rounded-lg bg-white p-6 shadow-sm dark:bg-boxdark">
        <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
          <div className="flex items-center gap-4">
            <div className="flex h-16 w-16 items-center justify-center rounded-full bg-primary/10">
              <Store size={32} className="text-primary" />
            </div>
            <div>
              <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
                {vendor.businessName}
              </h1>
              <div className="flex flex-wrap items-center gap-2 text-sm text-gray-500">
                <span>{vendor.name}</span>
                <span className="text-gray-400">•</span>
                <span>Joined on {formatDate(vendor.createdAt)}</span>
                <span className="text-gray-400">•</span>
                <span>{vendor.productCount || 0} Products</span>
              </div>
            </div>
          </div>

          <div className="flex items-center gap-3">
            {getStatusBadge(vendor.status as string)}
            
            <Link href={`/vendors/${vendorId}/edit`}>
              <Button variant="outline" className="flex items-center gap-1">
                <Edit size={16} />
                Edit Vendor
              </Button>
            </Link>
          </div>
        </div>
      </div>

      {/* Vendor Details */}
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        {/* Main Vendor Info */}
        <div className="lg:col-span-2">
          <Card>
            <CardHeader>
              <CardTitle>Business Details</CardTitle>
            </CardHeader>
            <CardContent className="space-y-6">
              {/* Business Information */}
              <div>
                <h3 className="mb-3 text-lg font-medium">Contact Information</h3>
                <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                  <div className="flex items-start gap-2">
                    <Store className="mt-0.5 h-5 w-5 text-gray-400" />
                    <div>
                      <p className="text-sm font-medium text-gray-500">Business Name</p>
                      <p className="text-gray-900 dark:text-white">{vendor.businessName}</p>
                    </div>
                  </div>
                  
                  <div className="flex items-start gap-2">
                    <User className="mt-0.5 h-5 w-5 text-gray-400" />
                    <div>
                      <p className="text-sm font-medium text-gray-500">Contact Person</p>
                      <p className="text-gray-900 dark:text-white">{vendor.name}</p>
                    </div>
                  </div>
                  
                  <div className="flex items-start gap-2">
                    <Mail className="mt-0.5 h-5 w-5 text-gray-400" />
                    <div>
                      <p className="text-sm font-medium text-gray-500">Email</p>
                      <p className="text-gray-900 dark:text-white">{vendor.email}</p>
                    </div>
                  </div>
                  
                  <div className="flex items-start gap-2">
                    <Phone className="mt-0.5 h-5 w-5 text-gray-400" />
                    <div>
                      <p className="text-sm font-medium text-gray-500">Phone</p>
                      <p className="text-gray-900 dark:text-white">{vendor.phone || 'Not provided'}</p>
                    </div>
                  </div>
                </div>
              </div>

              {/* Business Address */}
              {vendor.businessAddress && (
                <div>
                  <h3 className="mb-2 text-lg font-medium">Business Address</h3>
                  <div className="flex items-start gap-2">
                    <MapPin className="mt-0.5 h-5 w-5 text-gray-400" />
                    <p className="text-gray-700 dark:text-gray-300">{vendor.businessAddress}</p>
                  </div>
                </div>
              )}

              {/* Business Description */}
              {vendor.description && (
                <div>
                  <h3 className="mb-2 text-lg font-medium">Business Description</h3>
                  <p className="text-gray-700 dark:text-gray-300">{vendor.description}</p>
                </div>
              )}

              {/* Verification Status */}
              <div>
                <h3 className="mb-3 text-lg font-medium">Verification Status</h3>
                <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
                  <div className="flex items-center justify-between rounded-lg border border-gray-200 p-3 dark:border-gray-700">
                    <span className="text-sm text-gray-600 dark:text-gray-300">Email Verified</span>
                    <span className={`flex items-center text-sm ${vendor.isEmailVerified ? 'text-green-600' : 'text-red-600'}`}>
                      {vendor.isEmailVerified ? (
                        <>
                          <ShieldCheck size={14} className="mr-1" />
                          Yes
                        </>
                      ) : (
                        <>
                          <ShieldX size={14} className="mr-1" />
                          No
                        </>
                      )}
                    </span>
                  </div>
                  
                  <div className="flex items-center justify-between rounded-lg border border-gray-200 p-3 dark:border-gray-700">
                    <span className="text-sm text-gray-600 dark:text-gray-300">ID Verification</span>
                    <span className={`flex items-center text-sm ${vendor.isVerified ? 'text-green-600' : 'text-red-600'}`}>
                      {vendor.isVerified ? (
                        <>
                          <ShieldCheck size={14} className="mr-1" />
                          Yes
                        </>
                      ) : (
                        <>
                          <ShieldX size={14} className="mr-1" />
                          No
                        </>
                      )}
                    </span>
                  </div>
                  
                  <div className="flex items-center justify-between rounded-lg border border-gray-200 p-3 dark:border-gray-700">
                    <span className="text-sm text-gray-600 dark:text-gray-300">Business License</span>
                    <span className={`flex items-center text-sm ${vendor.hasBusinessLicense ? 'text-green-600' : 'text-red-600'}`}>
                      {vendor.hasBusinessLicense ? (
                        <>
                          <ShieldCheck size={14} className="mr-1" />
                          Yes
                        </>
                      ) : (
                        <>
                          <ShieldX size={14} className="mr-1" />
                          No
                        </>
                      )}
                    </span>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Vendor Products */}
          <div className="mt-6">
            <Card>
              <CardHeader className="flex flex-row items-center justify-between">
                <CardTitle>Vendor Products</CardTitle>
                <Link href={`/products?vendorId=${vendorId}`}>
                  <Button variant="outline" size="sm">View All</Button>
                </Link>
              </CardHeader>
              <CardContent>
                {vendorProducts.length > 0 ? (
                  <div className="space-y-4">
                    {vendorProducts.slice(0, 5).map((product) => (
                      <div 
                        key={product.id}
                        className="flex items-center justify-between rounded-lg border border-gray-200 p-4 dark:border-gray-700"
                      >
                        <div className="flex items-center gap-3">
                          <div className="flex h-10 w-10 items-center justify-center rounded-md bg-primary/10">
                            <Package size={20} className="text-primary" />
                          </div>
                          <div>
                            <h4 className="font-medium text-gray-900 dark:text-white">
                              {product.name}
                            </h4>
                            <p className="text-sm text-gray-500">
                              {product.price} • {product.status}
                            </p>
                          </div>
                        </div>
                        
                        <Link href={`/products/${product.id}`}>
                          <Button variant="ghost" size="sm">View</Button>
                        </Link>
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className="flex flex-col items-center justify-center rounded-lg border border-dashed border-gray-300 py-6 dark:border-gray-700">
                    <Package className="mb-2 h-10 w-10 text-gray-400" />
                    <p className="text-gray-500">No products found for this vendor</p>
                  </div>
                )}
              </CardContent>
            </Card>
          </div>
        </div>

        {/* Sidebar Info */}
        <div className="space-y-6">
          {/* Status Management */}
          <Card>
            <CardHeader>
              <CardTitle>Vendor Status</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="mb-4">
                <p className="mb-2 text-sm font-medium text-gray-500">Current Status</p>
                {getStatusBadge(vendor.status as string)}
              </div>
              
              <div className="space-y-2">
                <p className="text-sm font-medium text-gray-500">Update Status</p>
                <div className="flex flex-col gap-2">
                  <Button
                    onClick={() => handleStatusChange(VendorStatus.APPROVED)}
                    disabled={statusUpdating || vendor.status === VendorStatus.APPROVED}
                    className="w-full justify-start bg-green-600 hover:bg-green-700"
                  >
                    <Check className="mr-2 h-4 w-4" />
                    Approve Vendor
                  </Button>
                  
                  <Button
                    onClick={() => handleStatusChange(VendorStatus.REJECTED)}
                    disabled={statusUpdating || vendor.status === VendorStatus.REJECTED}
                    className="w-full justify-start bg-red-600 hover:bg-red-700"
                  >
                    <X className="mr-2 h-4 w-4" />
                    Reject Vendor
                  </Button>
                  
                  <Button
                    onClick={() => handleStatusChange(VendorStatus.SUSPENDED)}
                    disabled={statusUpdating || vendor.status === VendorStatus.SUSPENDED}
                    className="w-full justify-start bg-orange-600 hover:bg-orange-700"
                  >
                    <X className="mr-2 h-4 w-4" />
                    Suspend Vendor
                  </Button>
                </div>
              </div>
            </CardContent>
          </Card>
          
          {/* Business Metrics */}
          <Card>
            <CardHeader>
              <CardTitle>Business Metrics</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center justify-between rounded-lg border border-gray-200 p-3 dark:border-gray-700">
                <span className="text-sm text-gray-600 dark:text-gray-300">Total Products</span>
                <span className="text-lg font-semibold text-gray-900 dark:text-white">
                  {vendor.productCount || 0}
                </span>
              </div>
              
              <div className="flex items-center justify-between rounded-lg border border-gray-200 p-3 dark:border-gray-700">
                <span className="text-sm text-gray-600 dark:text-gray-300">Approved Products</span>
                <span className="text-lg font-semibold text-gray-900 dark:text-white">
                  {vendor.approvedProductCount || 0}
                </span>
              </div>
              
              <div className="flex items-center justify-between rounded-lg border border-gray-200 p-3 dark:border-gray-700">
                <span className="text-sm text-gray-600 dark:text-gray-300">Pending Products</span>
                <span className="text-lg font-semibold text-gray-900 dark:text-white">
                  {vendor.pendingProductCount || 0}
                </span>
              </div>
              
              <div className="flex items-center justify-between rounded-lg border border-gray-200 p-3 dark:border-gray-700">
                <span className="text-sm text-gray-600 dark:text-gray-300">Total Orders</span>
                <span className="text-lg font-semibold text-gray-900 dark:text-white">
                  {vendor.orderCount || 0}
                </span>
              </div>
            </CardContent>
          </Card>
          
          {/* Timestamps */}
          <Card>
            <CardHeader>
              <CardTitle>Vendor Timeline</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-start gap-2">
                <CalendarClock className="mt-0.5 h-5 w-5 text-gray-400" />
                <div>
                  <p className="text-sm font-medium text-gray-500">Joined On</p>
                  <p className="text-gray-900 dark:text-white">{formatDate(vendor.createdAt)}</p>
                </div>
              </div>
              
              {vendor.updatedAt && (
                <div className="flex items-start gap-2">
                  <CalendarClock className="mt-0.5 h-5 w-5 text-gray-400" />
                  <div>
                    <p className="text-sm font-medium text-gray-500">Last Updated</p>
                    <p className="text-gray-900 dark:text-white">{formatDate(vendor.updatedAt)}</p>
                  </div>
                </div>
              )}
              
              {vendor.statusUpdatedAt && (
                <div className="flex items-start gap-2">
                  <CalendarClock className="mt-0.5 h-5 w-5 text-gray-400" />
                  <div>
                    <p className="text-sm font-medium text-gray-500">Status Changed</p>
                    <p className="text-gray-900 dark:text-white">{formatDate(vendor.statusUpdatedAt)}</p>
                  </div>
                </div>
              )}
              
              {vendor.lastLoginAt && (
                <div className="flex items-start gap-2">
                  <CalendarClock className="mt-0.5 h-5 w-5 text-gray-400" />
                  <div>
                    <p className="text-sm font-medium text-gray-500">Last Login</p>
                    <p className="text-gray-900 dark:text-white">{formatDate(vendor.lastLoginAt)}</p>
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