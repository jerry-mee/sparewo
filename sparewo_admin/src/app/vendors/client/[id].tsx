'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { vendorService, VendorStatus } from '@/services/firebase.service';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardHeader, CardTitle, CardContent, CardFooter } from '@/components/ui/card';
import { Store, Edit, ArrowLeft, Check, X } from 'lucide-react';
import LoadingScreen from '@/components/LoadingScreen';

export default function VendorClientPage({ params }: { params: { id: string } }) {
  const [vendor, setVendor] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchVendor = async () => {
      try {
        const vendorData = await vendorService.getVendor(params.id);
        setVendor(vendorData);
      } catch (error: any) {
        console.error('Error fetching vendor:', error);
        setError(error.message || 'Failed to load vendor details');
      } finally {
        setLoading(false);
      }
    };

    fetchVendor();
  }, [params.id]);

  if (loading) return <LoadingScreen />;
  
  if (error || !vendor) {
    return (
      <div className="container mx-auto px-4 py-8">
        <Link href="/vendors" className="inline-flex items-center text-primary mb-6 hover:underline">
          <ArrowLeft className="mr-2 h-4 w-4" />
          Back to Vendors
        </Link>
        
        <Card>
          <CardHeader>
            <CardTitle className="text-red-600 dark:text-red-400">
              {error ? 'Error Loading Vendor' : 'Vendor Not Found'}
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p>{error || `Vendor ${params.id} could not be found.`}</p>
          </CardContent>
          <CardFooter>
            <Button onClick={() => window.location.reload()}>Try Again</Button>
          </CardFooter>
        </Card>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <Link href="/vendors" className="inline-flex items-center text-primary mb-6 hover:underline">
        <ArrowLeft className="mr-2 h-4 w-4" />
        Back to Vendors
      </Link>
      
      <div className="rounded-lg bg-white p-6 shadow-sm dark:bg-boxdark">
        <h1 className="text-2xl font-bold">{vendor.businessName || 'Vendor Details'}</h1>
        <p className="mt-2">ID: {params.id}</p>
        <Badge className="mt-2">{vendor.status}</Badge>
      </div>
      
      {/* Simplified vendor details for demo */}
      <div className="mt-6 grid grid-cols-1 gap-6 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Vendor Information</CardTitle>
          </CardHeader>
          <CardContent>
            <p><strong>Contact:</strong> {vendor.name}</p>
            <p><strong>Email:</strong> {vendor.email}</p>
            <p><strong>Phone:</strong> {vendor.phone || 'N/A'}</p>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
