"use client";

import { useState, useEffect, useMemo } from "react";
import { useRouter } from "next/navigation";
import { getOrders, getOrderStats } from "@/lib/firebase/orders";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { DocumentData } from "firebase/firestore";
import { formatCurrency, formatDate } from "@/lib/utils";
import Link from "next/link";
import { Search, ChevronRight, ShoppingCart, PackageCheck, Clock3, Truck } from "lucide-react";
import { toast } from "sonner";

interface OrderItem {
  productName: string;
  brand?: string;
  price: number;
  quantity: number;
}

interface Order {
  id: string;
  orderNumber: string;
  customerId: string;
  customerName?: string;
  userName?: string;
  totalAmount: number;
  status: string;
  createdAt: Date | string | number | { toDate(): Date } | null | undefined;
  items: OrderItem[];
}

interface OrderStats {
  total: number;
  pending: number;
  processing: number;
  completed: number;
  cancelled: number;
}

export default function OrdersPage() {
  const router = useRouter();
  const [orders, setOrders] = useState<Order[]>([]);
  const [stats, setStats] = useState<OrderStats>({ total: 0, pending: 0, processing: 0, completed: 0, cancelled: 0 });
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState("all");
  const [searchQuery, setSearchQuery] = useState("");
  const [lastDoc, setLastDoc] = useState<DocumentData | undefined>(undefined);
  const [hasMore, setHasMore] = useState(true);

  const fetchOrders = async (reset = false) => {
    setLoading(true);
    try {
      const result = await getOrders(statusFilter === "all" ? null : statusFilter, 10, reset ? undefined : lastDoc);

      const mappedOrders: Order[] = result.orders.map((order) => ({
        id: order.id,
        orderNumber: order.orderNumber,
        customerId: order.customerId,
        customerName: (order as unknown as Record<string, string>).userName || (order as unknown as Record<string, string>).customerName || "Guest User",
        totalAmount: order.totalAmount,
        status: order.status,
        createdAt: order.createdAt,
        items: order.items || [],
      }));

      if (reset) {
        setOrders(mappedOrders);
      } else {
        setOrders((prev) => [...prev, ...mappedOrders]);
      }

      setLastDoc(result.lastDoc);
      setHasMore(result.orders.length === 10);
    } catch (error) {
      console.error("Error fetching orders:", error);
      toast.error("Failed to load orders");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchOrders(true);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [statusFilter]);

  useEffect(() => {
    getOrderStats()
      .then((payload) => setStats(payload))
      .catch((error) => {
        console.error(error);
        toast.error("Failed to load order stats");
      });
  }, []);

  const filteredOrders = useMemo(() => {
    const needle = searchQuery.trim().toLowerCase();
    if (!needle) return orders;

    return orders.filter((order) => {
      const orderNumber = order.orderNumber?.toLowerCase() || "";
      const customerName = order.customerName?.toLowerCase() || "";
      return orderNumber.includes(needle) || customerName.includes(needle) || order.id.toLowerCase().includes(needle);
    });
  }, [orders, searchQuery]);

  const getStatusBadge = (status: string) => {
    const styles: Record<string, string> = {
      pending: "bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400",
      processing: "bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400",
      shipped: "bg-purple-100 text-purple-800 dark:bg-purple-900/30 dark:text-purple-400",
      delivered: "bg-indigo-100 text-indigo-800 dark:bg-indigo-900/30 dark:text-indigo-400",
      completed: "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400",
      cancelled: "bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400",
    };

    const style = styles[status] || "bg-gray-100 text-gray-800";
    return <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${style}`}>{status}</span>;
  };

  const summaryTiles = [
    {
      key: "total",
      label: "Total Orders",
      value: stats.total,
      icon: <ShoppingCart className="h-4 w-4 text-muted-foreground" />,
      onClick: () => setStatusFilter("all"),
      active: statusFilter === "all",
    },
    {
      key: "pending",
      label: "Pending",
      value: stats.pending,
      icon: <Clock3 className="h-4 w-4 text-amber-500" />,
      onClick: () => setStatusFilter("pending"),
      active: statusFilter === "pending",
    },
    {
      key: "processing",
      label: "Processing",
      value: stats.processing,
      icon: <Truck className="h-4 w-4 text-blue-500" />,
      onClick: () => setStatusFilter("processing"),
      active: statusFilter === "processing",
    },
    {
      key: "completed",
      label: "Completed",
      value: stats.completed,
      icon: <PackageCheck className="h-4 w-4 text-green-600" />,
      onClick: () => setStatusFilter("completed"),
      active: statusFilter === "completed",
    },
  ];

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-1">
        <h1 className="text-2xl font-semibold tracking-tight">Order Tracker</h1>
        <p className="text-muted-foreground">Track order progression, fulfillment assignment, and delivery status.</p>
      </div>

      <div className="grid gap-4 md:grid-cols-4">
        {summaryTiles.map((tile) => (
          <button key={tile.key} type="button" onClick={tile.onClick} className="text-left">
            <Card className={`transition-colors hover:border-primary/50 ${tile.active ? "border-primary/60 bg-primary/5" : ""}`}>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">{tile.label}</CardTitle>
                {tile.icon}
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{tile.value}</div>
              </CardContent>
            </Card>
          </button>
        ))}
      </div>

      <Card>
        <CardHeader>
          <div className="flex flex-col md:flex-row gap-4 md:items-center md:justify-between">
            <CardTitle className="flex items-center gap-2">
              <ShoppingCart className="h-5 w-5" /> All Orders
            </CardTitle>
            <div className="flex flex-col sm:flex-row gap-2">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                <Input
                  placeholder="Search order # or customer"
                  value={searchQuery}
                  onChange={(event) => setSearchQuery(event.target.value)}
                  className="h-9 w-[240px] pl-9"
                />
              </div>
              <Select value={statusFilter} onValueChange={setStatusFilter}>
                <SelectTrigger className="w-[150px] h-9">
                  <SelectValue placeholder="Status" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Status</SelectItem>
                  <SelectItem value="pending">Pending</SelectItem>
                  <SelectItem value="processing">Processing</SelectItem>
                  <SelectItem value="shipped">Shipped</SelectItem>
                  <SelectItem value="delivered">Delivered</SelectItem>
                  <SelectItem value="completed">Completed</SelectItem>
                  <SelectItem value="cancelled">Cancelled</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Order #</TableHead>
                  <TableHead>Date</TableHead>
                  <TableHead>Customer</TableHead>
                  <TableHead>Items</TableHead>
                  <TableHead>Total</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="text-right">Action</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {loading && orders.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={7} className="h-24 text-center">
                      Loading orders...
                    </TableCell>
                  </TableRow>
                ) : filteredOrders.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={7} className="h-24 text-center">
                      No orders found.
                    </TableCell>
                  </TableRow>
                ) : (
                  filteredOrders.map((order) => (
                    <TableRow
                      key={order.id}
                      className="cursor-pointer hover:bg-muted/40"
                      onClick={() => router.push(`/dashboard/orders/${order.id}`)}
                    >
                      <TableCell className="font-mono">{order.orderNumber}</TableCell>
                      <TableCell>{formatDate(order.createdAt)}</TableCell>
                      <TableCell>{order.customerName}</TableCell>
                      <TableCell>{order.items?.length || 0} items</TableCell>
                      <TableCell>{formatCurrency(order.totalAmount)}</TableCell>
                      <TableCell>{getStatusBadge(order.status)}</TableCell>
                      <TableCell className="text-right" onClick={(event) => event.stopPropagation()}>
                        <Link href={`/dashboard/orders/${order.id}`}>
                          <Button variant="ghost" size="icon" aria-label={`Open order ${order.orderNumber}`}>
                            <ChevronRight className="h-4 w-4" />
                          </Button>
                        </Link>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </div>
          {hasMore && (
            <div className="mt-4 flex justify-center">
              <Button variant="outline" onClick={() => fetchOrders(false)} disabled={loading}>
                {loading ? "Loading..." : "Load More"}
              </Button>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
