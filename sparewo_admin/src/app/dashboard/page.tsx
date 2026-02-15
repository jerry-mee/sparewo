// src/app/dashboard/page.tsx
"use client";

import React, { useEffect, useState } from "react";
import {
  Users,
  Package,
  CheckCircle,
  AlertCircle,
  Wrench,
  Store,
  Truck
} from 'lucide-react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { StatCard } from "@/components/ui/stat-card";
import { getTotalVendorCount } from "@/lib/firebase/vendors";
import { getTotalProductCount } from "@/lib/firebase/products";
import { getTotalClientCount } from "@/lib/firebase/clients";
import { getTotalBookingCount } from "@/lib/firebase/autohub";
import Link from "next/link";

export default function Dashboard() {
  const [stats, setStats] = useState({
    vendors: 0,
    products: 0,
    clients: 0,
    activeBookings: 0,
  });

  useEffect(() => {
    const fetchStats = async () => {
      try {
        // Fetch all counts in parallel
        const [
          totalVendors, 
          totalProducts,
          totalClients,
          activeBookings
        ] = await Promise.all([
          getTotalVendorCount(),
          getTotalProductCount(),
          getTotalClientCount(),
          getTotalBookingCount("pending") // Count only pending bookings for "Active Requests"
        ]);

        setStats({
          vendors: totalVendors,
          products: totalProducts,
          clients: totalClients, 
          activeBookings: activeBookings,
        });
      } catch (error) {
        console.error('Error fetching dashboard stats:', error);
      }
    };

    fetchStats();
  }, []);

  const recentActivity = [
    {
      id: '1',
      icon: <Users size={16} />,
      title: 'New vendor registration',
      description: 'Auto Parts Plus has registered as a new vendor',
      time: 'Just now',
      status: 'success',
    },
    {
      id: '2',
      icon: <Package size={16} />,
      title: 'New products added',
      description: '25 new products were uploaded by CarTech Solutions',
      time: '2 hours ago',
      status: 'success',
    },
    {
      id: '3',
      icon: <AlertCircle size={16} />,
      title: 'Product rejected',
      description: 'Brake pads from Mecha Parts were rejected',
      time: '5 hours ago',
      status: 'danger',
    },
    {
      id: '4',
      icon: <Wrench size={16} />,
      title: 'New Service Request',
      description: 'Service booking #BK-2024-001 needs assignment',
      time: 'Yesterday',
      status: 'warning',
    },
  ] as const;

  return (
    <div className="space-y-6">
      <div className="mb-6">
        <h1 className="text-2xl font-semibold">Dashboard</h1>
        <p className="mt-1 text-gray-500 dark:text-gray-400">
          Welcome back, here&apos;s what&apos;s happening with your platform today.
        </p>
      </div>

      {/* Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <StatCard
          title="Total Clients"
          value={stats.clients}
          change="+5%"
          icon={<Users className="h-6 w-6 text-white" />}
          color="bg-blue-600"
        />
        <StatCard
          title="Active Requests"
          value={stats.activeBookings}
          change="+2"
          icon={<Wrench className="h-6 w-6 text-white" />}
          color="bg-purple-600"
        />
        <StatCard
          title="Total Vendors"
          value={stats.vendors}
          change="+12%"
          icon={<Store className="h-6 w-6 text-white" />}
          color="bg-indigo-600"
        />
        <StatCard
          title="Products"
          value={stats.products}
          change="+8%"
          icon={<Package className="h-6 w-6 text-white" />}
          color="bg-orange-500"
        />
      </div>

      {/* Main Content */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Quick Actions */}
        <Card className="lg:col-span-1">
          <CardHeader>
            <CardTitle>Quick Actions</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <Link href="/dashboard/autohub">
              <Button variant="outline" className="flex items-center w-full justify-start">
                <Wrench size={18} className="mr-2" />
                Manage AutoHub
              </Button>
            </Link>
            <Link href="/dashboard/clients">
              <Button variant="outline" className="flex items-center w-full justify-start">
                <Users size={18} className="mr-2" />
                View Clients
              </Button>
            </Link>
            <Link href="/dashboard/vendors/pending">
              <Button variant="outline" className="flex items-center w-full justify-start">
                <CheckCircle size={18} className="mr-2" />
                Approve Vendors
              </Button>
            </Link>
            <Link href="/dashboard/orders">
              <Button variant="outline" className="flex items-center w-full justify-start">
                <Truck size={18} className="mr-2" />
                Process Orders
              </Button>
            </Link>
          </CardContent>
        </Card>

        {/* Recent Activity */}
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle>Recent Activity</CardTitle>
            <CardDescription>Latest actions in the system</CardDescription>
          </CardHeader>
          <CardContent>
            {recentActivity.map((activity) => (
              <ActivityItem
                key={activity.id}
                icon={activity.icon}
                title={activity.title}
                description={activity.description}
                time={activity.time}
                status={activity.status}
              />
            ))}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

// Activity Item Component
interface ActivityItemProps {
  icon: React.ReactNode;
  title: string;
  description: string;
  time: string;
  status: 'success' | 'warning' | 'danger';
}

const ActivityItem = ({ icon, title, description, time, status }: ActivityItemProps) => {
  const statusColors: Record<string, string> = {
    success: 'bg-green-500',
    warning: 'bg-amber-500',
    danger: 'bg-red-500'
  };

  return (
    <div className="flex items-start mb-4 pb-4 border-b border-gray-200 dark:border-gray-700 last:border-0">
      <div className={`${statusColors[status]} p-2 rounded-full mr-4 text-white flex-shrink-0`}>
        {icon}
      </div>
      <div className="flex-1 min-w-0">
        <h3 className="text-sm font-medium truncate">{title}</h3>
        <p className="text-xs text-gray-500 dark:text-gray-400 mt-1 truncate">{description}</p>
        <span className="text-xs text-gray-400 dark:text-gray-500 mt-1 block">{time}</span>
      </div>
    </div>
  );
};