'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { productService, ProductStatus } from '@/services/firebase.service';
import { Eye, Edit, Filter, Plus, Package } from 'lucide-react';

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

export default function ProductsPage() {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('all');
  const [statusUpdating, setStatusUpdating] = useState<string | null>(null);

  useEffect(() => {
    const unsubscribe = productService.listenToProducts((productsList) => {
      setProducts(productsList);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const filteredProducts = filter === 'all' 
    ? products 
    : products.filter(product => product.status === filter);

  const handleStatusChange = async (id: string, newStatus: string) => {
    try {
      setStatusUpdating(id);
      await productService.updateProductStatus(id, newStatus as ProductStatus);
      setStatusUpdating(null);
    } catch (error) {
      console.error('Error updating product status:', error);
      setStatusUpdating(null);
    }
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
      case ProductStatus.APPROVED: return 'badge-success';
      case ProductStatus.PENDING: return 'badge-pending';
      case ProductStatus.REJECTED: return 'badge-danger';
      case ProductStatus.OUTOFSTOCK: return 'badge-warning';
      case ProductStatus.DISCONTINUED: return 'badge-suspended';
      default: return 'badge-secondary';
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-800 dark:text-white">Products</h1>
          <p className="text-sm text-gray-500">Manage all products in your inventory</p>
        </div>
        
        <div className="flex flex-wrap gap-3">
          <select
            className="chart-filter"
            value={filter}
            onChange={(e) => setFilter(e.target.value)}
          >
            <option value="all">All Statuses</option>
            <option value={ProductStatus.PENDING}>Pending</option>
            <option value={ProductStatus.APPROVED}>Approved</option>
            <option value={ProductStatus.REJECTED}>Rejected</option>
            <option value={ProductStatus.OUTOFSTOCK}>Out of Stock</option>
            <option value={ProductStatus.DISCONTINUED}>Discontinued</option>
          </select>
          
          <Link 
            href="/products/new"
            className="flex items-center rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary-dark"
          >
            <Plus size={16} className="mr-2" />
            Add Product
          </Link>
        </div>
      </div>
      
      <div className="dashboard-card">
        <div className="overflow-x-auto">
          <table className="w-full table-auto">
            <thead className="bg-gray-50 dark:bg-boxdark-2">
              <tr className="border-b border-gray-200 dark:border-gray-700">
                <th className="whitespace-nowrap p-4 text-left font-medium text-gray-700 dark:text-gray-300">
                  Product Details
                </th>
                <th className="whitespace-nowrap p-4 text-left font-medium text-gray-700 dark:text-gray-300">
                  Vendor
                </th>
                <th className="whitespace-nowrap p-4 text-left font-medium text-gray-700 dark:text-gray-300">
                  Price
                </th>
                <th className="whitespace-nowrap p-4 text-left font-medium text-gray-700 dark:text-gray-300">
                  Stock
                </th>
                <th className="whitespace-nowrap p-4 text-left font-medium text-gray-700 dark:text-gray-300">
                  Status
                </th>
                <th className="whitespace-nowrap p-4 text-left font-medium text-gray-700 dark:text-gray-300">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={6} className="p-4 text-center">
                    <div className="mx-auto h-8 w-8 border-2 border-primary border-t-transparent spin"></div>
                  </td>
                </tr>
              ) : filteredProducts.length === 0 ? (
                <tr>
                  <td colSpan={6} className="p-4 text-center text-gray-500">
                    No products found
                  </td>
                </tr>
              ) : (
                filteredProducts.map((product) => (
                  <tr key={product.id} className="border-b border-gray-100 hover:bg-gray-50 dark:border-gray-700 dark:hover:bg-boxdark-2">
                    <td className="p-4">
                      <div className="flex items-center">
                        <div className="mr-3 flex h-10 w-10 items-center justify-center rounded-full bg-primary/10 text-primary">
                          <Package className="h-5 w-5" />
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
                    <td className="p-4">
                      <p className="text-gray-700 dark:text-gray-300">
                        {product.vendorName || 'Unknown Vendor'}
                      </p>
                    </td>
                    <td className="p-4">
                      <p className="text-gray-700 dark:text-gray-300">
                        {formatUGX(product.unitPrice || product.price || 0)}
                      </p>
                    </td>
                    <td className="p-4">
                      <p className="text-gray-700 dark:text-gray-300">
                        {product.stockQuantity || 0}
                      </p>
                    </td>
                    <td className="p-4">
                      <span className={`badge ${getStatusClass(String(product.status))}`}>
                        {String(product.status).charAt(0).toUpperCase() + String(product.status).slice(1)}
                      </span>
                    </td>
                    <td className="p-4">
                      <div className="flex items-center space-x-3.5">
                        {statusUpdating === product.id ? (
                          <div className="h-4 w-4 border-2 border-primary border-t-transparent spin"></div>
                        ) : (
                          <>
                            <select 
                              className="chart-filter text-xs"
                              value={String(product.status)}
                              onChange={(e) => handleStatusChange(product.id, e.target.value)}
                            >
                              <option value={ProductStatus.PENDING}>Pending</option>
                              <option value={ProductStatus.APPROVED}>Approve</option>
                              <option value={ProductStatus.REJECTED}>Reject</option>
                              <option value={ProductStatus.OUTOFSTOCK}>Out of Stock</option>
                              <option value={ProductStatus.DISCONTINUED}>Discontinue</option>
                            </select>
                            
                            <Link href={`/products/${product.id}/edit`} className="text-gray-500 hover:text-primary">
                              <Edit className="h-5 w-5" />
                            </Link>
                            
                            <Link href={`/products/${product.id}`} className="text-gray-500 hover:text-primary">
                              <Eye className="h-5 w-5" />
                            </Link>
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
      </div>
    </div>
  );
}