// src/app/dashboard/vendors/[id]/page.tsx
"use client";

import { useState, useEffect } from "react";
import { useParams } from "next/navigation";
import { getVendorById, updateVendorStatus } from "@/lib/firebase/vendors";
import { getProductsByVendorId } from "@/lib/firebase/products";
import { Vendor } from "@/lib/types/vendor";
import { Product } from "@/lib/types/product";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Tabs,
  TabsContent,
  TabsList,
  TabsTrigger,
} from "@/components/ui/tabs";
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
import { ChevronRight, CheckCircle, XCircle, ArrowLeft, ExternalLink } from "lucide-react";
import { toast } from "sonner";
import Image from "next/image";

export default function VendorDetailPage() {
  const { id } = useParams<{ id: string }>();
  const [vendor, setVendor] = useState<Vendor | null>(null);
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);

  // Dialog state
  const [dialogOpen, setDialogOpen] = useState(false);
  const [dialogAction, setDialogAction] = useState<"approve" | "reject">("approve");
  const [rejectionReason, setRejectionReason] = useState("");

  // Fetch vendor and products
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

  // Open approval dialog
  const openApproveDialog = () => {
    setDialogAction("approve");
    setDialogOpen(true);
  };

  // Open rejection dialog
  const openRejectDialog = () => {
    setDialogAction("reject");
    setRejectionReason("");
    setDialogOpen(true);
  };

  // Handle dialog confirmation
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

  if (loading) {
    return (
      <div className="flex justify-center items-center h-96">
        <div className="w-8 h-8 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
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
      <div className="flex items-center justify-between">
        <div className="flex items-center">
          <Link href="/dashboard/vendors">
            <Button variant="ghost" size="icon" className="mr-2">
              <ArrowLeft size={20} />
            </Button>
          </Link>
          <div>
            <h1 className="text-2xl font-semibold">{vendor.name}</h1>
            <p className="text-gray-500 dark:text-gray-400">
              {vendor.businessName}
            </p>
          </div>
        </div>

        {vendor.status === "pending" && (
          <div className="flex space-x-2">
            <Button
              onClick={openApproveDialog}
              variant="default"
              className="bg-green-600 hover:bg-green-700"
            >
              <CheckCircle size={16} className="mr-2" />
              Approve
            </Button>
            <Button
              onClick={openRejectDialog}
              variant="destructive"
            >
              <XCircle size={16} className="mr-2" />
              Reject
            </Button>
          </div>
        )}
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
                  <CardDescription>
                    Detailed information about the vendor
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                        Contact Name
                      </h3>
                      <p>{vendor.name}</p>
                    </div>
                    <div>
                      <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                        Business Name
                      </h3>
                      <p>{vendor.businessName}</p>
                    </div>
                    <div>
                      <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                        Email
                      </h3>
                      <p>{vendor.email}</p>
                    </div>
                    <div>
                      <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                        Phone
                      </h3>
                      <p>{vendor.phone}</p>
                    </div>
                    <div>
                      <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                        Address
                      </h3>
                      <p>{vendor.address}</p>
                    </div>
                    <div>
                      <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                        Business Type
                      </h3>
                      <p>{vendor.businessType}</p>
                    </div>
                    {vendor.businessRegistrationNumber && (
                      <div>
                        <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                          Registration Number
                        </h3>
                        <p>{vendor.businessRegistrationNumber}</p>
                      </div>
                    )}
                    {vendor.taxId && (
                      <div>
                        <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                          Tax ID
                        </h3>
                        <p>{vendor.taxId}</p>
                      </div>
                    )}
                  </div>

                  {vendor.description && (
                    <div>
                      <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400 mb-2">
                        Description
                      </h3>
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
                  <CardDescription>
                    Products uploaded by this vendor
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  {products.length === 0 ? (
                    <p className="text-center py-8 text-gray-500">
                      This vendor has not uploaded any products yet.
                    </p>
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
                              <TableCell>
                                UGX {product.price.toLocaleString()}
                              </TableCell>
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
                  <CardDescription>
                    Business verification documents
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  {!vendor.documentUrls || vendor.documentUrls.length === 0 ? (
                    <p className="text-center py-8 text-gray-500">
                      No documents have been uploaded by this vendor.
                    </p>
                  ) : (
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      {vendor.documentUrls.map((url, index) => (
                        <div key={index} className="border rounded-lg p-4">
                          <div className="aspect-video relative bg-gray-100 mb-3 rounded overflow-hidden">
                            {url.endsWith('.pdf') ? (
                              <div className="flex items-center justify-center h-full">
                                <p className="text-gray-500">PDF Document</p>
                              </div>
                            ) : (
                              <Image
                                src={url}
                                alt={`Document ${index + 1}`}
                                fill
                                className="object-cover"
                              />
                            )}
                          </div>
                          <div className="flex justify-between items-center">
                            <p className="text-sm font-medium">Document {index + 1}</p>
                            <a href={url} target="_blank" rel="noopener noreferrer">
                              <Button variant="ghost" size="sm">
                                <ExternalLink size={14} className="mr-1" />
                                View
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
              <div className="flex justify-between items-center">
                <div>
                  <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                    Current Status
                  </h3>
                  <div className="mt-1">
                    <VendorStatusBadge status={vendor.status} />
                  </div>
                </div>

                {vendor.status !== "pending" && (
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
              </div>

              <div>
                <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                  Date Joined
                </h3>
                <p>{formatDateTime(vendor.createdAt)}</p>
              </div>

              {vendor.status === "approved" && vendor.approvedAt && (
                <div>
                  <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                    Approval Date
                  </h3>
                  <p>{formatDateTime(vendor.approvedAt)}</p>
                </div>
              )}

              {vendor.status === "rejected" && vendor.rejectedAt && (
                <>
                  <div>
                    <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                      Rejection Date
                    </h3>
                    <p>{formatDateTime(vendor.rejectedAt)}</p>
                  </div>

                  {vendor.rejectionReason && (
                    <div>
                      <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                        Rejection Reason
                      </h3>
                      <p className="text-sm mt-1">{vendor.rejectionReason}</p>
                    </div>
                  )}
                </>
              )}

              <div>
                <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                  Product Count
                </h3>
                <p>{products.length}</p>
              </div>
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
                    className="object-contain"
                  />
                </div>
              </CardContent>
            </Card>
          )}
        </div>
      </div>

      {/* Approval/Rejection Dialog */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {dialogAction === "approve" ? "Approve Vendor" : "Reject Vendor"}
            </DialogTitle>
            <DialogDescription>
              {dialogAction === "approve"
                ? "Are you sure you want to approve this vendor? They will be able to upload products to the marketplace."
                : "Please provide a reason for rejecting this vendor."}
            </DialogDescription>
          </DialogHeader>

          {dialogAction === "reject" && (
            <Textarea
              placeholder="Reason for rejection"
              value={rejectionReason}
              onChange={(e) => setRejectionReason(e.target.value)}
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
    </div>
  );
}