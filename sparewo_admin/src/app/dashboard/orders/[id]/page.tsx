"use client";

import { useMemo, useState, useEffect } from "react";
import { useParams } from "next/navigation";
import {
  autoAssignVendorsToOrder,
  getOrderById,
  getOrderFulfillments,
  updateOrderPaymentStatus,
  updateFulfillmentStatus,
  updateOrderStatus,
} from "@/lib/firebase/orders";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { StatusPill } from "@/components/ui/status-pill";
import { Separator } from "@/components/ui/separator";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { formatCurrency, formatDate } from "@/lib/utils";
import {
  ArrowLeft,
  ChevronRight,
  MapPin,
  User,
  CreditCard,
  Truck,
  Route,
  Workflow,
  Save,
  RefreshCw,
  CheckCircle2,
} from "lucide-react";
import { toast } from "sonner";
import Link from "next/link";

interface DeliveryAddress {
  street: string;
  city: string;
  country: string;
}

interface OrderItem {
  productName?: string;
  name?: string;
  partName?: string;
  catalogProductId?: string;
  productId?: string;
  brand?: string;
  price?: number;
  unitPrice?: number;
  lineTotal?: number;
  quantity?: number;
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
  paymentStatus?: "pending" | "received";
  paymentReceived?: boolean;
  paymentReceivedAt?: Date | string | number | { toDate(): Date } | null | undefined;
  adminNotes?: string;
  subtotal?: number;
  deliveryFee?: number;
  updatedAt?: Date | string | number | { toDate(): Date } | null | undefined;
}

interface Fulfillment {
  id: string;
  vendorId: string;
  vendorName?: string;
  productName?: string;
  status: "pending" | "accepted" | "processing" | "shipped" | "delivered" | "cancelled";
  quantity: number;
  vendorPrice: number;
  totalVendorAmount: number;
  trackingNumber?: string;
  carrier?: string;
  vendorNotes?: string;
  createdAt?: unknown;
}

interface FulfillmentEdit {
  status: Fulfillment["status"];
  trackingNumber: string;
  carrier: string;
  vendorNotes: string;
}

const statusOptions = ["pending", "processing", "shipped", "delivered", "completed", "cancelled"] as const;
const fulfillmentStatusOptions: Fulfillment["status"][] = [
  "pending",
  "accepted",
  "processing",
  "shipped",
  "delivered",
  "cancelled",
];

const orderTrackerStages = ["pending", "processing", "shipped", "delivered", "completed"] as const;
const orderStageLabels: Record<(typeof orderTrackerStages)[number], string> = {
  pending: "Order Received",
  processing: "Processing",
  shipped: "Shipped",
  delivered: "Delivered",
  completed: "Completed",
};

type PaymentStatus = "pending" | "received";

interface NormalizedOrderItem {
  id: string;
  productName: string;
  brand: string;
  quantity: number;
  unitPrice: number;
  lineTotal: number;
}

const paymentStatusOptions: PaymentStatus[] = ["pending", "received"];

const orderStageDescriptions: Record<(typeof orderTrackerStages)[number], string> = {
  pending: "Order submitted and awaiting processing",
  processing: "Team is preparing items and assigning fulfillment",
  shipped: "Package has left warehouse and is in transit",
  delivered: "Package has arrived at the destination",
  completed: "Order lifecycle closed successfully",
};

const toNumber = (value: unknown): number => {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : 0;
  }
  return 0;
};

const normalizePaymentMethod = (value?: string): string => {
  if (!value) return "Mobile Money";
  return value
    .replace(/_/g, " ")
    .replace(/\b\w/g, (match) => match.toUpperCase());
};

export default function OrderDetailsPage() {
  const { id } = useParams<{ id: string }>();

  const [order, setOrder] = useState<OrderDetail | null>(null);
  const [fulfillments, setFulfillments] = useState<Fulfillment[]>([]);
  const [fulfillmentEdits, setFulfillmentEdits] = useState<Record<string, FulfillmentEdit>>({});

  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [assigning, setAssigning] = useState(false);
  const [savingFulfillmentId, setSavingFulfillmentId] = useState<string | null>(null);
  const [draftOrderStatus, setDraftOrderStatus] = useState<string>("pending");
  const [updatingOrderStatus, setUpdatingOrderStatus] = useState(false);
  const [draftPaymentStatus, setDraftPaymentStatus] = useState<PaymentStatus>("pending");
  const [updatingPaymentStatus, setUpdatingPaymentStatus] = useState(false);

  const loadOrder = async (isRefresh = false) => {
    if (isRefresh) setRefreshing(true);
    try {
      const [orderData, fulfillmentData] = await Promise.all([
        getOrderById(id),
        getOrderFulfillments(id),
      ]);

      const typedOrder = orderData as unknown as OrderDetail;
      setOrder(typedOrder);
      if (typedOrder) {
        setDraftOrderStatus(typedOrder.status || "pending");
        const resolvedPaymentStatus: PaymentStatus =
          typedOrder.paymentStatus === "received" || typedOrder.paymentReceived === true
            ? "received"
            : "pending";
        setDraftPaymentStatus(resolvedPaymentStatus);
      }
      setFulfillments(fulfillmentData as unknown as Fulfillment[]);

      const initialEdits: Record<string, FulfillmentEdit> = {};
      (fulfillmentData as unknown as Fulfillment[]).forEach((item) => {
        initialEdits[item.id] = {
          status: item.status,
          trackingNumber: item.trackingNumber || "",
          carrier: item.carrier || "",
          vendorNotes: item.vendorNotes || "",
        };
      });
      setFulfillmentEdits(initialEdits);
    } catch (error) {
      console.error(error);
      toast.error("Failed to load order details");
    } finally {
      setLoading(false);
      if (isRefresh) setRefreshing(false);
    }
  };

  useEffect(() => {
    loadOrder();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id]);

  const handleOrderStatusChange = (newStatus: string) => {
    setDraftOrderStatus(newStatus);
  };

  const handleApplyOrderStatus = async () => {
    if (!order) return;
    if (draftOrderStatus === order.status) {
      toast.message("Order status is already up to date");
      return;
    }

    setUpdatingOrderStatus(true);
    try {
      await updateOrderStatus(order.id, draftOrderStatus as typeof statusOptions[number]);
      setOrder({ ...order, status: draftOrderStatus });
      toast.success(`Order status updated to ${draftOrderStatus}`);
    } catch (error) {
      console.error(error);
      toast.error("Failed to update order status");
    } finally {
      setUpdatingOrderStatus(false);
    }
  };

  const handleApplyPaymentStatus = async () => {
    if (!order) return;
    const currentStatus: PaymentStatus =
      order.paymentStatus === "received" || order.paymentReceived === true ? "received" : "pending";
    if (currentStatus === draftPaymentStatus) {
      toast.message("Payment status is already up to date");
      return;
    }

    setUpdatingPaymentStatus(true);
    try {
      await updateOrderPaymentStatus(order.id, draftPaymentStatus);
      const received = draftPaymentStatus === "received";
      setOrder({
        ...order,
        paymentStatus: draftPaymentStatus,
        paymentReceived: received,
        paymentReceivedAt: received ? new Date() : null,
      });
      toast.success(`Payment marked as ${draftPaymentStatus}`);
    } catch (error) {
      console.error(error);
      toast.error("Failed to update payment status");
    } finally {
      setUpdatingPaymentStatus(false);
    }
  };

  const handleAutoAssign = async () => {
    if (!order) return;

    setAssigning(true);
    try {
      const assignmentIds = await autoAssignVendorsToOrder(order.id, true);
      toast.success(`Created ${assignmentIds.length} fulfillment assignment(s)`);
      await loadOrder(true);
    } catch (error) {
      console.error(error);
      toast.error("Failed to auto-assign fulfillments");
    } finally {
      setAssigning(false);
    }
  };

  const updateEdit = (fulfillmentId: string, updates: Partial<FulfillmentEdit>) => {
    setFulfillmentEdits((current) => ({
      ...current,
      [fulfillmentId]: {
        ...current[fulfillmentId],
        ...updates,
      },
    }));
  };

  const handleSaveFulfillment = async (fulfillmentId: string) => {
    const edit = fulfillmentEdits[fulfillmentId];
    if (!edit) return;

    setSavingFulfillmentId(fulfillmentId);
    try {
      await updateFulfillmentStatus(
        fulfillmentId,
        edit.status,
        edit.vendorNotes,
        edit.status === "shipped" || edit.status === "delivered"
          ? {
              trackingNumber: edit.trackingNumber || undefined,
              carrier: edit.carrier || undefined,
            }
          : undefined
      );

      toast.success("Fulfillment updated");
      await loadOrder(true);
    } catch (error) {
      console.error(error);
      toast.error("Failed to update fulfillment");
    } finally {
      setSavingFulfillmentId(null);
    }
  };

  const normalizedItems = useMemo<NormalizedOrderItem[]>(() => {
    if (!order) return [];
    return (order.items || []).map((item, index) => {
      const quantity = Math.max(1, toNumber(item.quantity) || 1);
      const unitPrice = toNumber(item.price) || toNumber(item.unitPrice);
      const lineTotalFromData = toNumber(item.lineTotal);
      const lineTotal = lineTotalFromData > 0 ? lineTotalFromData : unitPrice * quantity;
      const productName =
        item.productName?.trim() ||
        item.name?.trim() ||
        item.partName?.trim() ||
        (item.catalogProductId ? `Product ${item.catalogProductId.slice(0, 8).toUpperCase()}` : "") ||
        (item.productId ? `Product ${item.productId.slice(0, 8).toUpperCase()}` : "") ||
        `Order Item ${index + 1}`;
      return {
        id: item.catalogProductId || item.productId || String(index),
        productName,
        brand: item.brand?.trim() || "Brand not set",
        quantity,
        unitPrice,
        lineTotal,
      };
    });
  }, [order]);

  if (loading) {
    return (
      <div className="flex h-96 items-center justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary border-t-transparent" />
      </div>
    );
  }

  if (!order) return <div>Order not found</div>;

  const isCancelled = order.status === "cancelled";
  const currentOrderStageIndex = orderTrackerStages.indexOf(
    order.status as (typeof orderTrackerStages)[number]
  );
  const computedSubtotal = normalizedItems.reduce((sum, item) => sum + item.lineTotal, 0);
  const orderSubtotal = toNumber(order.subtotal) > 0 ? toNumber(order.subtotal) : computedSubtotal;
  const deliveryFee = Math.max(0, toNumber(order.deliveryFee));
  const orderTotal = toNumber(order.totalAmount) > 0 ? toNumber(order.totalAmount) : orderSubtotal + deliveryFee;
  const resolvedPaymentStatus: PaymentStatus =
    order.paymentStatus === "received" || order.paymentReceived === true ? "received" : "pending";
  const paymentStatusLabel = resolvedPaymentStatus === "received" ? "Received" : "Awaiting Payment";

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-2 text-sm text-muted-foreground">
        <Link href="/dashboard/orders">
          <Button variant="ghost" size="icon">
            <ArrowLeft className="h-5 w-5" />
          </Button>
        </Link>
        <span>Orders</span>
        <ChevronRight className="h-4 w-4" />
        <span>Tracking</span>
        <ChevronRight className="h-4 w-4" />
        <span className="font-medium text-foreground">{order.orderNumber}</span>
      </div>

      <Card>
        <CardContent className="space-y-4 pt-6">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <div>
              <h1 className="text-2xl font-bold tracking-tight">Order #{order.orderNumber}</h1>
              <p className="text-sm text-muted-foreground">Placed on {formatDate(order.createdAt)}</p>
            </div>
            <div className="flex flex-wrap items-center gap-2">
              <StatusPill status={order.status} />
              <select
                className="rounded-md border border-input bg-background px-3 py-1 text-sm shadow-sm"
                value={draftOrderStatus}
                onChange={(event) => handleOrderStatusChange(event.target.value)}
              >
                {statusOptions.map((option) => (
                  <option key={option} value={option}>
                    {option.charAt(0).toUpperCase() + option.slice(1)}
                  </option>
                ))}
              </select>
              <Button
                size="sm"
                onClick={handleApplyOrderStatus}
                disabled={updatingOrderStatus || draftOrderStatus === order.status}
              >
                {updatingOrderStatus ? "Updating..." : "Update Status"}
              </Button>
            </div>
          </div>

          <div className="grid gap-4 md:grid-cols-5">
            {orderTrackerStages.map((stage, index) => {
              const complete = !isCancelled && currentOrderStageIndex > index;
              const active = !isCancelled && currentOrderStageIndex === index;
              return (
                <div key={stage} className="relative rounded-lg border bg-background px-3 py-3">
                  <div className="flex items-center gap-2">
                    <span
                      className={`inline-flex h-7 w-7 items-center justify-center rounded-full border text-xs font-semibold ${
                        complete || active
                          ? "border-primary bg-primary text-primary-foreground"
                          : "border-muted-foreground/40 text-muted-foreground"
                      }`}
                    >
                      {complete ? <CheckCircle2 className="h-4 w-4" /> : index + 1}
                    </span>
                    <div>
                      <p className="text-xs uppercase tracking-wide text-muted-foreground">Step {index + 1}</p>
                      <p className="text-sm font-medium">{orderStageLabels[stage]}</p>
                    </div>
                  </div>
                  <p className="mt-2 text-xs text-muted-foreground">{orderStageDescriptions[stage]}</p>
                  {index < orderTrackerStages.length - 1 && (
                    <div className="pointer-events-none absolute -right-2 top-6 hidden md:block">
                      <ChevronRight className="h-4 w-4 text-muted-foreground/60" />
                    </div>
                  )}
                </div>
              );
            })}
          </div>

          {isCancelled && (
            <div className="rounded-md border border-rose-300 bg-rose-50 px-3 py-2 text-sm text-rose-800 dark:border-rose-500/40 dark:bg-rose-900/20 dark:text-rose-200">
              This order has been cancelled.
            </div>
          )}
        </CardContent>
      </Card>

      <div className="grid gap-3 md:grid-cols-3">
        <Card>
          <CardContent className="pt-5 text-sm">
            <p className="text-muted-foreground">Customer</p>
            <p className="mt-1 font-medium">{order.userName || order.customerName || "Guest"}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-5 text-sm">
            <p className="text-muted-foreground">Payment</p>
            <div className="mt-1 flex items-center gap-2">
              <p className="font-medium">{normalizePaymentMethod(order.paymentMethod)}</p>
              <span
                className={`rounded-full px-2 py-0.5 text-xs font-medium ${
                  resolvedPaymentStatus === "received"
                    ? "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300"
                    : "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300"
                }`}
              >
                {paymentStatusLabel}
              </span>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-5 text-sm">
            <p className="text-muted-foreground">Order Total</p>
            <p className="mt-1 font-semibold">{formatCurrency(orderTotal)}</p>
          </CardContent>
        </Card>
      </div>

      <div className="grid gap-6 md:grid-cols-3">
        <div className="space-y-6 md:col-span-2">
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
                  {normalizedItems.map((item) => (
                    <TableRow key={item.id}>
                      <TableCell>
                        <div className="flex flex-col">
                          <span className="font-medium">{item.productName}</span>
                          <span className="text-xs text-muted-foreground">{item.brand}</span>
                        </div>
                      </TableCell>
                      <TableCell className="text-right">{formatCurrency(item.unitPrice)}</TableCell>
                      <TableCell className="text-right">{item.quantity}</TableCell>
                      <TableCell className="text-right">{formatCurrency(item.lineTotal)}</TableCell>
                    </TableRow>
                  ))}
                  <TableRow>
                    <TableCell colSpan={3} className="text-right text-muted-foreground">
                      Subtotal
                    </TableCell>
                    <TableCell className="text-right">{formatCurrency(orderSubtotal)}</TableCell>
                  </TableRow>
                  <TableRow>
                    <TableCell colSpan={3} className="text-right text-muted-foreground">
                      Delivery Fee
                    </TableCell>
                    <TableCell className="text-right">{formatCurrency(deliveryFee)}</TableCell>
                  </TableRow>
                  <TableRow>
                    <TableCell colSpan={3} className="text-right font-medium">
                      Total
                    </TableCell>
                    <TableCell className="text-right font-bold">{formatCurrency(orderTotal)}</TableCell>
                  </TableRow>
                </TableBody>
              </Table>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between">
              <div>
                <CardTitle className="flex items-center gap-2">
                  <Route className="h-5 w-5" /> Fulfillment Tracker
                </CardTitle>
                <p className="text-sm text-muted-foreground mt-1">
                  Assign vendors, manage shipment progress, and track carrier details.
                </p>
              </div>
              <div className="flex items-center gap-2">
                <Button variant="outline" size="sm" onClick={() => loadOrder(true)} disabled={refreshing}>
                  <RefreshCw className="mr-2 h-4 w-4" /> Refresh
                </Button>
                <Button size="sm" onClick={handleAutoAssign} disabled={assigning || order.status === "cancelled"}>
                  <Workflow className="mr-2 h-4 w-4" />
                  {assigning ? "Assigning..." : "Auto Assign Vendors"}
                </Button>
              </div>
            </CardHeader>
            <CardContent>
              {fulfillments.length === 0 ? (
                <div className="rounded-lg border border-dashed p-6 text-center text-sm text-muted-foreground">
                  No fulfillments created yet. Use auto-assignment to generate vendor work orders.
                </div>
              ) : (
                <div className="space-y-4">
                  {fulfillments.map((fulfillment) => {
                    const edit = fulfillmentEdits[fulfillment.id];
                    if (!edit) return null;

                    return (
                      <div key={fulfillment.id} className="rounded-lg border p-4">
                        <div className="mb-3 flex flex-wrap items-center justify-between gap-2">
                          <div>
                            <p className="font-medium">{fulfillment.productName || "Order item"}</p>
                            <p className="text-xs text-muted-foreground">
                              Vendor: {fulfillment.vendorName || fulfillment.vendorId}
                            </p>
                          </div>
                          <div className="flex items-center gap-2">
                            <StatusPill status={edit.status} className="text-xs" />
                            <span className="text-xs rounded-full bg-muted px-2.5 py-1">
                              Qty {fulfillment.quantity} • {formatCurrency(fulfillment.totalVendorAmount)}
                            </span>
                          </div>
                        </div>

                        <div className="grid gap-3 md:grid-cols-4">
                          <div>
                            <label className="mb-1 block text-xs font-medium text-muted-foreground">Status</label>
                            <select
                              className="w-full rounded-md border border-input bg-background px-2.5 py-2 text-sm"
                              value={edit.status}
                              onChange={(event) =>
                                updateEdit(fulfillment.id, {
                                  status: event.target.value as Fulfillment["status"],
                                })
                              }
                            >
                              {fulfillmentStatusOptions.map((option) => (
                                <option key={option} value={option}>
                                  {option}
                                </option>
                              ))}
                            </select>
                          </div>

                          <div>
                            <label className="mb-1 block text-xs font-medium text-muted-foreground">Carrier</label>
                            <input
                              className="w-full rounded-md border border-input bg-background px-2.5 py-2 text-sm"
                              value={edit.carrier}
                              onChange={(event) => updateEdit(fulfillment.id, { carrier: event.target.value })}
                              placeholder="DHL / UPS / Local"
                            />
                          </div>

                          <div>
                            <label className="mb-1 block text-xs font-medium text-muted-foreground">Tracking #</label>
                            <input
                              className="w-full rounded-md border border-input bg-background px-2.5 py-2 text-sm"
                              value={edit.trackingNumber}
                              onChange={(event) =>
                                updateEdit(fulfillment.id, { trackingNumber: event.target.value })
                              }
                              placeholder="Optional"
                            />
                          </div>

                          <div>
                            <label className="mb-1 block text-xs font-medium text-muted-foreground">Vendor Notes</label>
                            <input
                              className="w-full rounded-md border border-input bg-background px-2.5 py-2 text-sm"
                              value={edit.vendorNotes}
                              onChange={(event) =>
                                updateEdit(fulfillment.id, { vendorNotes: event.target.value })
                              }
                              placeholder="Optional"
                            />
                          </div>
                        </div>

                        <div className="mt-3 flex justify-end">
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => handleSaveFulfillment(fulfillment.id)}
                            disabled={savingFulfillmentId === fulfillment.id}
                          >
                            <Save className="mr-2 h-4 w-4" />
                            {savingFulfillmentId === fulfillment.id ? "Saving..." : "Save Update"}
                          </Button>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </CardContent>
          </Card>
        </div>

        <div className="space-y-6">
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

          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-base">
                <MapPin className="h-4 w-4" /> Shipping Address
              </CardTitle>
            </CardHeader>
            <CardContent className="text-sm">
              {order.deliveryAddress ? (
                <div className="grid gap-1">
                  <span>{order.deliveryAddress.street || "Street not provided"}</span>
                  <span>
                    {[order.deliveryAddress.city, order.deliveryAddress.country].filter(Boolean).join(", ") ||
                      "Location not provided"}
                  </span>
                </div>
              ) : (
                <p className="text-muted-foreground">Pickup in store</p>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-base">
                <CreditCard className="h-4 w-4" /> Payment
              </CardTitle>
            </CardHeader>
            <CardContent className="text-sm">
              <div className="flex justify-between">
                <span>Payment Method</span>
                <span className="font-medium">{normalizePaymentMethod(order.paymentMethod)}</span>
              </div>
              <Separator className="my-2" />
              <div className="space-y-2 rounded-md border p-3">
                <p className="text-xs font-medium uppercase tracking-wide text-muted-foreground">Collection Status</p>
                <div className="flex items-center gap-2">
                  <select
                    className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm shadow-sm"
                    value={draftPaymentStatus}
                    onChange={(event) => setDraftPaymentStatus(event.target.value as PaymentStatus)}
                  >
                    {paymentStatusOptions.map((option) => (
                      <option key={option} value={option}>
                        {option === "received" ? "Received" : "Pending"}
                      </option>
                    ))}
                  </select>
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={handleApplyPaymentStatus}
                    disabled={updatingPaymentStatus || draftPaymentStatus === resolvedPaymentStatus}
                  >
                    {updatingPaymentStatus ? "Saving..." : "Update Status"}
                  </Button>
                </div>
                {order.paymentReceivedAt && resolvedPaymentStatus === "received" && (
                  <p className="text-xs text-muted-foreground">
                    Received on {formatDate(order.paymentReceivedAt)}
                  </p>
                )}
              </div>
              <Separator className="my-2" />
              <div className="flex justify-between font-bold">
                <span>Total Paid</span>
                <span>{resolvedPaymentStatus === "received" ? formatCurrency(orderTotal) : formatCurrency(0)}</span>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-base">
                <Truck className="h-4 w-4" /> Operational Notes
              </CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-sm text-muted-foreground">
                {order.adminNotes || "No order-level admin notes recorded yet."}
              </p>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
