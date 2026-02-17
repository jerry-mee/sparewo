"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import {
  AlertCircle,
  BellRing,
  ChevronRight,
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
import { formatCurrency, formatDate } from "@/lib/utils";
import { useAuth } from "@/lib/context/auth-context";
import { normalizeRole } from "@/lib/auth/roles";
import { auth } from "@/lib/firebase/config";

interface DashboardStats {
  vendors: number;
  products: number;
  clients: number;
  activeBookings: number;
  pendingOrders: number;
  pendingVendors: number;
  pendingProducts: number;
}

interface RecentOrder {
  id: string;
  orderNumber: string;
  customerName: string;
  totalAmount: number;
  status: string;
  createdAt: Date | string | number | { toDate(): Date } | null | undefined;
}

export default function Dashboard() {
  const { adminData, user } = useAuth();
  const currentRole = normalizeRole(adminData?.role);
  const canViewClients = currentRole === "Administrator" || currentRole === "Manager";
  const canViewVendors = currentRole === "Administrator" || currentRole === "Manager";
  const canViewComms = currentRole === "Administrator" || currentRole === "Manager";

  const [stats, setStats] = useState<DashboardStats>({
    vendors: 0,
    products: 0,
    clients: 0,
    activeBookings: 0,
    pendingOrders: 0,
    pendingVendors: 0,
    pendingProducts: 0,
  });
  const [recentOrders, setRecentOrders] = useState<RecentOrder[]>([]);

  useEffect(() => {
    const fetchStats = async () => {
      if (!user) return;
      try {
        const token = await auth.currentUser?.getIdToken();
        if (!token) return;

        const response = await fetch("/api/dashboard/overview", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${token}`,
          },
        });

        if (!response.ok) {
          throw new Error("Failed to load dashboard metrics");
        }

        const json = await response.json();
        setStats(json.stats);
        setRecentOrders(json.latestOrders || []);
      } catch (error) {
        console.error("Error fetching dashboard stats:", error);
      }
    };

    void fetchStats();
  }, [user]);

  const alertRows = [
    ...(canViewVendors
      ? [{
          id: "pending-vendors",
          label: "Vendor approvals pending",
          count: stats.pendingVendors,
          href: "/dashboard/vendors/pending",
        }]
      : []),
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

  const getStatusClass = (status: string) => {
    const styles: Record<string, string> = {
      pending: "bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400",
      processing: "bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400",
      shipped: "bg-purple-100 text-purple-800 dark:bg-purple-900/30 dark:text-purple-400",
      delivered: "bg-indigo-100 text-indigo-800 dark:bg-indigo-900/30 dark:text-indigo-400",
      completed: "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400",
      cancelled: "bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400",
    };

    return styles[status] || "bg-gray-100 text-gray-800";
  };

  return (
    <div className="space-y-6">
      <div className="mb-1">
        <h1 className="text-3xl font-display">Operations Overview</h1>
        <p className="mt-1 text-muted-foreground">
          Monitor platform health and jump straight into operational workflows.
        </p>
      </div>

      <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-4">
        {canViewClients && (
          <StatCard
            title="Total Clients"
            value={stats.clients}
            icon={<Users className="h-6 w-6 text-white" />}
            color="bg-secondary"
            href="/dashboard/clients"
          />
        )}
        <StatCard
          title="Active AutoHub Requests"
          value={stats.activeBookings}
          icon={<Wrench className="h-6 w-6 text-white" />}
          color="bg-primary"
          href="/dashboard/autohub"
        />
        {canViewVendors && (
          <StatCard
            title="Approved Vendors"
            value={stats.vendors - stats.pendingVendors}
            icon={<Store className="h-6 w-6 text-white" />}
            color="bg-emerald-600"
            href="/dashboard/vendors"
          />
        )}
        <StatCard
          title="Catalog Products"
          value={stats.products}
          icon={<Package className="h-6 w-6 text-white" />}
          color="bg-sky-700"
          href="/dashboard/products"
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
            {canViewComms && (
              <Link href="/dashboard/comms">
                <Button variant="outline" className="w-full justify-start">
                  <BellRing className="mr-2 h-4 w-4" /> Send Communication
                </Button>
              </Link>
            )}
            {canViewVendors && (
              <Link href="/dashboard/vendors/pending">
                <Button variant="outline" className="w-full justify-start">
                  <ShieldAlert className="mr-2 h-4 w-4" /> Review Vendors
                </Button>
              </Link>
            )}
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

      <Card>
        <CardHeader className="flex flex-row items-center justify-between gap-3">
          <div>
            <CardTitle>Latest Orders</CardTitle>
            <CardDescription>Open any order to continue processing immediately.</CardDescription>
          </div>
          <Link href="/dashboard/orders">
            <Button variant="ghost" className="gap-1">
              View all <ChevronRight className="h-4 w-4" />
            </Button>
          </Link>
        </CardHeader>
        <CardContent className="space-y-2">
          {recentOrders.length === 0 ? (
            <p className="text-sm text-muted-foreground">No orders yet.</p>
          ) : (
            recentOrders.map((order) => (
              <Link
                key={order.id}
                href={`/dashboard/orders/${order.id}`}
                className="flex flex-wrap items-center justify-between gap-3 rounded-lg border border-border bg-card px-4 py-3 transition-colors hover:bg-muted/50"
              >
                <div className="min-w-0">
                  <p className="text-sm font-medium">{order.orderNumber || order.id.slice(0, 8)}</p>
                  <p className="truncate text-xs text-muted-foreground">
                    {order.customerName} • {formatDate(order.createdAt)}
                  </p>
                </div>
                <div className="flex items-center gap-2">
                  <span className={`inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${getStatusClass(order.status)}`}>
                    {order.status}
                  </span>
                  <span className="text-sm font-semibold">{formatCurrency(order.totalAmount || 0)}</span>
                  <ChevronRight className="h-4 w-4 text-muted-foreground" />
                </div>
              </Link>
            ))
          )}
        </CardContent>
      </Card>
    </div>
  );
}
