
"use client";

import React, { useState, useEffect } from "react";
import { Container } from "@/components/ui/container";
import { StatCard } from "@/components/ui/stat-card";
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { vendorService, productService, orderService } from "@/services/firebase.service";
import { Users, Package, ShoppingBag, TrendingUp, ChevronRight, Calendar, AlertCircle } from "lucide-react";
import Link from "next/link";
import dynamic from "next/dynamic";

// Lazy load ApexCharts component to prevent SSR issues
const Chart = dynamic(() => import("react-apexcharts"), { ssr: false });

// Type definitions
interface DashboardStats {
  pendingVendors: number;
  totalVendors: number;
  pendingProducts: number;
  totalProducts: number;
  activeOrders: number;
  totalOrders: number;
  totalSales: number;
  garageRequests: number;
}

interface Activity {
  id: number;
  type: "order" | "vendor" | "product" | "system";
  message: string;
  time: string;
  icon: React.ReactNode;
}

export default function Home() {
  const [stats, setStats] = useState<DashboardStats>({
    pendingVendors: 0,
    totalVendors: 0,
    pendingProducts: 0,
    totalProducts: 0,
    activeOrders: 0,
    totalOrders: 0,
    totalSales: 0,
    garageRequests: 0,
  });
  
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [chartTimeframe, setChartTimeframe] = useState("monthly");

  useEffect(() => {
    const fetchData = async () => {
      try {
        // Fetch vendors data
        const vendorsUnsubscribe = vendorService.listenToVendors((vendors: any[]) => {
          const pendingVendors = vendors.filter(v => v.status === "pending").length;
          setStats(prev => ({...prev, pendingVendors, totalVendors: vendors.length}));
        });
        
        // Fetch products data
        const productsUnsubscribe = productService.listenToProducts((products: any[]) => {
          const pendingProducts = products.filter(p => p.status === "pending").length;
          setStats(prev => ({...prev, pendingProducts, totalProducts: products.length}));
        });
        
        // Fetch orders data
        const ordersUnsubscribe = orderService.listenToOrders((orders: any[]) => {
          const activeOrders = orders.filter(o => o.status !== "delivered" && o.status !== "cancelled").length;
          const totalSales = orders.reduce((sum, order) => sum + (order.totalAmount || 0), 0);
          
          setStats(prev => ({
            ...prev, 
            activeOrders, 
            totalOrders: orders.length,
            totalSales
          }));
        });
        
        // Simulated garage requests for now
        setStats(prev => ({
          ...prev,
          garageRequests: 5 // Simulated number - replace with actual count
        }));
        
        setLoading(false);
        
        // Cleanup
        return () => {
          vendorsUnsubscribe();
          productsUnsubscribe();
          ordersUnsubscribe();
        };
      } catch (error) {
        console.error("Error fetching dashboard data:", error);
        setError("Failed to load dashboard data. Please refresh the page.");
        setLoading(false);
      }
    };
    
    fetchData();
  }, []);

  // Format currency to UGX
  const formatUGX = (value: number): string => {
    return new Intl.NumberFormat("en-UG", { 
      style: "currency", 
      currency: "UGX",
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(value);
  };

  // Chart options
  const chartOptions = {
    chart: {
      id: "revenue-chart",
      toolbar: {
        show: false
      },
      zoom: {
        enabled: false,
      },
      fontFamily: "var(--font-family)",
    },
    colors: ["var(--color-chart-1)", "var(--color-chart-2)"],
    stroke: {
      curve: "smooth",
      width: 3,
    },
    grid: {
      borderColor: "var(--color-border)",
      strokeDashArray: 5,
      xaxis: {
        lines: {
          show: true
        }
      },
      padding: {
        top: 10,
        right: 10,
        bottom: 10,
        left: 10
      }
    },
    markers: {
      size: 0,
      hover: {
        size: 5
      }
    },
    xaxis: {
      categories: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
      labels: {
        style: {
          colors: "var(--color-muted-foreground)",
          fontFamily: "var(--font-family)",
        }
      },
      axisBorder: {
        show: false
      },
      axisTicks: {
        show: false
      }
    },
    yaxis: {
      labels: {
        style: {
          colors: "var(--color-muted-foreground)",
          fontFamily: "var(--font-family)",
        },
        formatter: function (value: number) {
          return formatUGX(value).replace("UGX", "");
        }
      }
    },
    tooltip: {
      x: {
        format: "MMM yyyy"
      },
      y: {
        formatter: function (value: number) {
          return formatUGX(value);
        }
      }
    },
    legend: {
      show: true,
      position: "top",
      horizontalAlign: "right",
      fontFamily: "var(--font-family)",
    },
    fill: {
      type: "gradient",
      gradient: {
        shade: "light",
        type: "vertical",
        shadeIntensity: 0.2,
        gradientToColors: undefined,
        inverseColors: false,
        opacityFrom: 0.7,
        opacityTo: 0.1,
        stops: [0, 100],
      }
    },
    dataLabels: {
      enabled: false
    }
  };

  // Sample data for the revenue chart
  const chartSeries = [
    {
      name: "Sales",
      data: [400000, 650000, 580000, 750000, 900000, 1100000, 950000, 1200000, 1100000, 980000, 1250000, 1400000]
    },
    {
      name: "Expenses",
      data: [250000, 300000, 350000, 320000, 390000, 450000, 470000, 500000, 550000, 520000, 600000, 650000]
    }
  ];

  // Recent activities
  const activities: Activity[] = [
    { 
      id: 1, 
      type: "order",
      icon: <ShoppingBag size={20} className="text-blue-500" />,
      message: "New order received", 
      time: "10 minutes ago" 
    },
    { 
      id: 2, 
      type: "vendor",
      icon: <Users size={20} className="text-orange-500" />,
      message: "New vendor registered", 
      time: "2 hours ago" 
    },
    { 
      id: 3, 
      type: "product",
      icon: <Package size={20} className="text-purple-500" />,
      message: "5 new products added for approval", 
      time: "Yesterday" 
    },
    { 
      id: 4, 
      type: "system",
      icon: <Calendar size={20} className="text-gray-500" />,
      message: "System Maintenance", 
      time: "Scheduled for March 15, 2025" 
    },
  ];

  // System status items
  const systemStatuses = [
    { name: "Admin Dashboard", status: "Online" },
    { name: "Vendor Portal", status: "Online" },
    { name: "Customer Store", status: "Online" },
    { name: "Firebase Services", status: "Connected" },
    { name: "Payment Gateway", status: "Active" },
  ];

  return (
    <Container className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold">SpareWo Admin Dashboard</h1>
          <p className="text-sm text-muted-foreground">Overview of system metrics and performance</p>
        </div>
        <div className="text-sm text-muted-foreground">
          Last updated: {new Date().toLocaleTimeString()}
        </div>
      </div>
      
      {/* Error Alert */}
      {error && (
        <Card className="border-destructive">
          <CardContent className="pt-6">
            <div className="flex items-center gap-2 text-destructive">
              <AlertCircle size={18} />
              <p>{error}</p>
            </div>
          </CardContent>
        </Card>
      )}
      
      {/* Stats Cards */}
      {loading ? (
        <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="h-[160px]">
              <Skeleton className="h-full w-full" />
            </div>
          ))}
        </div>
      ) : (
        <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
          {/* Vendors Card */}
          <StatCard
            title="Total Vendors"
            value={stats.totalVendors}
            icon={<Users size={22} />}
            detail={<span className="text-orange-500">{stats.pendingVendors} pending approval</span>}
            trend={{ value: "12%", isPositive: true }}
            iconColor="text-orange-500"
            iconBgColor="bg-orange-100"
          />
          
          {/* Products Card */}
          <StatCard
            title="Products"
            value={stats.totalProducts}
            icon={<Package size={22} />}
            detail={<span className="text-orange-500">{stats.pendingProducts} pending review</span>}
            trend={{ value: "5%", isPositive: true }}
            iconColor="text-blue-500"
            iconBgColor="bg-blue-100"
          />
          
          {/* Orders Card */}
          <StatCard
            title="Orders"
            value={stats.totalOrders}
            icon={<ShoppingBag size={22} />}
            detail={<span className="text-blue-500">{stats.activeOrders} active</span>}
            trend={{ value: "18%", isPositive: true }}
            iconColor="text-purple-500"
            iconBgColor="bg-purple-100"
          />
          
          {/* Sales Card */}
          <StatCard
            title="Total Sales"
            value={formatUGX(stats.totalSales)}
            icon={<TrendingUp size={22} />}
            detail={<span className="text-green-500">{formatUGX(stats.totalSales / 6)} this month</span>}
            trend={{ value: "24%", isPositive: true }}
            iconColor="text-green-500"
            iconBgColor="bg-green-100"
          />
        </div>
      )}
      
      {/* Charts and Activity */}
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        {/* Revenue Chart */}
        <Card className="lg:col-span-2">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <div>
              <CardTitle>Revenue Overview</CardTitle>
              <CardDescription>Sales performance over time</CardDescription>
            </div>
            <select
              className="rounded-md border border-input bg-background px-3 py-1.5 text-sm font-medium"
              value={chartTimeframe}
              onChange={(e) => setChartTimeframe(e.target.value)}
            >
              <option value="monthly">Monthly</option>
              <option value="weekly">Weekly</option>
              <option value="yearly">Yearly</option>
            </select>
          </CardHeader>
          
          <CardContent className="px-2">
            {loading ? (
              <div className="h-72 w-full">
                <Skeleton className="h-full w-full" />
              </div>
            ) : (
              <div className="h-72 w-full">
                {typeof window !== "undefined" && (
                  <Chart
                    options={chartOptions as any}
                    series={chartSeries}
                    type="area"
                    height="100%"
                  />
                )}
              </div>
            )}
          </CardContent>
          
          <CardFooter className="grid grid-cols-1 gap-4 border-t pt-6 sm:grid-cols-3">
            <div>
              <p className="text-sm text-muted-foreground">Total Sales</p>
              <p className="text-xl font-semibold">{formatUGX(stats.totalSales)}</p>
            </div>
            <div>
              <p className="text-sm text-muted-foreground">Pending Approvals</p>
              <p className="text-xl font-semibold">{stats.pendingVendors + stats.pendingProducts}</p>
            </div>
            <div>
              <p className="text-sm text-muted-foreground">Active Orders</p>
              <p className="text-xl font-semibold">{stats.activeOrders}</p>
            </div>
          </CardFooter>
        </Card>

        {/* Recent Activity */}
        <Card>
          <CardHeader className="pb-2">
            <div className="flex items-center justify-between">
              <CardTitle>Recent Activity</CardTitle>
              <Link href="/notifications" className="text-sm font-medium text-primary hover:underline">
                View All
              </Link>
            </div>
          </CardHeader>
          
          <CardContent className="px-6">
            {loading ? (
              <div className="space-y-4">
                {[...Array(4)].map((_, i) => (
                  <Skeleton key={i} className="h-14 w-full" />
                ))}
              </div>
            ) : (
              <div className="space-y-4">
                {activities.map((activity) => (
                  <div key={activity.id} className="flex items-start gap-3 rounded-lg p-2 transition-colors hover:bg-muted/40">
                    <div className="flex h-9 w-9 items-center justify-center rounded-full bg-muted">
                      {activity.icon}
                    </div>
                    <div className="flex-1">
                      <p className="font-medium">{activity.message}</p>
                      <p className="text-xs text-muted-foreground">{activity.time}</p>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
      
      {/* Quick Actions and System Status */}
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        {/* Quick Actions */}
        <Card className="lg:col-span-2">
          <CardHeader className="pb-2">
            <CardTitle>Quick Actions</CardTitle>
          </CardHeader>
          
          <CardContent>
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 md:grid-cols-4">
              <Link href="/vendors/pending">
                <Card className="h-full transition-all hover:border-primary hover:shadow-md">
                  <CardContent className="p-4">
                    <div className="mb-2 flex h-9 w-9 items-center justify-center rounded-full bg-orange-100">
                      <Users size={18} className="text-orange-500" />
                    </div>
                    <h3 className="font-medium">Pending Vendors</h3>
                    <div className="mt-auto flex items-center justify-between pt-2">
                      <span className="text-xl font-semibold">{stats.pendingVendors}</span>
                      <ChevronRight size={16} className="text-primary" />
                    </div>
                  </CardContent>
                </Card>
              </Link>
              
              <Link href="/products/pending">
                <Card className="h-full transition-all hover:border-primary hover:shadow-md">
                  <CardContent className="p-4">
                    <div className="mb-2 flex h-9 w-9 items-center justify-center rounded-full bg-blue-100">
                      <Package size={18} className="text-blue-500" />
                    </div>
                    <h3 className="font-medium">Pending Products</h3>
                    <div className="mt-auto flex items-center justify-between pt-2">
                      <span className="text-xl font-semibold">{stats.pendingProducts}</span>
                      <ChevronRight size={16} className="text-primary" />
                    </div>
                  </CardContent>
                </Card>
              </Link>
              
              <Link href="/orders">
                <Card className="h-full transition-all hover:border-primary hover:shadow-md">
                  <CardContent className="p-4">
                    <div className="mb-2 flex h-9 w-9 items-center justify-center rounded-full bg-purple-100">
                      <ShoppingBag size={18} className="text-purple-500" />
                    </div>
                    <h3 className="font-medium">Active Orders</h3>
                    <div className="mt-auto flex items-center justify-between pt-2">
                      <span className="text-xl font-semibold">{stats.activeOrders}</span>
                      <ChevronRight size={16} className="text-primary" />
                    </div>
                  </CardContent>
                </Card>
              </Link>
              
              <Link href="/autohub">
                <Card className="h-full transition-all hover:border-primary hover:shadow-md">
                  <CardContent className="p-4">
                    <div className="mb-2 flex h-9 w-9 items-center justify-center rounded-full bg-green-100">
                      <Calendar size={18} className="text-green-500" />
                    </div>
                    <h3 className="font-medium">Garage Requests</h3>
                    <div className="mt-auto flex items-center justify-between pt-2">
                      <span className="text-xl font-semibold">{stats.garageRequests}</span>
                      <ChevronRight size={16} className="text-primary" />
                    </div>
                  </CardContent>
                </Card>
              </Link>
            </div>
          </CardContent>
        </Card>

        {/* System Status */}
        <Card>
          <CardHeader className="pb-2">
            <CardTitle>System Status</CardTitle>
          </CardHeader>
          
          <CardContent>
            <div className="space-y-3">
              {systemStatuses.map((item, index) => (
                <div key={index} className="flex items-center justify-between rounded-lg border border-border p-3">
                  <span className="text-sm">{item.name}</span>
                  <Badge variant="success">
                    {item.status}
                  </Badge>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>
    </Container>
  );
}

