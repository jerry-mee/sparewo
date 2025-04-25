'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { productService, ProductStatus } from '@/services/firebase.service';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardHeader, CardTitle, CardContent, CardFooter } from '@/components/ui/card';
import { Package, Edit, ArrowLeft, Check, X, Image as ImageIcon } from 'lucide-react';
import LoadingScreen from '@/components/LoadingScreen';

export default function ProductClientPage({ params }: { params: { id: string } }) {
  const [product, setProduct] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchProduct = async () => {
      try {
        const productData = await productService.getProduct(params.id);
        setProduct(productData);
      } catch (error: any) {
        console.error('Error fetching product:', error);
        setError(error.message || 'Failed to load product details');
      } finally {
        setLoading(false);
      }
    };

    fetchProduct();
  }, [params.id]);

  if (loading) return <LoadingScreen />;
  
  if (error || !product) {
    return (
      <div className="container mx-auto px-4 py-8">
        <Link href="/products" className="inline-flex items-center text-primary mb-6 hover:underline">
          <ArrowLeft className="mr-2 h-4 w-4" />
          Back to Products
        </Link>
        
        <Card>
          <CardHeader>
            <CardTitle className="text-red-600 dark:text-red-400">
              {error ? 'Error Loading Product' : 'Product Not Found'}
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p>{error || `Product ${params.id} could not be found.`}</p>
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
      <Link href="/products" className="inline-flex items-center text-primary mb-6 hover:underline">
        <ArrowLeft className="mr-2 h-4 w-4" />
        Back to Products
      </Link>
      
      <div className="rounded-lg bg-white p-6 shadow-sm dark:bg-boxdark">
        <h1 className="text-2xl font-bold">{product.name || 'Product Details'}</h1>
        <p className="mt-2">ID: {params.id}</p>
        <Badge className="mt-2">{product.status}</Badge>
      </div>
      
      {/* Simplified product details for demo */}
      <div className="mt-6 grid grid-cols-1 gap-6 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Product Information</CardTitle>
          </CardHeader>
          <CardContent>
            <p><strong>Price:</strong> {product.price}</p>
            <p><strong>Vendor:</strong> {product.vendorName}</p>
            <p><strong>Description:</strong> {product.description}</p>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
