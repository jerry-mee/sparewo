'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { vendorService, VendorStatus } from '@/services/firebase.service';
import { CheckCircle, XCircle, Eye, AlertTriangle, Clock, Store, Mail, Phone, MapPin } from 'lucide-react';

// Helper function to format dates
const formatDate = (timestamp: any) => {
  if (!timestamp) return 'N/A';
  const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  });
};

interface Vendor {
  id: string;
  name: string;
  email: string;
  phone: string;
  businessName: string;
  businessAddress: string;
  status: VendorStatus;
  isVerified: boolean;
  isEmailVerified: boolean;
  createdAt: any;
  [key: string]: any;
}

export default function PendingVendorsPage() {
  const [vendors, setVendors] = useState<Vendor[]>([]);
  const [loading, setLoading] = useState(true);
  const [statusUpdating, setStatusUpdating] = useState<string | null>(null);
  const [feedback, setFeedback] = useState<{message: string, type: 'success' | 'error'} | null>(null);
  const [selectedVendor, setSelectedVendor] = useState<Vendor | null>(null);

  useEffect(() => {
    const fetchPendingVendors = async () => {
      try {
        const pendingVendors = await vendorService.getPendingVendors();
        setVendors(pendingVendors as Vendor[]);
        
        // Auto-select the first vendor if available
        if (pendingVendors.length > 0) {
          setSelectedVendor(pendingVendors[0] as Vendor);
        }
        
        setLoading(false);
      } catch (error) {
        console.error('Error fetching pending vendors:', error);
        setLoading(false);
      }
    };

    fetchPendingVendors();
  }, []);

  const handleStatusChange = async (id: string, newStatus: string) => {
    try {
      setStatusUpdating(id);
      await vendorService.updateVendorStatus(id, newStatus as VendorStatus);
      
      // Remove this vendor from the list and update selection
      const updatedVendors = vendors.filter(vendor => vendor.id !== id);
      setVendors(updatedVendors);
      
      // Update selected vendor if the current one was approved/rejected
      if (selectedVendor && selectedVendor.id === id) {
        setSelectedVendor(updatedVendors.length > 0 ? updatedVendors[0] : null);
      }
      
      setStatusUpdating(null);
      
      // Show success message
      setFeedback({
        message: `Vendor ${newStatus === VendorStatus.APPROVED ? 'approved' : 'rejected'} successfully`,
        type: 'success'
      });
      
      // Clear feedback after 3 seconds
      setTimeout(() => setFeedback(null), 3000);
    } catch (error) {
      console.error('Error updating vendor status:', error);
      setStatusUpdating(null);
      
      // Show error message
      setFeedback({
        message: `Failed to update vendor status`,
        type: 'error'
      });
      
      // Clear feedback after 3 seconds
      setTimeout(() => setFeedback(null), 3000);
    }
  };

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-800 dark:text-white">Pending Vendors</h1>
          <p className="text-sm text-gray-500">Review and approve vendor applications</p>
        </div>
        
        <div className="flex items-center gap-2 rounded-full bg-yellow-100 px-3 py-1.5 text-sm text-yellow-700">
          <Clock size={16} />
          <span>{vendors.length} pending review</span>
        </div>
      </div>

      {/* Feedback Toast */}
      {feedback && (
        <div className={`fixed top-20 right-4 z-50 rounded-lg px-4 py-3 shadow-lg ${
          feedback.type === 'success' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
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

      {loading ? (
        <div className="flex h-60 items-center justify-center">
          <div className="h-10 w-10 animate-spin rounded-full border-4 border-primary border-t-transparent"></div>
        </div>
      ) : vendors.length === 0 ? (
        <div className="flex flex-col items-center justify-center rounded-xl border border-gray-200 bg-white p-8 py-16 shadow-sm dark:border-gray-700 dark:bg-boxdark">
          <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-green-100 text-green-500">
            <CheckCircle size={32} />
          </div>
          <h2 className="mb-2 text-xl font-semibold text-gray-800 dark:text-white">All Caught Up!</h2>
          <p className="max-w-md text-center text-gray-500">
            There are no pending vendor applications to review at this time.
          </p>
          <Link 
            href="/vendors" 
            className="mt-6 rounded-lg bg-primary px-4 py-2 text-white transition-colors hover:bg-primary-dark"
          >
            View All Vendors
          </Link>
        </div>
      ) : (
        <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
          {/* Vendors List */}
          <div className="rounded-xl border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-boxdark">
            <div className="border-b border-gray-200 p-4 dark:border-gray-700">
              <h2 className="font-semibold text-gray-800 dark:text-white">Pending Applications</h2>
            </div>
            
            <div className="divide-y divide-gray-200 dark:divide-gray-700">
              {vendors.map((vendor) => (
                <div 
                  key={vendor.id}
                  className={`cursor-pointer p-4 transition-colors hover:bg-gray-50 dark:hover:bg-gray-800 ${
                    selectedVendor?.id === vendor.id ? 'bg-primary/5 dark:bg-primary/10' : ''
                  }`}
                  onClick={() => setSelectedVendor(vendor)}
                >
                  <div className="mb-2 flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary/10 text-primary">
                        <Store size={20} />
                      </div>
                      <div>
                        <h3 className="font-medium text-gray-800 dark:text-white">{vendor.businessName}</h3>
                        <p className="text-xs text-gray-500">{vendor.name}</p>
                      </div>
                    </div>
                    <span className="flex items-center rounded-full bg-yellow-100 px-2 py-0.5 text-xs font-medium text-yellow-600">
                      <Clock size={12} className="mr-1" />
                      Pending
                    </span>
                  </div>
                  <div className="mt-2 flex justify-between text-sm text-gray-500">
                    <span>{formatDate(vendor.createdAt)}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
          
          {/* Vendor Detail */}
          {selectedVendor ? (
            <div className="lg:col-span-2">
              <div className="rounded-xl border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-boxdark">
                <div className="border-b border-gray-200 p-6 dark:border-gray-700">
                  <div className="flex flex-wrap items-center justify-between gap-4">
                    <div className="flex items-center gap-4">
                      <div className="flex h-16 w-16 items-center justify-center rounded-full bg-primary/10 text-primary">
                        <Store size={32} />
                      </div>
                      <div>
                        <h2 className="text-xl font-semibold text-gray-800 dark:text-white">
                          {selectedVendor.businessName}
                        </h2>
                        <p className="text-sm text-gray-500">
                          Application submitted on {formatDate(selectedVendor.createdAt)}
                        </p>
                      </div>
                    </div>
                    
                    <div className="flex gap-2">
                      {statusUpdating === selectedVendor.id ? (
                        <div className="flex h-10 items-center rounded-lg bg-gray-100 px-4 dark:bg-gray-800">
                          <div className="mr-2 h-4 w-4 animate-spin rounded-full border-2 border-primary border-t-transparent"></div>
                          <span>Processing...</span>
                        </div>
                      ) : (
                        <>
                          <button
                            onClick={() => handleStatusChange(selectedVendor.id, VendorStatus.APPROVED)}
                            className="flex items-center gap-2 rounded-lg bg-green-600 px-4 py-2 text-white transition-colors hover:bg-green-700"
                          >
                            <CheckCircle size={16} />
                            Approve
                          </button>
                          <button
                            onClick={() => handleStatusChange(selectedVendor.id, VendorStatus.REJECTED)}
                            className="flex items-center gap-2 rounded-lg bg-red-600 px-4 py-2 text-white transition-colors hover:bg-red-700"
                          >
                            <XCircle size={16} />
                            Reject
                          </button>
                          <Link
                            href={`/vendors/${selectedVendor.id}`}
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
                    {/* Business Information */}
                    <div className="rounded-lg bg-gray-50 p-4 dark:bg-gray-800">
                      <h3 className="mb-4 font-semibold text-gray-700 dark:text-gray-300">Business Information</h3>
                      
                      <div className="space-y-4">
                        <div className="flex items-start gap-3">
                          <Store className="mt-0.5 h-5 w-5 text-gray-400" />
                          <div>
                            <p className="text-sm font-medium text-gray-500">Business Name</p>
                            <p className="text-gray-800 dark:text-gray-200">{selectedVendor.businessName}</p>
                          </div>
                        </div>
                        
                        <div className="flex items-start gap-3">
                          <MapPin className="mt-0.5 h-5 w-5 text-gray-400" />
                          <div>
                            <p className="text-sm font-medium text-gray-500">Business Address</p>
                            <p className="text-gray-800 dark:text-gray-200">
                              {selectedVendor.businessAddress || 'Not provided'}
                            </p>
                          </div>
                        </div>
                        
                        {selectedVendor.businessType && (
                          <div className="flex items-start gap-3">
                            <Store className="mt-0.5 h-5 w-5 text-gray-400" />
                            <div>
                              <p className="text-sm font-medium text-gray-500">Business Type</p>
                              <p className="text-gray-800 dark:text-gray-200">{selectedVendor.businessType}</p>
                            </div>
                          </div>
                        )}
                      </div>
                    </div>
                    
                    {/* Contact Information */}
                    <div className="rounded-lg bg-gray-50 p-4 dark:bg-gray-800">
                      <h3 className="mb-4 font-semibold text-gray-700 dark:text-gray-300">Contact Information</h3>
                      
                      <div className="space-y-4">
                        <div className="flex items-start gap-3">
                          <Store className="mt-0.5 h-5 w-5 text-gray-400" />
                          <div>
                            <p className="text-sm font-medium text-gray-500">Contact Person</p>
                            <p className="text-gray-800 dark:text-gray-200">{selectedVendor.name}</p>
                          </div>
                        </div>
                        
                        <div className="flex items-start gap-3">
                          <Mail className="mt-0.5 h-5 w-5 text-gray-400" />
                          <div>
                            <p className="text-sm font-medium text-gray-500">Email</p>
                            <p className="text-gray-800 dark:text-gray-200">{selectedVendor.email}</p>
                          </div>
                        </div>
                        
                        <div className="flex items-start gap-3">
                          <Phone className="mt-0.5 h-5 w-5 text-gray-400" />
                          <div>
                            <p className="text-sm font-medium text-gray-500">Phone</p>
                            <p className="text-gray-800 dark:text-gray-200">
                              {selectedVendor.phone || 'Not provided'}
                            </p>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                  
                  {/* Verification Status */}
                  <div className="mt-6 rounded-lg bg-gray-50 p-4 dark:bg-gray-800">
                    <h3 className="mb-4 font-semibold text-gray-700 dark:text-gray-300">Verification Status</h3>
                    
                    <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
                      <div className="flex items-center justify-between rounded-lg border border-gray-200 p-3 dark:border-gray-700">
                        <span className="text-sm text-gray-600 dark:text-gray-300">Email Verified</span>
                        <span className={`flex items-center text-sm ${selectedVendor.isEmailVerified ? 'text-green-600' : 'text-red-600'}`}>
                          {selectedVendor.isEmailVerified ? (
                            <>
                              <CheckCircle size={14} className="mr-1" />
                              Yes
                            </>
                          ) : (
                            <>
                              <XCircle size={14} className="mr-1" />
                              No
                            </>
                          )}
                        </span>
                      </div>
                      
                      <div className="flex items-center justify-between rounded-lg border border-gray-200 p-3 dark:border-gray-700">
                        <span className="text-sm text-gray-600 dark:text-gray-300">ID Verification</span>
                        <span className={`flex items-center text-sm ${selectedVendor.isVerified ? 'text-green-600' : 'text-red-600'}`}>
                          {selectedVendor.isVerified ? (
                            <>
                              <CheckCircle size={14} className="mr-1" />
                              Yes
                            </>
                          ) : (
                            <>
                              <XCircle size={14} className="mr-1" />
                              No
                            </>
                          )}
                        </span>
                      </div>
                      
                      <div className="flex items-center justify-between rounded-lg border border-gray-200 p-3 dark:border-gray-700">
                        <span className="text-sm text-gray-600 dark:text-gray-300">Business License</span>
                        <span className={`flex items-center text-sm ${selectedVendor.hasBusinessLicense ? 'text-green-600' : 'text-red-600'}`}>
                          {selectedVendor.hasBusinessLicense ? (
                            <>
                              <CheckCircle size={14} className="mr-1" />
                              Yes
                            </>
                          ) : (
                            <>
                              <XCircle size={14} className="mr-1" />
                              No
                            </>
                          )}
                        </span>
                      </div>
                    </div>
                  </div>
                  
                  {/* Business Description */}
                  {selectedVendor.description && (
                    <div className="mt-6 rounded-lg bg-gray-50 p-4 dark:bg-gray-800">
                      <h3 className="mb-2 font-semibold text-gray-700 dark:text-gray-300">Business Description</h3>
                      <p className="text-gray-700 dark:text-gray-300">{selectedVendor.description}</p>
                    </div>
                  )}
                </div>
              </div>
            </div>
          ) : (
            <div className="flex items-center justify-center rounded-xl border border-gray-200 bg-white p-8 dark:border-gray-700 dark:bg-boxdark lg:col-span-2">
              <div className="text-center">
                <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-gray-100 text-gray-400 dark:bg-gray-800">
                  <Store size={32} />
                </div>
                <h3 className="mb-1 text-lg font-medium">Select a Vendor</h3>
                <p className="text-gray-500">
                  Select a vendor from the list to review their application details.
                </p>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}