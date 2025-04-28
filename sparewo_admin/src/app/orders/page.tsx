'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import {
    // Correct imports
    productService,
    ProductStatus,
    Product
} from '@/services/firebase.service';
import { Eye, Edit, Filter, Plus, Package, Check, X } from 'lucide-react'; // Added Check, X
import LoadingScreen from '@/components/LoadingScreen';
import { Unsubscribe, Timestamp } from 'firebase/firestore'; // Import Timestamp
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Badge } from '@/components/ui/badge';

// Interface Product imported from service

export default function ProductsPage() {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<ProductStatus | 'all'>('all'); // Use enum type + 'all'
  const [statusUpdating, setStatusUpdating] = useState<string | null>(null);
  const [feedback, setFeedback] = useState<{message: string, type: 'success' | 'error'} | null>(null); // Add feedback state

  useEffect(() => {
    let unsubscribe: Unsubscribe = () => {};
    try {
        setLoading(true);
         // Ensure productService.listenToProducts exists, add types
        unsubscribe = productService.listenToProducts(
            (productsList: Product[]) => { // Add type
                setProducts(productsList || []);
                setLoading(false);
            },
            (err: Error) => { // Add type
                console.error("Product listener error:", err);
                setFeedback({ message: 'Failed to load products.', type: 'error' });
                setLoading(false);
            }
        );
    } catch (error: any) {
        console.error('Error setting up products listener:', error);
        setFeedback({ message: 'Error initializing product listener.', type: 'error' });
        setLoading(false);
    }
    return () => { unsubscribe(); };
  }, []);

  const filteredProducts = filter === 'all'
    ? products
     // Ensure 'status' exists on Product type
    : products.filter(product => product.status === filter);

  const handleStatusChange = async (id: string, newStatus: string) => {
     // Ensure 'status' exists on Product type
     const isValidStatus = Object.values(ProductStatus).includes(newStatus as ProductStatus);
     if (!isValidStatus) { return; }
    setStatusUpdating(id);
    try {
        // Ensure productService.updateProductStatus exists
      await productService.updateProductStatus(id, newStatus as ProductStatus);
       setFeedback({ message: `Status updated`, type: 'success' }); // Added feedback
    } catch (error: any) {
       setFeedback({ message: error.message || 'Failed to update status', type: 'error' }); // Added feedback
    } finally {
      setStatusUpdating(null);
       setTimeout(() => setFeedback(null), 3000); // Auto-clear feedback
    }
  };

  const formatUGX = (amount: number): string => {
      return new Intl.NumberFormat('en-UG', { style: 'currency', currency: 'UGX', minimumFractionDigits: 0, maximumFractionDigits: 0 }).format(amount);
  };

  // Fixed return type and added default return
  const getStatusClass = (status: ProductStatus | string): string => {
       // Ensure ProductStatus members exist
      switch (status) {
          case ProductStatus.APPROVED: return 'bg-green-100 text-green-600 dark:bg-green-900/30 dark:text-green-400';
          case ProductStatus.PENDING: return 'bg-yellow-100 text-yellow-600 dark:bg-yellow-900/30 dark:text-yellow-400';
          case ProductStatus.REJECTED: return 'bg-red-100 text-red-600 dark:bg-red-900/30 dark:text-red-400';
          case ProductStatus.OUTOFSTOCK: return 'bg-blue-100 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400'; // Changed OUTOFSTOCK color
          case ProductStatus.DISCONTINUED: return 'bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-400'; // Changed DISCONTINUED color/style
          default: return 'bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-400'; // Default case
      }
  };

  // Fixed return type
  const getStatusIcon = (status: ProductStatus | string): React.ReactNode => {
        switch (status) {
            case ProductStatus.APPROVED: return <Check size={14} />;
            case ProductStatus.REJECTED: return <X size={14} />;
            default: return null;
        }
  };

  if (loading) { return <LoadingScreen />; }

  // --- RENDER ---
  return (
    <div className="space-y-6">
        {/* Header and Controls */}
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <div>
                <h1 className="text-2xl font-bold text-card-foreground dark:text-white">Products</h1>
                <p className="text-sm text-muted-foreground">Manage all products in your inventory</p>
            </div>
            <div className="flex flex-wrap gap-3 self-start">
                <select
                    className="h-9 rounded-lg border border-input bg-background px-3 py-1 text-sm focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary"
                    value={filter}
                    onChange={(e) => setFilter(e.target.value as ProductStatus | 'all')}
                >
                    <option value="all">All Statuses</option>
                     {/* Use Enum members */}
                    <option value={ProductStatus.PENDING}>Pending</option>
                    <option value={ProductStatus.APPROVED}>Approved</option>
                    <option value={ProductStatus.REJECTED}>Rejected</option>
                    <option value={ProductStatus.OUTOFSTOCK}>Out of Stock</option>
                    <option value={ProductStatus.DISCONTINUED}>Discontinued</option>
                </select>
                <Link href="/products/new" className="flex items-center whitespace-nowrap rounded-lg bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90">
                    <Plus size={16} className="mr-1.5" /> Add Product
                </Link>
            </div>
        </div>

        {/* Feedback Toast */}
        {feedback && ( <div className={`fixed top-20 right-4 z-[100] rounded-lg px-4 py-3 shadow-lg ${ feedback.type === 'success' ? 'bg-green-100 ... border-green-200' : 'bg-red-100 ... border-red-200'}`}> <div className="flex items-center"> {feedback.type === 'success' ? (<Check className="mr-2 h-5 w-5 flex-shrink-0" />) : (<X className="mr-2 h-5 w-5 flex-shrink-0" />)} <p className="text-sm font-medium">{feedback.message}</p> </div> </div> )}

        {/* Product Table */}
        <div className="rounded-lg border border-border bg-card shadow-sm dark:bg-boxdark">
            <div className="overflow-x-auto">
                <table className="w-full table-auto text-sm">
                    <thead className="bg-muted/50 dark:bg-boxdark-2">
                        <tr className="border-b border-border dark:border-gray-700">
                            <th className="py-3 px-4 text-left font-medium text-muted-foreground">Product</th>
                            <th className="py-3 px-4 text-left font-medium text-muted-foreground">Vendor</th>
                            <th className="py-3 px-4 text-left font-medium text-muted-foreground">Price</th>
                            <th className="py-3 px-4 text-left font-medium text-muted-foreground">Stock</th>
                            <th className="py-3 px-4 text-left font-medium text-muted-foreground">Status</th>
                            <th className="py-3 px-4 text-left font-medium text-muted-foreground">Actions</th>
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-border dark:divide-gray-700">
                         {/* Corrected check */}
                        {filteredProducts.length === 0 ? ( <tr> <td colSpan={6} className="p-6 text-center text-muted-foreground">No products found.</td> </tr> )
                         : (
                             // Corrected map variable name and added type
                            filteredProducts.map((product: Product) => (
                                <tr key={product.id} className="hover:bg-muted/50 dark:hover:bg-boxdark-2"> {/* Ensure 'id' exists */}
                                     {/* Ensure all accessed properties exist on 'product' (type Product) */}
                                    <td className="py-3 px-4">
                                        <div className="flex items-center gap-3">
                                            <div className="flex h-10 w-10 items-center justify-center rounded-md bg-muted overflow-hidden flex-shrink-0">
                                                {product.images && product.images.length > 0 ? (<img src={product.images[0]} alt={product.partName || product.name || ''} className="h-full w-full object-cover" />) : (<Package className="h-5 w-5 text-muted-foreground" />)}
                                            </div>
                                            <div>
                                                <h5 className="font-medium text-card-foreground dark:text-white truncate" title={product.partName || product.name}>{product.partName || product.name || 'N/A'}</h5>
                                                <p className="text-xs text-muted-foreground truncate" title={`${product.brand || ''} ${product.partNumber ? `· ${product.partNumber}` : ''}`}>{product.brand || ''}{product.partNumber && ` · ${product.partNumber}`}</p>
                                            </div>
                                        </div>
                                    </td>
                                    <td className="py-3 px-4 text-muted-foreground">{product.vendorName || 'N/A'}</td>
                                    <td className="py-3 px-4 text-card-foreground dark:text-gray-300">{formatUGX(product.unitPrice || product.price || 0)}</td>
                                    <td className="py-3 px-4 text-card-foreground dark:text-gray-300">{product.stockQuantity ?? 'N/A'}</td>
                                    <td className="py-3 px-4">
                                        <span className={`inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-medium ${getStatusClass(product.status)}`}>
                                            {/* {getStatusIcon(product.status)} */} {/* Removed icon from here */}
                                            {String(product.status).charAt(0).toUpperCase() + String(product.status).slice(1)}
                                        </span>
                                    </td>
                                    <td className="py-3 px-4">
                                        <div className="flex items-center space-x-1">
                                            {statusUpdating === product.id ? (<div className="h-4 w-4 animate-spin rounded-full border-2 border-dashed border-primary"></div>)
                                             : (<>
                                                    {/* Use Select component if available, otherwise standard select */}
                                                    <select
                                                        className="h-7 rounded border border-input bg-background py-0 px-2 text-xs font-medium outline-none focus:border-primary focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-700"
                                                        value={String(product.status)} // Ensure status exists
                                                        onChange={(e) => handleStatusChange(product.id, e.target.value)} // Ensure id exists
                                                    >
                                                         {/* Use Enum members */}
                                                        <option value={ProductStatus.PENDING}>Pending</option>
                                                        <option value={ProductStatus.APPROVED}>Approve</option>
                                                        <option value={ProductStatus.REJECTED}>Reject</option>
                                                        <option value={ProductStatus.OUTOFSTOCK}>Out of Stock</option>
                                                        <option value={ProductStatus.DISCONTINUED}>Discontinue</option>
                                                    </select>
                                                     {/* Ensure id exists */}
                                                    <Link href={`/products/${product.id}/edit`} className="flex h-7 w-7 items-center justify-center rounded text-muted-foreground transition-colors hover:bg-muted hover:text-primary" title="Edit"> <Edit className="h-4 w-4" /> </Link>
                                                    <Link href={`/products/${product.id}`} className="flex h-7 w-7 items-center justify-center rounded text-muted-foreground transition-colors hover:bg-muted hover:text-primary" title="View"> <Eye className="h-4 w-4" /> </Link>
                                                </>
                                            )}
                                        </div>
                                    </td>
                                </tr>
                            ))
                        )}
                    </tbody>
                </table>
            </div>
             {/* Optional Pagination */}
        </div>
    </div>
  );
}