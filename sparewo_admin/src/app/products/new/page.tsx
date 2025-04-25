'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { productService, vendorService, ProductStatus } from '@/services/firebase.service';
import { Upload, Save, ArrowLeft } from 'lucide-react';
import Breadcrumb from '@/components/Breadcrumbs/Breadcrumb';

interface Vendor {
  id: string;
  businessName: string;
  name: string;
  [key: string]: any;
}

export default function AddProductPage() {
  const router = useRouter();
  const [vendors, setVendors] = useState<Vendor[]>([]);
  const [loading, setLoading] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState(false);
  const [productData, setProductData] = useState({
    partName: '',
    description: '',
    unitPrice: '',
    stockQuantity: '',
    vendorId: '',
    brand: '',
    partNumber: '',
    condition: 'new',
    category: '',
    compatibility: '',
    status: ProductStatus.PENDING
  });

  // Fetch vendors to associate with product
  useEffect(() => {
    const fetchVendors = async () => {
      try {
        const unsubscribe = vendorService.listenToVendors((vendorsList) => {
          // Only approved vendors can have products added
          setVendors(vendorsList.filter(v => v.status === 'approved'));
        });
        
        return () => unsubscribe();
      } catch (error) {
        console.error('Error fetching vendors:', error);
        setError('Failed to load vendors.');
      }
    };
    
    fetchVendors();
  }, []);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setProductData({
      ...productData,
      [name]: value
    });
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    
    try {
      // Format the data correctly
      const formattedData = {
        ...productData,
        unitPrice: parseFloat(productData.unitPrice),
        stockQuantity: parseInt(productData.stockQuantity, 10),
        vendorName: vendors.find(v => v.id === productData.vendorId)?.businessName || '',
        status: ProductStatus.PENDING // New products are always pending review
      };
      
      await productService.addProduct(formattedData);
      setSuccess(true);
      setLoading(false);
      
      // Show success message then redirect
      setTimeout(() => {
        router.push('/catalogs');
      }, 2000);
    } catch (error: any) {
      console.error('Error adding product:', error);
      setError(error.message || 'Failed to add product.');
      setLoading(false);
    }
  };

  return (
    <>
      <Breadcrumb 
        pageName="Add New Product" 
        items={[{ href: '/catalogs', label: 'Catalogs' }]} 
      />
      
      <div className="grid grid-cols-1 gap-6">
        <div className="rounded-lg bg-white p-6 shadow-md dark:bg-boxdark">
          {success ? (
            <div className="flex flex-col items-center justify-center py-12">
              <div className="mb-4 rounded-full bg-green-100 p-3 text-green-600">
                <svg className="h-8 w-8" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                </svg>
              </div>
              <h2 className="mb-2 text-xl font-semibold">Product Added Successfully!</h2>
              <p className="text-center text-gray-600 dark:text-gray-400">
                Your product has been added and is pending approval.
              </p>
              <button
                onClick={() => router.push('/catalogs')}
                className="mt-6 rounded-lg bg-primary px-4 py-2 text-white"
              >
                Go to Catalog
              </button>
            </div>
          ) : (
            <form onSubmit={handleSubmit}>
              {error && (
                <div className="mb-6 rounded-lg bg-red-100 p-4 text-red-600">
                  {error}
                </div>
              )}
              
              <div className="mb-6 grid grid-cols-1 gap-6 md:grid-cols-2">
                <div>
                  <label className="mb-2 block text-sm font-medium">Part Name*</label>
                  <input
                    type="text"
                    name="partName"
                    value={productData.partName}
                    onChange={handleInputChange}
                    className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-700"
                    required
                  />
                </div>
                
                <div>
                  <label className="mb-2 block text-sm font-medium">Vendor*</label>
                  <select
                    name="vendorId"
                    value={productData.vendorId}
                    onChange={handleInputChange}
                    className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-700"
                    required
                  >
                    <option value="">Select a vendor</option>
                    {vendors.map(vendor => (
                      <option key={vendor.id} value={vendor.id}>
                        {vendor.businessName} - {vendor.name}
                      </option>
                    ))}
                  </select>
                </div>
                
                <div>
                  <label className="mb-2 block text-sm font-medium">Unit Price (UGX)*</label>
                  <input
                    type="number"
                    name="unitPrice"
                    value={productData.unitPrice}
                    onChange={handleInputChange}
                    className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-700"
                    required
                    min="0"
                  />
                </div>
                
                <div>
                  <label className="mb-2 block text-sm font-medium">Stock Quantity*</label>
                  <input
                    type="number"
                    name="stockQuantity"
                    value={productData.stockQuantity}
                    onChange={handleInputChange}
                    className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-700"
                    required
                    min="0"
                  />
                </div>
                
                <div>
                  <label className="mb-2 block text-sm font-medium">Brand</label>
                  <input
                    type="text"
                    name="brand"
                    value={productData.brand}
                    onChange={handleInputChange}
                    className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-700"
                  />
                </div>
                
                <div>
                  <label className="mb-2 block text-sm font-medium">Part Number</label>
                  <input
                    type="text"
                    name="partNumber"
                    value={productData.partNumber}
                    onChange={handleInputChange}
                    className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-700"
                  />
                </div>
                
                <div>
                  <label className="mb-2 block text-sm font-medium">Condition*</label>
                  <select
                    name="condition"
                    value={productData.condition}
                    onChange={handleInputChange}
                    className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-700"
                    required
                  >
                    <option value="new">New</option>
                    <option value="used">Used</option>
                    <option value="refurbished">Refurbished</option>
                  </select>
                </div>
                
                <div>
                  <label className="mb-2 block text-sm font-medium">Category</label>
                  <input
                    type="text"
                    name="category"
                    value={productData.category}
                    onChange={handleInputChange}
                    className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-700"
                  />
                </div>
                
                <div className="md:col-span-2">
                  <label className="mb-2 block text-sm font-medium">Vehicle Compatibility</label>
                  <input
                    type="text"
                    name="compatibility"
                    value={productData.compatibility}
                    onChange={handleInputChange}
                    className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-700"
                    placeholder="e.g., Toyota Corolla 2005-2010, Honda Accord 2008-2012"
                  />
                </div>
                
                <div className="md:col-span-2">
                  <label className="mb-2 block text-sm font-medium">Description*</label>
                  <textarea
                    name="description"
                    value={productData.description}
                    onChange={handleInputChange}
                    className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary dark:border-gray-600 dark:bg-gray-700"
                    rows={4}
                    required
                  ></textarea>
                </div>
                
                <div className="md:col-span-2">
                  <label className="mb-2 block text-sm font-medium">Product Images</label>
                  <div className="flex items-center justify-center w-full">
                    <label className="flex flex-col items-center justify-center w-full h-32 border-2 border-dashed rounded-lg cursor-pointer border-gray-300 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700">
                      <div className="flex flex-col items-center justify-center pt-5 pb-6">
                        <Upload className="w-8 h-8 mb-3 text-gray-500" />
                        <p className="mb-2 text-sm text-gray-500 dark:text-gray-400">
                          <span className="font-semibold">Click to upload</span> or drag and drop
                        </p>
                        <p className="text-xs text-gray-500 dark:text-gray-400">
                          PNG, JPG or WEBP (MAX. 5MB)
                        </p>
                      </div>
                      <input 
                        type="file" 
                        className="hidden" 
                        disabled={true} 
                        // Image upload would be implemented here with Firebase storage
                      />
                    </label>
                  </div>
                  <p className="mt-2 text-xs text-gray-500">
                    Image upload will be available in the next update.
                  </p>
                </div>
              </div>
              
              <div className="flex items-center justify-between">
                <button
                  type="button"
                  onClick={() => router.back()}
                  className="flex items-center rounded-lg border border-gray-300 px-4 py-2 hover:bg-gray-50 dark:border-gray-600 dark:hover:bg-gray-700"
                >
                  <ArrowLeft size={16} className="mr-2" />
                  Back
                </button>
                
                <button
                  type="submit"
                  className="flex items-center rounded-lg bg-primary px-4 py-2 text-white hover:bg-primary-dark disabled:bg-primary/70"
                  disabled={loading}
                >
                  {loading ? (
                    <>
                      <div className="mr-2 h-4 w-4 animate-spin rounded-full border-2 border-t-transparent border-white"></div>
                      Processing...
                    </>
                  ) : (
                    <>
                      <Save size={16} className="mr-2" />
                      Save Product
                    </>
                  )}
                </button>
              </div>
            </form>
          )}
        </div>
      </div>
    </>
  );
}