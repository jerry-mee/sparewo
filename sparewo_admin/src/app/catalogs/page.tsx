'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { productService, ProductStatus } from '@/services/firebase.service';
import { Eye, Edit, Filter, Package, Check, X, Plus, Grid3X3, List, Search } from 'lucide-react';
import { Badge } from '@/components/ui/badge';
import LoadingScreen from '@/components/LoadingScreen';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Pagination, PaginationContent, PaginationEllipsis, PaginationItem, PaginationLink, PaginationNext, PaginationPrevious } from "@/components/ui/pagination";

interface Product {
  id: string;
  name?: string;
  partName?: string;
  description?: string;
  price?: number;
  unitPrice?: number;
  vendorId: string;
  vendorName?: string;
  status: ProductStatus | string;
  createdAt: any;
  brand?: string;
  partNumber?: string;
  condition?: string;
  stockQuantity?: number;
  images?: string[];
  [key: string]: any;
}

interface FilterOptions {
  status: ProductStatus | 'all';
  searchTerm: string;
}

export default function CatalogsPage() {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [catalogType, setCatalogType] = useState<'general' | 'store'>('general');
  const [filters, setFilters] = useState<FilterOptions>({
    status: 'all',
    searchTerm: ''
  });
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('list');
  const [statusUpdating, setStatusUpdating] = useState<string | null>(null);
  const [feedback, setFeedback] = useState<{message: string, type: 'success' | 'error'} | null>(null);
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage] = useState(20);

  useEffect(() => {
    try {
      const unsubscribe = productService.listenToProducts((productsList) => {
        setProducts(productsList || []);
        setLoading(false);
      });

      return () => {
        unsubscribe();
      };
    } catch (error) {
      console.error('Error setting up products listener:', error);
      setLoading(false);
      return () => {}; // Empty cleanup function
    }
  }, []);

  const filteredProducts = (() => {
    // First filter by catalog type
    let filtered = catalogType === 'store' 
      ? products.filter(product => product.status === ProductStatus.APPROVED)
      : products;
    
    // Then apply additional filter if needed
    if (filters.status !== 'all') {
      filtered = filtered.filter(product => product.status === filters.status);
    }
    
    // Then apply search if needed
    if (filters.searchTerm) {
      const term = filters.searchTerm.toLowerCase();
      filtered = filtered.filter(product => 
        (product.name?.toLowerCase().includes(term) || 
         product.partName?.toLowerCase().includes(term) ||
         product.brand?.toLowerCase().includes(term) ||
         product.partNumber?.toLowerCase().includes(term))
      );
    }
    
    return filtered;
  })();

  // Calculate pagination
  const totalItems = filteredProducts.length;
  const totalPages = Math.ceil(totalItems / itemsPerPage);
  
  // Get current page items
  const currentItems = filteredProducts.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );

  const handleStatusChange = async (id: string, newStatus: string) => {
    try {
      setStatusUpdating(id);
      await productService.updateProductStatus(id, newStatus as ProductStatus);
      setStatusUpdating(null);
      
      // Show success message
      setFeedback({
        message: `Product status updated to ${newStatus}`,
        type: 'success'
      });
      
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

  const handleFilterChange = (key: keyof FilterOptions, value: string) => {
    setFilters(prev => ({ ...prev, [key]: value }));
    setCurrentPage(1); // Reset to first page on filter change
  };

  // Format UGX currency
  const formatUGX = (amount: number) => {
    return new Intl.NumberFormat('en-UG', {
      style: 'currency',
      currency: 'UGX',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(amount);
  };

  const getStatusClass = (status: string) => {
    switch (status) {
      case ProductStatus.APPROVED: return 'bg-green-100 text-green-600 dark:bg-green-900/30 dark:text-green-400';
      case ProductStatus.PENDING: return 'bg-yellow-100 text-yellow-600 dark:bg-yellow-900/30 dark:text-yellow-400';
      case ProductStatus.REJECTED: return 'bg-red-100 text-red-600 dark:bg-red-900/30 dark:text-red-400';
      case ProductStatus.OUTOFSTOCK: return 'bg-blue-100 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400';
      case ProductStatus.DISCONTINUED: return 'bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-400';
      default: return 'bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-400';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case ProductStatus.APPROVED: return <Check size={14} />;
      case ProductStatus.REJECTED: return <X size={14} />;
      default: return null;
    }
  };

  if (loading) {
    return <LoadingScreen />;
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-800 dark:text-white">
            {catalogType === 'general' ? "General Catalog" : "Store Catalog"}
          </h1>
          <p className="text-sm text-gray-500">
            {catalogType === 'general' 
              ? "All products from all vendors (approved and unapproved)" 
              : "Only approved products visible to customers"}
          </p>
        </div>

        <div className="flex">
          <Badge variant="info" className="flex items-center py-1.5 px-3">
            <span>{totalItems} products</span>
          </Badge>
        </div>
      </div>

      {/* Feedback Toast */}
      {feedback && (
        <div className={`fixed top-20 right-4 z-50 rounded-lg px-4 py-3 shadow-md ${
          feedback.type === 'success' ? 'bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-400' : 'bg-red-100 text-red-800 dark:bg-red-900/20 dark:text-red-400'
        }`}>
          <div className="flex items-center">
            {feedback.type === 'success' ? (
              <Check className="mr-2 h-5 w-5" />
            ) : (
              <X className="mr-2 h-5 w-5" />
            )}
            <p>{feedback.message}</p>
          </div>
        </div>
      )}
      
      <div className="flex flex-wrap gap-3">
        {/* Catalog Type Toggle */}
        <div className="flex overflow-hidden rounded-lg border border-gray-300 dark:border-gray-700">
          <button
            className={`flex items-center gap-1.5 px-4 py-2 text-sm font-medium ${
              catalogType === 'general' 
                ? 'bg-primary text-white' 
                : 'bg-white text-gray-700 dark:bg-gray-800 dark:text-gray-300'
            }`}
            onClick={() => setCatalogType('general')}
          >
            <Package size={16} />
            General Catalog
          </button>
          <button
            className={`flex items-center gap-1.5 px-4 py-2 text-sm font-medium ${
              catalogType === 'store' 
                ? 'bg-primary text-white' 
                : 'bg-white text-gray-700 dark:bg-gray-800 dark:text-gray-300'
            }`}
            onClick={() => setCatalogType('store')}
          >
            <Package size={16} />
            Store Catalog
          </button>
        </div>
        
        {/* View Mode Toggle */}
        <div className="flex overflow-hidden rounded-lg border border-gray-300 dark:border-gray-700">
          <button
            className={`flex items-center gap-1.5 px-3 py-2 text-sm ${
              viewMode === 'list' 
                ? 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-white' 
                : 'bg-white text-gray-700 dark:bg-gray-800 dark:text-gray-300'
            }`}
            onClick={() => setViewMode('list')}
          >
            <List size={16} />
          </button>
          <button
            className={`flex items-center gap-1.5 px-3 py-2 text-sm ${
              viewMode === 'grid' 
                ? 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-white' 
                : 'bg-white text-gray-700 dark:bg-gray-800 dark:text-gray-300'
            }`}
            onClick={() => setViewMode('grid')}
          >
            <Grid3X3 size={16} />
          </button>
        </div>
        
        {/* Status Filter - Only for General Catalog */}
        {catalogType === 'general' && (
          <div className="flex items-center gap-1.5 rounded-lg border border-gray-300 bg-white px-4 py-2 dark:border-gray-700 dark:bg-gray-800">
            <Filter size={16} className="text-gray-500" />
            <Select value={filters.status as string} onValueChange={(value: string) => handleFilterChange('status', value as ProductStatus | 'all')}>
              <SelectTrigger className="border-0 bg-transparent p-0 focus:ring-0 focus:ring-offset-0">
                <SelectValue placeholder="All Statuses" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Statuses</SelectItem>
                <SelectItem value={ProductStatus.PENDING}>Pending</SelectItem>
                <SelectItem value={ProductStatus.APPROVED}>Approved</SelectItem>
                <SelectItem value={ProductStatus.REJECTED}>Rejected</SelectItem>
                <SelectItem value={ProductStatus.OUTOFSTOCK}>Out of Stock</SelectItem>
                <SelectItem value={ProductStatus.DISCONTINUED}>Discontinued</SelectItem>
              </SelectContent>
            </Select>
          </div>
        )}
        
        {/* Search Box */}
        <div className="relative flex flex-1 items-center min-w-[200px]">
          <Search size={16} className="absolute left-3 text-gray-500" />
          <input
            type="text"
            placeholder="Search products..."
            value={filters.searchTerm}
            onChange={(e) => handleFilterChange('searchTerm', e.target.value)}
            className="w-full rounded-lg border border-gray-300 bg-white pl-9 pr-4 py-2 text-sm placeholder-gray-500 focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-700 dark:bg-gray-800 dark:placeholder-gray-400"
          />
        </div>
        
        {/* Add Product Button */}
        <Link 
          href="/products/new"
          className="flex items-center rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary-dark"
        >
          <Plus size={16} className="mr-2" />
          Add Product
        </Link>
      </div>
      
      {/* Catalog Type Indicator */}
      <div className={`mb-6 rounded-lg p-4 text-sm ${
        catalogType === 'general'
          ? 'bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300'
          : 'bg-green-50 text-green-700 dark:bg-green-900/30 dark:text-green-300'
      }`}>
        <div className="flex items-center gap-2">
          <Package size={16} />
          <p>
            {catalogType === 'general'
              ? 'You are viewing the General Catalog. This includes all products regardless of approval status.'
              : 'You are viewing the Store Catalog. This only includes approved products that are visible to customers.'}
          </p>
        </div>
      </div>
      
      {currentItems.length === 0 ? (
        <div className="flex flex-col items-center justify-center rounded-lg bg-white p-8 shadow-md dark:bg-boxdark">
          <Package size={48} className="mb-3 text-gray-400" />
          <h3 className="mb-1 text-lg font-medium">No products found</h3>
          <p className="text-center text-gray-500">
            {filters.searchTerm 
              ? 'Try adjusting your search criteria'
              : catalogType === 'store' 
                ? 'There are no approved products in the store catalog yet'
                : 'There are no products matching the selected filter'}
          </p>
        </div>
      ) : (
        viewMode === 'list' ? (
          // List View
          <div className="rounded-lg border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-boxdark">
            <div className="overflow-x-auto">
              <table className="w-full table-auto">
                <thead>
                  <tr className="border-b border-gray-200 bg-gray-50 dark:border-gray-700 dark:bg-boxdark-2">
                    <th className="py-4 px-4 text-left font-medium text-gray-600 dark:text-gray-300">
                      Product Details
                    </th>
                    <th className="py-4 px-4 text-left font-medium text-gray-600 dark:text-gray-300">
                      Vendor
                    </th>
                    <th className="py-4 px-4 text-left font-medium text-gray-600 dark:text-gray-300">
                      Price
                    </th>
                    <th className="py-4 px-4 text-left font-medium text-gray-600 dark:text-gray-300">
                      Stock
                    </th>
                    <th className="py-4 px-4 text-left font-medium text-gray-600 dark:text-gray-300">
                      Status
                    </th>
                    <th className="py-4 px-4 text-left font-medium text-gray-600 dark:text-gray-300">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {currentItems.map((product) => (
                    <tr key={product.id} className="border-b border-gray-200 hover:bg-gray-50 dark:border-gray-700 dark:hover:bg-boxdark-2">
                      <td className="py-4 px-4">
                        <div className="flex items-center">
                          <div className="mr-3 flex h-10 w-10 items-center justify-center rounded-md bg-primary/10">
                            <Package className="h-5 w-5 text-primary" />
                          </div>
                          <div>
                            <h5 className="font-medium text-gray-800 dark:text-white">
                              {product.partName || product.name || 'Unnamed Product'}
                            </h5>
                            <p className="text-sm text-gray-500">
                              {product.brand} {product.partNumber && `· ${product.partNumber}`}
                            </p>
                          </div>
                        </div>
                      </td>
                      <td className="py-4 px-4">
                        <p className="text-gray-700 dark:text-gray-300">
                          {product.vendorName || 'Unknown Vendor'}
                        </p>
                      </td>
                      <td className="py-4 px-4">
                        <p className="text-gray-700 dark:text-gray-300">
                          {formatUGX(product.unitPrice || product.price || 0)}
                        </p>
                      </td>
                      <td className="py-4 px-4">
                        <p className="text-gray-700 dark:text-gray-300">
                          {product.stockQuantity || 0}
                        </p>
                      </td>
                      <td className="py-4 px-4">
                        <span className={`inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-xs font-medium ${getStatusClass(String(product.status))}`}>
                          {getStatusIcon(String(product.status))}
                          {String(product.status).charAt(0).toUpperCase() + String(product.status).slice(1)}
                        </span>
                      </td>
                      <td className="py-4 px-4">
                        <div className="flex items-center space-x-2">
                          {statusUpdating === product.id ? (
                            <div className="h-4 w-4 animate-spin rounded-full border-2 border-dashed border-primary"></div>
                          ) : (
                            <>
                              {catalogType === 'general' && (
                                <Select 
                                  value={String(product.status)} 
                                  onValueChange={(newStatus: string) => handleStatusChange(product.id, newStatus as ProductStatus)}
                                >
                                  <SelectTrigger className="h-8 rounded border border-gray-300 bg-white py-1 px-3 text-xs font-medium outline-none dark:border-gray-600 dark:bg-gray-700 dark:text-white">
                                    <SelectValue placeholder="Status" />
                                  </SelectTrigger>
                                  <SelectContent>
                                    <SelectItem value={ProductStatus.PENDING}>Pending</SelectItem>
                                    <SelectItem value={ProductStatus.APPROVED}>Approve</SelectItem>
                                    <SelectItem value={ProductStatus.REJECTED}>Reject</SelectItem>
                                    <SelectItem value={ProductStatus.OUTOFSTOCK}>Out of Stock</SelectItem>
                                    <SelectItem value={ProductStatus.DISCONTINUED}>Discontinue</SelectItem>
                                  </SelectContent>
                                </Select>
                              )}
                              
                              <Link 
                                href={`/products/${product.id}/edit`} 
                                className="flex h-7 w-7 items-center justify-center rounded-full text-gray-500 transition-colors hover:bg-gray-100 hover:text-primary dark:hover:bg-gray-800"
                                title="Edit"
                              >
                                <Edit className="h-4 w-4" />
                              </Link>
                              
                              <Link 
                                href={`/products/${product.id}`} 
                                className="flex h-7 w-7 items-center justify-center rounded-full text-gray-500 transition-colors hover:bg-gray-100 hover:text-primary dark:hover:bg-gray-800"
                                title="View Details"
                              >
                                <Eye className="h-4 w-4" />
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
            
            {/* Pagination */}
            {totalPages > 1 && (
              <div className="flex border-t border-gray-200 px-4 py-3 dark:border-gray-700">
                <Pagination className="mx-auto">
                  <PaginationContent>
                    <PaginationItem>
                      <PaginationPrevious href="#" onClick={(e: React.MouseEvent) => { e.preventDefault(); setCurrentPage(p => Math.max(1, p - 1)); }} aria-disabled={currentPage === 1} className={currentPage === 1 ? "pointer-events-none opacity-50" : ""} />
                    </PaginationItem>
                    
                    {/* First page */}
                    {currentPage > 2 && (
                      <PaginationItem>
                        <PaginationLink href="#" onClick={(e: React.MouseEvent) => { e.preventDefault(); setCurrentPage(1); }}>
                          1
                        </PaginationLink>
                      </PaginationItem>
                    )}
                    
                    {/* Ellipsis */}
                    {currentPage > 3 && (
                      <PaginationItem>
                        <PaginationEllipsis />
                      </PaginationItem>
                    )}
                    
                    {/* Page numbers */}
                    {Array.from({ length: Math.min(3, totalPages) }, (_, i) => {
                      let pageNum = currentPage;
                      if (currentPage === 1) {
                        pageNum = i + 1;
                      } else if (currentPage === totalPages) {
                        pageNum = totalPages - 2 + i;
                      } else {
                        pageNum = currentPage - 1 + i;
                      }
                      
                      if (pageNum > 0 && pageNum <= totalPages) {
                        return (
                          <PaginationItem key={pageNum}>
                            <PaginationLink href="#" onClick={(e: React.MouseEvent) => { e.preventDefault(); setCurrentPage(pageNum); }} isActive={currentPage === pageNum}>
                              {pageNum}
                            </PaginationLink>
                          </PaginationItem>
                        );
                      }
                      return null;
                    })}
                    
                    {/* Ellipsis */}
                    {currentPage < totalPages - 2 && (
                      <PaginationItem>
                        <PaginationEllipsis />
                      </PaginationItem>
                    )}
                    
                    {/* Last page */}
                    {currentPage < totalPages - 1 && (
                      <PaginationItem>
                        <PaginationLink href="#" onClick={(e: React.MouseEvent) => { e.preventDefault(); setCurrentPage(totalPages); }}>
                          {totalPages}
                        </PaginationLink>
                      </PaginationItem>
                    )}
                    
                    <PaginationItem>
                      <PaginationNext href="#" onClick={(e: React.MouseEvent) => { e.preventDefault(); setCurrentPage(p => Math.min(totalPages, p + 1)); }} aria-disabled={currentPage === totalPages} className={currentPage === totalPages ? "pointer-events-none opacity-50" : ""} />
                    </PaginationItem>
                  </PaginationContent>
                </Pagination>
              </div>
            )}
          </div>
        ) : (
          // Grid View
          <>
            <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
              {currentItems.map((product) => (
                <div key={product.id} className="rounded-lg border border-gray-200 bg-white shadow-sm transition-shadow hover:shadow-md dark:border-gray-700 dark:bg-boxdark">
                  <div className="p-4">
                    <div className="mb-3 flex items-center justify-between">
                      <div className="flex h-10 w-10 items-center justify-center rounded-md bg-primary/10">
                        <Package className="h-5 w-5 text-primary" />
                      </div>
                      <span className={`inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-xs font-medium ${getStatusClass(String(product.status))}`}>
                        {getStatusIcon(String(product.status))}
                        {String(product.status).charAt(0).toUpperCase() + String(product.status).slice(1)}
                      </span>
                    </div>
                    
                    <h3 className="mb-1 font-medium text-gray-800 dark:text-white">
                      {product.partName || product.name || 'Unnamed Product'}
                    </h3>
                    <p className="mb-3 text-sm text-gray-500">
                      {product.brand} {product.partNumber && `· ${product.partNumber}`}
                    </p>
                    
                    <div className="mb-3 grid grid-cols-2 gap-2 text-sm">
                      <div>
                        <p className="text-xs text-gray-500">Price</p>
                        <p className="font-medium">{formatUGX(product.unitPrice || product.price || 0)}</p>
                      </div>
                      <div>
                        <p className="text-xs text-gray-500">Stock</p>
                        <p className="font-medium">{product.stockQuantity || 0}</p>
                      </div>
                      <div className="col-span-2">
                        <p className="text-xs text-gray-500">Vendor</p>
                        <p className="font-medium">{product.vendorName || 'Unknown'}</p>
                      </div>
                    </div>
                    
                    <div className="flex items-center justify-between">
                      {statusUpdating === product.id ? (
                        <div className="h-4 w-4 animate-spin rounded-full border-2 border-dashed border-primary"></div>
                      ) : (
                        <>
                          {catalogType === 'general' && (
                            <Select 
                              value={String(product.status)} 
                              onValueChange={(newStatus: string) => handleStatusChange(product.id, newStatus as ProductStatus)}
                            >
                              <SelectTrigger className="h-8 rounded border border-gray-300 bg-white py-1 px-2 text-xs font-medium outline-none dark:border-gray-600 dark:bg-gray-700 dark:text-white">
                                <SelectValue placeholder="Status" />
                              </SelectTrigger>
                              <SelectContent>
                                <SelectItem value={ProductStatus.PENDING}>Pending</SelectItem>
                                <SelectItem value={ProductStatus.APPROVED}>Approve</SelectItem>
                                <SelectItem value={ProductStatus.REJECTED}>Reject</SelectItem>
                                <SelectItem value={ProductStatus.OUTOFSTOCK}>Out of Stock</SelectItem>
                                <SelectItem value={ProductStatus.DISCONTINUED}>Discontinue</SelectItem>
                              </SelectContent>
                            </Select>
                          )}
                          
                          <div className="flex items-center space-x-2">
                            <Link 
                              href={`/products/${product.id}/edit`} 
                              className="flex h-7 w-7 items-center justify-center rounded-full text-gray-500 transition-colors hover:bg-gray-100 hover:text-primary dark:hover:bg-gray-800"
                              title="Edit"
                            >
                              <Edit className="h-4 w-4" />
                            </Link>
                            
                            <Link 
                              href={`/products/${product.id}`} 
                              className="flex h-7 w-7 items-center justify-center rounded-full text-gray-500 transition-colors hover:bg-gray-100 hover:text-primary dark:hover:bg-gray-800"
                              title="View Details"
                            >
                              <Eye className="h-4 w-4" />
                            </Link>
                          </div>
                        </>
                      )}
                    </div>
                  </div>
                </div>
              ))}
            </div>
            
            {/* Pagination for Grid View */}
            {totalPages > 1 && (
              <div className="mt-6">
                <Pagination className="mx-auto">
                  <PaginationContent>
                    <PaginationItem>
                      <PaginationPrevious href="#" onClick={(e: React.MouseEvent) => { e.preventDefault(); setCurrentPage(p => Math.max(1, p - 1)); }} aria-disabled={currentPage === 1} className={currentPage === 1 ? "pointer-events-none opacity-50" : ""} />
                    </PaginationItem>
                    
                    {/* First page */}
                    {currentPage > 2 && (
                      <PaginationItem>
                        <PaginationLink href="#" onClick={(e: React.MouseEvent) => { e.preventDefault(); setCurrentPage(1); }}>
                          1
                        </PaginationLink>
                      </PaginationItem>
                    )}
                    
                    {/* Ellipsis */}
                    {currentPage > 3 && (
                      <PaginationItem>
                        <PaginationEllipsis />
                      </PaginationItem>
                    )}
                    
                    {/* Page numbers */}
                    {Array.from({ length: Math.min(3, totalPages) }, (_, i) => {
                      let pageNum = currentPage;
                      if (currentPage === 1) {
                        pageNum = i + 1;
                      } else if (currentPage === totalPages) {
                        pageNum = totalPages - 2 + i;
                      } else {
                        pageNum = currentPage - 1 + i;
                      }
                      
                      if (pageNum > 0 && pageNum <= totalPages) {
                        return (
                          <PaginationItem key={pageNum}>
                            <PaginationLink href="#" onClick={(e: React.MouseEvent) => { e.preventDefault(); setCurrentPage(pageNum); }} isActive={currentPage === pageNum}>
                              {pageNum}
                            </PaginationLink>
                          </PaginationItem>
                        );
                      }
                      return null;
                    })}
                    
                    {/* Ellipsis */}
                    {currentPage < totalPages - 2 && (
                      <PaginationItem>
                        <PaginationEllipsis />
                      </PaginationItem>
                    )}
                    
                    {/* Last page */}
                    {currentPage < totalPages - 1 && (
                      <PaginationItem>
                        <PaginationLink href="#" onClick={(e: React.MouseEvent) => { e.preventDefault(); setCurrentPage(totalPages); }}>
                          {totalPages}
                        </PaginationLink>
                      </PaginationItem>
                    )}
                    
                    <PaginationItem>
                      <PaginationNext href="#" onClick={(e: React.MouseEvent) => { e.preventDefault(); setCurrentPage(p => Math.min(totalPages, p + 1)); }} aria-disabled={currentPage === totalPages} className={currentPage === totalPages ? "pointer-events-none opacity-50" : ""} />
                    </PaginationItem>
                  </PaginationContent>
                </Pagination>
              </div>
            )}
          </>
        )
      )}
    </div>
  );
}