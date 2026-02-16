"use client";

import { useState, useEffect } from "react";
import { useParams } from "next/navigation";
import { getVendorById, updateVendorStatus, toggleVendorSuspension } from "@/lib/firebase/vendors";
import { getProductsByVendorId } from "@/lib/firebase/products";
import { resetPassword } from "@/lib/firebase/auth";
import { createNotification } from "@/lib/firebase/notifications";
import { Vendor } from "@/lib/types/vendor";
import { Product } from "@/lib/types/product";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Textarea } from "@/components/ui/textarea";
import { VendorStatusBadge } from "@/components/vendor/vendor-status-badge";
import { ProductStatusBadge } from "@/components/product/product-status-badge";
import { formatDateTime } from "@/lib/utils";
import Link from "next/link";
import {
  ChevronRight,
  CheckCircle,
  XCircle,
  ArrowLeft,
  ExternalLink,
  Ban,
  KeyRound,
  BellRing,
} from "lucide-react";
import { toast } from "sonner";
import Image from "next/image";

export default function VendorDetailPage() {
  const { id } = useParams<{ id: string }>();
  const [vendor, setVendor] = useState<Vendor | null>(null);
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);

  const [dialogOpen, setDialogOpen] = useState(false);
  const [dialogAction, setDialogAction] = useState<"approve" | "reject">("approve");
  const [rejectionReason, setRejectionReason] = useState("");

  const [sendingReset, setSendingReset] = useState(false);
  const [suspending, setSuspending] = useState(false);
  const [messageDialogOpen, setMessageDialogOpen] = useState(false);
  const [messageText, setMessageText] = useState("");
  const [sendingMessage, setSendingMessage] = useState(false);

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      try {
        const vendorData = await getVendorById(id as string);
        setVendor(vendorData);

        if (vendorData) {
          const productsData = await getProductsByVendorId(id as string);
          setProducts(productsData.products);
        }
      } catch (error) {
        console.error("Error fetching vendor data:", error);
        toast.error("Failed to load vendor data");
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [id]);

  const openApproveDialog = () => {
    setDialogAction("approve");
    setDialogOpen(true);
  };

  const openRejectDialog = () => {
    setDialogAction("reject");
    setRejectionReason("");
    setDialogOpen(true);
  };

  const handleConfirm = async () => {
    if (!vendor) return;

    try {
      if (dialogAction === "approve") {
        await updateVendorStatus(vendor.id, "approved");
        setVendor({ ...vendor, status: "approved" });
        toast.success(`Vendor ${vendor.name} has been approved`);
      } else {
        await updateVendorStatus(vendor.id, "rejected", rejectionReason);
        setVendor({ ...vendor, status: "rejected", rejectionReason });
        toast.success(`Vendor ${vendor.name} has been rejected`);
      }
    } catch (error) {
      console.error(`Error ${dialogAction}ing vendor:`, error);
      toast.error(`Failed to ${dialogAction} vendor`);
    } finally {
      setDialogOpen(false);
    }
  };

  const handlePasswordReset = async () => {
    if (!vendor?.email) {
      toast.error("Vendor has no email address on file");
      return;
    }

    setSendingReset(true);
    try {
      await resetPassword(vendor.email);
      toast.success("Password reset email dispatched");
    } catch (error) {
      console.error(error);
      toast.error("Could not send reset email");
    } finally {
      setSendingReset(false);
    }
  };

  const handleSuspensionToggle = async () => {
    if (!vendor) return;

    setSuspending(true);
    try {
      const shouldSuspend = !vendor.isSuspended;
      await toggleVendorSuspension(vendor.id, shouldSuspend, shouldSuspend ? "Operational compliance hold" : undefined);
      setVendor({
        ...vendor,
        isSuspended: shouldSuspend,
        suspensionReason: shouldSuspend ? "Operational compliance hold" : undefined,
      });
      toast.success(shouldSuspend ? "Vendor suspended" : "Vendor reactivated");
    } catch (error) {
      console.error(error);
      toast.error("Failed to update suspension status");
    } finally {
      setSuspending(false);
    }
  };

  const handleSendMessage = async () => {
    if (!vendor) return;
    const text = messageText.trim();
    if (!text) {
      toast.error("Message cannot be empty");
      return;
    }

    setSendingMessage(true);
    try {
      await createNotification({
        userId: vendor.id,
        title: "Message from SpareWo Admin",
        message: text,
        type: "info",
        link: "/notifications",
        read: false,
      });

      setMessageText("");
      setMessageDialogOpen(false);
      toast.success("Vendor notification sent");
    } catch (error) {
      console.error(error);
      toast.error("Failed to send vendor notification");
    } finally {
      setSendingMessage(false);
    }
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-96">
        <div className="w-8 h-8 border-4 border-primary border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  if (!vendor) {
    return (
      <div className="text-center py-12">
        <h2 className="text-xl font-semibold mb-2">Vendor Not Found</h2>
        <p className="text-gray-500 dark:text-gray-400 mb-6">
          The vendor you are looking for does not exist or has been removed.
        </p>
        <Link href="/dashboard/vendors">
          <Button>
            <ArrowLeft size={16} className="mr-2" />
            Back to Vendors
          </Button>
        </Link>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center">
          <Link href="/dashboard/vendors">
            <Button variant="ghost" size="icon" className="mr-2">
              <ArrowLeft size={20} />
            </Button>
          </Link>
          <div>
            <h1 className="text-2xl font-semibold">{vendor.name}</h1>
            <p className="text-gray-500 dark:text-gray-400">{vendor.businessName}</p>
          </div>
        </div>

        <div className="flex flex-wrap gap-2">
          <Button variant="outline" onClick={() => setMessageDialogOpen(true)}>
            <BellRing className="mr-2 h-4 w-4" /> Notify
          </Button>
          <Button variant="outline" onClick={handlePasswordReset} disabled={sendingReset || !vendor.email}>
            <KeyRound className="mr-2 h-4 w-4" /> {sendingReset ? "Sending..." : "Password Reset"}
          </Button>
          <Button variant={vendor.isSuspended ? "default" : "destructive"} onClick={handleSuspensionToggle} disabled={suspending}>
            <Ban className="mr-2 h-4 w-4" />
            {vendor.isSuspended ? "Reactivate" : "Suspend"}
          </Button>
          {vendor.status === "pending" && !vendor.isSuspended && (
            <>
              <Button onClick={openApproveDialog} className="bg-green-600 hover:bg-green-700">
                <CheckCircle size={16} className="mr-2" /> Approve
              </Button>
              <Button onClick={openRejectDialog} variant="destructive">
                <XCircle size={16} className="mr-2" /> Reject
              </Button>
            </>
          )}
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="md:col-span-2">
          <Tabs defaultValue="details">
            <TabsList>
              <TabsTrigger value="details">Details</TabsTrigger>
              <TabsTrigger value="products">Products</TabsTrigger>
              <TabsTrigger value="documents">Documents</TabsTrigger>
            </TabsList>

            <TabsContent value="details" className="pt-4">
              <Card>
                <CardHeader>
                  <CardTitle>Vendor Information</CardTitle>
                  <CardDescription>Detailed information about the vendor</CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <Info label="Contact Name" value={vendor.name} />
                    <Info label="Business Name" value={vendor.businessName} />
                    <Info label="Email" value={vendor.email} />
                    <Info label="Phone" value={vendor.phone} />
                    <Info label="Address" value={vendor.address} />
                    <Info label="Business Type" value={vendor.businessType} />
                    {vendor.businessRegistrationNumber && (
                      <Info label="Registration Number" value={vendor.businessRegistrationNumber} />
                    )}
                    {vendor.taxId && <Info label="Tax ID" value={vendor.taxId} />}
                  </div>

                  {vendor.description && (
                    <div>
                      <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400 mb-2">Description</h3>
                      <p className="text-sm">{vendor.description}</p>
                    </div>
                  )}
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="products" className="pt-4">
              <Card>
                <CardHeader>
                  <CardTitle>Vendor Products</CardTitle>
                  <CardDescription>Products uploaded by this vendor</CardDescription>
                </CardHeader>
                <CardContent>
                  {products.length === 0 ? (
                    <p className="text-center py-8 text-gray-500">This vendor has not uploaded products yet.</p>
                  ) : (
                    <div className="border rounded-lg overflow-hidden">
                      <Table>
                        <TableHeader>
                          <TableRow>
                            <TableHead>Product Name</TableHead>
                            <TableHead>Category</TableHead>
                            <TableHead>Price</TableHead>
                            <TableHead>Status</TableHead>
                            <TableHead className="text-right">Action</TableHead>
                          </TableRow>
                        </TableHeader>
                        <TableBody>
                          {products.map((product) => (
                            <TableRow key={product.id}>
                              <TableCell>{product.name}</TableCell>
                              <TableCell>{product.category}</TableCell>
                              <TableCell>UGX {product.price.toLocaleString()}</TableCell>
                              <TableCell>
                                <ProductStatusBadge status={product.status} />
                              </TableCell>
                              <TableCell className="text-right">
                                <Link href={`/dashboard/products/${product.id}`}>
                                  <Button variant="ghost" size="icon">
                                    <ChevronRight size={18} />
                                  </Button>
                                </Link>
                              </TableCell>
                            </TableRow>
                          ))}
                        </TableBody>
                      </Table>
                    </div>
                  )}
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="documents" className="pt-4">
              <Card>
                <CardHeader>
                  <CardTitle>Vendor Documents</CardTitle>
                  <CardDescription>Business verification documents</CardDescription>
                </CardHeader>
                <CardContent>
                  {!vendor.documentUrls || vendor.documentUrls.length === 0 ? (
                    <p className="text-center py-8 text-gray-500">No documents uploaded.</p>
                  ) : (
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      {vendor.documentUrls.map((url, index) => (
                        <div key={index} className="border rounded-lg p-4">
                          <div className="aspect-video relative bg-gray-100 mb-3 rounded overflow-hidden">
                            {url.endsWith(".pdf") ? (
                              <div className="flex items-center justify-center h-full">
                                <p className="text-gray-500">PDF Document</p>
                              </div>
                            ) : (
                              <Image
                                src={url}
                                alt={`Document ${index + 1}`}
                                fill
                                sizes="(max-width: 768px) 100vw, 50vw"
                                className="object-cover"
                              />
                            )}
                          </div>
                          <div className="flex justify-between items-center">
                            <p className="text-sm font-medium">Document {index + 1}</p>
                            <a href={url} target="_blank" rel="noopener noreferrer">
                              <Button variant="ghost" size="sm">
                                <ExternalLink size={14} className="mr-1" /> View
                              </Button>
                            </a>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </CardContent>
              </Card>
            </TabsContent>
          </Tabs>
        </div>

        <div>
          <Card>
            <CardHeader>
              <CardTitle>Status</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">Current Status</h3>
                <div className="mt-1">
                  <VendorStatusBadge status={vendor.status} isSuspended={vendor.isSuspended} />
                </div>
              </div>

              {vendor.status !== "pending" && !vendor.isSuspended && (
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => {
                    if (vendor.status === "approved") {
                      openRejectDialog();
                    } else {
                      openApproveDialog();
                    }
                  }}
                >
                  {vendor.status === "approved" ? "Reject" : "Approve"}
                </Button>
              )}

              <Info label="Date Joined" value={formatDateTime(vendor.createdAt)} />
              {vendor.status === "approved" && vendor.approvedAt && (
                <Info label="Approval Date" value={formatDateTime(vendor.approvedAt)} />
              )}
              {vendor.status === "rejected" && vendor.rejectedAt && (
                <Info label="Rejection Date" value={formatDateTime(vendor.rejectedAt)} />
              )}
              {vendor.rejectionReason && <Info label="Rejection Reason" value={vendor.rejectionReason} />}
              {vendor.isSuspended && (
                <Info label="Suspension Reason" value={vendor.suspensionReason || "Suspended by admin"} />
              )}
              <Info label="Product Count" value={String(products.length)} />
            </CardContent>
          </Card>

          {vendor.logoUrl && (
            <Card className="mt-4">
              <CardHeader>
                <CardTitle>Vendor Logo</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="aspect-square relative bg-gray-100 rounded overflow-hidden">
                  <Image
                    src={vendor.logoUrl}
                    alt={`${vendor.businessName} Logo`}
                    fill
                    sizes="(max-width: 768px) 100vw, 33vw"
                    className="object-contain"
                  />
                </div>
              </CardContent>
            </Card>
          )}
        </div>
      </div>

      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{dialogAction === "approve" ? "Approve Vendor" : "Reject Vendor"}</DialogTitle>
            <DialogDescription>
              {dialogAction === "approve"
                ? "Approve this vendor to allow marketplace operations."
                : "Provide a clear rejection reason."}
            </DialogDescription>
          </DialogHeader>

          {dialogAction === "reject" && (
            <Textarea
              placeholder="Reason for rejection"
              value={rejectionReason}
              onChange={(event) => setRejectionReason(event.target.value)}
              className="min-h-[100px]"
            />
          )}

          <DialogFooter>
            <Button variant="outline" onClick={() => setDialogOpen(false)}>
              Cancel
            </Button>
            <Button
              onClick={handleConfirm}
              variant={dialogAction === "approve" ? "default" : "destructive"}
              disabled={dialogAction === "reject" && !rejectionReason.trim()}
            >
              {dialogAction === "approve" ? "Approve" : "Reject"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={messageDialogOpen} onOpenChange={setMessageDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Send Vendor Notification</DialogTitle>
            <DialogDescription>
              Send an in-app message to {vendor.businessName}. This appears in their notification feed.
            </DialogDescription>
          </DialogHeader>
          <Textarea
            value={messageText}
            onChange={(event) => setMessageText(event.target.value)}
            placeholder="Write your message..."
            className="min-h-[120px]"
          />
          <DialogFooter>
            <Button variant="outline" onClick={() => setMessageDialogOpen(false)}>
              Cancel
            </Button>
            <Button onClick={handleSendMessage} disabled={sendingMessage || !messageText.trim()}>
              {sendingMessage ? "Sending..." : "Send Notification"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

function Info({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">{label}</h3>
      <p className="break-words">{value}</p>
    </div>
  );
}
