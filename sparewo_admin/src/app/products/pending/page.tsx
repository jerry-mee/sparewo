'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { productService, ProductStatus } from '@/services/firebase.service';
import { CheckCircle, XCircle, Eye, AlertTriangle, Clock, Package, Filter, Search, Grid3X3, List, ChevronRight } from 'lucide-react';
import { Badge } from '@/components/ui/badge';
import { Checkbox } from '@/components/ui/checkbox';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import LoadingScreen from '@/components/LoadingScreen';

interface Product {
  id: string;
  name?: string;
  partName?: string;
  description?: string;
  unitPrice?: number;
  price?: number;
  vendorId: string;
  vendorName?: string;
  status: ProductStatus | string;
  brand?: string;
  partNumber?: string;
  createdAt: any;
  stockQuantity?: number;
  category?: string;
  images?: string[];
  [key: string]: any;
}

interface FilterOptions {
  vendorId: string;
  category: string;
  searchTerm: string;
}

export default function PendingProductsPage() {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');
  const [filters, setFilters] = useState<FilterOptions>({
    vendorId: 'all',
    category: 'all',
    searchTerm: ''
  });
  const [statusUpdating, setStatusUpdating] = useState<string | null>(null);
  const [feedback, setFeedback] = useState<{message: string, type: 'success' | 'error'} | null>(null);
  const [vendors, setVendors] = useState<{id: string, name: string}[]>([]);
  const [categories, setCategories] = useState<string[]>([]);
  const [selectedProduct, setSelectedProduct] = useState<Product | null>(null);
  const [selectedProducts, setSelectedProducts] = useState<string[]>([]);
  const [isApproveAllModalOpen, setIsApproveAllModalOpen] = useState(false);

  useEffect(() => {
    const fetchPendingProducts = async () => {
      try {
        const pendingProducts = await productService.getPendingProducts();
        setProducts(pendingProducts as Product[]);
        
        // Auto-select the first product if available
        if (pendingProducts.length > 0) {
          setSelectedProduct(pendingProducts[0] as Product);
        }
        
        // Extract unique vendors and categories for filtering
        const uniqueVendors = new Set();
        const uniqueCategories = new Set();
        
        pendingProducts.forEach((product: Product) => {
          if (product.vendorId && product.vendorName) {
            uniqueVendors.add(JSON.stringify({id: product.vendorId, name: product.vendorName}));
          }
          if (product.category) {
            uniqueCategories.add(product.category);
          }
        });
        
        setVendors(Array.from(uniqueVendors).map(v => JSON.parse(v as string)));
        setCategories(Array.from(uniqueCategories) as string[]);
        
        setLoading(false);
      } catch (error) {
        console.error('Error fetching pending products:', error);
        setLoading(false);
      }
    };

    fetchPendingProducts();
  }, []);

  const handleStatusChange = async (id: string, newStatus: string) => {
    try {
      setStatusUpdating(id);
      await productService.updateProductStatus(id, newStatus as ProductStatus);
      
      // Remove product from list and update selection
      const updatedProducts = products.filter(product => product.id !== id);
      setProducts(updatedProducts);
      
      // Remove from selected products list if present
      if (selectedProducts.includes(id)) {
        setSelectedProducts(selectedProducts.filter(productId => productId !== id));
      }
      
      // Update selected product if the current one was approved/rejected
      if (selectedProduct && selectedProduct.id === id) {
        setSelectedProduct(updatedProducts.length > 0 ? updatedProducts[0] : null);
      }
      
      // Show success message
      setFeedback({
        message: `Product ${newStatus === ProductStatus.APPROVED ? 'approved' : 'rejected'} successfully`,
        type: 'success'
      });
      
      setStatusUpdating(null);
      
      // Clear feedback after 3 seconds
      setTimeout(() => setFeedback(null), 3000);
    } catch (error) {
      console.error('Error updating product status:', error);
      setStatusUpdating(null);
      
      // Show error message
      setFeedback({
        message: 'Failed to update product status',
        type: 'error'
      });
      
      // Clear feedback after 3 seconds
      setTimeout(() => setFeedback(null), 3000);
    }
  };

  const handleBulkAction = async (action: 'approve' | 'reject') => {
    if (selectedProducts.length === 0) return;
    
    setStatusUpdating('bulk');
    let successCount = 0;
    let errorCount = 0;
    
    try {
      // Process in batches to avoid overwhelming Firebase
      for (const id of selectedProducts) {
        try {
          const status = action === 'approve' ? ProductStatus.APPROVED : ProductStatus.REJECTED;
          await productService.updateProductStatus(id, status);
          successCount++;
        } catch (error) {
          console.error(`Error updating product ${id}:`, error);
          errorCount++;
        }
      }
      
      // Remove processed products from the list
      const updatedProducts = products.filter(product => !selectedProducts.includes(product.id));
      setProducts(updatedProducts);
      
      // Update selected product if necessary
      if (selectedProduct && selectedProducts.includes(selectedProduct.id)) {
        setSelectedProduct(updatedProducts.length > 0 ? updatedProducts[0] : null);
      }
      
      // Reset selected products
      setSelectedProducts([]);
      
      // Show feedback
      setFeedback({
        message: `Bulk action completed: ${successCount} ${action === 'approve' ? 'approved' : 'rejected'}${errorCount > 0 ? `, ${errorCount} failed` : ''}`,
        type: errorCount > 0 ? 'error' : 'success'
      });
      
      setTimeout(() => setFeedback(null), 3000);
    } catch (error) {
      console.error('Error in bulk action:', error);
      setFeedback({
        message: 'Failed to complete bulk action',
        type: 'error'
      });
      
      setTimeout(() => setFeedback(null), 3000);
    } finally {
      setStatusUpdating(null);
      setIsApproveAllModalOpen(false);
    }
  };

  const toggleProductSelection = (id: string) => {
    if (selectedProducts.includes(id)) {
      setSelectedProducts(selectedProducts.filter(productId => productId !== id));
    } else {
      setSelectedProducts([...selectedProducts, id]);
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

  // Format date
  const formatDate = (timestamp: any) => {
    if (!timestamp) return 'N/A';
    const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
    return date.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  };

  // Apply filters to products
  const filteredProducts = products.filter(product => {
    if (filters.vendorId !== 'all' && product.vendorId !== filters.vendorId) {
      return false;
    }
    if (filters.category !== 'all' && product.category !== filters.category) {
      return false;
    }
    if (filters.searchTerm) {
      const term = filters.searchTerm.toLowerCase();
      return (
        (product.name?.toLowerCase().includes(term)) || 
        (product.partName?.toLowerCase().includes(term)) || 
        (product.brand?.toLowerCase().includes(term)) || 
        (product.partNumber?.toLowerCase().includes(term))
      );
    }
    return true;
  });

  // Handle filter changes
  const handleFilterChange = (key: keyof FilterOptions, value: string) => {
    setFilters(prev => ({
      ...prev,
      [key]: value
    }));
  };

  if (loading) {
    return <LoadingScreen />;
  }

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-800 dark:text-white">Pending Products</h1>
          <p className="text-sm text-gray-500">Review and approve products before they appear in the store</p>
        </div>
        
        <div className="flex items-center gap-2">
          <Badge variant="warning" className="flex items-center gap-1 py-1.5 px-3 text-sm">
            <Clock size={16} />
            <span>{products.length} pending review</span>
          </Badge>
          
          {selectedProducts.length > 0 && (
            <Badge variant="info" className="flex items-center gap-1 py-1.5 px-3 text-sm">
              {selectedProducts.length} selected
            </Badge>
          )}
        </div>
      </div>

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

      {/* Filters */}
      <div className="rounded-xl border border-gray-200 bg-white p-4 shadow-sm dark:border-gray-700 dark:bg-boxdark">
        <div className="flex flex-wrap items-center gap-4">
          {/* Bulk Actions */}
          {selectedProducts.length > 0 && (
            <div className="flex gap-2">
              <button
                onClick={() => handleBulkAction('approve')}
                disabled={statusUpdating === 'bulk'}
                className="flex items-center gap-1 rounded-lg bg-green-600 px-3 py-2 text-sm font-medium text-white hover:bg-green-700 disabled:opacity-70"
              >
                <CheckCircle size={16} />
                Approve Selected ({selectedProducts.length})
              </button>
              
              <button
                onClick={() => handleBulkAction('reject')}
                disabled={statusUpdating === 'bulk'}
                className="flex items-center gap-1 rounded-lg bg-red-600 px-3 py-2 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-70"
              >
                <XCircle size={16} />
                Reject Selected
              </button>
            </div>
          )}
          
          {/* View Mode Toggle */}
          <div className="flex overflow-hidden rounded-lg border border-gray-300 bg-white dark:border-gray-700 dark:bg-boxdark">
            <button
              onClick={() => setViewMode('list')}
              className={`flex h-9 w-9 items-center justify-center ${
                viewMode === 'list' 
                  ? 'bg-primary text-white' 
                  : 'text-gray-600 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-700'
              }`}
              aria-label="List view"
            >
              <List size={18} />
            </button>
            <button
              onClick={() => setViewMode('grid')}
              className={`flex h-9 w-9 items-center justify-center ${
                viewMode === 'grid' 
                  ? 'bg-primary text-white' 
                  : 'text-gray-600 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-700'
              }`}
              aria-label="Grid view"
            >
              <Grid3X3 size={18} />
            </button>
          </div>

          {/* Vendor Filter */}
          {vendors.length > 0 && (
            <div className="flex items-center rounded-lg border border-gray-300 bg-white dark:border-gray-700 dark:bg-boxdark">
              <div className="flex h-9 w-9 items-center justify-center text-gray-500 dark:text-gray-400">
                <Filter size={16} />
              </div>
              <Select value={filters.vendorId} onValueChange={(value: string) => handleFilterChange('vendorId', value)}>
                <SelectTrigger className="border-0 bg-transparent p-0 focus:ring-0 focus:ring-offset-0">
                  <SelectValue placeholder="All Vendors" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Vendors</SelectItem>
                  {vendors.map(vendor => (
                    <SelectItem key={vendor.id} value={vendor.id}>{vendor.name}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          )}
          
          {/* Category Filter */}
          {categories.length > 0 && (
            <div className="flex items-center rounded-lg border border-gray-300 bg-white dark:border-gray-700 dark:bg-boxdark">
              <div className="flex h-9 w-9 items-center justify-center text-gray-500 dark:text-gray-400">
                <Filter size={16} />
              </div>
              <Select value={filters.category} onValueChange={(value: string) => handleFilterChange('category', value)}>
                <SelectTrigger className="border-0 bg-transparent p-0 focus:ring-0 focus:ring-offset-0">
                  <SelectValue placeholder="All Categories" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Categories</SelectItem>
                  {categories.map(category => (
                    <SelectItem key={category} value={category}>{category}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          )}
          
          {/* Search Box */}
          <div className="relative flex flex-1 items-center min-w-[200px]">
            <div className="absolute left-3 text-gray-500">
              <Search size={16} />
            </div>
            <input
              type="text"
              placeholder="Search products..."
              value={filters.searchTerm}
              onChange={(e) => handleFilterChange('searchTerm', e.target.value)}
              className="w-full rounded-lg border border-gray-300 bg-white pl-9 pr-4 py-2 text-sm placeholder-gray-500 focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-700 dark:bg-boxdark dark:placeholder-gray-400"
            />
          </div>
        </div>
      </div>

      {filteredProducts.length === 0 ? (
        <div className="flex flex-col items-center justify-center rounded-xl border border-gray-200 bg-white p-8 py-16 shadow-sm dark:border-gray-700 dark:bg-boxdark">
          <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-green-100 text-green-500">
            <CheckCircle size={32} />
          </div>
          <h2 className="mb-2 text-xl font-semibold text-gray-800 dark:text-white">All Caught Up!</h2>
          <p className="max-w-md text-center text-gray-500">
            {products.length === 0 
              ? "There are no pending products to review at this time."
              : "No products match your current filters. Try adjusting your search criteria."}
          </p>
          {products.length > 0 && filters.searchTerm && (
            <button
              onClick={() => setFilters({vendorId: 'all', category: 'all', searchTerm: ''})}
              className="mt-4 text-primary hover:underline"
            >
              Clear all filters
            </button>
          )}
          <Link 
            href="/products" 
            className="mt-6 rounded-lg bg-primary px-4 py-2 text-white transition-colors hover:bg-primary-dark"
          >
            View All Products
          </Link>
        </div>
      ) : (
        <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
          {/* Product List */}
          <div className={viewMode === 'list' ? 'lg:col-span-3' : 'lg:col-span-1'}>
            <div className="rounded-xl border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-boxdark">
              <div className="border-b border-gray-200 p-4 dark:border-gray-700">
                <h2 className="font-semibold text-gray-800 dark:text-white">
                  Pending Products ({filteredProducts.length})
                </h2>
              </div>
              
              {viewMode === 'list' ? (
                <div className="overflow-x-auto">
                  <table className="w-full divide-y divide-gray-200 dark:divide-gray-700">
                    <thead className="bg-gray-50 dark:bg-gray-800">
                      <tr>
                        <th className="px-4 py-3 text-left">
                          <Checkbox 
                            checked={selectedProducts.length === filteredProducts.length && filteredProducts.length > 0}
                            onCheckedChange={(checked) => {
                              if (checked) {
                                setSelectedProducts(filteredProducts.map(p => p.id));
                              } else {
                                setSelectedProducts([]);
                              }
                            }}
                            className="rounded border-gray-300 text-primary focus:ring-primary"
                          />
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                          Product Details
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                          Vendor
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                          Price
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
                          Date Submitted
                        </th>
                        <th className="px-6 py-3 text-right text-xs font-medium uppercase tracking-wider text-gray-500">
                          Actions
                        </th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-200 bg-white dark:divide-gray-700 dark:bg-boxdark">
                      {filteredProducts.map(product => (
                        <tr 
                          key={product.id} 
                          className={`cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-800 ${
                            selectedProduct?.id === product.id ? 'bg-primary/5 dark:bg-primary/10' : ''
                          }`}
                          onClick={() => setSelectedProduct(product)}
                        >
                          <td className="px-4 py-4 whitespace-nowrap" onClick={(e) => e.stopPropagation()}>
                            <Checkbox 
                              checked={selectedProducts.includes(product.id)}
                              onCheckedChange={() => toggleProductSelection(product.id)}
                              className="rounded border-gray-300 text-primary focus:ring-primary"
                            />
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            <div className="flex items-center">
                              <div className="flex-shrink-0 h-10 w-10 flex items-center justify-center rounded-md bg-primary/10 text-primary">
                                <Package size={20} />
                              </div>
                              <div className="ml-4">
                                <div className="text-sm font-medium text-gray-900 dark:text-white">
                                  {product.partName || product.name || 'Unnamed Product'}
                                </div>
                                <div className="text-sm text-gray-500">
                                  {product.brand} {product.partNumber && `• ${product.partNumber}`}
                                </div>
                              </div>
                            </div>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            <div className="text-sm text-gray-900 dark:text-white">{product.vendorName}</div>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            <div className="text-sm text-gray-900 dark:text-white">
                              {formatUGX(product.unitPrice || product.price || 0)}
                            </div>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                            {formatDate(product.createdAt)}
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-right">
                            <div className="flex items-center justify-end space-x-2">
                              {statusUpdating === product.id ? (
                                <div className="h-5 w-5 animate-spin rounded-full border-2 border-primary border-t-transparent"></div>
                              ) : (
                                <>
                                  <button
                                    onClick={(e) => {
                                      e.stopPropagation();
                                      handleStatusChange(product.id, ProductStatus.APPROVED);
                                    }}
                                    className="rounded-full p-1 text-green-600 hover:bg-green-100"
                                    title="Approve"
                                  >
                                    <CheckCircle size={18} />
                                  </button>
                                  <button
                                    onClick={(e) => {
                                      e.stopPropagation();
                                      handleStatusChange(product.id, ProductStatus.REJECTED);
                                    }}
                                    className="rounded-full p-1 text-red-600 hover:bg-red-100"
                                    title="Reject"
                                  >
                                    <XCircle size={18} />
                                  </button>
                                  <Link
                                    href={`/products/${product.id}`}
                                    onClick={(e) => e.stopPropagation()}
                                    className="rounded-full p-1 text-gray-600 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-700"
                                    title="View Details"
                                  >
                                    <Eye size={18} />
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
              ) : (
                <div className="grid grid-cols-1 gap-4 p-4 sm:grid-cols-2 lg:grid-cols-1">
                  {filteredProducts.map(product => (
                    <div 
                      key={product.id}
                      className={`relative cursor-pointer rounded-lg border border-gray-200 p-4 transition-colors hover:border-primary dark:border-gray-700 ${
                        selectedProduct?.id === product.id ? 'border-primary bg-primary/5 dark:bg-primary/10' : ''
                      }`}
                      onClick={() => setSelectedProduct(product)}
                    >
                      {/* Checkbox in top-right corner */}
                      <div 
                        className="absolute top-2 right-2" 
                        onClick={(e) => e.stopPropagation()}
                      >
                        <Checkbox 
                          checked={selectedProducts.includes(product.id)}
                          onCheckedChange={() => toggleProductSelection(product.id)}
                          className="rounded border-gray-300 text-primary focus:ring-primary"
                        />
                      </div>
                      
                      <div className="mb-3 flex items-center gap-3">
                        <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary/10 text-primary">
                          <Package size={20} />
                        </div>
                        <div>
                          <h3 className="font-medium text-gray-800 dark:text-white">
                            {product.partName || product.name || 'Unnamed Product'}
                          </h3>
                          <p className="text-xs text-gray-500">
                            {product.brand} {product.partNumber && `• ${product.partNumber}`}
                          </p>
                        </div>
                      </div>
                      
                      <div className="mb-3 grid grid-cols-2 gap-2 text-sm">
                        <div>
                          <p className="text-xs text-gray-500">Price</p>
                          <p className="font-medium text-gray-700 dark:text-gray-300">
                            {formatUGX(product.unitPrice || product.price || 0)}
                          </p>
                        </div>
                        <div>
                          <p className="text-xs text-gray-500">Stock</p>
                          <p className="font-medium text-gray-700 dark:text-gray-300">
                            {product.stockQuantity || 0} units
                          </p>
                        </div>
                        <div>
                          <p className="text-xs text-gray-500">Vendor</p>
                          <p className="font-medium text-gray-700 dark:text-gray-300">
                            {product.vendorName || 'Unknown'}
                          </p>
                        </div>
                        <div>
                          <p className="text-xs text-gray-500">Date</p>
                          <p className="font-medium text-gray-700 dark:text-gray-300">
                            {formatDate(product.createdAt)}
                          </p>
                        </div>
                      </div>
                      
                      {statusUpdating !== product.id && (
                        <div className="flex justify-end gap-2">
                          <button
                            onClick={(e) => {
                              e.stopPropagation();
                              handleStatusChange(product.id, ProductStatus.APPROVED);
                            }}
                            className="flex items-center rounded-md bg-green-100 px-2 py-1 text-xs font-medium text-green-600 hover:bg-green-200 dark:bg-green-900/30 dark:text-green-400 dark:hover:bg-green-900/50"
                            title="Approve"
                          >
                            <CheckCircle size={12} className="mr-1" />
                            Approve
                          </button>
                          <button
                            onClick={(e) => {
                              e.stopPropagation();
                              handleStatusChange(product.id, ProductStatus.REJECTED);
                            }}
                            className="flex items-center rounded-md bg-red-100 px-2 py-1 text-xs font-medium text-red-600 hover:bg-red-200 dark:bg-red-900/30 dark:text-red-400 dark:hover:bg-red-900/50"
                            title="Reject"
                          >
                            <XCircle size={12} className="mr-1" />
                            Reject
                          </button>
                          <Link
                            href={`/products/${product.id}`}
                            onClick={(e) => e.stopPropagation()}
                            className="flex items-center rounded-md bg-gray-100 px-2 py-1 text-xs font-medium text-gray-600 hover:bg-gray-200 dark:bg-gray-700 dark:text-gray-300 dark:hover:bg-gray-600"
                          >
                            <Eye size={12} className="mr-1" />
                            View
                          </Link>
                        </div>
                      )}
                      
                      {statusUpdating === product.id && (
                        <div className="flex justify-center">
                          <div className="h-5 w-5 animate-spin rounded-full border-2 border-primary border-t-transparent"></div>
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
          
          {/* Product Detail */}
          {selectedProduct && viewMode === 'grid' && (
            <div className="lg:col-span-2">
              <div className="rounded-xl border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-boxdark">
                <div className="border-b border-gray-200 p-6 dark:border-gray-700">
                  <div className="flex flex-wrap items-center justify-between gap-4">
                    <div className="flex items-center gap-4">
                      <div className="flex h-16 w-16 items-center justify-center rounded-full bg-primary/10 text-primary">
                        <Package size={32} />
                      </div>
                      <div>
                        <h2 className="text-xl font-semibold text-gray-800 dark:text-white">
                          {selectedProduct.partName || selectedProduct.name || 'Unnamed Product'}
                        </h2>
                        <p className="text-sm text-gray-500">
                          {selectedProduct.brand} {selectedProduct.partNumber && `• ${selectedProduct.partNumber}`}
                          {' • '}Submitted on {formatDate(selectedProduct.createdAt)}
                        </p>
                      </div>
                    </div>
                    
                    <div className="flex gap-2">
                      {statusUpdating === selectedProduct.id ? (
                        <div className="flex h-10 items-center rounded-lg bg-gray-100 px-4 dark:bg-gray-800">
                          <div className="mr-2 h-4 w-4 animate-spin rounded-full border-2 border-primary border-t-transparent"></div>
                          <span>Processing...</span>
                        </div>
                      ) : (
                        <>
                          <button
                            onClick={() => handleStatusChange(selectedProduct.id, ProductStatus.APPROVED)}
                            className="flex items-center gap-2 rounded-lg bg-green-600 px-4 py-2 text-white transition-colors hover:bg-green-700"
                          >
                            <CheckCircle size={16} />
                            Approve
                          </button>
                          <button
                            onClick={() => handleStatusChange(selectedProduct.id, ProductStatus.REJECTED)}
                            className="flex items-center gap-2 rounded-lg bg-red-600 px-4 py-2 text-white transition-colors hover:bg-red-700"
                          >
                            <XCircle size={16} />
                            Reject
                          </button>
                          <Link
                            href={`/products/${selectedProduct.id}`}
                            className="flex items-center gap-2 rounded-lg border border-gray-300 bg-white px-4 py-2 transition-colors hover:bg-gray-50 dark:border-gray-600 dark:bg-boxdark dark:hover:bg-gray-800"
                          >
                            <Eye size={16} />
                            View
                          </Link>
                        </>
                      )}
                    </div>
                  </div>
                </div>
                
                <div className="p-6">
                  <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
                    {/* Product Information */}
                    <div className="rounded-lg bg-gray-50 p-4 dark:bg-gray-800">
                      <h3 className="mb-4 font-semibold text-gray-700 dark:text-gray-300">Product Information</h3>
                      
                      <div className="space-y-4">
                        <div className="grid grid-cols-2 gap-4">
                          <div>
                            <p className="text-sm font-medium text-gray-500">Product Name</p>
                            <p className="text-gray-800 dark:text-gray-200">
                              {selectedProduct.partName || selectedProduct.name || 'Unnamed Product'}
                            </p>
                          </div>
                          
                          <div>
                            <p className="text-sm font-medium text-gray-500">Brand</p>
                            <p className="text-gray-800 dark:text-gray-200">
                              {selectedProduct.brand || 'N/A'}
                            </p>
                          </div>
                          
                          <div>
                            <p className="text-sm font-medium text-gray-500">Part Number</p>
                            <p className="text-gray-800 dark:text-gray-200">
                              {selectedProduct.partNumber || 'N/A'}
                            </p>
                          </div>
                          
                          <div>
                            <p className="text-sm font-medium text-gray-500">Category</p>
                            <p className="text-gray-800 dark:text-gray-200">
                              {selectedProduct.category || 'Uncategorized'}
                            </p>
                          </div>
                          
                          <div>
                            <p className="text-sm font-medium text-gray-500">Condition</p>
                            <p className="text-gray-800 dark:text-gray-200">
                              {selectedProduct.condition ? 
                                selectedProduct.condition.charAt(0).toUpperCase() + selectedProduct.condition.slice(1) : 
                                'New'}
                            </p>
                          </div>
                          
                          <div>
                            <p className="text-sm font-medium text-gray-500">Stock Quantity</p>
                            <p className="text-gray-800 dark:text-gray-200">
                              {selectedProduct.stockQuantity || 0} units
                            </p>
                          </div>
                        </div>
                      </div>
                    </div>
                    
                    {/* Pricing & Vendor */}
                    <div className="rounded-lg bg-gray-50 p-4 dark:bg-gray-800">
                      <h3 className="mb-4 font-semibold text-gray-700 dark:text-gray-300">Pricing & Vendor</h3>
                      
                      <div className="space-y-4">
                        <div>
                          <p className="text-sm font-medium text-gray-500">Price</p>
                          <p className="text-xl font-bold text-gray-800 dark:text-gray-200">
                            {formatUGX(selectedProduct.unitPrice || selectedProduct.price || 0)}
                          </p>
                        </div>
                        
                        <div className="pt-2">
                          <p className="text-sm font-medium text-gray-500">Vendor</p>
                          <p className="text-gray-800 dark:text-gray-200">{selectedProduct.vendorName}</p>
                          
                          {selectedProduct.vendorId && (
                            <Link 
                              href={`/vendors/${selectedProduct.vendorId}`}
                              className="mt-1 inline-flex items-center text-sm text-primary hover:underline"
                            >
                              View Vendor
                              <ChevronRight size={16} className="ml-1" />
                            </Link>
                          )}
                        </div>
                      </div>
                    </div>
                  </div>
                  
                  {/* Description */}
                  {selectedProduct.description && (
                    <div className="mt-6 rounded-lg bg-gray-50 p-4 dark:bg-gray-800">
                      <h3 className="mb-2 font-semibold text-gray-700 dark:text-gray-300">Product Description</h3>
                      <p className="text-gray-700 dark:text-gray-300">{selectedProduct.description}</p>
                    </div>
                  )}
                  
                  {/* Vehicle Compatibility */}
                  {selectedProduct.compatibility && (
                    <div className="mt-6 rounded-lg bg-gray-50 p-4 dark:bg-gray-800">
                      <h3 className="mb-2 font-semibold text-gray-700 dark:text-gray-300">Vehicle Compatibility</h3>
                      <p className="text-gray-700 dark:text-gray-300">{selectedProduct.compatibility}</p>
                    </div>
                  )}
                  
                  {/* Product Images */}
                  {selectedProduct.images && selectedProduct.images.length > 0 && (
                    <div className="mt-6 rounded-lg bg-gray-50 p-4 dark:bg-gray-800">
                      <h3 className="mb-2 font-semibold text-gray-700 dark:text-gray-300">Product Images</h3>
                      <div className="grid grid-cols-3 gap-2">
                        {selectedProduct.images.map((imgUrl: string, index: number) => (
                          <div key={index} className="aspect-square overflow-hidden rounded-md">
                            <img 
                              src={imgUrl} 
                              alt={`Product image ${index + 1}`} 
                              className="h-full w-full object-cover"
                            />
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                </div>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}