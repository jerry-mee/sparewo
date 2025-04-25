'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/hooks/useAuth';
import Link from 'next/link';

export default function Home() {
  const router = useRouter();
  const { user, loading } = useAuth();

  useEffect(() => {
    if (!loading && !user) {
      router.push('/auth/sign-in');
    }
  }, [user, loading, router]);

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <p>Loading...</p>
      </div>
    );
  }

  if (!user) {
    return null;
  }

  return (
    <div className="flex min-h-screen flex-col items-center justify-center p-4 text-center">
      <h1 className="text-4xl font-bold mb-4">SpareWo Admin Dashboard</h1>
      <p className="text-xl mb-8">Vendor and Product Management</p>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 max-w-4xl">
        <Link href="/vendors" className="p-6 bg-blue-100 rounded-lg hover:bg-blue-200 transition-colors">
          <h2 className="text-2xl font-bold mb-2">Vendors</h2>
          <p>Manage vendor applications and approvals</p>
        </Link>
        <Link href="/products" className="p-6 bg-green-100 rounded-lg hover:bg-green-200 transition-colors">
          <h2 className="text-2xl font-bold mb-2">Products</h2>
          <p>Manage product catalog and approvals</p>
        </Link>
        <Link href="/catalogs" className="p-6 bg-purple-100 rounded-lg hover:bg-purple-200 transition-colors">
          <h2 className="text-2xl font-bold mb-2">Catalogs</h2>
          <p>Manage general and store catalogs</p>
        </Link>
        <Link href="/orders" className="p-6 bg-orange-100 rounded-lg hover:bg-orange-200 transition-colors">
          <h2 className="text-2xl font-bold mb-2">Orders</h2>
          <p>Track and manage customer orders</p>
        </Link>
      </div>
    </div>
  );
}