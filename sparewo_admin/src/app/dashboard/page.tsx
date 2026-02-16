"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import {
  AlertCircle,
  BellRing,
  Package,
  ShieldAlert,
  ShoppingCart,
  Store,
  Users,
  Wrench,
} from "lucide-react";

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { StatCard } from "@/components/ui/stat-card";
import { getTotalVendorCount, countVendorsByStatus } from "@/lib/firebase/vendors";
import { getTotalProductCount, countProductsByStatus } from "@/lib/firebase/products";
import { getTotalClientCount } from "@/lib/firebase/clients";
import { getTotalBookingCount } from "@/lib/firebase/autohub";
import { getOrderStats } from "@/lib/firebase/orders";

interface DashboardStats {
  vendors: number;
  products: number;
  clients: number;
  activeBookings: number;
  pendingOrders: number;
  pendingVendors: number;
  pendingProducts: number;
}

export default function Dashboard() {
  const [stats, setStats] = useState<DashboardStats>({
    vendors: 0,
    products: 0,
    clients: 0,
    activeBookings: 0,
    pendingOrders: 0,
    pendingVendors: 0,
    pendingProducts: 0,
  });

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const [
          totalVendors,
          totalProducts,
          totalClients,
          activeBookings,
          orderStats,
          pendingVendors,
          pendingProducts,
        ] = await Promise.all([
          getTotalVendorCount(),
          getTotalProductCount(),
          getTotalClientCount(),
          getTotalBookingCount("pending"),
          getOrderStats(),
          countVendorsByStatus("pending"),
          countProductsByStatus("pending"),
        ]);

        setStats({
          vendors: totalVendors,
          products: totalProducts,
          clients: totalClients,
          activeBookings,
          pendingOrders: orderStats.pending,
          pendingVendors,
          pendingProducts,
        });
      } catch (error) {
        console.error("Error fetching dashboard stats:", error);
      }
    };

    fetchStats();
  }, []);

  const alertRows = [
    {
      id: "pending-vendors",
      label: "Vendor approvals pending",
      count: stats.pendingVendors,
      href: "/dashboard/vendors/pending",
    },
    {
      id: "pending-products",
      label: "Product approvals pending",
      count: stats.pendingProducts,
      href: "/dashboard/products/pending",
    },
    {
      id: "pending-orders",
      label: "Orders waiting processing",
      count: stats.pendingOrders,
      href: "/dashboard/orders",
    },
  ];

  return (
    <div className="space-y-6">
      <div className="mb-1">
        <h1 className="text-3xl font-display">Operations Overview</h1>
        <p className="mt-1 text-muted-foreground">
          Monitor platform health and jump straight into operational workflows.
        </p>
      </div>

      <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-4">
        <StatCard
          title="Total Clients"
          value={stats.clients}
          icon={<Users className="h-6 w-6 text-white" />}
          color="bg-secondary"
        />
        <StatCard
          title="Active AutoHub Requests"
          value={stats.activeBookings}
          icon={<Wrench className="h-6 w-6 text-white" />}
          color="bg-primary"
        />
        <StatCard
          title="Approved Vendors"
          value={stats.vendors - stats.pendingVendors}
          icon={<Store className="h-6 w-6 text-white" />}
          color="bg-emerald-600"
        />
        <StatCard
          title="Catalog Products"
          value={stats.products}
          icon={<Package className="h-6 w-6 text-white" />}
          color="bg-sky-700"
        />
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        <Card className="lg:col-span-1">
          <CardHeader>
            <CardTitle>Quick Actions</CardTitle>
            <CardDescription>High-frequency operations</CardDescription>
          </CardHeader>
          <CardContent className="space-y-3">
            <Link href="/dashboard/autohub">
              <Button variant="outline" className="w-full justify-start">
                <Wrench className="mr-2 h-4 w-4" /> AutoHub Queue
              </Button>
            </Link>
            <Link href="/dashboard/orders">
              <Button variant="outline" className="w-full justify-start">
                <ShoppingCart className="mr-2 h-4 w-4" /> Track Orders
              </Button>
            </Link>
            <Link href="/dashboard/comms">
              <Button variant="outline" className="w-full justify-start">
                <BellRing className="mr-2 h-4 w-4" /> Send Communication
              </Button>
            </Link>
            <Link href="/dashboard/vendors/pending">
              <Button variant="outline" className="w-full justify-start">
                <ShieldAlert className="mr-2 h-4 w-4" /> Review Vendors
              </Button>
            </Link>
          </CardContent>
        </Card>

        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle>Priority Alerts</CardTitle>
            <CardDescription>Queues that need immediate attention</CardDescription>
          </CardHeader>
          <CardContent className="space-y-3">
            {alertRows.map((alert) => (
              <Link
                key={alert.id}
                href={alert.href}
                className="flex items-center justify-between rounded-lg border border-border bg-card px-4 py-3 transition-colors hover:bg-muted/50"
              >
                <div className="flex items-center gap-3">
                  <AlertCircle className="h-4 w-4 text-primary" />
                  <span className="text-sm">{alert.label}</span>
                </div>
                <span className="rounded-full bg-muted px-2.5 py-1 text-xs font-semibold">{alert.count}</span>
              </Link>
            ))}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
