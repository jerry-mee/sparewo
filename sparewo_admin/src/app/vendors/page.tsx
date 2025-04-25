'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { vendorService, VendorStatus } from '@/services/firebase.service';
import { Eye, UserPlus, Check, X, AlertCircle, Clock } from 'lucide-react';

interface Vendor {
  id: string;
  name: string;
  email: string;
  phone: string;
  businessName: string;
  businessAddress: string;
  status: VendorStatus;
  isVerified: boolean;
  createdAt: any;
  [key: string]: any;
}

export default function VendorsPage() {
  const [vendors, setVendors] = useState<Vendor[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('all');
  const [statusUpdating, setStatusUpdating] = useState<string | null>(null);

  useEffect(() => {
    const unsubscribe = vendorService.listenToVendors((vendorsList) => {
      setVendors(vendorsList as Vendor[]);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const filteredVendors = filter === 'all' 
    ? vendors 
    : vendors.filter(vendor => vendor.status === filter);

  const handleStatusChange = async (id: string, newStatus: string) => {
    try {
      setStatusUpdating(id);
      await vendorService.updateVendorStatus(id, newStatus as VendorStatus);
      setStatusUpdating(null);
    } catch (error) {
      console.error('Error updating vendor status:', error);
      setStatusUpdating(null);
    }
  };

  // Format date nicely
  const formatDate = (timestamp: any) => {
    if (!timestamp) return 'N/A';
    const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
    return date.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  };

  const getStatusBadge = (status: VendorStatus) => {
    switch (status) {
      case VendorStatus.APPROVED:
        return <span className="badge badge-success">Approved</span>;
      case VendorStatus.PENDING:
        return <span className="badge badge-pending">Pending</span>;
      case VendorStatus.REJECTED:
        return <span className="badge badge-danger">Rejected</span>;
      case VendorStatus.SUSPENDED:
        return <span className="badge badge-suspended">Suspended</span>;
      default:
        return <span className="badge">{status}</span>;
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-800 dark:text-white">Vendors</h1>
          <p className="text-sm text-gray-500">Manage all SpareWo vendors and their details</p>
        </div>
        
        <div className="flex flex-wrap gap-3">
          <select
            className="chart-filter"
            value={filter}
            onChange={(e) => setFilter(e.target.value)}
          >
            <option value="all">All Statuses</option>
            <option value={VendorStatus.PENDING}>Pending</option>
            <option value={VendorStatus.APPROVED}>Approved</option>
            <option value={VendorStatus.REJECTED}>Rejected</option>
            <option value={VendorStatus.SUSPENDED}>Suspended</option>
          </select>
          
          <Link 
            href="/vendors/new"
            className="flex items-center rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary-dark"
          >
            <UserPlus size={16} className="mr-2" />
            Add Vendor
          </Link>
        </div>
      </div>
      
      <div className="dashboard-card">
        <div className="overflow-x-auto">
          <table className="w-full table-auto">
            <thead className="bg-gray-50 dark:bg-boxdark-2">
              <tr className="border-b border-gray-200 dark:border-gray-700">
                <th className="whitespace-nowrap p-4 text-left font-medium text-gray-700 dark:text-gray-300">
                  Business Details
                </th>
                <th className="whitespace-nowrap p-4 text-left font-medium text-gray-700 dark:text-gray-300">
                  Contact Info
                </th>
                <th className="whitespace-nowrap p-4 text-left font-medium text-gray-700 dark:text-gray-300">
                  Registration Date
                </th>
                <th className="whitespace-nowrap p-4 text-left font-medium text-gray-700 dark:text-gray-300">
                  Status
                </th>
                <th className="whitespace-nowrap p-4 text-left font-medium text-gray-700 dark:text-gray-300">
                  Verification
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
              ) : filteredVendors.length === 0 ? (
                <tr>
                  <td colSpan={6} className="p-4 text-center text-gray-500">
                    No vendors found
                  </td>
                </tr>
              ) : (
                filteredVendors.map((vendor) => (
                  <tr key={vendor.id} className="border-b border-gray-100 hover:bg-gray-50 dark:border-gray-700 dark:hover:bg-boxdark-2">
                    <td className="p-4">
                      <div>
                        <h5 className="font-medium text-gray-800 dark:text-white">
                          {vendor.businessName || 'N/A'}
                        </h5>
                        <p className="text-sm text-gray-500">
                          {vendor.businessAddress || 'No address provided'}
                        </p>
                      </div>
                    </td>
                    <td className="p-4">
                      <div>
                        <p className="font-medium text-gray-700 dark:text-gray-300">{vendor.name}</p>
                        <p className="text-sm text-gray-500">{vendor.email}</p>
                        <p className="text-sm text-gray-500">{vendor.phone || 'No phone'}</p>
                      </div>
                    </td>
                    <td className="p-4">
                      <p className="text-gray-700 dark:text-gray-300">{formatDate(vendor.createdAt)}</p>
                    </td>
                    <td className="p-4">
                      {getStatusBadge(vendor.status)}
                    </td>
                    <td className="p-4">
                      <div className="flex flex-col gap-1">
                        <span className={`text-xs ${vendor.isEmailVerified ? 'text-green-600' : 'text-gray-500'}`}>
                          Email: {vendor.isEmailVerified ? 'Verified' : 'Not Verified'}
                        </span>
                        <span className={`text-xs ${vendor.isVerified ? 'text-green-600' : 'text-gray-500'}`}>
                          Account: {vendor.isVerified ? 'Verified' : 'Not Verified'}
                        </span>
                      </div>
                    </td>
                    <td className="p-4">
                      <div className="flex items-center space-x-3.5">
                        {statusUpdating === vendor.id ? (
                          <div className="h-4 w-4 border-2 border-primary border-t-transparent spin"></div>
                        ) : (
                          <>
                            <select 
                              className="chart-filter text-xs"
                              value={vendor.status}
                              onChange={(e) => handleStatusChange(vendor.id, e.target.value)}
                            >
                              <option value={VendorStatus.PENDING}>Pending</option>
                              <option value={VendorStatus.APPROVED}>Approve</option>
                              <option value={VendorStatus.REJECTED}>Reject</option>
                              <option value={VendorStatus.SUSPENDED}>Suspend</option>
                            </select>
                            
                            <Link href={`/vendors/${vendor.id}`} className="text-gray-500 hover:text-primary">
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