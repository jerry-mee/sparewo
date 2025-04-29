"use client";

import React from "react";
import { 
  Users, 
  Package, 
  ShoppingCart, 
  Clock, 
  CheckCircle, 
  AlertCircle, 
  PlusCircle, 
  Truck 
} from 'lucide-react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";

export default function Dashboard() {
  // Sample stats
  const stats = {
    vendors: 156,
    vendorChange: "+12%",
    products: 1284,
    productChange: "+8%",
    pendingApprovals: 42,
    orders: 845,
    orderChange: "+28%"
  };

  // Sample activity feed
  const recentActivity: {
    id: string;
    icon: React.ReactNode;
    title: string;
    description: string;
    time: string;
    status: 'success' | 'warning' | 'danger';
  }[] = [
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
      icon: <ShoppingCart size={16} />,
      title: 'New order received',
      description: 'Order #10234 needs to be assigned to a vendor',
      time: 'Yesterday',
      status: 'warning',
    },
  ];

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
          title="Total Vendors" 
          value={stats.vendors} 
          change={stats.vendorChange} 
          icon={<Users className="h-6 w-6 text-white" />} 
          color="bg-indigo-600"
        />
        <StatCard 
          title="Products" 
          value={stats.products} 
          change={stats.productChange} 
          icon={<Package className="h-6 w-6 text-white" />} 
          color="bg-orange-500"
        />
        <StatCard 
          title="Pending Approvals" 
          value={stats.pendingApprovals} 
          change="-"
          icon={<Clock className="h-6 w-6 text-white" />} 
          color="bg-amber-500"
        />
        <StatCard 
          title="Total Orders" 
          value={stats.orders} 
          change={stats.orderChange} 
          icon={<ShoppingCart className="h-6 w-6 text-white" />} 
          color="bg-green-600"
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
            <Button 
              variant="outline" 
              className="flex items-center w-full justify-start"
            >
              <PlusCircle size={18} className="mr-2" />
              Add New Vendor
            </Button>
            <Button 
              variant="outline" 
              className="flex items-center w-full justify-start"
            >
              <Package size={18} className="mr-2" />
              Review Products
            </Button>
            <Button 
              variant="outline" 
              className="flex items-center w-full justify-start"
            >
              <Truck size={18} className="mr-2" />
              Process Orders
            </Button>
            <Button 
              variant="outline" 
              className="flex items-center w-full justify-start"
            >
              <CheckCircle size={18} className="mr-2" />
              Approve Vendors
            </Button>
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

// Stat Card Component
interface StatCardProps {
  title: string;
  value: number | string;
  change?: string;
  icon: React.ReactNode;
  color: string;
}

const StatCard = ({ title, value, change, icon, color }: StatCardProps) => {
  return (
    <Card>
      <CardContent className="p-6">
        <div className="flex items-center">
          <div className={`p-3 rounded-full ${color} mr-4`}>
            {icon}
          </div>
          <div>
            <p className="text-sm font-medium text-gray-500 dark:text-gray-400">{title}</p>
            <p className="text-2xl font-semibold">{value}</p>
            {change && (
              <div className="flex items-center mt-1">
                <span className="text-xs font-medium text-green-500">
                  {change}
                </span>
                <span className="text-xs ml-1 text-gray-500 dark:text-gray-400">from last month</span>
              </div>
            )}
          </div>
        </div>
      </CardContent>
    </Card>
  );
};

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
      <div className={`${statusColors[status]} p-2 rounded-full mr-4 text-white`}>
        {icon}
      </div>
      <div className="flex-1">
        <h3 className="text-sm font-medium">{title}</h3>
        <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">{description}</p>
        <span className="text-xs text-gray-400 dark:text-gray-500 mt-1 block">{time}</span>
      </div>
    </div>
  );
};