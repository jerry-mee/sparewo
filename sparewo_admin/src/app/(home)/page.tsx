"use client";

import React, { useState, useEffect } from "react";
// Assuming these UI components exist and are correctly imported
import { Container } from "@/components/ui/container";
import { StatCard } from "@/components/ui/stat-card";
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
// Correct imports for services, types, and enums
import {
    vendorService,
    productService,
    orderService,
    Vendor,
    Product,
    Order,
    VendorStatus,
    ProductStatus,
    OrderStatus,
    Unsubscribe // Import Unsubscribe type here
} from "@/services/firebase.service";
import { Users, Package, ShoppingBag, TrendingUp, ChevronRight, Calendar, AlertCircle } from "lucide-react";
import Link from "next/link";
import dynamic from "next/dynamic";
// Removed duplicate Timestamp import

const Chart = dynamic(() => import("react-apexcharts"), { ssr: false });

// --- Type Definitions ---
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
    id: number; // Required for key prop in map
    type: "order" | "vendor" | "product" | "system";
    message: string;
    time: string;
    icon: React.ReactNode;
}
interface SystemStatusItem {
    name: string;
    status: string;
}

// --- Component ---
export default function Home() {
    // --- State ---
    const [stats, setStats] = useState<DashboardStats>({
        pendingVendors: 0, totalVendors: 0, pendingProducts: 0, totalProducts: 0,
        activeOrders: 0, totalOrders: 0, totalSales: 0, garageRequests: 0,
    });
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [chartTimeframe, setChartTimeframe] = useState("monthly");

    // --- Data Fetching Effect ---
    useEffect(() => {
        let vendorsUnsubscribe: Unsubscribe = () => {};
        let productsUnsubscribe: Unsubscribe = () => {};
        let ordersUnsubscribe: Unsubscribe = () => {};

        const fetchData = () => {
          try {
            setLoading(true);

            vendorsUnsubscribe = vendorService.listenToVendors(
              (vendors: Vendor[]) => {
                // Check if status exists before filtering
                const pendingVendors = vendors.filter(v => v && v.status === VendorStatus.PENDING).length;
                setStats(prev => ({...prev, pendingVendors, totalVendors: vendors.length}));
              },
              (err: Error) => { console.error("Vendor listener error:", err); setError(prev => prev || "Failed to load vendor data."); }
            );

            productsUnsubscribe = productService.listenToProducts(
              (products: Product[]) => {
                 // Check if status exists
                const pendingProducts = products.filter(p => p && p.status === ProductStatus.PENDING).length;
                setStats(prev => ({...prev, pendingProducts, totalProducts: products.length}));
              },
              (err: Error) => { console.error("Product listener error:", err); setError(prev => prev || "Failed to load product data."); }
            );

            ordersUnsubscribe = orderService.listenToOrders(
              (orders: Order[]) => {
                 // Check if status and totalAmount exist
                const activeOrders = orders.filter(o => o && o.status !== OrderStatus.DELIVERED && o.status !== OrderStatus.CANCELLED).length;
                const totalSales: number = orders.reduce((sum, order) => sum + (order?.totalAmount || 0), 0); // Add check for order
                setStats(prev => ({ ...prev, activeOrders, totalOrders: orders.length, totalSales }));
              },
              (err: Error) => { console.error("Order listener error:", err); setError(prev => prev || "Failed to load order data."); }
            );

            setStats(prev => ({ ...prev, garageRequests: 5 })); // Simulation
            setLoading(false);

          } catch (fetchError: any) {
            console.error("Error setting up listeners:", fetchError);
            setError("Failed to initialize dashboard data.");
            setLoading(false);
          }
        };

        fetchData();

        return () => { vendorsUnsubscribe(); productsUnsubscribe(); ordersUnsubscribe(); };
    }, []);

    // --- Helper Functions (Defined within component scope) ---
    const formatUGX = (value: number): string => {
         return new Intl.NumberFormat("en-UG", { style: "currency", currency: "UGX", minimumFractionDigits: 0, maximumFractionDigits: 0 }).format(value);
    };

    // --- Chart Config (Defined within component scope) ---
    const chartOptions: any = { // Using 'any' for simplicity, refine if needed
        chart: { id: "revenue-chart", toolbar: { show: false }, zoom: { enabled: false }, fontFamily: "inherit", },
        colors: ["hsl(var(--primary))", "hsl(var(--secondary))"],
        stroke: { curve: "smooth", width: 3, },
        grid: { borderColor: "hsl(var(--border))", strokeDashArray: 5, xaxis: { lines: { show: false } }, yaxis: { lines: { show: true } }, padding: { top: 5, right: 10, bottom: 0, left: 10 } },
        markers: { size: 0, hover: { size: 5 } },
        xaxis: { categories: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"], labels: { style: { colors: "hsl(var(--muted-foreground))", fontFamily: "inherit" } }, axisBorder: { show: false }, axisTicks: { show: false } },
        yaxis: { labels: { style: { colors: "hsl(var(--muted-foreground))", fontFamily: "inherit" }, formatter: function (value: number) { return formatUGX(value).replace("UGX", "").trim(); } } },
        tooltip: { theme: "dark", x: { format: "MMM yyyy" }, y: { formatter: function (value: number) { return formatUGX(value); } } },
        legend: { show: true, position: "top", horizontalAlign: "right", fontFamily: "inherit", },
        fill: { type: "gradient", gradient: { shade: "light", type: "vertical", shadeIntensity: 0.2, inverseColors: false, opacityFrom: 0.7, opacityTo: 0.1, stops: [0, 100], } },
        dataLabels: { enabled: false }
    };

    // Chart data (Added explicit type)
    const chartSeries: { name: string; data: number[] }[] = [
        { name: "Sales", data: [400000, 650000, 580000, 750000, 900000, 1100000, 950000, 1200000, 1100000, 980000, 1250000, 1400000] },
        { name: "Expenses", data: [250000, 300000, 350000, 320000, 390000, 450000, 470000, 500000, 550000, 520000, 600000, 650000] }
    ];

    // --- Sample Data (Defined within component scope) ---
    const activities: Activity[] = [ /* ... data ... */ ];
    const systemStatuses: SystemStatusItem[] = [ /* ... data ... */ ];

    // --- RENDER ---
    return (
        // Use Container component correctly
        <Container className="space-y-6">
            {/* Header */}
            <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
                <div>
                    <h1 className="text-2xl font-bold text-card-foreground dark:text-white">Dashboard</h1>
                    <p className="text-sm text-muted-foreground">System metrics overview</p>
                </div>
                <div className="text-sm text-muted-foreground"> Last updated: {new Date().toLocaleTimeString()} </div>
            </div>

            {/* Error Alert */}
            {error && ( <Card className="border-destructive bg-destructive/10"> <CardContent className="pt-6"> <div className="flex items-center gap-2 text-destructive"> <AlertCircle size={18} /> <p>{error}</p> </div> </CardContent> </Card> )}

            {/* Stats Cards */}
            {/* Check loading state */}
            {loading ? (
                <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4"> {[...Array(4)].map((_, i) => (<Skeleton key={i} className="h-[140px] w-full rounded-lg" />))} </div>
             ) : (
                 <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
                    {/* Use state variable 'stats' correctly */}
                    <StatCard title="Total Vendors" value={stats.totalVendors} icon={<Users size={22} />} detail={<span className="text-orange-600 dark:text-orange-400">{stats.pendingVendors} pending</span>} trend={{ value: "+12%", isPositive: true }} iconColor="text-orange-600 dark:text-orange-400" iconBgColor="bg-orange-100 dark:bg-orange-900/30" />
                    <StatCard title="Products" value={stats.totalProducts} icon={<Package size={22} />} detail={<span className="text-blue-600 dark:text-blue-400">{stats.pendingProducts} pending</span>} trend={{ value: "+5%", isPositive: true }} iconColor="text-blue-600 dark:text-blue-400" iconBgColor="bg-blue-100 dark:bg-blue-900/30" />
                    <StatCard title="Orders" value={stats.totalOrders} icon={<ShoppingBag size={22} />} detail={<span className="text-purple-600 dark:text-purple-400">{stats.activeOrders} active</span>} trend={{ value: "+18%", isPositive: true }} iconColor="text-purple-600 dark:text-purple-400" iconBgColor="bg-purple-100 dark:bg-purple-900/30" />
                    <StatCard title="Total Sales" value={formatUGX(stats.totalSales)} icon={<TrendingUp size={22} />} detail={<span className="text-green-600 dark:text-green-400">Total Revenue</span>} trend={{ value: "+24%", isPositive: true }} iconColor="text-green-600 dark:text-green-400" iconBgColor="bg-green-100 dark:bg-green-900/30" />
                 </div>
             )}

            {/* Charts and Activity */}
            <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
                 <Card className="lg:col-span-2">
                     <CardHeader className="flex flex-row items-center justify-between pb-2"> {/* ... */} </CardHeader>
                     <CardContent className="px-2 pt-4">
                         {/* Check loading state */}
                         {loading ? ( <Skeleton className="h-72 w-full" /> ) : (
                            <div className="h-72 w-full">
                                {typeof window !== "undefined" && Chart && (
                                    // Pass correct variables
                                    <Chart options={chartOptions} series={chartSeries} type="area" height="100%" />
                                )}
                            </div>
                         )}
                     </CardContent>
                     <CardFooter className="grid grid-cols-1 gap-4 border-t pt-4 sm:grid-cols-3">
                         {/* Use state variable 'stats' */}
                         <div> <p className="text-xs text-muted-foreground">Total Sales</p> <p className="text-lg font-semibold">{formatUGX(stats.totalSales)}</p> </div>
                         <div> <p className="text-xs text-muted-foreground">Pending Approvals</p> <p className="text-lg font-semibold">{stats.pendingVendors + stats.pendingProducts}</p> </div>
                         <div> <p className="text-xs text-muted-foreground">Active Orders</p> <p className="text-lg font-semibold">{stats.activeOrders}</p> </div>
                     </CardFooter>
                 </Card>

                 <Card>
                     <CardHeader className="pb-2"> {/* ... */} </CardHeader>
                     <CardContent className="px-0 pt-2">
                         {/* Check loading state */}
                         {loading ? ( <div className="space-y-4 px-6">{[...Array(4)].map((_, i) => (<Skeleton key={i} className="h-14 w-full rounded-md" />))}</div> )
                          : ( <div className="space-y-1">
                                 {/* Use activities variable, provide key */}
                                 {activities.map((activity: Activity) => (
                                     <div key={activity.id} className="flex items-start gap-3 rounded-lg p-3 transition-colors hover:bg-muted/40 mx-3">
                                         <div className="flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-full bg-muted"> {activity.icon} </div>
                                         <div className="flex-1"> <p className="text-sm font-medium">{activity.message}</p> <p className="text-xs text-muted-foreground">{activity.time}</p> </div>
                                     </div>
                                 ))}
                              </div>
                         )}
                     </CardContent>
                 </Card>
            </div>

            {/* Quick Actions and System Status */}
            <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
                 <Card className="lg:col-span-2">
                     <CardHeader className="pb-2"> <CardTitle className="text-base font-semibold">Quick Actions</CardTitle> </CardHeader>
                     <CardContent>
                          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 md:grid-cols-4">
                              {/* Use state variable 'stats' */}
                              <Link href="/vendors/pending"> <Card className="..."> <CardContent className="..."> {/* ... */} <span className="...">{stats.pendingVendors}</span> {/* ... */} </CardContent> </Card> </Link>
                              <Link href="/products/pending"> <Card className="..."> <CardContent className="..."> {/* ... */} <span className="...">{stats.pendingProducts}</span> {/* ... */} </CardContent> </Card> </Link>
                              <Link href="/orders"> <Card className="..."> <CardContent className="..."> {/* ... */} <span className="...">{stats.activeOrders}</span> {/* ... */} </CardContent> </Card> </Link>
                              <Link href="/autohub"> <Card className="..."> <CardContent className="..."> {/* ... */} <span className="...">{stats.garageRequests}</span> {/* ... */} </CardContent> </Card> </Link>
                          </div>
                      </CardContent>
                 </Card>

                 <Card>
                     <CardHeader className="pb-2"> <CardTitle className="text-base font-semibold">System Status</CardTitle> </CardHeader>
                     <CardContent>
                          <div className="space-y-3">
                               {/* Use systemStatuses variable */}
                              {systemStatuses.map((item: SystemStatusItem, index: number) => (
                                  <div key={index} className="...">
                                      <span className="...">{item.name}</span>
                                      <Badge variant={item.status === 'Online' || item.status === 'Connected' || item.status === 'Active' ? 'success' : 'destructive'}>{item.status}</Badge>
                                  </div>
                              ))}
                          </div>
                      </CardContent>
                 </Card>
            </div>
        </Container> // Correct closing tag
    );
}