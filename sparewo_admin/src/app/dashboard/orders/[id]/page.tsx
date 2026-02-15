"use client";

import { useState, useEffect } from "react";
import { useParams } from "next/navigation";
import { getOrderById, updateOrderStatus } from "@/lib/firebase/orders";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Separator } from "@/components/ui/separator";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { formatCurrency, formatDate } from "@/lib/utils";
import { ArrowLeft, MapPin, User, CreditCard } from "lucide-react";
import { toast } from "sonner";
import Link from "next/link";

interface DeliveryAddress {
  street: string;
  city: string;
  country: string;
}

interface OrderItem {
  productName: string;
  brand?: string;
  price: number;
  quantity: number;
}

interface OrderDetail {
  id: string;
  orderNumber: string;
  status: string;
  createdAt: Date | string | number | { toDate(): Date } | null | undefined;
  items: OrderItem[];
  totalAmount: number;
  userName?: string;
  customerName?: string;
  userEmail?: string;
  customerPhone?: string;
  deliveryAddress?: DeliveryAddress;
  paymentMethod?: string;
}

export default function OrderDetailsPage() {
  const { id } = useParams<{ id: string }>();
  const [order, setOrder] = useState<OrderDetail | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchOrder = async () => {
      setLoading(true);
      try {
        const data = await getOrderById(id);
        // Cast to unknown first to allow assignment if structure matches mostly
        setOrder(data as unknown as OrderDetail);
      } catch (error) {
        console.error(error);
        toast.error("Failed to load order details");
      } finally {
        setLoading(false);
      }
    };
    fetchOrder();
  }, [id]);

  const handleStatusChange = async (newStatus: string) => {
    if (!order) return;
    try {
      // @ts-expect-error - Mismatch in string literal types vs string
      await updateOrderStatus(order.id, newStatus);
      setOrder({ ...order, status: newStatus });
      toast.success(`Order status updated to ${newStatus}`);
    } catch (error) {
      console.error(error);
      toast.error("Failed to update order status");
    }
  };

  if (loading) {
    return (
      <div className="flex h-96 items-center justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary border-t-transparent" />
      </div>
    );
  }

  if (!order) return <div>Order not found</div>;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Link href="/dashboard/orders">
            <Button variant="ghost" size="icon"><ArrowLeft className="h-5 w-5" /></Button>
          </Link>
          <div>
            <h1 className="text-2xl font-bold tracking-tight">Order #{order.orderNumber}</h1>
            <p className="text-sm text-muted-foreground">Placed on {formatDate(order.createdAt)}</p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <span className="text-sm font-medium">Status:</span>
          <select 
            className="rounded-md border border-input bg-background px-3 py-1 text-sm shadow-sm"
            value={order.status}
            onChange={(e) => handleStatusChange(e.target.value)}
          >
            <option value="pending">Pending</option>
            <option value="processing">Processing</option>
            <option value="shipped">Shipped</option>
            <option value="delivered">Delivered</option>
            <option value="cancelled">Cancelled</option>
          </select>
        </div>
      </div>

      <div className="grid gap-6 md:grid-cols-3">
        <div className="space-y-6 md:col-span-2">
          {/* Order Items */}
          <Card>
            <CardHeader>
              <CardTitle>Items</CardTitle>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Product</TableHead>
                    <TableHead className="text-right">Price</TableHead>
                    <TableHead className="text-right">Qty</TableHead>
                    <TableHead className="text-right">Total</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {order.items?.map((item: OrderItem, i: number) => (
                    <TableRow key={i}>
                      <TableCell>
                        <div className="flex flex-col">
                          <span className="font-medium">{item.productName}</span>
                          <span className="text-xs text-muted-foreground">{item.brand || "SpareWo Brand"}</span>
                        </div>
                      </TableCell>
                      <TableCell className="text-right">{formatCurrency(item.price)}</TableCell>
                      <TableCell className="text-right">{item.quantity}</TableCell>
                      <TableCell className="text-right">{formatCurrency(item.price * item.quantity)}</TableCell>
                    </TableRow>
                  ))}
                  <TableRow>
                    <TableCell colSpan={3} className="text-right font-medium">Total</TableCell>
                    <TableCell className="text-right font-bold">{formatCurrency(order.totalAmount)}</TableCell>
                  </TableRow>
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </div>

        <div className="space-y-6">
          {/* Customer Details */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-base">
                <User className="h-4 w-4" /> Customer
              </CardTitle>
            </CardHeader>
            <CardContent className="text-sm">
              <div className="grid gap-1">
                <span className="font-medium">{order.userName || order.customerName || "Guest"}</span>
                <span className="text-muted-foreground">{order.userEmail || "No email"}</span>
                <span className="text-muted-foreground">{order.customerPhone || "No phone"}</span>
              </div>
            </CardContent>
          </Card>

          {/* Shipping Address */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-base">
                <MapPin className="h-4 w-4" /> Shipping Address
              </CardTitle>
            </CardHeader>
            <CardContent className="text-sm">
              {order.deliveryAddress ? (
                <div className="grid gap-1">
                  <span>{order.deliveryAddress.street}</span>
                  <span>{order.deliveryAddress.city}, {order.deliveryAddress.country}</span>
                </div>
              ) : (
                <p className="text-muted-foreground">Pickup in store</p>
              )}
            </CardContent>
          </Card>

          {/* Payment Info */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-base">
                <CreditCard className="h-4 w-4" /> Payment
              </CardTitle>
            </CardHeader>
            <CardContent className="text-sm">
              <div className="flex justify-between">
                <span>Payment Method</span>
                <span className="font-medium capitalize">{order.paymentMethod || "Mobile Money"}</span>
              </div>
              <Separator className="my-2" />
              <div className="flex justify-between font-bold">
                <span>Total Paid</span>
                <span>{formatCurrency(order.totalAmount)}</span>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}